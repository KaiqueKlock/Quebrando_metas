import 'package:quebrando_metas/features/goals/domain/action.dart';

class ActionMapper {
  const ActionMapper._();

  static Map<String, dynamic> toMap(ActionItem action) {
    return <String, dynamic>{
      'id': action.id,
      'goalId': action.goalId,
      'title': action.title,
      'isCompleted': action.isCompleted,
      'createdAt': action.createdAt.toIso8601String(),
      'updatedAt': action.updatedAt.toIso8601String(),
      'order': action.order,
      'completedAt': action.completedAt?.toIso8601String(),
    };
  }

  static ActionItem fromMap(Map<String, dynamic> map) {
    final DateTime createdAt = _parseDateTime(map['createdAt']) ?? DateTime.now();
    final DateTime updatedAt = _parseDateTime(map['updatedAt']) ?? createdAt;
    final DateTime? completedAt = _parseDateTime(map['completedAt']);

    return ActionItem(
      id: (map['id'] ?? '').toString(),
      goalId: (map['goalId'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      isCompleted: _parseBool(map['isCompleted']) ?? false,
      createdAt: createdAt,
      updatedAt: updatedAt,
      order: _parseInt(map['order']) ?? 0,
      completedAt: completedAt,
    );
  }

  static int? _parseInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static bool? _parseBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final String normalized = value.trim().toLowerCase();
      if (normalized == 'true') return true;
      if (normalized == 'false') return false;
    }
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
