import 'package:quebrando_metas/core/utils/progress_calculator.dart';
import 'package:quebrando_metas/core/utils/simple_id.dart';
import 'package:quebrando_metas/features/goals/domain/title_validator.dart';

class Goal {
  const Goal({
    required this.id,
    required this.title,
    this.description,
    this.priorityRank,
    required this.createdAt,
    required this.updatedAt,
    required this.completedActions,
    required this.totalActions,
  });

  final String id;
  final String title;
  final String? description;
  final int? priorityRank;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int completedActions;
  final int totalActions;

  double get progress => ProgressCalculator.fromCompletedCount(
    completedActions: completedActions,
    totalActions: totalActions,
  );

  factory Goal.create({
    required String title,
    String? description,
    DateTime? now,
  }) {
    final DateTime timestamp = now ?? DateTime.now();

    return Goal(
      id: SimpleId.generate(),
      title: TitleValidator.validate(title),
      description: description?.trim().isEmpty == true
          ? null
          : description?.trim(),
      priorityRank: null,
      createdAt: timestamp,
      updatedAt: timestamp,
      completedActions: 0,
      totalActions: 0,
    );
  }

  Goal copyWith({
    String? id,
    String? title,
    String? description,
    bool clearDescription = false,
    int? priorityRank,
    bool clearPriority = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? completedActions,
    int? totalActions,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title == null ? this.title : TitleValidator.validate(title),
      description: clearDescription ? null : description ?? this.description,
      priorityRank: clearPriority ? null : priorityRank ?? this.priorityRank,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedActions: completedActions ?? this.completedActions,
      totalActions: totalActions ?? this.totalActions,
    );
  }
}
