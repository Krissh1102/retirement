import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:retierment/services/questions_data.dart';

class FinancialProvider extends ChangeNotifier {
  final FirebaseService _dataService = FirebaseService();

  // User Profile Data
  Map<String, dynamic>? _userProfile;
  bool _isLoading = false;
  String? _error;

  // Investment Data
  double _totalPortfolioValue = 0.0;
  double _totalInvested = 0.0;
  double _totalReturns = 0.0;
  double _returnPercentage = 0.0;
  List<Map<String, dynamic>> _holdings = [];
  List<Map<String, dynamic>> _transactions = [];
  Map<String, dynamic> _assetAllocation = {};

  // Goals Data
  RetirementProjection? _projection;
  List<Map<String, dynamic>> _milestones = [];
  double _corpusProgress = 0.0;
  double _targetCorpus = 0.0;
  double _currentCorpus = 0.0;
  double _monthlySIP = 0.0;

  // Spending Data
  Map<String, dynamic> _monthlyExpenses = {};
  List<Map<String, dynamic>> _spendingCategories = [];
  Map<String, dynamic> _spendingInsights = {};

  // Scenarios Data
  Map<String, dynamic> _projections = {};
  List<Map<String, dynamic>> _stressTests = [];
  List<String> _recommendations = [];

  // Stream subscriptions for real-time updates
  final Map<String, StreamSubscription> _streamSubscriptions = {};

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get userProfile => _userProfile;

  // Investment Getters
  double get totalPortfolioValue => _totalPortfolioValue;
  double get totalInvested => _totalInvested;
  double get totalReturns => _totalReturns;
  double get returnPercentage => _returnPercentage;
  List<Map<String, dynamic>> get holdings => _holdings;
  List<Map<String, dynamic>> get transactions => _transactions;
  Map<String, dynamic> get assetAllocation => _assetAllocation;

  // Goals Getters
  RetirementProjection? get projection => _projection;
  List<Map<String, dynamic>> get milestones => _milestones;
  double get corpusProgress => _corpusProgress;
  double get targetCorpus => _targetCorpus;
  double get currentCorpus => _currentCorpus;
  double get monthlySIP => _monthlySIP;

  // Spending Getters
  Map<String, dynamic> get monthlyExpenses => _monthlyExpenses;
  List<Map<String, dynamic>> get spendingCategories => _spendingCategories;
  Map<String, dynamic> get spendingInsights => _spendingInsights;

  // Scenarios Getters
  Map<String, dynamic> get projections => _projections;
  List<Map<String, dynamic>> get stressTests => _stressTests;
  List<String> get recommendations => _recommendations;

  // ============================================================================
  // INITIALIZATION & DATA LOADING
  // ============================================================================

  /// Load complete user profile with hierarchical structure
  Future<void> loadUserProfile([String? userId]) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Check if user data exists, initialize if not
      final userExists = await _dataService.userDataExists(userId);
      if (!userExists) {
        await _dataService.initializeUserData(userId);
      }

      // Load complete user profile from all subcollections
      _userProfile = await _dataService.loadUserProfile(userId);

      if (_userProfile != null) {
        _parseHierarchicalUserData(_userProfile!);
        _setupRealTimeListeners(userId);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void _parseHierarchicalUserData(Map<String, dynamic> data) {
    // Parse Investment Data from subcollection
    final investments = data['investments'] as Map<String, dynamic>?;
    if (investments != null) {
      // Parse portfolio summary
      final portfolio =
          investments['portfolio_summary'] as Map<String, dynamic>?;
      if (portfolio != null) {
        _totalPortfolioValue = _safeDouble(portfolio['current_value']);
        _totalInvested = _safeDouble(portfolio['total_invested']);
        _totalReturns = _safeDouble(portfolio['total_returns']);
        _returnPercentage = _safeDouble(portfolio['returns_percentage']);
        _assetAllocation = Map<String, dynamic>.from(
          portfolio['asset_allocation'] ?? {},
        );
      }

      // Parse holdings - FIXED
      var holdingsData = investments['holdings'];
      if (holdingsData != null) {
        // Handle if holdingsData is Map<dynamic, dynamic>
        if (holdingsData is! Map<String, dynamic> && holdingsData is Map) {
          holdingsData = Map<String, dynamic>.from(holdingsData);
        }

        if (holdingsData is Map<String, dynamic>) {
          final holdingsList = holdingsData['holdings'] as List?;
          _holdings =
              holdingsList?.map((item) {
                if (item is Map<String, dynamic>) {
                  return item;
                } else if (item is Map) {
                  return Map<String, dynamic>.from(item);
                }
                return <String, dynamic>{};
              }).toList() ??
              [];
        }
      }

      // Parse transactions - FIXED
      var transactionsData = investments['transactions'];
      if (transactionsData != null) {
        // Handle if transactionsData is Map<dynamic, dynamic>
        if (transactionsData is! Map<String, dynamic> &&
            transactionsData is Map) {
          transactionsData = Map<String, dynamic>.from(transactionsData);
        }

        if (transactionsData is Map<String, dynamic>) {
          final transactionsList = transactionsData['transactions'] as List?;
          _transactions =
              transactionsList?.map((item) {
                if (item is Map<String, dynamic>) {
                  return item;
                } else if (item is Map) {
                  return Map<String, dynamic>.from(item);
                }
                return <String, dynamic>{};
              }).toList() ??
              [];
        }
      }
    }

    // Parse Goals Data from subcollection
    final goals = data['goals'] as Map<String, dynamic>?;
    if (goals != null) {
      // Parse retirement goals
      final retirementGoals =
          goals['retirement_goals'] as Map<String, dynamic>?;
      if (retirementGoals != null) {
        _targetCorpus = _safeDouble(retirementGoals['target_corpus']);
        _currentCorpus = _safeDouble(retirementGoals['current_corpus']);
        _monthlySIP = _safeDouble(retirementGoals['monthly_sip']);

        _projection = RetirementProjection(
          targetCorpus: _targetCorpus,
          currentCorpus: _currentCorpus,
          monthlySIP: _monthlySIP,
          yearsToRetirement: _safeInt(retirementGoals['years_to_retirement']),
          expectedReturn: _safeDouble(retirementGoals['expected_return']),
          inflationRate: _safeDouble(retirementGoals['inflation_rate']),
          successProbability: _safeDouble(
            retirementGoals['success_probability'],
          ),
        );
      }

      // Parse milestones - FIXED
      var milestonesData = goals['milestones'];
      if (milestonesData != null) {
        // Handle if milestonesData is Map<dynamic, dynamic>
        if (milestonesData is! Map<String, dynamic> && milestonesData is Map) {
          milestonesData = Map<String, dynamic>.from(milestonesData);
        }

        if (milestonesData is Map<String, dynamic>) {
          final milestonesList = milestonesData['milestones'] as List?;
          _milestones =
              milestonesList?.map((item) {
                if (item is Map<String, dynamic>) {
                  return item;
                } else if (item is Map) {
                  return Map<String, dynamic>.from(item);
                }
                return <String, dynamic>{};
              }).toList() ??
              [];
        }
      }

      // Parse progress
      final progress = goals['progress'] as Map<String, dynamic>?;
      if (progress != null) {
        _corpusProgress = _safeDouble(progress['corpus_progress']);
      }
    }

    // Parse Spending Data from subcollection
    final spending = data['spending'] as Map<String, dynamic>?;
    if (spending != null) {
      // Parse monthly expenses
      final monthlyExpensesData =
          spending['monthly_expenses'] as Map<String, dynamic>?;
      _monthlyExpenses =
          monthlyExpensesData != null
              ? Map<String, dynamic>.from(monthlyExpensesData)
              : {};

      // Parse categories - FIXED
      var categoriesData = spending['categories'];
      if (categoriesData != null) {
        // Handle if categoriesData is Map<dynamic, dynamic>
        if (categoriesData is! Map<String, dynamic> && categoriesData is Map) {
          categoriesData = Map<String, dynamic>.from(categoriesData);
        }

        if (categoriesData is Map<String, dynamic>) {
          final categoriesList = categoriesData['categories'] as List?;
          _spendingCategories =
              categoriesList?.map((item) {
                if (item is Map<String, dynamic>) {
                  return item;
                } else if (item is Map) {
                  return Map<String, dynamic>.from(item);
                }
                return <String, dynamic>{};
              }).toList() ??
              [];
        }
      }

      // Parse insights
      final insightsData = spending['insights'] as Map<String, dynamic>?;
      _spendingInsights =
          insightsData != null ? Map<String, dynamic>.from(insightsData) : {};
    }

    // Parse Scenarios Data from subcollection
    final scenarios = data['scenarios'] as Map<String, dynamic>?;
    if (scenarios != null) {
      // Parse projections
      final projectionsData = scenarios['projections'] as Map<String, dynamic>?;
      _projections =
          projectionsData != null
              ? Map<String, dynamic>.from(projectionsData)
              : {};

      // Parse stress tests - FIXED
      final stressTestsData =
          scenarios['stress_tests'] as Map<String, dynamic>?;
      if (stressTestsData != null) {
        final stressTestsList = stressTestsData['stress_tests'] as List?;
        _stressTests =
            stressTestsList?.map((item) {
              if (item is Map<String, dynamic>) {
                return item;
              } else if (item is Map) {
                return Map<String, dynamic>.from(item);
              }
              return <String, dynamic>{};
            }).toList() ??
            [];
      }

      // Parse recommendations - FIXED
      final recommendationsData =
          scenarios['recommendations'] as Map<String, dynamic>?;
      if (recommendationsData != null) {
        final recList = recommendationsData['recommendations'] as List?;
        _recommendations =
            recList?.map((item) => item.toString()).toList() ?? [];
      }
    }
  }

  /// Setup real-time listeners for different collections
  void _setupRealTimeListeners([String? userId]) {
    _clearStreamSubscriptions();

    // Listen to investment changes
    _streamSubscriptions['investments'] = _dataService
        .getUserDataStream('investments')
        .listen(
          (snapshot) => _handleInvestmentUpdate(snapshot),
          onError: (error) => _handleStreamError(error),
        );

    // Listen to goals changes
    _streamSubscriptions['goals'] = _dataService
        .getUserDataStream('goals')
        .listen(
          (snapshot) => _handleGoalsUpdate(snapshot),
          onError: (error) => _handleStreamError(error),
        );

    // Listen to spending changes
    _streamSubscriptions['spending'] = _dataService
        .getUserDataStream('spending')
        .listen(
          (snapshot) => _handleSpendingUpdate(snapshot),
          onError: (error) => _handleStreamError(error),
        );

    // Listen to scenarios changes
    _streamSubscriptions['scenarios'] = _dataService
        .getUserDataStream('scenarios')
        .listen(
          (snapshot) => _handleScenariosUpdate(snapshot),
          onError: (error) => _handleStreamError(error),
        );
  }

  // ============================================================================
  // REAL-TIME UPDATE HANDLERS
  // ============================================================================

  void _handleInvestmentUpdate(QuerySnapshot snapshot) {
    final investmentData = <String, dynamic>{};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data is Map<String, dynamic>) {
        investmentData[doc.id] = data;
      } else if (data is Map) {
        investmentData[doc.id] = Map<String, dynamic>.from(data);
      }
    }

    // Update investment-related properties
    _parseInvestmentData({'investments': investmentData});
    notifyListeners();
  }

  void _handleGoalsUpdate(QuerySnapshot snapshot) {
    final goalsData = <String, dynamic>{};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data is Map<String, dynamic>) {
        goalsData[doc.id] = data;
      } else if (data is Map) {
        goalsData[doc.id] = Map<String, dynamic>.from(data);
      }
    }

    // Update goals-related properties
    _parseGoalsData({'goals': goalsData});
    notifyListeners();
  }

  void _handleSpendingUpdate(QuerySnapshot snapshot) {
    final spendingData = <String, dynamic>{};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data is Map<String, dynamic>) {
        spendingData[doc.id] = data;
      } else if (data is Map) {
        spendingData[doc.id] = Map<String, dynamic>.from(data);
      }
    }

    // Update spending-related properties
    _parseSpendingData({'spending': spendingData});
    notifyListeners();
  }

  void _handleScenariosUpdate(QuerySnapshot snapshot) {
    final scenariosData = <String, dynamic>{};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data is Map<String, dynamic>) {
        scenariosData[doc.id] = data;
      } else if (data is Map) {
        scenariosData[doc.id] = Map<String, dynamic>.from(data);
      }
    }

    // Update scenarios-related properties
    _parseScenariosData({'scenarios': scenariosData});
    notifyListeners();
  }

  void _handleStreamError(dynamic error) {
    _error = error.toString();
    notifyListeners();
  }

  // ============================================================================
  // INDIVIDUAL DATA PARSERS
  // ============================================================================

  void _parseInvestmentData(Map<String, dynamic> data) {
    final investments = data['investments'] as Map<String, dynamic>?;
    if (investments != null) {
      final portfolio =
          investments['portfolio_summary'] as Map<String, dynamic>?;
      if (portfolio != null) {
        _totalPortfolioValue = _safeDouble(portfolio['current_value']);
        _totalInvested = _safeDouble(portfolio['total_invested']);
        _totalReturns = _safeDouble(portfolio['total_returns']);
        _returnPercentage = _safeDouble(portfolio['returns_percentage']);

        final allocation = portfolio['asset_allocation'];
        if (allocation is Map<String, dynamic>) {
          _assetAllocation = allocation;
        } else if (allocation is Map) {
          _assetAllocation = Map<String, dynamic>.from(allocation);
        } else {
          _assetAllocation = {};
        }
      }

      var holdingsData = investments['holdings'];
      if (holdingsData != null) {
        if (holdingsData is! Map<String, dynamic> && holdingsData is Map) {
          holdingsData = Map<String, dynamic>.from(holdingsData);
        }

        if (holdingsData is Map<String, dynamic>) {
          final holdingsList = holdingsData['holdings'] as List?;
          _holdings =
              holdingsList?.map((item) {
                if (item is Map<String, dynamic>) {
                  return item;
                } else if (item is Map) {
                  return Map<String, dynamic>.from(item);
                }
                return <String, dynamic>{};
              }).toList() ??
              [];
        }
      }

      var transactionsData = investments['transactions'];
      if (transactionsData != null) {
        if (transactionsData is! Map<String, dynamic> &&
            transactionsData is Map) {
          transactionsData = Map<String, dynamic>.from(transactionsData);
        }

        if (transactionsData is Map<String, dynamic>) {
          final transactionsList = transactionsData['transactions'] as List?;
          _transactions =
              transactionsList?.map((item) {
                if (item is Map<String, dynamic>) {
                  return item;
                } else if (item is Map) {
                  return Map<String, dynamic>.from(item);
                }
                return <String, dynamic>{};
              }).toList() ??
              [];
        }
      }
    }
  }

  void _parseGoalsData(Map<String, dynamic> data) {
    final goals = data['goals'] as Map<String, dynamic>?;
    if (goals != null) {
      final retirementGoals =
          goals['retirement_goals'] as Map<String, dynamic>?;
      if (retirementGoals != null) {
        _targetCorpus = _safeDouble(retirementGoals['target_corpus']);
        _currentCorpus = _safeDouble(retirementGoals['current_corpus']);
        _monthlySIP = _safeDouble(retirementGoals['monthly_sip']);

        _projection = RetirementProjection(
          targetCorpus: _targetCorpus,
          currentCorpus: _currentCorpus,
          monthlySIP: _monthlySIP,
          yearsToRetirement: _safeInt(retirementGoals['years_to_retirement']),
          expectedReturn: _safeDouble(retirementGoals['expected_return']),
          inflationRate: _safeDouble(retirementGoals['inflation_rate']),
          successProbability: _safeDouble(
            retirementGoals['success_probability'],
          ),
        );
      }

      final milestonesData = goals['milestones'] as Map<String, dynamic>?;
      if (milestonesData != null) {
        final milestonesList = milestonesData['milestones'] as List?;
        _milestones =
            milestonesList?.map((item) {
              if (item is Map<String, dynamic>) {
                return item;
              } else if (item is Map) {
                return Map<String, dynamic>.from(item);
              }
              return <String, dynamic>{};
            }).toList() ??
            [];
      }

      final progress = goals['progress'] as Map<String, dynamic>?;
      if (progress != null) {
        _corpusProgress = _safeDouble(progress['corpus_progress']);
      }
    }
  }

  void _parseSpendingData(Map<String, dynamic> data) {
    final spending = data['spending'] as Map<String, dynamic>?;
    if (spending != null) {
      final monthlyExpensesData =
          spending['monthly_expenses'] as Map<String, dynamic>?;
      if (monthlyExpensesData is Map<String, dynamic>) {
        _monthlyExpenses = monthlyExpensesData;
      } else if (monthlyExpensesData is Map) {
        _monthlyExpenses = Map<String, dynamic>.from(
          monthlyExpensesData as Map,
        );
      } else {
        _monthlyExpenses = {};
      }

      var categoriesData = spending['categories'];
      if (categoriesData != null) {
        if (categoriesData is! Map<String, dynamic> && categoriesData is Map) {
          categoriesData = Map<String, dynamic>.from(categoriesData);
        }

        if (categoriesData is Map<String, dynamic>) {
          final categoriesList = categoriesData['categories'] as List?;
          _spendingCategories =
              categoriesList?.map((item) {
                if (item is Map<String, dynamic>) {
                  return item;
                } else if (item is Map) {
                  return Map<String, dynamic>.from(item);
                }
                return <String, dynamic>{};
              }).toList() ??
              [];
        }
      }

      final insightsData = spending['insights'] as Map<String, dynamic>?;
      if (insightsData is Map<String, dynamic>) {
        _spendingInsights = insightsData;
      } else if (insightsData is Map) {
        _spendingInsights = Map<String, dynamic>.from(insightsData as Map);
      } else {
        _spendingInsights = {};
      }
    }
  }

  void _parseScenariosData(Map<String, dynamic> data) {
    final scenarios = data['scenarios'] as Map<String, dynamic>?;
    if (scenarios != null) {
      final projectionsData = scenarios['projections'] as Map<String, dynamic>?;
      if (projectionsData is Map<String, dynamic>) {
        _projections = projectionsData;
      } else if (projectionsData is Map) {
        _projections = Map<String, dynamic>.from(projectionsData as Map);
      } else {
        _projections = {};
      }

      final stressTestsData =
          scenarios['stress_tests'] as Map<String, dynamic>?;
      if (stressTestsData != null) {
        final stressTestsList = stressTestsData['stress_tests'] as List?;
        _stressTests =
            stressTestsList?.map((item) {
              if (item is Map<String, dynamic>) {
                return item;
              } else if (item is Map) {
                return Map<String, dynamic>.from(item);
              }
              return <String, dynamic>{};
            }).toList() ??
            [];
      }

      final recommendationsData =
          scenarios['recommendations'] as Map<String, dynamic>?;
      if (recommendationsData != null) {
        final recList = recommendationsData['recommendations'] as List?;
        _recommendations =
            recList?.map((item) => item.toString()).toList() ?? [];
      }
    }
  }

  // ============================================================================
  // UPDATE METHODS
  // ============================================================================

  /// Update portfolio value
  Future<void> updatePortfolioValue(double newValue, [String? userId]) async {
    try {
      await _dataService.updatePortfolioValue(newValue, userId);
      // Real-time listener will automatically update the UI
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Update monthly expenses
  Future<void> updateMonthlyExpenses(
    Map<String, dynamic> expenses, [
    String? userId,
  ]) async {
    try {
      await _dataService.updateMonthlyExpenses(expenses, userId);
      // Real-time listener will automatically update the UI
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Add new transaction
  Future<void> addTransaction(
    Map<String, dynamic> transaction, [
    String? userId,
  ]) async {
    try {
      await _dataService.addTransaction(transaction, userId);
      // Real-time listener will automatically update the UI
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Add new holding
  Future<void> addHolding(
    Map<String, dynamic> holding, [
    String? userId,
  ]) async {
    try {
      await _dataService.addHolding(holding, userId);
      // Real-time listener will automatically update the UI
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Update retirement goals
  Future<void> updateRetirementGoals(
    Map<String, dynamic> goals, [
    String? userId,
  ]) async {
    try {
      await _dataService.updateRetirementGoals(goals, userId);
      // Real-time listener will automatically update the UI
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Update spending categories
  Future<void> updateSpendingCategories(
    List<Map<String, dynamic>> categories, [
    String? userId,
  ]) async {
    try {
      await _dataService.updateSpendingCategories(categories, userId);
      // Real-time listener will automatically update the UI
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Add expense to category
  Future<void> addExpenseToCategory(
    String categoryId,
    double amount,
    String description, [
    String? userId,
  ]) async {
    try {
      await _dataService.addExpenseToCategory(
        categoryId,
        amount,
        description,
        userId,
      );
      // Real-time listener will automatically update the UI
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Update milestone progress
  Future<void> updateMilestoneProgress(
    String milestoneId,
    double progress, [
    String? userId,
  ]) async {
    try {
      await _dataService.updateMilestoneProgress(milestoneId, progress, userId);
      // Real-time listener will automatically update the UI
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Save retirement questionnaire data
  Future<void> saveRetirementData(Map<String, dynamic> userData) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _dataService.saveRetirementData(userData);

      // Reload the complete profile after saving
      await loadUserProfile();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================================
  // ANALYTICS & HELPER METHODS
  // ============================================================================

  /// Get portfolio analytics
  Future<Map<String, dynamic>> getPortfolioAnalytics([String? userId]) async {
    try {
      return await _dataService.getPortfolioAnalytics(userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return {};
    }
  }

  /// Get spending analytics
  Future<Map<String, dynamic>> getSpendingAnalytics([String? userId]) async {
    try {
      return await _dataService.getSpendingAnalytics(userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return {};
    }
  }

  // ============================================================================
  // DASHBOARD HELPER METHODS
  // ============================================================================

  String getPortfolioValueFormatted() {
    if (_totalPortfolioValue >= 10000000) {
      return '₹${(_totalPortfolioValue / 10000000).toStringAsFixed(2)} Cr';
    } else if (_totalPortfolioValue >= 100000) {
      return '₹${(_totalPortfolioValue / 100000).toStringAsFixed(2)} L';
    } else if (_totalPortfolioValue >= 1000) {
      return '₹${(_totalPortfolioValue / 1000).toStringAsFixed(1)} K';
    }
    return '₹${_totalPortfolioValue.toStringAsFixed(0)}';
  }

  String getMonthlySIPFormatted() {
    if (_monthlySIP >= 100000) {
      return '₹${(_monthlySIP / 100000).toStringAsFixed(2)} L';
    } else if (_monthlySIP >= 1000) {
      return '₹${(_monthlySIP / 1000).toStringAsFixed(0)} K';
    }
    return '₹${_monthlySIP.toStringAsFixed(0)}';
  }

  String getReturnPercentageFormatted() {
    return '${_returnPercentage >= 0 ? '+' : ''}${_returnPercentage.toStringAsFixed(1)}%';
  }

  Color getReturnColor() {
    return _returnPercentage >= 0 ? Colors.green : Colors.red;
  }

  double getReadinessScore() {
    return (_projection?.successProbability ?? 0.75) * 100;
  }

  String getReadinessScoreFormatted() {
    return '${getReadinessScore().toStringAsFixed(0)}%';
  }

  /// Get top performing fund
  Map<String, dynamic>? getTopPerformingFund() {
    if (_holdings.isEmpty) return null;

    return _holdings.reduce((a, b) {
      final aReturn = _safeDouble(a['return_percentage']);
      final bReturn = _safeDouble(b['return_percentage']);
      return aReturn > bReturn ? a : b;
    });
  }

  /// Get spending category insights
  Map<String, dynamic> getSpendingCategoryInsight() {
    if (_spendingCategories.isEmpty) {
      return {
        'highest_category': null,
        'total_budget': 0.0,
        'total_spent': 0.0,
        'budget_utilization': 0.0,
      };
    }

    final highestSpendingCategory = _spendingCategories.reduce((a, b) {
      final aSpent = _safeDouble(a['spent']);
      final bSpent = _safeDouble(b['spent']);
      return aSpent > bSpent ? a : b;
    });

    final totalBudget = _spendingCategories.fold<double>(
      0.0,
      (sum, category) => sum + _safeDouble(category['budget']),
    );

    final totalSpent = _spendingCategories.fold<double>(
      0.0,
      (sum, category) => sum + _safeDouble(category['spent']),
    );

    return {
      'highest_category': highestSpendingCategory,
      'total_budget': totalBudget,
      'total_spent': totalSpent,
      'budget_utilization': totalBudget > 0 ? (totalSpent / totalBudget) : 0.0,
    };
  }

  /// Get next milestone
  Map<String, dynamic>? getNextMilestone() {
    if (_milestones.isEmpty) return null;

    // Find the first unachieved milestone
    for (final milestone in _milestones) {
      if (!(milestone['achieved'] ?? false)) {
        return milestone;
      }
    }

    return null; // All milestones achieved
  }

  /// Get completed milestones count
  int getCompletedMilestonesCount() {
    return _milestones.where((m) => m['achieved'] ?? false).length;
  }

  /// Get milestone completion percentage
  double getMilestoneCompletionPercentage() {
    if (_milestones.isEmpty) return 0.0;
    return (getCompletedMilestonesCount() / _milestones.length) * 100;
  }

  /// Check if user is on track for retirement
  bool get isOnTrackForRetirement {
    return _projection?.isOnTrack ?? false;
  }

  /// Get projected vs target corpus status
  Map<String, dynamic> getCorpusStatus() {
    if (_projection == null) {
      return {
        'projected': 0.0,
        'target': _targetCorpus,
        'shortfall': _targetCorpus,
        'is_sufficient': false,
        'percentage_achieved': 0.0,
      };
    }

    final projected = _projection!.projectedCorpus;
    final shortfall = _projection!.shortfall;
    final issufficient = shortfall <= 0;
    final percentageAchieved =
        _targetCorpus > 0 ? (projected / _targetCorpus) * 100 : 0.0;

    return {
      'projected': projected,
      'target': _targetCorpus,
      'shortfall': shortfall,
      'is_sufficient': issufficient,
      'percentage_achieved': percentageAchieved.clamp(0.0, 100.0),
    };
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Safe conversion to double with null/type checking
  double _safeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Safe conversion to int with null/type checking
  int _safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Clear all stream subscriptions
  void _clearStreamSubscriptions() {
    for (final subscription in _streamSubscriptions.values) {
      subscription.cancel();
    }
    _streamSubscriptions.clear();
  }

  /// Refresh all data
  Future<void> refreshData([String? userId]) async {
    await loadUserProfile(userId);
  }

  @override
  void dispose() {
    _clearStreamSubscriptions();
    super.dispose();
  }
}

// ============================================================================
// RETIREMENT PROJECTION MODEL
// ============================================================================

class RetirementProjection {
  final double targetCorpus;
  final double currentCorpus;
  final double monthlySIP;
  final int yearsToRetirement;
  final double expectedReturn;
  final double inflationRate;
  final double successProbability;

  RetirementProjection({
    required this.targetCorpus,
    required this.currentCorpus,
    required this.monthlySIP,
    required this.yearsToRetirement,
    required this.expectedReturn,
    required this.inflationRate,
    required this.successProbability,
  });

  /// Calculate projected corpus at retirement
  double get projectedCorpus {
    if (yearsToRetirement <= 0) return currentCorpus;

    final monthlyReturn = expectedReturn / 12;
    final totalMonths = yearsToRetirement * 12;

    // Future value of current corpus
    final currentCorpusFV =
        currentCorpus * pow(1 + expectedReturn, yearsToRetirement);

    // Future value of SIP annuity
    double sipFV = 0.0;
    if (monthlyReturn > 0 && monthlySIP > 0) {
      sipFV =
          monthlySIP *
          ((pow(1 + monthlyReturn, totalMonths) - 1) / monthlyReturn);
    } else {
      sipFV = monthlySIP * totalMonths;
    }

    return currentCorpusFV + sipFV;
  }

  /// Calculate shortfall or surplus
  double get shortfall {
    final projected = projectedCorpus;
    return projected >= targetCorpus ? 0 : targetCorpus - projected;
  }

  /// Calculate surplus if any
  double get surplus {
    final projected = projectedCorpus;
    return projected > targetCorpus ? projected - targetCorpus : 0;
  }

  /// Calculate required monthly SIP to achieve target
  double get requiredMonthlySIP {
    if (shortfall <= 0 || yearsToRetirement <= 0) return monthlySIP;

    final monthlyReturn = expectedReturn / 12;
    final totalMonths = yearsToRetirement * 12;
    final currentCorpusFV =
        currentCorpus * pow(1 + expectedReturn, yearsToRetirement);
    final remainingTarget = targetCorpus - currentCorpusFV;

    if (remainingTarget <= 0) return 0;

    if (monthlyReturn > 0) {
      return remainingTarget *
          monthlyReturn /
          (pow(1 + monthlyReturn, totalMonths) - 1);
    } else {
      return remainingTarget / totalMonths;
    }
  }

  /// Check if current plan is on track
  bool get isOnTrack => successProbability >= 0.75;

  /// Get projection status
  String get status {
    if (isOnTrack) return 'On Track';
    if (successProbability >= 0.5) return 'Moderate Risk';
    return 'High Risk';
  }

  /// Get projection status color
  Color get statusColor {
    if (isOnTrack) return Colors.green;
    if (successProbability >= 0.5) return Colors.orange;
    return Colors.red;
  }

  /// Calculate years until target is achieved at current rate
  double get yearsToTarget {
    if (monthlySIP <= 0 || expectedReturn <= 0) return double.infinity;

    final monthlyReturn = expectedReturn / 12;
    final targetWithoutCurrent = targetCorpus - currentCorpus;

    if (targetWithoutCurrent <= 0) return 0;

    // Using logarithmic formula to solve for time
    final numerator = log(
      1 + (targetWithoutCurrent * monthlyReturn) / monthlySIP,
    );
    final denominator = log(1 + monthlyReturn);

    return numerator / denominator / 12; // Convert months to years
  }

  /// Get formatted projection details
  Map<String, String> get formattedDetails {
    return {
      'projected_corpus': _formatCurrency(projectedCorpus),
      'target_corpus': _formatCurrency(targetCorpus),
      'shortfall': shortfall > 0 ? _formatCurrency(shortfall) : '₹0',
      'surplus': surplus > 0 ? _formatCurrency(surplus) : '₹0',
      'required_monthly_sip': _formatCurrency(requiredMonthlySIP),
      'current_monthly_sip': _formatCurrency(monthlySIP),
      'years_to_retirement': yearsToRetirement.toString(),
      'success_probability':
          '${(successProbability * 100).toStringAsFixed(0)}%',
      'expected_return': '${(expectedReturn * 100).toStringAsFixed(1)}%',
      'inflation_rate': '${(inflationRate * 100).toStringAsFixed(1)}%',
    };
  }

  /// Format currency for display
  String _formatCurrency(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(2)} L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(0)} K';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  /// Calculate monthly investment needed for a specific target
  double calculateMonthlySIPForTarget(
    double targetAmount,
    int years,
    double returnRate,
  ) {
    if (years <= 0 || targetAmount <= 0) return 0.0;

    final monthlyReturn = returnRate / 12;
    final totalMonths = years * 12;
    final currentCorpusFV = currentCorpus * pow(1 + returnRate, years);
    final remainingTarget = targetAmount - currentCorpusFV;

    if (remainingTarget <= 0) return 0.0;

    if (monthlyReturn > 0) {
      return remainingTarget *
          monthlyReturn /
          (pow(1 + monthlyReturn, totalMonths) - 1);
    } else {
      return remainingTarget / totalMonths;
    }
  }

  /// Get scenario projections for different return rates
  Map<String, double> get scenarioProjections {
    return {
      'conservative': _calculateProjection(0.08), // 8% return
      'moderate': _calculateProjection(0.12), // 12% return
      'aggressive': _calculateProjection(0.15), // 15% return
    };
  }

  double _calculateProjection(double returnRate) {
    if (yearsToRetirement <= 0) return currentCorpus;

    final monthlyReturn = returnRate / 12;
    final totalMonths = yearsToRetirement * 12;

    // Future value of current corpus
    final currentCorpusFV =
        currentCorpus * pow(1 + returnRate, yearsToRetirement);

    // Future value of SIP annuity
    double sipFV = 0.0;
    if (monthlyReturn > 0 && monthlySIP > 0) {
      sipFV =
          monthlySIP *
          ((pow(1 + monthlyReturn, totalMonths) - 1) / monthlyReturn);
    } else {
      sipFV = monthlySIP * totalMonths;
    }

    return currentCorpusFV + sipFV;
  }

  /// Get inflation-adjusted target corpus
  double get inflationAdjustedTarget {
    if (yearsToRetirement <= 0) return targetCorpus;
    return targetCorpus * pow(1 + inflationRate, yearsToRetirement);
  }

  /// Calculate real return rate (adjusted for inflation)
  double get realReturnRate {
    return ((1 + expectedReturn) / (1 + inflationRate)) - 1;
  }

  /// Get retirement readiness assessment
  Map<String, dynamic> get readinessAssessment {
    final projected = projectedCorpus;
    final achievementRatio = targetCorpus > 0 ? projected / targetCorpus : 0.0;

    String assessment;
    String recommendation;
    Color statusColor;

    if (achievementRatio >= 1.2) {
      assessment = 'Excellent';
      recommendation = 'You\'re on track to exceed your retirement goal!';
      statusColor = Colors.green[700]!;
    } else if (achievementRatio >= 1.0) {
      assessment = 'Good';
      recommendation = 'You\'re on track to meet your retirement goal.';
      statusColor = Colors.green;
    } else if (achievementRatio >= 0.8) {
      assessment = 'Fair';
      recommendation =
          'Consider increasing your SIP by ${((requiredMonthlySIP - monthlySIP) / 1000).toStringAsFixed(0)}K monthly.';
      statusColor = Colors.orange;
    } else if (achievementRatio >= 0.6) {
      assessment = 'Poor';
      recommendation = 'Significant increase in investment needed.';
      statusColor = Colors.red[300]!;
    } else {
      assessment = 'Critical';
      recommendation = 'Major changes to retirement plan required.';
      statusColor = Colors.red[700]!;
    }

    return {
      'score': (achievementRatio * 100).clamp(0.0, 100.0),
      'assessment': assessment,
      'recommendation': recommendation,
      'status_color': statusColor,
      'achievement_ratio': achievementRatio,
    };
  }

  @override
  String toString() {
    return 'RetirementProjection('
        'target: ${_formatCurrency(targetCorpus)}, '
        'projected: ${_formatCurrency(projectedCorpus)}, '
        'shortfall: ${_formatCurrency(shortfall)}, '
        'success: ${(successProbability * 100).toStringAsFixed(0)}%)';
  }
}
