class ScenarioSimulation {
  final String scenarioName;
  final String description;
  final Map<String, double> parameters;
  final double impactOnCorpus;
  final List<String> actionSteps;
  final double recoveryTime;

  ScenarioSimulation({
    required this.scenarioName,
    required this.description,
    required this.parameters,
    required this.impactOnCorpus,
    required this.actionSteps,
    required this.recoveryTime,
  });
}
