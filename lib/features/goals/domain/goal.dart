class Goal {
  const Goal({
    required this.id,
    required this.title,
    this.description,
    required this.createdAt,
    required this.progress,
  });

  final String id;
  final String title;
  final String? description;
  final DateTime createdAt;
  final double progress;
}
