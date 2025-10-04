import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  DocumentReference get _userDocRef =>
      _firestore.collection('users').doc(_currentUserId);

  CollectionReference get _profileCollection =>
      _userDocRef.collection('profile');
  CollectionReference get _investmentsCollection =>
      _userDocRef.collection('investments');
  CollectionReference get _goalsCollection => _userDocRef.collection('goals');
  CollectionReference get _spendingCollection =>
      _userDocRef.collection('spending');
  CollectionReference get _scenariosCollection =>
      _userDocRef.collection('scenarios');

  Future<void> initializeUserData([String? userId]) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) throw Exception('User not authenticated');

    try {
      final userDocRef = _firestore.collection('users').doc(uid);
      final docSnapshot = await userDocRef.get();

      if (!docSnapshot.exists) {
        WriteBatch batch = _firestore.batch();

        final defaultData = _getDefaultUserData();

        batch.set(
          _firestore
              .collection('users')
              .doc(uid)
              .collection('profile')
              .doc('personal_info'),
          defaultData['profile']['personal_info'],
        );
        batch.set(
          _firestore
              .collection('users')
              .doc(uid)
              .collection('profile')
              .doc('financial_profile'),
          defaultData['profile']['financial_profile'],
        );
        batch.set(
          _firestore
              .collection('users')
              .doc(uid)
              .collection('profile')
              .doc('preferences'),
          defaultData['profile']['preferences'],
        );

        batch.set(
          _firestore
              .collection('users')
              .doc(uid)
              .collection('investments')
              .doc('portfolio_summary'),
          defaultData['investments']['portfolio_summary'],
        );
        batch.set(
          _firestore
              .collection('users')
              .doc(uid)
              .collection('investments')
              .doc('holdings'),
          {'holdings': []},
        );
        batch.set(
          _firestore
              .collection('users')
              .doc(uid)
              .collection('investments')
              .doc('transactions'),
          {'transactions': []},
        );

        batch.set(
          _firestore
              .collection('users')
              .doc(uid)
              .collection('goals')
              .doc('retirement_goals'),
          defaultData['goals']['retirement_goals'],
        );
        batch.set(
          _firestore
              .collection('users')
              .doc(uid)
              .collection('goals')
              .doc('milestones'),
          defaultData['goals']['milestones'],
        );
        batch.set(
          _firestore
              .collection('users')
              .doc(uid)
              .collection('goals')
              .doc('progress'),
          defaultData['goals']['progress'],
        );

        batch.set(
          _firestore
              .collection('users')
              .doc(uid)
              .collection('spending')
              .doc('monthly_expenses'),
          defaultData['spending']['monthly_expenses'],
        );
        batch.set(
          _firestore
              .collection('users')
              .doc(uid)
              .collection('spending')
              .doc('categories'),
          defaultData['spending']['categories'],
        );
        batch.set(
          _firestore
              .collection('users')
              .doc(uid)
              .collection('spending')
              .doc('insights'),
          defaultData['spending']['insights'],
        );

        batch.set(
          _firestore
              .collection('users')
              .doc(uid)
              .collection('scenarios')
              .doc('projections'),
          defaultData['scenarios']['projections'],
        );
        batch.set(
          _firestore
              .collection('users')
              .doc(uid)
              .collection('scenarios')
              .doc('stress_tests'),
          {'stress_tests': []},
        );
        batch.set(
          _firestore
              .collection('users')
              .doc(uid)
              .collection('scenarios')
              .doc('recommendations'),
          defaultData['scenarios']['recommendations'],
        );

        batch.set(userDocRef, {
          'created_at': FieldValue.serverTimestamp(),
          'last_updated': FieldValue.serverTimestamp(),
          'version': '2.0',
        });

        await batch.commit();
      }
    } catch (e) {
      throw Exception('Failed to initialize user data: $e');
    }
  }

  Future<void> saveUserProfile(Map<String, dynamic> userData) async {
    try {
      // Try to get UID from userData or from FirebaseAuth
      final uid =
          (userData['uid'] ?? FirebaseAuth.instance.currentUser?.uid)
              as String?;

      if (uid == null || uid.isEmpty) {
        throw Exception('User ID is missing — cannot save profile.');
      }

      // Clean null string fields before saving
      final cleanData = _sanitizeData(userData);

      await _firestore
          .collection('users')
          .doc(uid)
          .set(cleanData, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save user profile: $e');
    }
  }

  /// Helper: recursively replace nulls with empty strings or clean maps
  Map<String, dynamic> _sanitizeData(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    data.forEach((key, value) {
      if (value == null) {
        result[key] = '';
      } else if (value is Map) {
        result[key] = _sanitizeData(Map<String, dynamic>.from(value));
      } else {
        result[key] = value;
      }
    });
    return result;
  }

  Future<bool> saveRetirementData(Map<String, dynamic> userData) async {
    if (_currentUserId == null) throw Exception('User not authenticated');

    try {
      final profileData = _prepareProfileData(userData);
      final investmentData = _prepareInvestmentData(userData);
      final goalsData = _prepareGoalsData(userData);
      final spendingData = _prepareSpendingData(userData);
      final scenarioData = _prepareScenarioData(userData);

      WriteBatch batch = _firestore.batch();

      profileData.forEach((docId, data) {
        batch.set(_profileCollection.doc(docId), data);
      });

      investmentData.forEach((docId, data) {
        batch.set(_investmentsCollection.doc(docId), data);
      });

      goalsData.forEach((docId, data) {
        batch.set(_goalsCollection.doc(docId), data);
      });

      spendingData.forEach((docId, data) {
        batch.set(_spendingCollection.doc(docId), data);
      });

      scenarioData.forEach((docId, data) {
        batch.set(_scenariosCollection.doc(docId), data);
      });

      batch.update(_userDocRef, {
        'last_updated': FieldValue.serverTimestamp(),
        'questionnaire_completed': true,
        'questionnaire_completed_at': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      return true;
    } catch (e) {
      print('Failed to save retirement data: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> loadUserProfile([String? userId]) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return null;

    try {
      Map<String, dynamic> completeProfile = {};

      final userDocRef = _firestore.collection('users').doc(uid);

      final profileSnapshot = await userDocRef.collection('profile').get();
      completeProfile['profile'] = {};
      for (var doc in profileSnapshot.docs) {
        completeProfile['profile'][doc.id] = doc.data();
      }

      final investmentSnapshot =
          await userDocRef.collection('investments').get();
      completeProfile['investments'] = {};
      for (var doc in investmentSnapshot.docs) {
        completeProfile['investments'][doc.id] = doc.data();
      }

      final goalsSnapshot = await userDocRef.collection('goals').get();
      completeProfile['goals'] = {};
      for (var doc in goalsSnapshot.docs) {
        completeProfile['goals'][doc.id] = doc.data();
      }

      final spendingSnapshot = await userDocRef.collection('spending').get();
      completeProfile['spending'] = {};
      for (var doc in spendingSnapshot.docs) {
        completeProfile['spending'][doc.id] = doc.data();
      }

      final scenariosSnapshot = await userDocRef.collection('scenarios').get();
      completeProfile['scenarios'] = {};
      for (var doc in scenariosSnapshot.docs) {
        completeProfile['scenarios'][doc.id] = doc.data();
      }

      final userDoc = await userDocRef.get();
      if (userDoc.exists) {
        completeProfile['metadata'] = userDoc.data();
      }

      return completeProfile;
    } catch (e) {
      throw Exception('Failed to load user profile: $e');
    }
  }

  Stream<QuerySnapshot> getUserDataStream(String collection) {
    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection(collection)
        .snapshots();
  }

  Stream<DocumentSnapshot> getDocumentStream(
    String collection,
    String document,
  ) {
    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection(collection)
        .doc(document)
        .snapshots();
  }

  Future<void> updateUserProfile(
    Map<String, dynamic> profileData, [
    String? userId,
  ]) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('profile')
          .doc('personal_info')
          .update({...profileData, 'updated_at': FieldValue.serverTimestamp()});
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  Future<bool> updateProfileField(
    String collection,
    String document,
    Map<String, dynamic> updates, [
    String? userId,
  ]) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return false;

    try {
      updates['updated_at'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('users')
          .doc(uid)
          .collection(collection)
          .doc(document)
          .update(updates);
      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  Future<void> updatePortfolioValue(double newValue, [String? userId]) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('investments')
          .doc('portfolio_summary')
          .update({
            'current_value': newValue,
            'last_updated': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to update portfolio value: $e');
    }
  }

  Future<void> addTransaction(
    Map<String, dynamic> transaction, [
    String? userId,
  ]) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) throw Exception('User not authenticated');

    try {
      transaction['timestamp'] = FieldValue.serverTimestamp();
      transaction['id'] = _firestore.collection('temp').doc().id;

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('investments')
          .doc('transactions')
          .update({
            'transactions': FieldValue.arrayUnion([transaction]),
          });

      await _updatePortfolioSummaryAfterTransaction(uid, transaction);
    } catch (e) {
      throw Exception('Failed to add transaction: $e');
    }
  }

  Future<void> addHolding(
    Map<String, dynamic> holding, [
    String? userId,
  ]) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) throw Exception('User not authenticated');

    try {
      holding['id'] = _firestore.collection('temp').doc().id;
      holding['created_at'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('investments')
          .doc('holdings')
          .update({
            'holdings': FieldValue.arrayUnion([holding]),
          });
    } catch (e) {
      throw Exception('Failed to add holding: $e');
    }
  }

  Future<void> updateHolding(
    String holdingId,
    Map<String, dynamic> updates, [
    String? userId,
  ]) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) throw Exception('User not authenticated');

    try {
      final holdingsDoc =
          await _firestore
              .collection('users')
              .doc(uid)
              .collection('investments')
              .doc('holdings')
              .get();
      if (!holdingsDoc.exists) return;

      final holdingsData = holdingsDoc.data() as Map<String, dynamic>;
      final holdings = List<Map<String, dynamic>>.from(
        holdingsData['holdings'] ?? [],
      );

      final holdingIndex = holdings.indexWhere((h) => h['id'] == holdingId);
      if (holdingIndex != -1) {
        holdings[holdingIndex] = {...holdings[holdingIndex], ...updates};
        holdings[holdingIndex]['updated_at'] = FieldValue.serverTimestamp();

        await _firestore
            .collection('users')
            .doc(uid)
            .collection('investments')
            .doc('holdings')
            .update({'holdings': holdings});
      }
    } catch (e) {
      throw Exception('Failed to update holding: $e');
    }
  }

  Future<void> updateAssetAllocation(
    Map<String, dynamic> allocation, [
    String? userId,
  ]) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('investments')
          .doc('portfolio_summary')
          .update({
            'asset_allocation': allocation,
            'last_updated': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to update asset allocation: $e');
    }
  }

  Future<void> updateRetirementGoals(
    Map<String, dynamic> goals, [
    String? userId,
  ]) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('goals')
          .doc('retirement_goals')
          .update({...goals, 'updated_at': FieldValue.serverTimestamp()});

      // Update progress metrics if corpus changed
      if (goals['current_corpus'] != null || goals['target_corpus'] != null) {
        await _updateGoalProgress(uid);
      }
    } catch (e) {
      throw Exception('Failed to update retirement goals: $e');
    }
  }

  Future<void> _updateGoalProgress(String userId) async {
    try {
      final goalsDoc =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('goals')
              .doc('retirement_goals')
              .get();

      if (!goalsDoc.exists) return;

      final goalsData = goalsDoc.data() as Map<String, dynamic>;
      final currentCorpus = (goalsData['current_corpus'] ?? 0.0).toDouble();
      final targetCorpus = (goalsData['target_corpus'] ?? 0.0).toDouble();

      final corpusProgress =
          targetCorpus > 0 ? (currentCorpus / targetCorpus) * 100 : 0.0;

      // Check and update milestone achievements
      await _checkMilestoneAchievements(userId, currentCorpus);

      // Update progress document
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('goals')
          .doc('progress')
          .update({
            'corpus_progress': corpusProgress,
            'last_updated': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print('Failed to update goal progress: $e');
    }
  }

  Future<void> _checkMilestoneAchievements(
    String userId,
    double currentCorpus,
  ) async {
    try {
      final milestonesDoc =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('goals')
              .doc('milestones')
              .get();

      if (!milestonesDoc.exists) return;

      final milestonesData = milestonesDoc.data() as Map<String, dynamic>;
      final milestones = List<Map<String, dynamic>>.from(
        milestonesData['milestones'] ?? [],
      );

      bool milestonesUpdated = false;

      for (var milestone in milestones) {
        final targetAmount = (milestone['target_amount'] ?? 0.0).toDouble();
        final wasAchieved = milestone['achieved'] ?? false;

        if (!wasAchieved && currentCorpus >= targetAmount) {
          milestone['achieved'] = true;
          milestone['achievement_date'] = FieldValue.serverTimestamp();
          milestonesUpdated = true;
        }
      }

      if (milestonesUpdated) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('goals')
            .doc('milestones')
            .update({
              'milestones': milestones,
              'last_updated': FieldValue.serverTimestamp(),
            });

        // Update milestone completion rate
        final achievedCount =
            milestones.where((m) => m['achieved'] == true).length;
        final completionRate =
            milestones.isNotEmpty
                ? (achievedCount / milestones.length) * 100
                : 0.0;

        await _firestore
            .collection('users')
            .doc(userId)
            .collection('goals')
            .doc('progress')
            .update({'milestone_completion_rate': completionRate});
      }
    } catch (e) {
      print('Failed to check milestone achievements: $e');
    }
  }

  Future<void> addCustomMilestone(
    Map<String, dynamic> milestone, [
    String? userId,
  ]) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) throw Exception('User not authenticated');

    try {
      milestone['id'] = _firestore.collection('temp').doc().id;
      milestone['created_at'] = FieldValue.serverTimestamp();
      milestone['custom'] = true;
      milestone['achieved'] = false;

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('goals')
          .doc('milestones')
          .update({
            'milestones': FieldValue.arrayUnion([milestone]),
          });
    } catch (e) {
      throw Exception('Failed to add custom milestone: $e');
    }
  }

  Future<void> deleteMilestone(String milestoneId, [String? userId]) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) throw Exception('User not authenticated');

    try {
      final milestonesDoc =
          await _firestore
              .collection('users')
              .doc(uid)
              .collection('goals')
              .doc('milestones')
              .get();

      if (!milestonesDoc.exists) return;

      final milestonesData = milestonesDoc.data() as Map<String, dynamic>;
      final milestones = List<Map<String, dynamic>>.from(
        milestonesData['milestones'] ?? [],
      );

      milestones.removeWhere((m) => m['id'] == milestoneId);

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('goals')
          .doc('milestones')
          .update({
            'milestones': milestones,
            'last_updated': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to delete milestone: $e');
    }
  }

  Future<void> addMilestone(
    Map<String, dynamic> milestone, [
    String? userId,
  ]) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) throw Exception('User not authenticated');

    try {
      milestone['id'] = _firestore.collection('temp').doc().id;
      milestone['created_at'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('goals')
          .doc('milestones')
          .update({
            'milestones': FieldValue.arrayUnion([milestone]),
          });
    } catch (e) {
      throw Exception('Failed to add milestone: $e');
    }
  }

  Future<void> updateMilestoneProgress(
    String milestoneId,
    double progress, [
    String? userId,
  ]) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) throw Exception('User not authenticated');

    try {
      final milestonesDoc =
          await _firestore
              .collection('users')
              .doc(uid)
              .collection('goals')
              .doc('milestones')
              .get();
      if (!milestonesDoc.exists) return;

      final milestonesData = milestonesDoc.data() as Map<String, dynamic>;
      final milestones = List<Map<String, dynamic>>.from(
        milestonesData['milestones'] ?? [],
      );

      final milestoneIndex = milestones.indexWhere(
        (m) => m['id'] == milestoneId,
      );
      if (milestoneIndex != -1) {
        milestones[milestoneIndex]['progress'] = progress;
        milestones[milestoneIndex]['updated_at'] = FieldValue.serverTimestamp();

        if (progress >= 100.0) {
          milestones[milestoneIndex]['achieved'] = true;
          milestones[milestoneIndex]['achievement_date'] =
              FieldValue.serverTimestamp();
        }

        await _firestore
            .collection('users')
            .doc(uid)
            .collection('goals')
            .doc('milestones')
            .update({'milestones': milestones});
      }
    } catch (e) {
      throw Exception('Failed to update milestone progress: $e');
    }
  }

  Map<String, dynamic>? _getNextMilestone(
    List<Map<String, dynamic>> milestones,
    double currentCorpus,
  ) {
    for (var milestone in milestones) {
      if (milestone['achieved'] != true) {
        final targetAmount = (milestone['target_amount'] ?? 0.0).toDouble();
        if (targetAmount > currentCorpus) {
          return {
            'milestone_number': milestone['milestone_number'],
            'target_amount': targetAmount,
            'target_percentage': milestone['target_percentage'],
            'amount_needed': targetAmount - currentCorpus,
          };
        }
      }
    }
    return null;
  }

  double _calculateProjectedCorpus(
    double currentCorpus,
    double monthlySip,
    int years,
    double annualReturn,
  ) {
    if (years <= 0) return currentCorpus;

    final monthlyRate = annualReturn / 100 / 12;
    final months = years * 12;

    // Future value of current corpus
    final futureValueOfCorpus =
        currentCorpus * math.pow(1 + monthlyRate, months);

    // Future value of SIP
    final futureValueOfSip =
        monthlySip > 0
            ? monthlySip *
                ((math.pow(1 + monthlyRate, months) - 1) / monthlyRate)
            : 0.0;

    return futureValueOfCorpus + futureValueOfSip;
  }

  double _calculateRequiredSipAmount(
    double targetCorpus,
    double currentCorpus,
    int years,
    double annualReturn,
  ) {
    if (years <= 0) return 0.0;

    final monthlyRate = annualReturn / 100 / 12;
    final months = years * 12;

    // Future value of current corpus
    final futureValueOfCorpus =
        currentCorpus * math.pow(1 + monthlyRate, months);

    // Remaining amount needed from SIP
    final remainingAmount = targetCorpus - futureValueOfCorpus;

    if (remainingAmount <= 0) return 0.0;

    // Calculate required SIP using FV of annuity formula
    final requiredSip =
        remainingAmount * monthlyRate / (math.pow(1 + monthlyRate, months) - 1);

    return requiredSip;
  }

  Future<void> updateMonthlyExpenses(
    Map<String, dynamic> expenses, [
    String? userId,
  ]) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('spending')
          .doc('monthly_expenses')
          .update({...expenses, 'last_updated': FieldValue.serverTimestamp()});
    } catch (e) {
      throw Exception('Failed to update monthly expenses: $e');
    }
  }

  Future<void> updateSpendingCategories(
    List<Map<String, dynamic>> categories, [
    String? userId,
  ]) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('spending')
          .doc('categories')
          .update({
            'categories': categories,
            'last_updated': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to update spending categories: $e');
    }
  }

  Future<void> addExpenseToCategory(
    String categoryId,
    double amount,
    String description, [
    String? userId,
  ]) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) throw Exception('User not authenticated');

    try {
      final categoriesDoc =
          await _firestore
              .collection('users')
              .doc(uid)
              .collection('spending')
              .doc('categories')
              .get();
      if (!categoriesDoc.exists) return;

      final categoriesData = categoriesDoc.data() as Map<String, dynamic>;
      final categories = List<Map<String, dynamic>>.from(
        categoriesData['categories'] ?? [],
      );

      final categoryIndex = categories.indexWhere((c) => c['id'] == categoryId);
      if (categoryIndex != -1) {
        final currentSpent =
            (categories[categoryIndex]['spent'] ?? 0.0).toDouble();
        categories[categoryIndex]['spent'] = currentSpent + amount;

        await _firestore
            .collection('users')
            .doc(uid)
            .collection('spending')
            .doc('categories')
            .update({
              'categories': categories,
              'last_updated': FieldValue.serverTimestamp(),
            });

        final expensesDoc =
            await _firestore
                .collection('users')
                .doc(uid)
                .collection('spending')
                .doc('monthly_expenses')
                .get();
        if (expensesDoc.exists) {
          final expensesData = expensesDoc.data() as Map<String, dynamic>;
          final currentCategoryExpense =
              (expensesData[categoryId] ?? 0.0).toDouble();

          await _firestore
              .collection('users')
              .doc(uid)
              .collection('spending')
              .doc('monthly_expenses')
              .update({
                categoryId: currentCategoryExpense + amount,
                'last_updated': FieldValue.serverTimestamp(),
              });
        }
      }
    } catch (e) {
      throw Exception('Failed to add expense to category: $e');
    }
  }

  Future<void> updateScenarios(
    Map<String, dynamic> scenarios, [
    String? userId,
  ]) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('scenarios')
          .doc('projections')
          .update({...scenarios, 'last_updated': FieldValue.serverTimestamp()});
    } catch (e) {
      throw Exception('Failed to update scenarios: $e');
    }
  }

  Future<void> addStressTest(
    Map<String, dynamic> stressTest, [
    String? userId,
  ]) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) throw Exception('User not authenticated');

    try {
      stressTest['id'] = _firestore.collection('temp').doc().id;
      stressTest['created_at'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('scenarios')
          .doc('stress_tests')
          .update({
            'stress_tests': FieldValue.arrayUnion([stressTest]),
          });
    } catch (e) {
      throw Exception('Failed to add stress test: $e');
    }
  }

  Future<void> updateRecommendations(
    List<String> recommendations, [
    String? userId,
  ]) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('scenarios')
          .doc('recommendations')
          .update({
            'recommendations': recommendations,
            'last_updated': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to update recommendations: $e');
    }
  }

  Future<Map<String, dynamic>> getPortfolioAnalytics([String? userId]) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) throw Exception('User not authenticated');

    try {
      final holdingsDoc =
          await _firestore
              .collection('users')
              .doc(uid)
              .collection('investments')
              .doc('holdings')
              .get();
      final transactionsDoc =
          await _firestore
              .collection('users')
              .doc(uid)
              .collection('investments')
              .doc('transactions')
              .get();

      final holdings = List<Map<String, dynamic>>.from(
        holdingsDoc.exists ? holdingsDoc.data()!['holdings'] ?? [] : [],
      );
      final transactions = List<Map<String, dynamic>>.from(
        transactionsDoc.exists
            ? transactionsDoc.data()!['transactions'] ?? []
            : [],
      );

      final totalHoldings = holdings.length;
      final totalTransactions = transactions.length;
      final averageHoldingValue =
          holdings.isNotEmpty
              ? holdings.fold<double>(
                    0.0,
                    (sum, h) =>
                        sum + ((h['current_value'] ?? 0.0) as num).toDouble(),
                  ) /
                  holdings.length
              : 0.0;

      return {
        'total_holdings': totalHoldings,
        'total_transactions': totalTransactions,
        'average_holding_value': averageHoldingValue,
        'last_transaction_date':
            transactions.isNotEmpty ? transactions.last['timestamp'] : null,
      };
    } catch (e) {
      throw Exception('Failed to get portfolio analytics: $e');
    }
  }

  Future<Map<String, dynamic>> getSpendingAnalytics([String? userId]) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) throw Exception('User not authenticated');

    try {
      final categoriesDoc =
          await _firestore
              .collection('users')
              .doc(uid)
              .collection('spending')
              .doc('categories')
              .get();
      final expensesDoc =
          await _firestore
              .collection('users')
              .doc(uid)
              .collection('spending')
              .doc('monthly_expenses')
              .get();

      final categories = List<Map<String, dynamic>>.from(
        categoriesDoc.exists ? categoriesDoc.data()!['categories'] ?? [] : [],
      );
      final expenses =
          expensesDoc.exists ? expensesDoc.data() as Map<String, dynamic> : {};

      final totalBudget = categories.fold<double>(
        0.0,
        (sum, c) => sum + ((c['budget'] ?? 0.0) as num).toDouble(),
      );
      final totalSpent = categories.fold<double>(
        0.0,
        (sum, c) => sum + ((c['spent'] ?? 0.0) as num).toDouble(),
      );
      final budgetUtilization =
          totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0.0;

      String topCategory = '';
      double maxSpent = 0.0;
      for (final category in categories) {
        final spent = ((category['spent'] ?? 0.0) as num).toDouble();
        if (spent > maxSpent) {
          maxSpent = spent;
          topCategory = category['name'] ?? '';
        }
      }

      return {
        'total_budget': totalBudget,
        'total_spent': totalSpent,
        'budget_utilization': budgetUtilization,
        'categories_count': categories.length,
        'top_spending_category': topCategory,
        'top_spending_amount': maxSpent,
      };
    } catch (e) {
      throw Exception('Failed to get spending analytics: $e');
    }
  }

  Future<Map<String, dynamic>?> backupUserData([String? userId]) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return null;

    try {
      return await loadUserProfile(uid);
    } catch (e) {
      throw Exception('Failed to backup user data: $e');
    }
  }

  Future<void> restoreUserData(
    Map<String, dynamic> backupData, [
    String? userId,
  ]) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) throw Exception('User not authenticated');

    try {
      WriteBatch batch = _firestore.batch();
      final userDocRef = _firestore.collection('users').doc(uid);

      if (backupData['profile'] != null) {
        final profileData = backupData['profile'] as Map<String, dynamic>;
        profileData.forEach((docId, data) {
          batch.set(
            userDocRef.collection('profile').doc(docId),
            data as Map<String, dynamic>,
          );
        });
      }

      ['investments', 'goals', 'spending', 'scenarios'].forEach((collection) {
        if (backupData[collection] != null) {
          final collectionData = backupData[collection] as Map<String, dynamic>;
          collectionData.forEach((docId, data) {
            batch.set(
              userDocRef.collection(collection).doc(docId),
              data as Map<String, dynamic>,
            );
          });
        }
      });

      if (backupData['metadata'] != null) {
        batch.set(userDocRef, backupData['metadata'] as Map<String, dynamic>);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to restore user data: $e');
    }
  }

  Future<void> deleteUserData([String? userId]) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) throw Exception('User not authenticated');

    try {
      WriteBatch batch = _firestore.batch();
      final userDocRef = _firestore.collection('users').doc(uid);

      final collections = [
        'profile',
        'investments',
        'goals',
        'spending',
        'scenarios',
      ];

      for (final collection in collections) {
        final snapshot = await userDocRef.collection(collection).get();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
      }

      batch.delete(userDocRef);

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete user data: $e');
    }
  }

  Future<void> batchUpdate(
    Map<String, Map<String, Map<String, dynamic>>> updates, [
    String? userId,
  ]) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) throw Exception('User not authenticated');

    try {
      WriteBatch batch = _firestore.batch();
      final userDocRef = _firestore.collection('users').doc(uid);

      updates.forEach((collection, documents) {
        documents.forEach((document, fields) {
          batch.update(userDocRef.collection(collection).doc(document), {
            ...fields,
            'updated_at': FieldValue.serverTimestamp(),
          });
        });
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to perform batch update: $e');
    }
  }

  Future<void> _updatePortfolioSummaryAfterTransaction(
    String userId,
    Map<String, dynamic> transaction,
  ) async {
    try {
      final portfolioDoc =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('investments')
              .doc('portfolio_summary')
              .get();
      if (!portfolioDoc.exists) return;

      final portfolio = portfolioDoc.data() as Map<String, dynamic>;
      final double currentValue =
          ((portfolio['current_value'] ?? 0.0) as num).toDouble();
      final double currentInvested =
          ((portfolio['total_invested'] ?? 0.0) as num).toDouble();
      final double transactionAmount =
          ((transaction['amount'] ?? 0.0) as num).toDouble();

      double newInvested = currentInvested;

      if (transaction['type'] == 'buy' || transaction['type'] == 'sip') {
        newInvested += transactionAmount;
      } else if (transaction['type'] == 'sell' ||
          transaction['type'] == 'redeem') {
        newInvested -= transactionAmount;
      }

      final double newReturns = currentValue - newInvested;
      final double newReturnPercentage =
          newInvested > 0 ? (newReturns / newInvested) * 100 : 0.0;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('investments')
          .doc('portfolio_summary')
          .update({
            'total_invested': newInvested,
            'total_returns': newReturns,
            'returns_percentage': newReturnPercentage,
            'last_updated': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print('Failed to update portfolio summary: $e');
    }
  }

  Map<String, dynamic> _getDefaultUserData() {
    return {
      'profile': {
        'personal_info': {
          'name': '',
          'email': _auth.currentUser?.email ?? '',
          'age': 25,
          'retirement_age': 60,
          'life_expectancy': 80,
          'location': '',
          'marital_status': '',
          'dependents': 0,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        },
        'financial_profile': {
          'current_income': 0.0,
          'monthly_expenses': 0.0,
          'existing_savings': 0.0,
          'existing_investments': 0.0,
          'annual_income': 0.0,
          'annual_expenses': 0.0,
          'monthly_surplus': 0.0,
          'tax_slab': '',
          'section_80c_investment': 0.0,
          'expected_inflation_rate': 6.0,
          'expected_return_rate': 12.0,
          'updated_at': FieldValue.serverTimestamp(),
        },
        'preferences': {
          'risk_tolerance': 'moderate',
          'investment_experience': '',
          'preferred_investments': <String>[],
          'sip_amount': 0.0,
          'investment_frequency': 'monthly',
          'health_insurance': '',
          'emergency_fund_months': 6,
          'updated_at': FieldValue.serverTimestamp(),
        },
      },
      'investments': {
        'portfolio_summary': {
          'total_invested': 0.0,
          'current_value': 0.0,
          'total_returns': 0.0,
          'returns_percentage': 0.0,
          'monthly_sip': 10000.0,
          'asset_allocation': {
            'equity': 60.0,
            'debt': 30.0,
            'gold': 10.0,
            'others': 0.0,
          },
          'last_updated': FieldValue.serverTimestamp(),
        },
      },
      'goals': {
        'retirement_goals': {
          'target_corpus': 10000000.0,
          'current_corpus': 0.0,
          'monthly_sip': 10000.0,
          'years_to_retirement': 30,
          'expected_return': 0.12,
          'inflation_rate': 0.06,
          'success_probability': 0.75,
          'retirement_lifestyle_goals': <String>[],
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        },
        'milestones': {
          'milestones': <Map<String, dynamic>>[],
          'current_progress': 0.0,
          'next_milestone_target': 1000000.0,
          'created_at': FieldValue.serverTimestamp(),
        },
        'progress': {
          'corpus_progress': 0.0,
          'milestone_completion_rate': 0.0,
          'last_updated': FieldValue.serverTimestamp(),
        },
      },
      'spending': {
        'monthly_expenses': {
          'total_monthly_expenses': 0.0,
          'emergency_fund_target': 0.0,
          'housing': 0.0,
          'food': 0.0,
          'transportation': 0.0,
          'utilities': 0.0,
          'entertainment': 0.0,
          'healthcare': 0.0,
          'shopping': 0.0,
          'others': 0.0,
          'last_updated': FieldValue.serverTimestamp(),
        },
        'categories': {
          'categories': [
            {
              'id': 'housing',
              'name': 'Housing',
              'budget': 15000.0,
              'spent': 0.0,
              'color': '#FF6B6B',
            },
            {
              'id': 'food',
              'name': 'Food & Dining',
              'budget': 8000.0,
              'spent': 0.0,
              'color': '#4ECDC4',
            },
            {
              'id': 'transportation',
              'name': 'Transportation',
              'budget': 5000.0,
              'spent': 0.0,
              'color': '#45B7D1',
            },
            {
              'id': 'entertainment',
              'name': 'Entertainment',
              'budget': 3000.0,
              'spent': 0.0,
              'color': '#96CEB4',
            },
          ],
          'default_categories': [
            'Housing',
            'Food & Dining',
            'Transportation',
            'Healthcare',
            'Insurance',
            'Education',
            'Entertainment',
            'Shopping',
            'Utilities',
            'Miscellaneous',
          ],
          'custom_categories': <String>[],
          'created_at': FieldValue.serverTimestamp(),
        },
        'insights': {
          'top_category': 'housing',
          'savings_rate': 0.0,
          'budget_variance': 0.0,
          'spending_trend': 'stable',
          'last_calculated': FieldValue.serverTimestamp(),
        },
      },
      'scenarios': {
        'projections': {
          'conservative': {
            'expected_return': 0.08,
            'projected_corpus': 0.0,
            'success_probability': 0.90,
          },
          'moderate': {
            'expected_return': 0.12,
            'projected_corpus': 0.0,
            'success_probability': 0.75,
          },
          'aggressive': {
            'expected_return': 0.15,
            'projected_corpus': 0.0,
            'success_probability': 0.60,
          },
          'sip_projections': {},
          'corpus_scenarios': {},
          'inflation_impact': {},
          'last_calculated': FieldValue.serverTimestamp(),
        },
        'recommendations': {
          'recommended_sip': {},
          'asset_allocation_suggestions': <Map<String, dynamic>>[],
          'tax_saving_suggestions': <Map<String, dynamic>>[],
          'general_recommendations': [
            'Consider increasing your SIP amount by 10% annually',
            'Review and rebalance your portfolio quarterly',
            'Maintain 6 months of emergency fund',
          ],
          'created_at': FieldValue.serverTimestamp(),
        },
      },
    };
  }

  Map<String, Map<String, dynamic>> _prepareProfileData(
    Map<String, dynamic> userData,
  ) {
    return {
      'personal_info': {
        'name': userData['name'] ?? '',
        'age': int.tryParse(userData['age'] ?? '0') ?? 0,
        'retirement_age': int.tryParse(userData['retirementAge'] ?? '0') ?? 0,
        'life_expectancy': int.tryParse(userData['lifeExpectancy'] ?? '0') ?? 0,
        'location': userData['location'] ?? '',
        'marital_status': userData['maritalStatus'] ?? '',
        'dependents': int.tryParse(userData['dependents'] ?? '0') ?? 0,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      },
      'financial_profile': {
        'current_income':
            double.tryParse(userData['currentIncome'] ?? '0') ?? 0.0,
        'monthly_expenses':
            double.tryParse(userData['monthlyExpenses'] ?? '0') ?? 0.0,
        'existing_savings':
            double.tryParse(userData['existingSavings'] ?? '0') ?? 0.0,
        'existing_investments':
            double.tryParse(userData['existingInvestments'] ?? '0') ?? 0.0,
        'tax_slab': userData['taxSlab'] ?? '',
        'section_80c_investment':
            double.tryParse(userData['section80c'] ?? '0') ?? 0.0,
        'expected_inflation_rate':
            double.tryParse(userData['expectedInflationRate'] ?? '6') ?? 6.0,
        'expected_return_rate':
            double.tryParse(userData['expectedReturnRate'] ?? '12') ?? 12.0,
        'annual_income':
            (double.tryParse(userData['currentIncome'] ?? '0') ?? 0.0) * 12,
        'annual_expenses':
            (double.tryParse(userData['monthlyExpenses'] ?? '0') ?? 0.0) * 12,
        'monthly_surplus':
            (double.tryParse(userData['currentIncome'] ?? '0') ?? 0.0) -
            (double.tryParse(userData['monthlyExpenses'] ?? '0') ?? 0.0),
        'updated_at': FieldValue.serverTimestamp(),
      },
      'preferences': {
        'risk_tolerance': userData['riskTolerance'] ?? '',
        'investment_experience': userData['investmentExperience'] ?? '',
        'preferred_investments': List<String>.from(
          userData['preferredInvestments'] ?? [],
        ),
        'sip_amount': double.tryParse(userData['sipAmount'] ?? '0') ?? 0.0,
        'investment_frequency': userData['investmentFrequency'] ?? '',
        'health_insurance': userData['healthInsurance'] ?? '',
        'emergency_fund_months':
            int.tryParse(userData['emergencyFundMonths'] ?? '6') ?? 6,
        'updated_at': FieldValue.serverTimestamp(),
      },
    };
  }

  Map<String, Map<String, dynamic>> _prepareInvestmentData(
    Map<String, dynamic> userData,
  ) {
    final currentInvestments =
        double.tryParse(userData['existingInvestments'] ?? '0') ?? 0.0;
    final sipAmount = double.tryParse(userData['sipAmount'] ?? '0') ?? 0.0;

    return {
      'portfolio_summary': {
        'total_invested': currentInvestments,
        'current_value': currentInvestments,
        'total_returns': 0.0,
        'returns_percentage': 0.0,
        'monthly_sip': sipAmount,
        'asset_allocation': _generateAssetAllocation(
          userData['riskTolerance'] ?? '',
        ),
        'last_updated': FieldValue.serverTimestamp(),
      },
      'holdings': {
        'holdings': <Map<String, dynamic>>[],
        'last_updated': FieldValue.serverTimestamp(),
      },
      'transactions': {
        'transactions': <Map<String, dynamic>>[],
        'last_updated': FieldValue.serverTimestamp(),
      },
    };
  }

  Map<String, Map<String, dynamic>> _prepareGoalsData(
    Map<String, dynamic> userData,
  ) {
    final currentAge = int.tryParse(userData['age'] ?? '0') ?? 0;
    final retirementAge = int.tryParse(userData['retirementAge'] ?? '0') ?? 0;
    final lifeExpectancy = int.tryParse(userData['lifeExpectancy'] ?? '0') ?? 0;
    final monthlyExpenses =
        double.tryParse(userData['monthlyExpenses'] ?? '0') ?? 0.0;
    final inflationRate =
        double.tryParse(userData['expectedInflationRate'] ?? '6') ?? 6.0;

    final yearsToRetirement = retirementAge - currentAge;
    final yearsInRetirement = lifeExpectancy - retirementAge;
    final futureMonthlyExpenses =
        monthlyExpenses *
        math.pow(1 + (inflationRate / 100), yearsToRetirement);
    final retirementCorpus = futureMonthlyExpenses * 12 * yearsInRetirement;

    return {
      'retirement_goals': {
        'target_corpus': retirementCorpus,
        'current_corpus':
            double.tryParse(userData['existingInvestments'] ?? '0') ?? 0.0,
        'monthly_expenses_at_retirement': futureMonthlyExpenses,
        'years_to_retirement': yearsToRetirement,
        'years_in_retirement': yearsInRetirement,
        'retirement_lifestyle_goals': List<String>.from(
          userData['retirementGoals'] ?? [],
        ),
        'corpus_calculation_details': {
          'current_monthly_expenses': monthlyExpenses,
          'inflation_rate': inflationRate,
          'years_to_retirement': yearsToRetirement,
          'years_in_retirement': yearsInRetirement,
        },
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      },
      'milestones': {
        'milestones': _generateMilestones(retirementCorpus, yearsToRetirement),
        'current_progress': 0.0,
        'next_milestone_target': retirementCorpus * 0.1,
        'created_at': FieldValue.serverTimestamp(),
      },
      'progress': {
        'corpus_progress': 0.0,
        'milestone_completion_rate': 0.0,
        'last_updated': FieldValue.serverTimestamp(),
      },
    };
  }

  Map<String, Map<String, dynamic>> _prepareSpendingData(
    Map<String, dynamic> userData,
  ) {
    final monthlyExpenses =
        double.tryParse(userData['monthlyExpenses'] ?? '0') ?? 0.0;
    final emergencyFundMonths =
        int.tryParse(userData['emergencyFundMonths'] ?? '6') ?? 6;

    return {
      'monthly_expenses': {
        'total_monthly_expenses': monthlyExpenses,
        'emergency_fund_target': monthlyExpenses * emergencyFundMonths,
        'expense_categories': _generateExpenseCategories(monthlyExpenses),
        'last_updated': FieldValue.serverTimestamp(),
      },
      'categories': {
        'categories': _getDefaultSpendingCategories(monthlyExpenses),
        'default_categories': [
          'Housing',
          'Food & Dining',
          'Transportation',
          'Healthcare',
          'Insurance',
          'Education',
          'Entertainment',
          'Shopping',
          'Utilities',
          'Miscellaneous',
        ],
        'custom_categories': <String>[],
        'created_at': FieldValue.serverTimestamp(),
      },
      'insights': {
        'top_category': 'housing',
        'savings_rate': 0.0,
        'budget_variance': 0.0,
        'spending_trend': 'stable',
        'last_calculated': FieldValue.serverTimestamp(),
      },
    };
  }

  Future<Map<String, dynamic>> getGoalAnalytics([String? userId]) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) throw Exception('User not authenticated');

    try {
      final goalsDoc =
          await _firestore
              .collection('users')
              .doc(uid)
              .collection('goals')
              .doc('retirement_goals')
              .get();

      final milestonesDoc =
          await _firestore
              .collection('users')
              .doc(uid)
              .collection('goals')
              .doc('milestones')
              .get();

      final progressDoc =
          await _firestore
              .collection('users')
              .doc(uid)
              .collection('goals')
              .doc('progress')
              .get();

      if (!goalsDoc.exists) {
        return {'error': 'No goals data found'};
      }

      final goalsData = goalsDoc.data() as Map<String, dynamic>;
      final milestonesData =
          milestonesDoc.exists
              ? milestonesDoc.data() as Map<String, dynamic>
              : {};
      final progressData =
          progressDoc.exists ? progressDoc.data() as Map<String, dynamic> : {};

      final currentCorpus = (goalsData['current_corpus'] ?? 0.0).toDouble();
      final targetCorpus = (goalsData['target_corpus'] ?? 0.0).toDouble();
      final yearsToRetirement = goalsData['years_to_retirement'] ?? 0;
      final monthlySip = (goalsData['monthly_sip'] ?? 0.0).toDouble();

      final milestones = List<Map<String, dynamic>>.from(
        milestonesData['milestones'] ?? [],
      );

      final achievedMilestones =
          milestones.where((m) => m['achieved'] == true).length;
      final remainingAmount = targetCorpus - currentCorpus;
      final progressPercentage =
          targetCorpus > 0 ? (currentCorpus / targetCorpus) * 100 : 0.0;

      // Calculate projected corpus with current SIP
      final projectedCorpus = _calculateProjectedCorpus(
        currentCorpus,
        monthlySip,
        yearsToRetirement,
        12.0, // 12% expected return
      );

      final shortfall = targetCorpus - projectedCorpus;
      final onTrack = projectedCorpus >= targetCorpus;

      // Calculate required SIP to meet goal
      final requiredSip = _calculateRequiredSipAmount(
        targetCorpus,
        currentCorpus,
        yearsToRetirement,
        12.0,
      );

      return {
        'current_corpus': currentCorpus,
        'target_corpus': targetCorpus,
        'remaining_amount': remainingAmount,
        'progress_percentage': progressPercentage,
        'years_to_retirement': yearsToRetirement,
        'monthly_sip': monthlySip,
        'projected_corpus': projectedCorpus,
        'shortfall': shortfall > 0 ? shortfall : 0.0,
        'on_track': onTrack,
        'required_sip': requiredSip,
        'sip_adjustment_needed': requiredSip - monthlySip,
        'total_milestones': milestones.length,
        'achieved_milestones': achievedMilestones,
        'milestone_completion_rate':
            milestones.isNotEmpty
                ? (achievedMilestones / milestones.length) * 100
                : 0.0,
        'next_milestone': _getNextMilestone(milestones, currentCorpus),
        'lifestyle_goals_count':
            (goalsData['retirement_lifestyle_goals'] as List?)?.length ?? 0,
      };
    } catch (e) {
      throw Exception('Failed to get goal analytics: $e');
    }
  }

  Map<String, Map<String, dynamic>> _prepareScenarioData(
    Map<String, dynamic> userData,
  ) {
    final sipAmount = double.tryParse(userData['sipAmount'] ?? '0') ?? 0.0;
    final returnRate =
        double.tryParse(userData['expectedReturnRate'] ?? '12') ?? 12.0;
    final currentAge = int.tryParse(userData['age'] ?? '0') ?? 0;
    final retirementAge = int.tryParse(userData['retirementAge'] ?? '0') ?? 0;
    final yearsToRetirement = retirementAge - currentAge;

    return {
      'projections': {
        'conservative': {
          'expected_return': 0.08,
          'projected_corpus': _calculateFutureValue(
            sipAmount,
            8.0,
            yearsToRetirement,
          ),
          'success_probability': 0.90,
        },
        'moderate': {
          'expected_return': 0.12,
          'projected_corpus': _calculateFutureValue(
            sipAmount,
            12.0,
            yearsToRetirement,
          ),
          'success_probability': 0.75,
        },
        'aggressive': {
          'expected_return': 0.15,
          'projected_corpus': _calculateFutureValue(
            sipAmount,
            15.0,
            yearsToRetirement,
          ),
          'success_probability': 0.60,
        },
        'sip_projections': _calculateSipProjections(
          sipAmount,
          returnRate,
          yearsToRetirement,
        ),
        'corpus_scenarios': _generateCorpusScenarios(
          sipAmount,
          yearsToRetirement,
        ),
        'inflation_impact': _calculateInflationImpact(userData),
        'last_calculated': FieldValue.serverTimestamp(),
      },
      'recommendations': {
        'recommended_sip': _calculateRecommendedSip(userData),
        'asset_allocation_suggestions': _getAssetAllocationRecommendations(
          userData['riskTolerance'] ?? '',
        ),
        'tax_saving_suggestions': _getTaxSavingSuggestions(userData),
        'general_recommendations': _getGeneralRecommendations(userData),
        'created_at': FieldValue.serverTimestamp(),
      },
    };
  }

  Map<String, double> _generateAssetAllocation(String riskTolerance) {
    switch (riskTolerance) {
      case 'Conservative (Low Risk)':
        return {'equity': 30.0, 'debt': 60.0, 'gold': 10.0};
      case 'Moderate (Medium Risk)':
        return {'equity': 60.0, 'debt': 30.0, 'gold': 10.0};
      case 'Aggressive (High Risk)':
        return {'equity': 80.0, 'debt': 15.0, 'gold': 5.0};
      default:
        return {'equity': 60.0, 'debt': 30.0, 'gold': 10.0};
    }
  }

  List<Map<String, dynamic>> _generateMilestones(
    double targetCorpus,
    int yearsToRetirement,
  ) {
    List<Map<String, dynamic>> milestones = [];

    for (int i = 1; i <= 10; i++) {
      milestones.add({
        'milestone_number': i,
        'target_amount': targetCorpus * (i * 0.1),
        'target_percentage': i * 10,
        'target_year': DateTime.now().year + (yearsToRetirement * i ~/ 10),
        'achieved': false,
        'achievement_date': null,
        'id': _firestore.collection('temp').doc().id,
      });
    }

    return milestones;
  }

  Map<String, double> _generateExpenseCategories(double totalExpenses) {
    return {
      'Housing': totalExpenses * 0.30,
      'Food & Dining': totalExpenses * 0.20,
      'Transportation': totalExpenses * 0.15,
      'Healthcare': totalExpenses * 0.10,
      'Insurance': totalExpenses * 0.05,
      'Education': totalExpenses * 0.05,
      'Entertainment': totalExpenses * 0.05,
      'Shopping': totalExpenses * 0.05,
      'Utilities': totalExpenses * 0.03,
      'Miscellaneous': totalExpenses * 0.02,
    };
  }

  Future<Map<String, dynamic>> getGoalRecommendations([String? userId]) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) throw Exception('User not authenticated');

    try {
      final analytics = await getGoalAnalytics(uid);
      final recommendations = <String>[];
      final actionItems = <Map<String, dynamic>>[];

      // Check if on track
      if (analytics['on_track'] == false) {
        final shortfall = analytics['shortfall'] as double;
        final sipAdjustment = analytics['sip_adjustment_needed'] as double;

        recommendations.add(
          'Your current SIP may not be sufficient to reach your retirement goal. '
          'Consider increasing your monthly SIP by ₹${_formatCurrency(sipAdjustment)}.',
        );

        actionItems.add({
          'title': 'Increase SIP',
          'description': 'Adjust monthly investment to meet goal',
          'priority': 'high',
          'action': 'update_sip',
          'suggested_value': analytics['required_sip'],
        });
      } else {
        recommendations.add(
          'Great job! You\'re on track to meet your retirement goal.',
        );
      }

      // Milestone recommendations
      if (analytics['next_milestone'] != null) {
        final nextMilestone =
            analytics['next_milestone'] as Map<String, dynamic>;
        recommendations.add(
          'Your next milestone is ${nextMilestone['target_percentage']}% of your goal. '
          'You need ₹${_formatCurrency(nextMilestone['amount_needed'])} more.',
        );
      }

      // Lifestyle goals recommendation
      if (analytics['lifestyle_goals_count'] == 0) {
        recommendations.add(
          'Add lifestyle goals to visualize your retirement dreams and stay motivated.',
        );

        actionItems.add({
          'title': 'Set Lifestyle Goals',
          'description': 'Define what you want to do in retirement',
          'priority': 'medium',
          'action': 'add_lifestyle_goals',
        });
      }

      // Diversification check
      recommendations.add(
        'Regularly review your asset allocation to ensure it aligns with your risk tolerance and time horizon.',
      );

      // Annual increase recommendation
      final currentSip = analytics['monthly_sip'] as double;
      final suggestedIncrease = currentSip * 0.10;
      recommendations.add(
        'Consider increasing your SIP by 10% (₹${_formatCurrency(suggestedIncrease)}) annually to account for income growth.',
      );

      actionItems.add({
        'title': 'Annual SIP Increase',
        'description': 'Step up your investments with your income',
        'priority': 'medium',
        'action': 'schedule_sip_increase',
        'suggested_increase': suggestedIncrease,
      });

      return {
        'recommendations': recommendations,
        'action_items': actionItems,
        'overall_health_score': _calculateGoalHealthScore(analytics),
        'generated_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('Failed to get goal recommendations: $e');
    }
  }

  double _calculateGoalHealthScore(Map<String, dynamic> analytics) {
    double score = 0.0;

    // Progress percentage (40 points)
    final progressPercentage = (analytics['progress_percentage'] as double)
        .clamp(0, 100);
    score += (progressPercentage / 100) * 40;

    // On track status (30 points)
    if (analytics['on_track'] == true) {
      score += 30;
    }

    // Milestone completion (20 points)
    final milestoneRate = (analytics['milestone_completion_rate'] as double)
        .clamp(0, 100);
    score += (milestoneRate / 100) * 20;

    // Lifestyle goals set (10 points)
    if ((analytics['lifestyle_goals_count'] as int) > 0) {
      score += 10;
    }

    return score.clamp(0, 100);
  }

  String _formatCurrency(double amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(2)} L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(2)} K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }

  List<Map<String, dynamic>> _getDefaultSpendingCategories(
    double totalExpenses,
  ) {
    final categories = [
      {
        'id': 'housing',
        'name': 'Housing',
        'percentage': 0.30,
        'color': '#FF6B6B',
      },
      {
        'id': 'food',
        'name': 'Food & Dining',
        'percentage': 0.20,
        'color': '#4ECDC4',
      },
      {
        'id': 'transportation',
        'name': 'Transportation',
        'percentage': 0.15,
        'color': '#45B7D1',
      },
      {
        'id': 'healthcare',
        'name': 'Healthcare',
        'percentage': 0.10,
        'color': '#96CEB4',
      },
      {
        'id': 'insurance',
        'name': 'Insurance',
        'percentage': 0.05,
        'color': '#FECA57',
      },
      {
        'id': 'education',
        'name': 'Education',
        'percentage': 0.05,
        'color': '#FF9FF3',
      },
      {
        'id': 'entertainment',
        'name': 'Entertainment',
        'percentage': 0.05,
        'color': '#54A0FF',
      },
      {
        'id': 'shopping',
        'name': 'Shopping',
        'percentage': 0.05,
        'color': '#5F27CD',
      },
      {
        'id': 'utilities',
        'name': 'Utilities',
        'percentage': 0.03,
        'color': '#00D2D3',
      },
      {
        'id': 'miscellaneous',
        'name': 'Miscellaneous',
        'percentage': 0.02,
        'color': '#FF9F43',
      },
    ];

    return categories
        .map(
          (category) => {
            'id': category['id'],
            'name': category['name'],
            'budget': totalExpenses * (category['percentage'] as double),
            'spent': 0.0,
            'color': category['color'],
          },
        )
        .toList();
  }

  double _calculateFutureValue(
    double monthlyAmount,
    double annualRate,
    int years,
  ) {
    if (monthlyAmount <= 0 || years <= 0) return 0.0;

    final monthlyRate = annualRate / 100 / 12;
    final months = years * 12;

    return monthlyAmount *
        (math.pow(1 + monthlyRate, months) - 1) /
        monthlyRate;
  }

  Map<String, dynamic> _calculateSipProjections(
    double sipAmount,
    double returnRate,
    int years,
  ) {
    final monthlyRate = returnRate / 100 / 12;
    final months = years * 12;

    final futureValue = _calculateFutureValue(sipAmount, returnRate, years);
    final totalInvested = sipAmount * months;
    final returns = futureValue - totalInvested;

    return {
      'monthly_sip': sipAmount,
      'investment_period_years': years,
      'expected_return_rate': returnRate,
      'total_invested': totalInvested,
      'expected_corpus': futureValue,
      'expected_returns': returns,
      'return_multiple': totalInvested > 0 ? futureValue / totalInvested : 0.0,
    };
  }

  Map<String, Map<String, dynamic>> _generateCorpusScenarios(
    double sipAmount,
    int years,
  ) {
    return {
      'optimistic': _calculateSipProjections(sipAmount, 15.0, years),
      'realistic': _calculateSipProjections(sipAmount, 12.0, years),
      'pessimistic': _calculateSipProjections(sipAmount, 8.0, years),
    };
  }

  Map<String, dynamic> _calculateInflationImpact(
    Map<String, dynamic> userData,
  ) {
    final currentExpenses =
        double.tryParse(userData['monthlyExpenses'] ?? '0') ?? 0.0;
    final inflationRate =
        double.tryParse(userData['expectedInflationRate'] ?? '6') ?? 6.0;
    final yearsToRetirement =
        (int.tryParse(userData['retirementAge'] ?? '0') ?? 0) -
        (int.tryParse(userData['age'] ?? '0') ?? 0);

    final futureExpenses =
        currentExpenses *
        math.pow(1 + (inflationRate / 100), yearsToRetirement);

    return {
      'current_monthly_expenses': currentExpenses,
      'future_monthly_expenses': futureExpenses,
      'inflation_multiplier':
          currentExpenses > 0 ? futureExpenses / currentExpenses : 0.0,
      'purchasing_power_erosion':
          currentExpenses > 0
              ? ((futureExpenses - currentExpenses) / currentExpenses) * 100
              : 0.0,
    };
  }

  Map<String, dynamic> _calculateRecommendedSip(Map<String, dynamic> userData) {
    final currentIncome =
        double.tryParse(userData['currentIncome'] ?? '0') ?? 0.0;
    final currentExpenses =
        double.tryParse(userData['monthlyExpenses'] ?? '0') ?? 0.0;
    final surplus = currentIncome - currentExpenses;

    return {
      'minimum_recommended': surplus * 0.2,
      'optimal_recommended': surplus * 0.5,
      'aggressive_recommended': surplus * 0.7,
      'current_surplus': surplus,
      'recommendation_rationale':
          'Based on 20-50% of monthly surplus for sustainable investing',
    };
  }

  List<Map<String, dynamic>> _getAssetAllocationRecommendations(
    String riskTolerance,
  ) {
    final allocation = _generateAssetAllocation(riskTolerance);

    return [
      {
        'category': 'Equity Mutual Funds',
        'allocation_percentage': allocation['equity'],
        'rationale': 'Long-term wealth creation through equity exposure',
        'suggested_instruments': [
          'Large Cap Funds',
          'Mid Cap Funds',
          'ELSS Funds',
        ],
      },
      {
        'category': 'Debt Instruments',
        'allocation_percentage': allocation['debt'],
        'rationale': 'Stability and capital preservation',
        'suggested_instruments': ['PPF', 'EPF', 'Debt Mutual Funds', 'NSC'],
      },
      {
        'category': 'Gold',
        'allocation_percentage': allocation['gold'],
        'rationale': 'Hedge against inflation and portfolio diversification',
        'suggested_instruments': [
          'Gold ETF',
          'Digital Gold',
          'Gold Mutual Funds',
        ],
      },
    ];
  }

  List<Map<String, dynamic>> _getTaxSavingSuggestions(
    Map<String, dynamic> userData,
  ) {
    final current80c = double.tryParse(userData['section80c'] ?? '0') ?? 0.0;
    final remaining80c = 150000 - current80c;

    return [
      {
        'section': '80C',
        'current_investment': current80c,
        'remaining_limit': remaining80c > 0 ? remaining80c : 0,
        'suggested_instruments': [
          'ELSS Mutual Funds',
          'PPF',
          'Life Insurance Premium',
          'NSC',
        ],
        'tax_benefit': remaining80c * 0.3,
      },
      {
        'section': '80D',
        'limit': 25000,
        'suggested_instruments': ['Health Insurance Premium'],
        'benefit': 'Health coverage + tax deduction',
      },
      {
        'section': 'NPS (80CCD)',
        'additional_limit': 50000,
        'suggested_instruments': ['National Pension System'],
        'benefit': 'Retirement corpus + additional tax deduction',
      },
    ];
  }

  List<String> _getGeneralRecommendations(Map<String, dynamic> userData) {
    List<String> recommendations = [];

    final currentIncome =
        double.tryParse(userData['currentIncome'] ?? '0') ?? 0.0;
    final currentExpenses =
        double.tryParse(userData['monthlyExpenses'] ?? '0') ?? 0.0;
    final emergencyMonths =
        int.tryParse(userData['emergencyFundMonths'] ?? '6') ?? 6;
    final healthInsurance = userData['healthInsurance'] ?? '';

    recommendations.add(
      'Build emergency fund of $emergencyMonths months expenses (₹${(currentExpenses * emergencyMonths).toStringAsFixed(0)})',
    );

    if (healthInsurance == 'No coverage' || healthInsurance.isEmpty) {
      recommendations.add(
        'Get comprehensive health insurance coverage of at least ₹5-10 lakhs',
      );
    }

    if (currentIncome > currentExpenses) {
      recommendations.add(
        'Start SIP with at least ₹${((currentIncome - currentExpenses) * 0.2).toStringAsFixed(0)} per month',
      );
    }

    recommendations.addAll([
      'Diversify investments across equity, debt, and gold for optimal risk-adjusted returns',
      'Maximize Section 80C deductions through ELSS and PPF investments',
      'Review and rebalance your portfolio annually or when life circumstances change',
      'Consider increasing your SIP amount by 10% annually',
      'Maintain a long-term investment horizon for better returns',
    ]);

    return recommendations;
  }

  Future<Map<String, dynamic>?> getUserRetirementData([String? userId]) async {
    return await loadUserProfile(userId);
  }

  Future<bool> userDataExists([String? userId]) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return false;

    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      return userDoc.exists;
    } catch (e) {
      return false;
    }
  }

  Future<DateTime?> getUserCreationDate([String? userId]) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return null;

    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final timestamp = data['created_at'] as Timestamp?;
        return timestamp?.toDate();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<DateTime?> getLastUpdatedTimestamp([String? userId]) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return null;

    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final timestamp = data['last_updated'] as Timestamp?;
        return timestamp?.toDate();
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
