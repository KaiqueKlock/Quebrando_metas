class ActionItem {
  const ActionItem({
    required this.id,
    required this.goalId,
    required this.title,
    required this.isCompleted,
    required this.createdAt,
  });

  final String id;
  final String goalId;
  final String title;
  final bool isCompleted;
  final DateTime createdAt;
}
