import 'package:quebrando_metas/core/utils/simple_id.dart';
import 'package:quebrando_metas/features/goals/domain/title_validator.dart';

class ActionItem {
  const ActionItem({
    required this.id,
    required this.goalId,
    required this.title,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
    required this.order,
    this.totalFocusMinutes = 0,
    this.lastFocusStartedAt,
    this.completedAt,
  });

  final String id;
  final String goalId;
  final String title;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int order;
  final int totalFocusMinutes;
  final DateTime? lastFocusStartedAt;
  final DateTime? completedAt;

  factory ActionItem.create({
    required String goalId,
    required String title,
    required int order,
    DateTime? now,
  }) {
    final DateTime timestamp = now ?? DateTime.now();

    return ActionItem(
      id: SimpleId.generate(),
      goalId: goalId,
      title: TitleValidator.validate(title),
      isCompleted: false,
      createdAt: timestamp,
      updatedAt: timestamp,
      order: order,
      totalFocusMinutes: 0,
      lastFocusStartedAt: null,
      completedAt: null,
    );
  }

  ActionItem markCompleted({DateTime? now}) {
    final DateTime timestamp = now ?? DateTime.now();
    return copyWith(
      isCompleted: true,
      updatedAt: timestamp,
      completedAt: timestamp,
    );
  }

  ActionItem markPending({DateTime? now}) {
    return copyWith(
      isCompleted: false,
      updatedAt: now ?? DateTime.now(),
      clearCompletedAt: true,
    );
  }

  ActionItem registerFocus({
    required int durationMinutes,
    DateTime? startedAt,
    DateTime? now,
  }) {
    final int sanitizedDuration = durationMinutes < 0 ? 0 : durationMinutes;
    return copyWith(
      totalFocusMinutes: totalFocusMinutes + sanitizedDuration,
      lastFocusStartedAt: startedAt ?? now ?? DateTime.now(),
      updatedAt: now ?? DateTime.now(),
    );
  }

  ActionItem copyWith({
    String? id,
    String? goalId,
    String? title,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? order,
    int? totalFocusMinutes,
    DateTime? lastFocusStartedAt,
    bool clearLastFocusStartedAt = false,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return ActionItem(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      title: title == null ? this.title : TitleValidator.validate(title),
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      order: order ?? this.order,
      totalFocusMinutes: totalFocusMinutes ?? this.totalFocusMinutes,
      lastFocusStartedAt: clearLastFocusStartedAt
          ? null
          : lastFocusStartedAt ?? this.lastFocusStartedAt,
      completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
    );
  }
}
