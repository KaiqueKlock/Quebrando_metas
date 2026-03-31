@Tags(['smoke'])
import 'package:flutter_test/flutter_test.dart';
import 'package:quebrando_metas/features/goals/data/action_day_confirmation_mapper.dart';
import 'package:quebrando_metas/features/goals/data/action_mapper.dart';
import 'package:quebrando_metas/features/goals/data/focus_session_mapper.dart';
import 'package:quebrando_metas/features/goals/data/goal_mapper.dart';
import 'package:quebrando_metas/features/goals/domain/action_day_confirmation.dart';
import 'package:quebrando_metas/features/goals/domain/focus_session.dart';

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
      expect(goal.totalFocusMinutes, 0);
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
      expect(action.totalFocusMinutes, 0);
      expect(action.lastFocusStartedAt, isNull);
    });

    test('fromMap should parse legacy lastFocusAt when present', () {
      final DateTime lastFocusAt = DateTime(2026, 3, 18, 9, 0);
      final Map<String, dynamic> raw = <String, dynamic>{
        'id': 'action-2',
        'goalId': 'goal-1',
        'title': 'Acao com foco legado',
        'isCompleted': false,
        'createdAt': DateTime(2026, 3, 12).toIso8601String(),
        'updatedAt': DateTime(2026, 3, 12).toIso8601String(),
        'order': 0,
        'totalFocusMinutes': 45,
        'lastFocusAt': lastFocusAt.toIso8601String(),
      };

      final action = ActionMapper.fromMap(raw);

      expect(action.totalFocusMinutes, 45);
      expect(action.lastFocusStartedAt, lastFocusAt);
    });
  });

  group('FocusSessionMapper compatibility', () {
    test('fromMap should fallback unknown status to running', () {
      final Map<String, dynamic> raw = <String, dynamic>{
        'id': 'session-1',
        'actionId': 'action-1',
        'goalId': 'goal-1',
        'startedAt': DateTime(2026, 3, 18, 9, 0).toIso8601String(),
        'durationMinutes': 25,
        'status': 'legacy-status',
        'createdAt': DateTime(2026, 3, 18, 9, 0).toIso8601String(),
        'updatedAt': DateTime(2026, 3, 18, 9, 0).toIso8601String(),
      };

      final FocusSession session = FocusSessionMapper.fromMap(raw);

      expect(session.id, 'session-1');
      expect(session.status, FocusSessionStatus.running);
      expect(session.durationMinutes, 25);
    });
  });

  group('ActionDayConfirmationMapper compatibility', () {
    test('fromMap should fallback date fields from legacy keys', () {
      final DateTime legacyTimestamp = DateTime(2026, 3, 30, 14, 20);
      final Map<String, dynamic> raw = <String, dynamic>{
        'id': 'confirm-1',
        'goalId': 'goal-1',
        'actionId': 'action-1',
        'timestamp': legacyTimestamp.toIso8601String(),
      };

      final ActionDayConfirmation confirmation =
          ActionDayConfirmationMapper.fromMap(raw);

      expect(confirmation.id, 'confirm-1');
      expect(confirmation.goalId, 'goal-1');
      expect(confirmation.actionId, 'action-1');
      expect(confirmation.confirmedAt, legacyTimestamp);
      expect(confirmation.createdAt, legacyTimestamp);
      expect(confirmation.updatedAt, legacyTimestamp);
    });
  });
}
