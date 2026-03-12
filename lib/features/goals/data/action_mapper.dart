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
    return ActionItem(
      id: map['id'] as String,
      goalId: map['goalId'] as String,
      title: map['title'] as String,
      isCompleted: map['isCompleted'] as bool,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      order: map['order'] as int,
      completedAt:
          map['completedAt'] == null ? null : DateTime.parse(map['completedAt'] as String),
    );
  }
}
