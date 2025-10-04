class SpendingInsight {
  final String category;
  final double amount;
  final double percentage;
  final String impactDescription;
  final double retirementImpact;
  final String recommendation;
  final InsightSeverity severity;

  SpendingInsight({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.impactDescription,
    required this.retirementImpact,
    required this.recommendation,
    required this.severity,
  });
}

enum InsightSeverity { low, medium, high, critical }
