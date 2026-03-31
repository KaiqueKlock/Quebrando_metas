import 'package:quebrando_metas/core/utils/simple_id.dart';

class ActionDayConfirmation {
  const ActionDayConfirmation({
    required this.id,
    required this.goalId,
    required this.actionId,
    required this.confirmedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String goalId;
  final String actionId;
  final DateTime confirmedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ActionDayConfirmation.create({
    required String goalId,
    required String actionId,
    DateTime? now,
  }) {
    final DateTime timestamp = now ?? DateTime.now();
    return ActionDayConfirmation(
      id: SimpleId.generate(),
      goalId: goalId,
      actionId: actionId,
      confirmedAt: timestamp,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }

  ActionDayConfirmation copyWith({
    String? id,
    String? goalId,
    String? actionId,
    DateTime? confirmedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ActionDayConfirmation(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      actionId: actionId ?? this.actionId,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
