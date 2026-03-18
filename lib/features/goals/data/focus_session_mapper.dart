import 'package:quebrando_metas/features/goals/domain/focus_session.dart';

class FocusSessionMapper {
  const FocusSessionMapper._();

  static Map<String, dynamic> toMap(FocusSession session) {
    return <String, dynamic>{
      'id': session.id,
      'actionId': session.actionId,
      'goalId': session.goalId,
      'startedAt': session.startedAt.toIso8601String(),
      'endedAt': session.endedAt?.toIso8601String(),
      'durationMinutes': session.durationMinutes,
      'status': _statusToString(session.status),
      'createdAt': session.createdAt.toIso8601String(),
      'updatedAt': session.updatedAt.toIso8601String(),
    };
  }

  static FocusSession fromMap(Map<String, dynamic> map) {
    final DateTime createdAt =
        _parseDateTime(map['createdAt']) ?? DateTime.now();
    final DateTime startedAt = _parseDateTime(map['startedAt']) ?? createdAt;

    return FocusSession(
      id: (map['id'] ?? '').toString(),
      actionId: (map['actionId'] ?? '').toString(),
      goalId: (map['goalId'] ?? '').toString(),
      startedAt: startedAt,
      endedAt: _parseDateTime(map['endedAt']),
      durationMinutes: _parseInt(map['durationMinutes']) ?? 0,
      status: _statusFromString(map['status']),
      createdAt: createdAt,
      updatedAt: _parseDateTime(map['updatedAt']) ?? createdAt,
    );
  }

  static String _statusToString(FocusSessionStatus status) {
    switch (status) {
      case FocusSessionStatus.running:
        return 'running';
      case FocusSessionStatus.completed:
        return 'completed';
      case FocusSessionStatus.canceled:
        return 'canceled';
    }
  }

  static FocusSessionStatus _statusFromString(Object? value) {
    final String status = (value ?? '').toString().trim().toLowerCase();
    switch (status) {
      case 'completed':
        return FocusSessionStatus.completed;
      case 'canceled':
      case 'cancelled':
        return FocusSessionStatus.canceled;
      default:
        return FocusSessionStatus.running;
    }
  }

  static int? _parseInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return null;
  }
}
