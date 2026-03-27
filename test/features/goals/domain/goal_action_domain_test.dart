@Tags(['smoke'])
import 'package:flutter_test/flutter_test.dart';
import 'package:quebrando_metas/features/goals/domain/action.dart';
import 'package:quebrando_metas/features/goals/domain/focus_session.dart';
import 'package:quebrando_metas/features/goals/domain/goal.dart';

void main() {
  group('Goal', () {
    test('create should initialize with zero progress counters', () {
      final Goal goal = Goal.create(title: '  Get fit  ');

      expect(goal.title, 'Get fit');
      expect(goal.completedActions, 0);
      expect(goal.totalActions, 0);
      expect(goal.totalFocusMinutes, 0);
      expect(goal.progress, 0);
    });

    test('create should normalize blank description to null', () {
      final Goal goal = Goal.create(title: 'Study', description: '   ');

      expect(goal.description, isNull);
    });

    test('copyWith should clear description when requested', () {
      final Goal goal = Goal.create(
        title: 'Study',
        description: 'Initial description',
      );

      final Goal updated = goal.copyWith(clearDescription: true);

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
      expect(action.totalFocusMinutes, 0);
      expect(action.lastFocusStartedAt, isNull);
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

    test('registerFocus should accumulate minutes and set last focus date', () {
      final DateTime now = DateTime(2026, 3, 18, 10, 0);
      final ActionItem action = ActionItem.create(
        goalId: 'goal-1',
        title: 'Read 10 pages',
        order: 0,
        now: now,
      );

      final ActionItem focused = action.registerFocus(
        durationMinutes: 25,
        startedAt: now,
      );

      expect(focused.totalFocusMinutes, 25);
      expect(focused.lastFocusStartedAt, now);
      expect(focused.updatedAt, isNot(action.updatedAt));
    });
  });

  group('FocusSession', () {
    test('start should create a running session', () {
      final DateTime now = DateTime(2026, 3, 18, 9, 0);
      final FocusSession session = FocusSession.start(
        actionId: 'action-1',
        goalId: 'goal-1',
        durationMinutes: 25,
        now: now,
      );

      expect(session.actionId, 'action-1');
      expect(session.goalId, 'goal-1');
      expect(session.durationMinutes, 25);
      expect(session.status, FocusSessionStatus.running);
      expect(session.startedAt, now);
      expect(session.endedAt, isNull);
    });

    test('markCompleted should set endedAt and completed status', () {
      final DateTime startedAt = DateTime(2026, 3, 18, 9, 0);
      final DateTime endedAt = DateTime(2026, 3, 18, 9, 25);
      final FocusSession running = FocusSession.start(
        actionId: 'action-1',
        goalId: 'goal-1',
        durationMinutes: 25,
        now: startedAt,
      );

      final FocusSession completed = running.markCompleted(now: endedAt);

      expect(completed.status, FocusSessionStatus.completed);
      expect(completed.endedAt, endedAt);
    });

    test('accountedMinutes should use elapsed time for canceled sessions', () {
      final DateTime startedAt = DateTime(2026, 3, 18, 9, 0);
      final FocusSession running = FocusSession.start(
        actionId: 'action-1',
        goalId: 'goal-1',
        durationMinutes: 25,
        now: startedAt,
      );
      final FocusSession canceled = running.markCanceled(
        now: DateTime(2026, 3, 18, 9, 4),
      );

      expect(canceled.accountedMinutes(), 4);
      expect(canceled.qualifiesForStreak(), isFalse);
    });

    test(
      'qualifiesForStreak should be true only when accounted minutes >= 5',
      () {
        final DateTime startedAt = DateTime(2026, 3, 18, 9, 0);
        final FocusSession running = FocusSession.start(
          actionId: 'action-1',
          goalId: 'goal-1',
          durationMinutes: 25,
          now: startedAt,
        );
        final FocusSession completed = running.markCompleted(
          now: DateTime(2026, 3, 18, 9, 5),
        );

        expect(completed.accountedMinutes(), 5);
        expect(completed.qualifiesForStreak(), isTrue);
      },
    );
  });
}
