import 'package:flutter/material.dart';
import 'package:retierment/screens/chatbotScreen.dart';
import 'package:retierment/screens/goals_screen.dart';
import 'package:retierment/screens/investments_screen.dart';
import 'package:retierment/screens/persnoalizedAI.dart';
import 'package:retierment/screens/profile_screen.dart';
import 'package:retierment/services/questions_data.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:math' as math;

// Main Home Screen with Bottom Navigation
class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({Key? key}) : super(key: key);

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _currentIndex = 0;
  final FirebaseService _firebaseService = FirebaseService();
  final GlobalKey<_DashboardHomeState> _dashboardKey =
      GlobalKey<_DashboardHomeState>();

  final List<Widget> _screens = [
    const DashboardHome(),
    const InvestmentScreen(),
    const GoalsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
                _buildNavItem(
                  1,
                  Icons.trending_up_outlined,
                  Icons.trending_up,
                  'Invest',
                ),
                _buildNavItem(2, Icons.flag_outlined, Icons.flag, 'Goals'),
                _buildNavItem(3, Icons.person_outline, Icons.person, 'Profile'),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      AIChatbotScreen(firebaseService: _firebaseService),
            ),
          );
          _dashboardKey.currentState?._loadUserData();
        },
        backgroundColor: Colors.black,
        elevation: 2,
        icon: const Icon(Icons.psychology_outlined, color: Colors.white),
        label: const Text(
          'AI Advisor',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData outlinedIcon,
    IconData filledIcon,
    String label,
  ) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? filledIcon : outlinedIcon,
              color: isSelected ? Colors.black : Colors.grey.shade600,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.grey.shade600,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAIAdvisor(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AIAdvisorScreen(firebaseService: _firebaseService),
      ),
    );
  }
}

// AI Advisor Screen with Gemini Integration
class AIAdvisorScreen extends StatefulWidget {
  final FirebaseService firebaseService;

  const AIAdvisorScreen({Key? key, required this.firebaseService})
    : super(key: key);

  @override
  State<AIAdvisorScreen> createState() => _AIAdvisorScreenState();
}

class _AIAdvisorScreenState extends State<AIAdvisorScreen> {
  Map<String, dynamic>? _userData;
  String? _aiAdvice;
  bool _isLoading = true;
  bool _isGenerating = false;
  late GenerativeModel _model;

  @override
  void initState() {
    super.initState();
    _initializeGemini();
    _loadDataAndGenerateAdvice();
  }

  void _initializeGemini() {
    // Replace with your Gemini API key
    const apiKey = 'AIzaSyC3TVQ5iUDbpal03iE6udPF86xngJn-XOg';
    _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
  }

  Future<void> _loadDataAndGenerateAdvice() async {
    try {
      final data = await widget.firebaseService.loadUserProfile();
      setState(() {
        _userData = data;
        _isLoading = false;
      });
      await _generatePersonalizedAdvice();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generatePersonalizedAdvice() async {
    if (_userData == null) return;

    setState(() => _isGenerating = true);

    try {
      final portfolio = _userData!['investments']?['portfolio_summary'] ?? {};
      final goals = _userData!['goals']?['retirement_goals'] ?? {};
      final profile = _userData!['profile']?['personal_info'] ?? {};

      final prompt = '''
You are a professional financial advisor. Analyze the following user data and provide personalized retirement planning advice:

User Profile:
- Name: ${profile['name'] ?? 'User'}
- Age: ${profile['age'] ?? 'N/A'}
- Income: ${profile['income'] ?? 'N/A'}
- Risk Profile: ${profile['risk_profile'] ?? 'Moderate'}

Portfolio:
- Current Value: ₹${portfolio['current_value'] ?? 0}
- Total Invested: ₹${portfolio['total_invested'] ?? 0}
- Returns: ₹${portfolio['total_returns'] ?? 0}

Retirement Goals:
- Target Corpus: ₹${goals['target_corpus'] ?? 0}
- Current Corpus: ₹${goals['current_corpus'] ?? 0}
- Retirement Age: ${goals['retirement_age'] ?? 60}

Provide:
1. Overall Financial Health Assessment (1-2 sentences)
2. Top 3 Specific Recommendations (actionable steps)
3. Risk Analysis (1-2 sentences)
4. Investment Strategy Suggestions (2-3 specific suggestions)

Keep it concise, professional, and actionable. Format as clear sections.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      setState(() {
        _aiAdvice = response.text ?? 'Unable to generate advice at this time.';
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _aiAdvice = 'Error generating advice. Please try again later.';
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'AI Financial Advisor',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.black),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    if (_isGenerating)
                      _buildLoadingCard()
                    else if (_aiAdvice != null)
                      _buildAdviceCard(),
                    const SizedBox(height: 20),
                    _buildRefreshButton(),
                  ],
                ),
              ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.psychology, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personalized Analysis',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4),
                Text(
                  'AI-powered insights based on your financial data',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
          const SizedBox(height: 16),
          Text(
            'Analyzing your financial data...',
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildAdviceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Your Personalized Advice',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _aiAdvice!,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isGenerating ? null : _generatePersonalizedAdvice,
        icon: const Icon(Icons.refresh, size: 20),
        label: const Text('Generate New Analysis'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          side: BorderSide(color: Colors.grey.shade300),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

// Dashboard Home Screen
class DashboardHome extends StatefulWidget {
  const DashboardHome({Key? key}) : super(key: key);

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  final FirebaseService _firebaseService = FirebaseService();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final data = await _firebaseService.loadUserProfile();
      setState(() {
        _userData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.black),
              )
              : RefreshIndicator(
                onRefresh: _loadUserData,
                color: Colors.black,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildAppBar(),
                    SliverPadding(
                      padding: const EdgeInsets.all(20),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildPortfolioCard(),
                          const SizedBox(height: 16),
                          _buildRetirementGoalCard(),
                          const SizedBox(height: 16),
                          _buildMetricsGrid(),
                          const SizedBox(height: 16),
                          _buildRecentTransactions(),
                          const SizedBox(height: 16),
                          _buildInvestmentRoadmap(),
                          const SizedBox(height: 100),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back,',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              _getProfileName(),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioCard() {
    final portfolio = _userData?['investments']?['portfolio_summary'] ?? {};
    final currentValue = (portfolio['current_value'] ?? 0.0).toDouble();
    final returns = (portfolio['total_returns'] ?? 0.0).toDouble();
    final totalInvested = (portfolio['total_invested'] ?? 0.0).toDouble();
    final returnPercentage =
        totalInvested > 0 ? (returns / totalInvested) * 100 : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Portfolio Value',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${_formatCurrency(currentValue)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: returns >= 0 ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${returns >= 0 ? '+' : ''}${returnPercentage.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invested',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${_formatCurrency(totalInvested)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Returns',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${_formatCurrency(returns)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRetirementGoalCard() {
    final goals = _userData?['goals']?['retirement_goals'] ?? {};
    final targetCorpus = (goals['target_corpus'] ?? 0.0).toDouble();
    final currentCorpus = (goals['current_corpus'] ?? 0.0).toDouble();
    final progress =
        targetCorpus > 0 ? (currentCorpus / targetCorpus) * 100 : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Retirement Goal',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(
                '${progress.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${_formatCurrency(currentCorpus)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Target',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${_formatCurrency(targetCorpus)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    final currentAge = _userData?['profile']?['personal_info']?['age'] ?? 30;
    final goals = _userData?['goals']?['retirement_goals'] ?? {};
    final retirementAge = goals['retirement_age'] ?? 60;
    final yearsToRetirement = retirementAge - currentAge;

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Current Age',
            currentAge.toString(),
            Icons.person_outline,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            'Retirement',
            retirementAge.toString(),
            Icons.flag_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: Colors.grey.shade700),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    final transactions =
        _userData?['investments']?['transactions']?['transactions'] ?? [];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Transactions',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          transactions.isEmpty
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 48,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No transactions yet',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactions.length > 5 ? 5 : transactions.length,
                separatorBuilder:
                    (_, __) => Divider(height: 24, color: Colors.grey.shade200),
                itemBuilder: (context, index) {
                  final transaction = transactions[index];
                  final type = transaction['type'] ?? 'Transaction';
                  final amount = (transaction['amount'] ?? 0.0).toDouble();
                  final isCredit =
                      type.toLowerCase().contains('credit') ||
                      type.toLowerCase().contains('buy');

                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                          size: 18,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              type,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              transaction['date'] ?? 'Recent',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${isCredit ? '+' : '-'}₹${_formatCurrency(amount)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                },
              ),
        ],
      ),
    );
  }

  String _getProfileName() {
    return _userData?['profile']?['personal_info']?['name'] ?? 'User';
  }

  Widget _buildInvestmentRoadmap() {
    final goals = _userData?['goals']?['retirement_goals'] ?? {};
    final portfolio = _userData?['investments']?['portfolio_summary'] ?? {};
    final profile = _userData?['profile']?['personal_info'] ?? {};

    final currentAge = profile['age'] ?? 30;
    final retirementAge = goals['retirement_age'] ?? 60;
    final targetCorpus = (goals['target_corpus'] ?? 0.0).toDouble();
    final currentCorpus = (goals['current_corpus'] ?? 0.0).toDouble();
    final monthlyIncome = (profile['income'] ?? 0.0).toDouble();
    final monthlyExpenses = (profile['monthly_expenses'] ?? 0.0).toDouble();

    final yearsToRetirement = retirementAge - currentAge;
    final monthsToRetirement = yearsToRetirement * 12;

    // Calculate corpus gap
    final corpusGap = targetCorpus - currentCorpus;

    // Get expected return rate from user input or default to 12%
    final expectedReturn =
        (profile['expected_return_rate'] ?? 12.0).toDouble() / 100;
    final monthlyReturn = expectedReturn / 12;

    // Calculate required monthly SIP using future value of annuity formula
    // FV = P * [((1 + r)^n - 1) / r] * (1 + r)
    final monthlyRequired =
        corpusGap > 0 && monthsToRetirement > 0
            ? corpusGap /
                (((math.pow(1 + monthlyReturn, monthsToRetirement) - 1) /
                        monthlyReturn) *
                    (1 + monthlyReturn))
            : 0.0;

    // Get user's current savings capacity
    final disposableIncome = monthlyIncome - monthlyExpenses;
    final suggestedSIP =
        monthlyRequired > disposableIncome * 0.7
            ? disposableIncome *
                0.5 // If required is too high, suggest 50% of disposable income
            : monthlyRequired;

    final riskProfile =
        profile['risk_profile']?.toString().toLowerCase() ?? 'moderate';

    // Calculate dynamic allocation based on user's risk profile and age
    Map<String, double> allocation = _calculateOptimalAllocation(
      riskProfile,
      currentAge,
    );

    // Generate personalized stages based on user's timeline
    final stages = _generateInvestmentStages(
      currentAge,
      retirementAge,
      riskProfile,
      corpusGap,
      currentCorpus,
    );

    // Calculate if user is on track
    final projectedCorpus = _calculateProjectedCorpus(
      currentCorpus,
      suggestedSIP,
      monthsToRetirement,
      monthlyReturn,
    );
    final onTrackPercentage =
        targetCorpus > 0
            ? (projectedCorpus / targetCorpus * 100).clamp(0, 150)
            : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.map_outlined, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Investment Roadmap',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Personalized plan for $yearsToRetirement years to retirement',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Progress Indicator
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Goal Progress',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    Text(
                      '${onTrackPercentage.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (onTrackPercentage / 100).clamp(0.0, 1.0),
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      onTrackPercentage >= 100 ? Colors.green : Colors.orange,
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  onTrackPercentage >= 100
                      ? 'You\'re on track to meet your goal!'
                      : 'Consider increasing monthly investments',
                  style: TextStyle(
                    color:
                        onTrackPercentage >= 100
                            ? Colors.green.shade300
                            : Colors.orange.shade300,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Monthly Investment Required
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recommended Monthly SIP',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₹${_formatCurrency(suggestedSIP)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Gap to cover: ₹${_formatCurrency(corpusGap)}',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.calendar_month,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$yearsToRetirement yrs',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Asset Allocation based on user profile
          Text(
            'Recommended Asset Allocation',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Based on your ${riskProfile} risk profile and $currentAge years age',
            style: TextStyle(color: Colors.white60, fontSize: 11),
          ),
          const SizedBox(height: 16),
          ...allocation.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildAllocationBar(entry.key, entry.value),
            ),
          ),

          const SizedBox(height: 24),

          // Investment Stages Timeline
          Text(
            'Investment Strategy Timeline',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...stages.asMap().entries.map((entry) {
            final isLast = entry.key == stages.length - 1;
            return _buildStageItem(entry.value, isLast);
          }),

          const SizedBox(height: 24),

          // Projection Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Projected Corpus',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      '₹${_formatCurrency(projectedCorpus)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Expected Returns',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      '${(expectedReturn * 100).toStringAsFixed(1)}% p.a.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => PersonalizedRoadmapScreen(
                          userData: _userData ?? {},
                        ),
                  ),
                );
              },
              icon: const Icon(Icons.psychology_outlined, size: 20),
              label: const Text('Get Detailed AI Analysis'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to calculate projected corpus
  double _calculateProjectedCorpus(
    double currentCorpus,
    double monthlySIP,
    int months,
    double monthlyReturn,
  ) {
    // Future value of current corpus
    final fvCurrent = currentCorpus * math.pow(1 + monthlyReturn, months);

    // Future value of SIP annuity
    final fvSIP =
        monthlySIP *
        (((math.pow(1 + monthlyReturn, months) - 1) / monthlyReturn) *
            (1 + monthlyReturn));

    return fvCurrent + fvSIP;
  }

  // Enhanced allocation calculation
  Map<String, double> _calculateOptimalAllocation(String riskProfile, int age) {
    // Base equity allocation using age rule: 100 - age
    double equityBase = 100 - age.toDouble();

    // Risk profile multipliers
    Map<String, double> riskMultipliers = {
      'conservative': 0.6,
      'moderate': 1.0,
      'aggressive': 1.3,
    };

    double multiplier = riskMultipliers[riskProfile] ?? 1.0;
    equityBase = (equityBase * multiplier).clamp(20, 85);

    double equity = equityBase;
    double remainingAllocation = 100 - equity;

    // Distribute remaining based on risk profile
    double debt, gold, alternative;

    if (riskProfile == 'conservative') {
      debt = remainingAllocation * 0.75;
      gold = remainingAllocation * 0.20;
      alternative = remainingAllocation * 0.05;
    } else if (riskProfile == 'aggressive') {
      debt = remainingAllocation * 0.60;
      gold = remainingAllocation * 0.15;
      alternative = remainingAllocation * 0.25;
    } else {
      debt = remainingAllocation * 0.70;
      gold = remainingAllocation * 0.20;
      alternative = remainingAllocation * 0.10;
    }

    return {
      'Equity (Stocks/MF)': equity,
      'Debt (Bonds/FD)': debt,
      'Gold': gold,
      'Alternative Assets': alternative,
    };
  }

  // Enhanced stage generation
  List<Map<String, dynamic>> _generateInvestmentStages(
    int currentAge,
    int retirementAge,
    String riskProfile,
    double corpusGap,
    double currentCorpus,
  ) {
    List<Map<String, dynamic>> stages = [];
    int yearsToRetirement = retirementAge - currentAge;

    // Calculate milestone ages
    int phase1End = currentAge + (yearsToRetirement * 0.5).round();
    int phase2End = retirementAge - 5;

    if (yearsToRetirement > 15) {
      // Three-phase approach for long timeline
      stages.add({
        'title': 'Phase 1: Wealth Accumulation',
        'period':
            'Age $currentAge - $phase1End (${phase1End - currentAge} years)',
        'strategy':
            riskProfile == 'aggressive'
                ? 'Focus on high-growth equity funds and direct stocks. Target 70-80% equity allocation for maximum wealth creation.'
                : riskProfile == 'conservative'
                ? 'Balanced approach with 40-50% equity in large-cap funds and 50-60% in debt for steady growth with lower volatility.'
                : 'Invest 60-70% in diversified equity funds and 30-40% in debt instruments for balanced growth.',
      });

      stages.add({
        'title': 'Phase 2: Portfolio Rebalancing',
        'period':
            'Age $phase1End - $phase2End (${phase2End - phase1End} years)',
        'strategy':
            'Gradually reduce equity to ${riskProfile == 'aggressive'
                ? '50-60%'
                : riskProfile == 'conservative'
                ? '30-40%'
                : '40-50%'}. '
            'Increase allocation to debt and gold for stability while maintaining growth potential.',
      });

      stages.add({
        'title': 'Phase 3: Capital Preservation',
        'period':
            'Age $phase2End - $retirementAge (${retirementAge - phase2End} years)',
        'strategy':
            'Shift to ${riskProfile == 'aggressive'
                ? '30-40%'
                : riskProfile == 'conservative'
                ? '20-25%'
                : '25-30%'} equity. '
            'Focus on liquid funds, FDs, and high-quality bonds to protect accumulated wealth.',
      });
    } else if (yearsToRetirement > 5) {
      // Two-phase approach for medium timeline
      int midPoint = currentAge + (yearsToRetirement * 0.6).round();

      stages.add({
        'title': 'Phase 1: Accelerated Growth',
        'period':
            'Age $currentAge - $midPoint (${midPoint - currentAge} years)',
        'strategy':
            'Maintain ${riskProfile == 'aggressive'
                ? '60-70%'
                : riskProfile == 'conservative'
                ? '35-45%'
                : '50-60%'} equity allocation. '
            'Focus on consistent SIP investments to build corpus quickly.',
      });

      stages.add({
        'title': 'Phase 2: Stability Focus',
        'period':
            'Age $midPoint - $retirementAge (${retirementAge - midPoint} years)',
        'strategy':
            'Reduce equity to ${riskProfile == 'aggressive'
                ? '40-50%'
                : riskProfile == 'conservative'
                ? '25-30%'
                : '30-40%'}. '
            'Prioritize capital protection while maintaining moderate growth.',
      });
    } else {
      // Single-phase conservative approach for short timeline
      stages.add({
        'title': 'Focused Capital Preservation',
        'period': 'Age $currentAge - $retirementAge ($yearsToRetirement years)',
        'strategy':
            'Conservative strategy with ${riskProfile == 'aggressive'
                ? '35-40%'
                : riskProfile == 'conservative'
                ? '20-25%'
                : '25-35%'} equity. '
            'Prioritize safety with debt funds, FDs, and low-volatility instruments. '
            'Consider increasing monthly SIP to compensate for shorter timeline.',
      });
    }

    return stages;
  }

  Widget _buildAllocationBar(String assetClass, double percentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              assetClass,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(0)}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percentage / 100,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStageItem(Map<String, dynamic> stage, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: Colors.white.withOpacity(0.3),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stage['title'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stage['period'],
                  style: TextStyle(color: Colors.white60, fontSize: 11),
                ),
                const SizedBox(height: 8),
                Text(
                  stage['strategy'],
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Map<String, double> _calculateOptimalAllocation(String riskProfile, int age) {
  //   // Age-based adjustment (equity reduces with age)
  //   double equityBase = 100 - age.toDouble();

  //   // Risk profile adjustment
  //   if (riskProfile == 'conservative') {
  //     equityBase *= 0.6;
  //   } else if (riskProfile == 'aggressive') {
  //     equityBase *= 1.2;
  //   }

  //   equityBase = equityBase.clamp(20, 80);

  //   double equity = equityBase;
  //   double debt = (100 - equity) * 0.7;
  //   double gold = (100 - equity) * 0.2;
  //   double alternative = (100 - equity) * 0.1;

  //   // Normalize to 100%
  //   double total = equity + debt + gold + alternative;

  //   return {
  //     'Equity (Stocks/MF)': (equity / total * 100),
  //     'Debt (Bonds/FD)': (debt / total * 100),
  //     'Gold': (gold / total * 100),
  //     'Alternative': (alternative / total * 100),
  //   };
  // }

  // List<Map<String, dynamic>> _generateInvestmentStages(
  //   int currentAge,
  //   int retirementAge,
  // ) {
  //   List<Map<String, dynamic>> stages = [];
  //   int yearsToRetirement = retirementAge - currentAge;

  //   if (yearsToRetirement > 15) {
  //     // Aggressive Phase
  //     stages.add({
  //       'title': 'Phase 1: Growth',
  //       'period': 'Age $currentAge - ${currentAge + (yearsToRetirement ~/ 2)}',
  //       'strategy':
  //           'Focus on high-growth equity investments. Allocate 60-70% to equity mutual funds and stocks for maximum wealth creation.',
  //     });

  //     // Balanced Phase
  //     stages.add({
  //       'title': 'Phase 2: Consolidation',
  //       'period':
  //           'Age ${currentAge + (yearsToRetirement ~/ 2)} - ${retirementAge - 5}',
  //       'strategy':
  //           'Gradually shift to balanced portfolio. Reduce equity to 40-50% and increase debt allocation for stability.',
  //     });

  //     // Conservative Phase
  //     stages.add({
  //       'title': 'Phase 3: Preservation',
  //       'period': 'Age ${retirementAge - 5} - $retirementAge',
  //       'strategy':
  //           'Protect accumulated wealth. Move to 30-40% equity with focus on debt instruments and fixed deposits.',
  //     });
  //   } else if (yearsToRetirement > 5) {
  //     // Balanced Approach
  //     stages.add({
  //       'title': 'Phase 1: Balanced Growth',
  //       'period': 'Age $currentAge - ${retirementAge - 3}',
  //       'strategy':
  //           'Maintain 50-60% equity allocation with focus on large-cap funds and blue-chip stocks for steady growth.',
  //     });

  //     stages.add({
  //       'title': 'Phase 2: Capital Protection',
  //       'period': 'Age ${retirementAge - 3} - $retirementAge',
  //       'strategy':
  //           'Shift to conservative allocation with 30-40% equity. Prioritize capital preservation over aggressive growth.',
  //     });
  //   } else {
  //     // Conservative Approach
  //     stages.add({
  //       'title': 'Capital Preservation Focus',
  //       'period': 'Age $currentAge - $retirementAge',
  //       'strategy':
  //           'Conservative strategy with 30-40% equity. Focus on debt funds, FDs, and guaranteed return instruments to protect capital.',
  //     });
  //   }

  //   return stages;
  // }

  String _formatCurrency(double amount) {
    double absAmount = amount.abs();
    if (absAmount >= 10000000) {
      return '${(absAmount / 10000000).toStringAsFixed(2)}Cr';
    } else if (absAmount >= 100000) {
      return '${(absAmount / 100000).toStringAsFixed(2)}L';
    } else if (absAmount >= 1000) {
      return '${(absAmount / 1000).toStringAsFixed(2)}K';
    }
    return absAmount.toStringAsFixed(0);
  }
}
