import 'package:quebrando_metas/features/goals/domain/action_day_confirmation.dart';

class ActionDayConfirmationMapper {
  const ActionDayConfirmationMapper._();

  static Map<String, dynamic> toMap(ActionDayConfirmation confirmation) {
    return <String, dynamic>{
      'id': confirmation.id,
      'goalId': confirmation.goalId,
      'actionId': confirmation.actionId,
      'confirmedAt': confirmation.confirmedAt.toIso8601String(),
      'createdAt': confirmation.createdAt.toIso8601String(),
      'updatedAt': confirmation.updatedAt.toIso8601String(),
    };
  }

  static ActionDayConfirmation fromMap(Map<String, dynamic> map) {
    final DateTime now = DateTime.now();
    final DateTime confirmedAt =
        _parseDateTime(map['confirmedAt']) ??
        _parseDateTime(map['doneAt']) ??
        _parseDateTime(map['timestamp']) ??
        _parseDateTime(map['createdAt']) ??
        now;
    final DateTime createdAt = _parseDateTime(map['createdAt']) ?? confirmedAt;
    final DateTime updatedAt = _parseDateTime(map['updatedAt']) ?? createdAt;

    return ActionDayConfirmation(
      id: (map['id'] ?? '').toString(),
      goalId: (map['goalId'] ?? '').toString(),
      actionId: (map['actionId'] ?? '').toString(),
      confirmedAt: confirmedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }
}
