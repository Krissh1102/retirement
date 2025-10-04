class RetirementProjection {
  final double projectedCorpus;
  final double requiredCorpus;
  final double monthlyPensionAmount;
  final double shortfall;
  final double inflationAdjustedAmount;
  final List<YearlyProjection> yearlyProjections;
  final double successProbability;

  RetirementProjection({
    required this.projectedCorpus,
    required this.requiredCorpus,
    required this.monthlyPensionAmount,
    required this.shortfall,
    required this.inflationAdjustedAmount,
    required this.yearlyProjections,
    required this.successProbability,
  });
}

class YearlyProjection {
  final int year;
  final double corpus;
  final double contribution;
  final double returns;
  final double inflationAdjustedValue;

  YearlyProjection({
    required this.year,
    required this.corpus,
    required this.contribution,
    required this.returns,
    required this.inflationAdjustedValue,
  });
}
