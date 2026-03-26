import 'package:quebrando_metas/core/utils/simple_id.dart';

enum FocusSessionStatus { running, completed, canceled }

class FocusSession {
  static const int streakMinimumMinutes = 5;

  const FocusSession({
    required this.id,
    required this.actionId,
    required this.goalId,
    required this.startedAt,
    required this.durationMinutes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.endedAt,
  });

  final String id;
  final String actionId;
  final String goalId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int durationMinutes;
  final FocusSessionStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory FocusSession.start({
    required String actionId,
    required String goalId,
    required int durationMinutes,
    DateTime? now,
  }) {
    final DateTime timestamp = now ?? DateTime.now();
    return FocusSession(
      id: SimpleId.generate(),
      actionId: actionId,
      goalId: goalId,
      startedAt: timestamp,
      endedAt: null,
      durationMinutes: durationMinutes,
      status: FocusSessionStatus.running,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }

  FocusSession markCompleted({DateTime? now}) {
    final DateTime timestamp = now ?? DateTime.now();
    return copyWith(
      endedAt: timestamp,
      status: FocusSessionStatus.completed,
      updatedAt: timestamp,
    );
  }

  FocusSession markCanceled({DateTime? now}) {
    final DateTime timestamp = now ?? DateTime.now();
    return copyWith(
      endedAt: timestamp,
      status: FocusSessionStatus.canceled,
      updatedAt: timestamp,
    );
  }

  FocusSession copyWith({
    String? id,
    String? actionId,
    String? goalId,
    DateTime? startedAt,
    DateTime? endedAt,
    bool clearEndedAt = false,
    int? durationMinutes,
    FocusSessionStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FocusSession(
      id: id ?? this.id,
      actionId: actionId ?? this.actionId,
      goalId: goalId ?? this.goalId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: clearEndedAt ? null : endedAt ?? this.endedAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int accountedMinutes() {
    if (status == FocusSessionStatus.running) return 0;

    if (endedAt != null) {
      final int elapsed = endedAt!.difference(startedAt).inMinutes;
      if (elapsed <= 0) return 0;
      if (elapsed > durationMinutes) return durationMinutes;
      return elapsed;
    }

    if (status == FocusSessionStatus.completed) {
      return durationMinutes;
    }

    return 0;
  }

  bool qualifiesForStreak({int minimumMinutes = streakMinimumMinutes}) {
    return accountedMinutes() >= minimumMinutes;
  }
}
