import 'dart:math' as Math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:retierment/services/questions_data.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({Key? key}) : super(key: key);

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  late TabController _tabController;

  Map<String, dynamic>? retirementGoals;
  Map<String, dynamic>? progressData;
  List<Map<String, dynamic>> milestones = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadGoalsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGoalsData() async {
    try {
      final userData = await _firebaseService.loadUserProfile();
      if (userData != null && userData['goals'] != null) {
        setState(() {
          retirementGoals = userData['goals']['retirement_goals'];
          progressData = userData['goals']['progress'];
          milestones = List<Map<String, dynamic>>.from(
            userData['goals']['milestones']?['milestones'] ?? [],
          );
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading goals data: $e')));
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      isLoading = true;
    });
    await _loadGoalsData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Retirement Goals',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshData,
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: _showUpdateGoalsDialog,
            tooltip: 'Edit Goals',
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _refreshData,
                child: Column(
                  children: [
                    _buildGoalsSummary(),
                    Expanded(
                      child: Column(
                        children: [
                          _buildTabBar(),
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildOverviewTab(),
                                _buildMilestonesTab(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildGoalsSummary() {
    final targetCorpus = retirementGoals?['target_corpus']?.toDouble() ?? 0.0;
    final currentCorpus = retirementGoals?['current_corpus']?.toDouble() ?? 0.0;
    final yearsToRetirement = retirementGoals?['years_to_retirement'] ?? 0;
    final progressPercentage =
        targetCorpus > 0 ? (currentCorpus / targetCorpus) * 100 : 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Retirement Goal Progress',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.white),
                onPressed: _showGoalInfoDialog,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress Circle
          Row(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  children: [
                    CircularProgressIndicator(
                      value: progressPercentage / 100,
                      strokeWidth: 8,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                    Center(
                      child: Text(
                        '${progressPercentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGoalStat(
                      'Target Corpus',
                      '₹${_formatAmount(targetCorpus)}',
                    ),
                    const SizedBox(height: 8),
                    _buildGoalStat(
                      'Current Corpus',
                      '₹${_formatAmount(currentCorpus)}',
                    ),
                    const SizedBox(height: 8),
                    _buildGoalStat(
                      'Years to Retirement',
                      '$yearsToRetirement years',
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.trending_up, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Remaining: ₹${_formatAmount(targetCorpus - currentCorpus)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(25),
      ),
      child: TabBar(
        indicatorSize: TabBarIndicatorSize.tab,
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF2E7D32),
          borderRadius: BorderRadius.circular(25),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade600,
        tabs: const [Tab(text: 'Overview'), Tab(text: 'Milestones')],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressChart(),
          const SizedBox(height: 20),
          _buildGoalDetails(),
          const SizedBox(height: 20),
          _buildRetirementLifestyleGoals(),
        ],
      ),
    );
  }

  Widget _buildProgressChart() {
    final targetCorpus = retirementGoals?['target_corpus']?.toDouble() ?? 0.0;
    final currentCorpus = retirementGoals?['current_corpus']?.toDouble() ?? 0.0;
    final yearsToRetirement = retirementGoals?['years_to_retirement'] ?? 30;

    // Generate projected data points
    List<FlSpot> projectionSpots = [];
    List<FlSpot> currentSpots = [FlSpot(0, currentCorpus)];

    final annualSip = 120000.0; // Assuming 10k monthly SIP
    final returnRate = 0.12; // 12% annual return

    for (int year = 1; year <= yearsToRetirement; year++) {
      final projectedValue =
          _calculateFutureValue(annualSip / 12, returnRate * 100, year) +
          currentCorpus;
      projectionSpots.add(FlSpot(year.toDouble(), projectedValue));
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Goal Progress Projection',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            _formatAmount(value),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            'Y${value.toInt()}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    // Target line
                    LineChartBarData(
                      spots: [
                        FlSpot(0, targetCorpus),
                        FlSpot(yearsToRetirement.toDouble(), targetCorpus),
                      ],
                      isCurved: false,
                      color: Colors.red,
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                      dashArray: [5, 5],
                    ),
                    // Projection line
                    LineChartBarData(
                      spots: projectionSpots,
                      isCurved: true,
                      color: const Color(0xFF2E7D32),
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF2E7D32).withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildChartLegend('Target Goal', Colors.red, true),
                const SizedBox(width: 16),
                _buildChartLegend(
                  'Projected Growth',
                  const Color(0xFF2E7D32),
                  false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartLegend(String label, Color color, bool isDashed) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1),
          ),
          child:
              isDashed
                  ? Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: color, width: 1),
                    ),
                  )
                  : null,
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildGoalDetails() {
    final monthlyExpensesAtRetirement =
        retirementGoals?['monthly_expenses_at_retirement']?.toDouble() ?? 0.0;
    final yearsInRetirement = retirementGoals?['years_in_retirement'] ?? 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Retirement Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              'Monthly Expenses (Future)',
              '₹${_formatAmount(monthlyExpensesAtRetirement)}',
            ),
            _buildDetailRow('Years in Retirement', '$yearsInRetirement years'),
            _buildDetailRow(
              'Required Monthly SIP',
              '₹${_calculateRequiredSip()}',
            ),
            _buildDetailRow(
              'Current Success Rate',
              '${_calculateSuccessRate()}%',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildRetirementLifestyleGoals() {
    final lifestyleGoals =
        retirementGoals?['retirement_lifestyle_goals'] as List<dynamic>? ?? [];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Retirement Lifestyle Goals',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Color(0xFF2E7D32)),
                  onPressed: _showAddLifestyleGoalDialog,
                  tooltip: 'Add Lifestyle Goal',
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (lifestyleGoals.isEmpty)
              Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.beach_access,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'No lifestyle goals set',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add your retirement dreams and aspirations',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ...lifestyleGoals.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: Color(0xFF2E7D32),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.value.toString(),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                        onPressed: () => _deleteLifestyleGoal(entry.key),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestonesTab() {
    if (milestones.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.flag_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No milestones set',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const Text(
              'Milestones help track your progress',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _generateMilestones,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate Milestones'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: milestones.length,
      itemBuilder: (context, index) {
        final milestone = milestones[index];
        final targetAmount = milestone['target_amount']?.toDouble() ?? 0.0;
        final targetPercentage = milestone['target_percentage'] ?? 0;
        final achieved = milestone['achieved'] ?? false;
        final targetYear = milestone['target_year'] ?? DateTime.now().year;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border:
                  achieved
                      ? Border.all(color: const Color(0xFF2E7D32), width: 2)
                      : null,
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor:
                    achieved ? const Color(0xFF2E7D32) : Colors.grey.shade400,
                child:
                    achieved
                        ? const Icon(Icons.check, color: Colors.white)
                        : Text(
                          '$targetPercentage%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
              title: Text(
                'Milestone ${milestone['milestone_number']} - $targetPercentage% Goal',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  decoration: achieved ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Target: ₹${_formatAmount(targetAmount)}'),
                  Text('Year: $targetYear'),
                  if (achieved && milestone['achievement_date'] != null)
                    Text(
                      'Achieved: ${_formatDate(milestone['achievement_date'])}',
                      style: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
              trailing:
                  achieved
                      ? const Icon(Icons.emoji_events, color: Color(0xFF2E7D32))
                      : Icon(
                        Icons.radio_button_unchecked,
                        color: Colors.grey.shade400,
                      ),
            ),
          ),
        );
      },
    );
  }

  void _showUpdateGoalsDialog() {
    final targetCorpusController = TextEditingController(
      text: retirementGoals?['target_corpus']?.toString() ?? '',
    );
    final sipAmountController = TextEditingController(
      text: retirementGoals?['monthly_sip']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Update Retirement Goals'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: targetCorpusController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Target Retirement Corpus',
                      prefixText: '₹',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: sipAmountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Monthly SIP Amount',
                      prefixText: '₹',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newTargetCorpus =
                      double.tryParse(targetCorpusController.text) ?? 0.0;
                  final newSipAmount =
                      double.tryParse(sipAmountController.text) ?? 0.0;

                  if (newTargetCorpus > 0 && newSipAmount > 0) {
                    await _updateGoals(newTargetCorpus, newSipAmount);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Goals updated successfully!'),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Update'),
              ),
            ],
          ),
    );
  }

  void _showAddLifestyleGoalDialog() {
    final goalController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Lifestyle Goal'),
            content: TextField(
              controller: goalController,
              decoration: const InputDecoration(
                labelText: 'Your retirement dream',
                hintText: 'e.g., Travel the world, Start a hobby farm',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (goalController.text.trim().isNotEmpty) {
                    await _addLifestyleGoal(goalController.text.trim());
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lifestyle goal added!')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  void _showGoalInfoDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Goal Information'),
            content: const Text(
              'Your retirement goal is calculated based on:\n\n'
              '• Current age and retirement age\n'
              '• Monthly expenses and inflation\n'
              '• Years in retirement\n'
              '• Expected returns\n\n'
              'Keep updating your progress to stay on track!',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Got it'),
              ),
            ],
          ),
    );
  }

  Future<void> _updateGoals(double targetCorpus, double sipAmount) async {
    try {
      await _firebaseService.updateRetirementGoals({
        'target_corpus': targetCorpus,
        'monthly_sip': sipAmount,
      });
      await _refreshData();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating goals: $e')));
    }
  }

  Future<void> _addLifestyleGoal(String goal) async {
    try {
      final currentGoals = List<String>.from(
        retirementGoals?['retirement_lifestyle_goals'] ?? [],
      );
      currentGoals.add(goal);

      await _firebaseService.updateRetirementGoals({
        'retirement_lifestyle_goals': currentGoals,
      });
      await _refreshData();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding goal: $e')));
    }
  }

  Future<void> _deleteLifestyleGoal(int index) async {
    try {
      final currentGoals = List<String>.from(
        retirementGoals?['retirement_lifestyle_goals'] ?? [],
      );
      currentGoals.removeAt(index);

      await _firebaseService.updateRetirementGoals({
        'retirement_lifestyle_goals': currentGoals,
      });
      await _refreshData();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Goal removed')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error removing goal: $e')));
    }
  }

  Future<void> _generateMilestones() async {
    try {
      final targetCorpus = retirementGoals?['target_corpus']?.toDouble() ?? 0.0;
      final yearsToRetirement = retirementGoals?['years_to_retirement'] ?? 30;

      List<Map<String, dynamic>> newMilestones = [];
      for (int i = 1; i <= 10; i++) {
        newMilestones.add({
          'milestone_number': i,
          'target_amount': targetCorpus * (i * 0.1),
          'target_percentage': i * 10,
          'target_year': DateTime.now().year + (yearsToRetirement * i ~/ 10),
          'achieved': false,
          'achievement_date': null,
        });
      }

      await _firebaseService.updateProfileField('goals', 'milestones', {
        'milestones': newMilestones,
      });

      await _refreshData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Milestones generated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating milestones: $e')),
      );
    }
  }

  String _formatAmount(double amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(2)}Cr';
    } else if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(2)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(2)}K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown date';

    try {
      DateTime date;
      if (timestamp is DateTime) {
        date = timestamp;
      } else {
        date = DateTime.parse(timestamp.toString());
      }

      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  String _calculateRequiredSip() {
    final targetCorpus = retirementGoals?['target_corpus']?.toDouble() ?? 0.0;
    final currentCorpus = retirementGoals?['current_corpus']?.toDouble() ?? 0.0;
    final yearsToRetirement = retirementGoals?['years_to_retirement'] ?? 30;

    final remainingAmount = targetCorpus - currentCorpus;
    final monthlyRate = 0.12 / 12; // 12% annual return
    final months = yearsToRetirement * 12;

    if (months <= 0 || monthlyRate <= 0) return '0';

    final requiredSip =
        remainingAmount *
        monthlyRate /
        ((1 + monthlyRate) * (Math.pow(1 + monthlyRate, months) - 1));

    return _formatAmount(requiredSip);
  }

  String _calculateSuccessRate() {
    final targetCorpus = retirementGoals?['target_corpus']?.toDouble() ?? 0.0;
    final currentCorpus = retirementGoals?['current_corpus']?.toDouble() ?? 0.0;
    final yearsToRetirement = retirementGoals?['years_to_retirement'] ?? 30;

    if (targetCorpus <= 0 || yearsToRetirement <= 0) return '0';

    final currentProgress = (currentCorpus / targetCorpus) * 100;
    final timeProgress =
        (30 - yearsToRetirement) / 30 * 100; // Assuming 30 year max

    final successRate = (currentProgress + timeProgress) / 2;
    return successRate.clamp(0, 100).toStringAsFixed(0);
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
        ((Math.pow(1 + monthlyRate, months) - 1) / monthlyRate);
  }
}
