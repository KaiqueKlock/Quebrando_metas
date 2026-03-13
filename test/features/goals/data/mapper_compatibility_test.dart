import 'package:flutter_test/flutter_test.dart';
import 'package:quebrando_metas/features/goals/data/action_mapper.dart';
import 'package:quebrando_metas/features/goals/data/goal_mapper.dart';

void main() {
  group('GoalMapper compatibility', () {
    test('fromMap should fallback counters to zero when absent', () {
      final Map<String, dynamic> raw = <String, dynamic>{
        'id': 'goal-1',
        'title': 'Meta antiga',
        'description': null,
        'createdAt': DateTime(2026, 3, 12).toIso8601String(),
        'updatedAt': DateTime(2026, 3, 12).toIso8601String(),
      };

      final goal = GoalMapper.fromMap(raw);

      expect(goal.id, 'goal-1');
      expect(goal.title, 'Meta antiga');
      expect(goal.completedActions, 0);
      expect(goal.totalActions, 0);
    });
  });

  group('ActionMapper compatibility', () {
    test('fromMap should keep goalId empty when key is invalid', () {
      final Map<String, dynamic> raw = <String, dynamic>{
        'id': 'action-1',
        'goal_id': 'goal-legacy',
        'title': 'Acao antiga',
        'isCompleted': 1,
        'createdAt': DateTime(2026, 3, 12).millisecondsSinceEpoch,
        'updatedAt': DateTime(2026, 3, 12).toIso8601String(),
        'order': '2',
      };

      final action = ActionMapper.fromMap(raw);

      expect(action.id, 'action-1');
      expect(action.goalId, isEmpty);
      expect(action.isCompleted, isTrue);
      expect(action.order, 2);
    });
  });
}
