class UserProfile {
  final String id;
  final String name;
  final int age;
  final double monthlyIncome;
  final double monthlyExpenses;
  final int retirementAge;
  final double currentSavings;
  final double debtAmount;
  final List<FinancialGoal> goals;
  final RiskProfile riskProfile;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.retirementAge,
    required this.currentSavings,
    required this.debtAmount,
    required this.goals,
    required this.riskProfile,
    required this.createdAt,
  });

  double get savingsRate => (monthlyIncome - monthlyExpenses) / monthlyIncome;
  int get yearsToRetirement => retirementAge - age;
}

class FinancialGoal {
  final String id;
  final String title;
  final double targetAmount;
  final DateTime targetDate;
  final GoalType type;
  final double currentProgress;
  final Priority priority;

  FinancialGoal({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.targetDate,
    required this.type,
    required this.currentProgress,
    required this.priority,
  });
}

enum GoalType { retirement, emergency, education, home, travel, other }

enum Priority { high, medium, low }

enum RiskProfile { conservative, moderate, aggressive }
