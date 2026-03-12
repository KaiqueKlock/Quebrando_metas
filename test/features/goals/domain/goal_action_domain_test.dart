import 'package:flutter_test/flutter_test.dart';
import 'package:quebrando_metas/features/goals/domain/action.dart';
import 'package:quebrando_metas/features/goals/domain/goal.dart';

void main() {
  group('Goal', () {
    test('create should initialize with zero progress counters', () {
      final Goal goal = Goal.create(title: '  Get fit  ');

      expect(goal.title, 'Get fit');
      expect(goal.completedActions, 0);
      expect(goal.totalActions, 0);
      expect(goal.progress, 0);
    });

    test('create should normalize blank description to null', () {
      final Goal goal = Goal.create(
        title: 'Study',
        description: '   ',
      );

      expect(goal.description, isNull);
    });

    test('copyWith should clear description when requested', () {
      final Goal goal = Goal.create(
        title: 'Study',
        description: 'Initial description',
      );

      final Goal updated = goal.copyWith(
        clearDescription: true,
      );

      expect(updated.description, isNull);
    });
  });

  group('ActionItem', () {
    test('create should start as pending', () {
      final ActionItem action = ActionItem.create(
        goalId: 'goal-1',
        title: 'Read 10 pages',
        order: 0,
      );

      expect(action.isCompleted, isFalse);
      expect(action.completedAt, isNull);
      expect(action.order, 0);
    });

    test('markCompleted should set completed metadata', () {
      final ActionItem action = ActionItem.create(
        goalId: 'goal-1',
        title: 'Read 10 pages',
        order: 0,
      );

      final ActionItem completed = action.markCompleted();

      expect(completed.isCompleted, isTrue);
      expect(completed.completedAt, isNotNull);
    });

    test('markPending should clear completed metadata', () {
      final ActionItem action = ActionItem.create(
        goalId: 'goal-1',
        title: 'Read 10 pages',
        order: 0,
      ).markCompleted();

      final ActionItem pending = action.markPending();

      expect(pending.isCompleted, isFalse);
      expect(pending.completedAt, isNull);
    });
  });
}
