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

  static Goal fromMap(Map<dynamic, dynamic> map) {
    return Goal(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      completedActions: map['completedActions'] as int,
      totalActions: map['totalActions'] as int,
    );
  }
}
