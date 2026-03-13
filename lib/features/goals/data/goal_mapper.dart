import 'package:quebrando_metas/features/goals/domain/goal.dart';

class GoalMapper {
  const GoalMapper._();

  static Map<String, dynamic> toMap(Goal goal) {
    return <String, dynamic>{
      'id': goal.id,
      'title': goal.title,
      'description': goal.description,
      'createdAt': goal.createdAt.toIso8601String(),
      'updatedAt': goal.updatedAt.toIso8601String(),
      'completedActions': goal.completedActions,
      'totalActions': goal.totalActions,
    };
  }

  static Goal fromMap(Map<String, dynamic> map) {
    final DateTime createdAt = _parseDateTime(map['createdAt']) ?? DateTime.now();
    final DateTime updatedAt = _parseDateTime(map['updatedAt']) ?? createdAt;

    return Goal(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      description: map['description'] as String?,
      createdAt: createdAt,
      updatedAt: updatedAt,
      completedActions: _parseInt(map['completedActions']) ?? 0,
      totalActions: _parseInt(map['totalActions']) ?? 0,
    );
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
