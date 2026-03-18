import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quebrando_metas/features/goals/domain/action.dart';
import 'package:quebrando_metas/features/goals/domain/focus_session.dart';
import 'package:quebrando_metas/features/goals/domain/goal.dart';
import 'package:quebrando_metas/features/goals/presentation/goal_actions_controller.dart';
import 'package:quebrando_metas/features/goals/presentation/goals_controller.dart';
import '../../../fakes/fake_in_memory_goals_repository.dart';

void main() {
  group('Focus streak persistence', () {
    test('persists best streak while focus starts happen on consecutive days', () async {
      final DateTime base = DateTime(2026, 3, 10, 8);
      final Goal goal = Goal(
        id: 'goal-streak',
        title: 'Meta streak',
        description: null,
        createdAt: base,
        updatedAt: base,
        completedActions: 0,
        totalActions: 1,
      );
      final ActionItem action = ActionItem(
        id: 'action-streak',
        goalId: goal.id,
        title: 'Acao streak',
        isCompleted: false,
        createdAt: base,
        updatedAt: base,
        order: 0,
      );
      final FakeInMemoryGoalsRepository repository = FakeInMemoryGoalsRepository(
        initialGoals: <Goal>[goal],
        initialActions: <ActionItem>[action],
      );

      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          goalsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(goalActionsControllerProvider(goal.id).future);
      final GoalActionsController controller = container.read(
        goalActionsControllerProvider(goal.id).notifier,
      );

      await controller.startFocusSession(
        goalId: goal.id,
        actionId: action.id,
        durationMinutes: 15,
        now: DateTime(2026, 3, 10, 9),
      );
      expect(await repository.getBestFocusStreak(), 1);

      await controller.startFocusSession(
        goalId: goal.id,
        actionId: action.id,
        durationMinutes: 15,
        now: DateTime(2026, 3, 11, 9),
      );
      expect(await repository.getBestFocusStreak(), 2);

      await controller.startFocusSession(
        goalId: goal.id,
        actionId: action.id,
        durationMinutes: 15,
        now: DateTime(2026, 3, 13, 9),
      );
      expect(await repository.getBestFocusStreak(), 2);
    });

    test('migrates best streak from sessions when persisted value is missing', () async {
      final DateTime base = DateTime(2026, 3, 10, 8);
      final Goal goal = Goal(
        id: 'goal-streak-migration',
        title: 'Meta migracao',
        description: null,
        createdAt: base,
        updatedAt: base,
        completedActions: 0,
        totalActions: 1,
      );
      final ActionItem action = ActionItem(
        id: 'action-streak-migration',
        goalId: goal.id,
        title: 'Acao migracao',
        isCompleted: false,
        createdAt: base,
        updatedAt: base,
        order: 0,
      );
      final List<FocusSession> sessions = <FocusSession>[
        _sessionAt(goal.id, action.id, DateTime(2026, 3, 9, 9)),
        _sessionAt(goal.id, action.id, DateTime(2026, 3, 10, 9)),
        _sessionAt(goal.id, action.id, DateTime(2026, 3, 11, 9)),
      ];
      final FakeInMemoryGoalsRepository repository = FakeInMemoryGoalsRepository(
        initialGoals: <Goal>[goal],
        initialActions: <ActionItem>[action],
        initialFocusSessions: sessions,
        initialBestFocusStreak: 0,
      );

      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          goalsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final int best = await container.read(bestFocusStreakProvider.future);

      expect(best, 3);
      expect(await repository.getBestFocusStreak(), 3);
    });

    test('does not increase best streak with multiple starts on same day', () async {
      final DateTime base = DateTime(2026, 3, 20, 8);
      final Goal goal = Goal(
        id: 'goal-streak-same-day',
        title: 'Meta mesmo dia',
        description: null,
        createdAt: base,
        updatedAt: base,
        completedActions: 0,
        totalActions: 1,
      );
      final ActionItem action = ActionItem(
        id: 'action-streak-same-day',
        goalId: goal.id,
        title: 'Acao mesmo dia',
        isCompleted: false,
        createdAt: base,
        updatedAt: base,
        order: 0,
      );
      final FakeInMemoryGoalsRepository repository = FakeInMemoryGoalsRepository(
        initialGoals: <Goal>[goal],
        initialActions: <ActionItem>[action],
      );

      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          goalsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(goalActionsControllerProvider(goal.id).future);
      final GoalActionsController controller = container.read(
        goalActionsControllerProvider(goal.id).notifier,
      );

      await controller.startFocusSession(
        goalId: goal.id,
        actionId: action.id,
        durationMinutes: 15,
        now: DateTime(2026, 3, 20, 9, 0),
      );
      await controller.startFocusSession(
        goalId: goal.id,
        actionId: action.id,
        durationMinutes: 25,
        now: DateTime(2026, 3, 20, 18, 0),
      );

      expect(await repository.getBestFocusStreak(), 1);
    });

    test('keeps persisted best streak when historical sessions are lower', () async {
      final DateTime base = DateTime(2026, 3, 10, 8);
      final Goal goal = Goal(
        id: 'goal-streak-high-best',
        title: 'Meta best alto',
        description: null,
        createdAt: base,
        updatedAt: base,
        completedActions: 0,
        totalActions: 1,
      );
      final ActionItem action = ActionItem(
        id: 'action-streak-high-best',
        goalId: goal.id,
        title: 'Acao best alto',
        isCompleted: false,
        createdAt: base,
        updatedAt: base,
        order: 0,
      );
      final List<FocusSession> sessions = <FocusSession>[
        _sessionAt(goal.id, action.id, DateTime(2026, 3, 9, 9)),
        _sessionAt(goal.id, action.id, DateTime(2026, 3, 10, 9)),
      ];
      final FakeInMemoryGoalsRepository repository = FakeInMemoryGoalsRepository(
        initialGoals: <Goal>[goal],
        initialActions: <ActionItem>[action],
        initialFocusSessions: sessions,
        initialBestFocusStreak: 5,
      );

      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          goalsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final int best = await container.read(bestFocusStreakProvider.future);

      expect(best, 5);
      expect(await repository.getBestFocusStreak(), 5);
    });

    test('focus streak provider returns zero after a one-day gap', () async {
      final DateTime now = DateTime.now();
      final DateTime base = now.subtract(const Duration(days: 4));
      final Goal goal = Goal(
        id: 'goal-streak-gap',
        title: 'Meta gap',
        description: null,
        createdAt: base,
        updatedAt: base,
        completedActions: 0,
        totalActions: 1,
      );
      final ActionItem action = ActionItem(
        id: 'action-streak-gap',
        goalId: goal.id,
        title: 'Acao gap',
        isCompleted: false,
        createdAt: base,
        updatedAt: base,
        order: 0,
      );
      final List<FocusSession> sessions = <FocusSession>[
        _sessionAt(goal.id, action.id, now.subtract(const Duration(days: 2))),
        _sessionAt(goal.id, action.id, now.subtract(const Duration(days: 3))),
      ];
      final FakeInMemoryGoalsRepository repository = FakeInMemoryGoalsRepository(
        initialGoals: <Goal>[goal],
        initialActions: <ActionItem>[action],
        initialFocusSessions: sessions,
      );

      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          goalsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final int streak = await container.read(focusStreakProvider.future);

      expect(streak, 0);
    });
  });
}

FocusSession _sessionAt(String goalId, String actionId, DateTime startedAt) {
  final DateTime endedAt = startedAt.add(const Duration(minutes: 15));
  return FocusSession(
    id: 'session-${startedAt.microsecondsSinceEpoch}',
    actionId: actionId,
    goalId: goalId,
    startedAt: startedAt,
    endedAt: endedAt,
    durationMinutes: 15,
    status: FocusSessionStatus.completed,
    createdAt: startedAt,
    updatedAt: endedAt,
  );
}
