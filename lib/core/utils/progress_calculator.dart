class ProgressCalculator {
  const ProgressCalculator._();

  static double fromCompletedCount({
    required int completedActions,
    required int totalActions,
  }) {
    if (totalActions <= 0) return 0;
    return completedActions / totalActions;
  }
}
