@Tags(['regression'])
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quebrando_metas/features/goals/domain/action.dart';
import 'package:quebrando_metas/features/goals/domain/action_day_confirmation.dart';
import 'package:quebrando_metas/features/goals/domain/action_weekly_status_calculator.dart';
import 'package:quebrando_metas/features/goals/domain/focus_session.dart';
import 'package:quebrando_metas/features/goals/domain/goal.dart';
import 'package:quebrando_metas/features/goals/domain/goal_monthly_history.dart';
import 'package:quebrando_metas/features/goals/presentation/goal_actions_controller.dart';
import 'package:quebrando_metas/features/goals/presentation/goals_controller.dart';
import '../../../fakes/fake_in_memory_goals_repository.dart';

void main() {
  group('Focus streak persistence', () {
    test(
      'persists best streak only when sessions with >= 5 minutes are recorded',
      () async {
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
        final FakeInMemoryGoalsRepository repository =
            FakeInMemoryGoalsRepository(
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

        final FocusSession day1 = await controller.startFocusSession(
          goalId: goal.id,
          actionId: action.id,
          durationMinutes: 15,
          now: DateTime(2026, 3, 10, 9),
        );
        await controller.completeFocusSession(
          day1,
          elapsedMinutes: 5,
          now: DateTime(2026, 3, 10, 9, 5),
        );
        expect(await repository.getBestFocusStreak(), 1);

        final FocusSession day2 = await controller.startFocusSession(
          goalId: goal.id,
          actionId: action.id,
          durationMinutes: 15,
          now: DateTime(2026, 3, 11, 9),
        );
        await controller.completeFocusSession(
          day2,
          elapsedMinutes: 5,
          now: DateTime(2026, 3, 11, 9, 5),
        );
        expect(await repository.getBestFocusStreak(), 2);

        final FocusSession day3 = await controller.startFocusSession(
          goalId: goal.id,
          actionId: action.id,
          durationMinutes: 15,
          now: DateTime(2026, 3, 13, 9),
        );
        await controller.completeFocusSession(
          day3,
          elapsedMinutes: 5,
          now: DateTime(2026, 3, 13, 9, 5),
        );
        expect(await repository.getBestFocusStreak(), 2);
      },
    );

    test(
      'migrates best streak from sessions when persisted value is missing',
      () async {
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
        final FakeInMemoryGoalsRepository repository =
            FakeInMemoryGoalsRepository(
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
      },
    );

    test(
      'does not increase best streak with multiple eligible sessions on same day',
      () async {
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
        final FakeInMemoryGoalsRepository repository =
            FakeInMemoryGoalsRepository(
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

        final FocusSession first = await controller.startFocusSession(
          goalId: goal.id,
          actionId: action.id,
          durationMinutes: 15,
          now: DateTime(2026, 3, 20, 9, 0),
        );
        await controller.completeFocusSession(
          first,
          elapsedMinutes: 5,
          now: DateTime(2026, 3, 20, 9, 5),
        );

        final FocusSession second = await controller.startFocusSession(
          goalId: goal.id,
          actionId: action.id,
          durationMinutes: 25,
          now: DateTime(2026, 3, 20, 18, 0),
        );
        await controller.completeFocusSession(
          second,
          elapsedMinutes: 5,
          now: DateTime(2026, 3, 20, 18, 5),
        );

        expect(await repository.getBestFocusStreak(), 1);
      },
    );

    test(
      'keeps persisted best streak when historical sessions are lower',
      () async {
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
        final FakeInMemoryGoalsRepository repository =
            FakeInMemoryGoalsRepository(
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
      },
    );

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
      final FakeInMemoryGoalsRepository repository =
          FakeInMemoryGoalsRepository(
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

    test(
      'does not increase streak when canceled before five minutes',
      () async {
        final DateTime base = DateTime(2026, 3, 22, 8);
        final Goal goal = Goal(
          id: 'goal-streak-under-five',
          title: 'Meta abaixo de cinco',
          description: null,
          createdAt: base,
          updatedAt: base,
          completedActions: 0,
          totalActions: 1,
        );
        final ActionItem action = ActionItem(
          id: 'action-streak-under-five',
          goalId: goal.id,
          title: 'Acao abaixo de cinco',
          isCompleted: false,
          createdAt: base,
          updatedAt: base,
          order: 0,
        );
        final FakeInMemoryGoalsRepository repository =
            FakeInMemoryGoalsRepository(
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

        final FocusSession session = await controller.startFocusSession(
          goalId: goal.id,
          actionId: action.id,
          durationMinutes: 15,
          now: DateTime(2026, 3, 22, 9, 0),
        );
        await controller.cancelFocusSession(
          session,
          elapsedMinutes: 4,
          now: DateTime(2026, 3, 22, 9, 4),
        );

        final int current = await container.read(focusStreakProvider.future);
        final int best = await container.read(bestFocusStreakProvider.future);

        expect(current, 0);
        expect(best, 0);
        expect(await repository.getBestFocusStreak(), 0);
      },
    );
  });

  test('builds monthly history in checklist mode', () async {
    final DateTime now = DateTime(2026, 3, 15, 10, 0);
    final Goal goal = Goal(
      id: 'goal-monthly-checklist',
      title: 'Meta mensal checklist',
      description: null,
      createdAt: now,
      updatedAt: now,
      completedActions: 0,
      totalActions: 2,
    );
    final List<ActionItem> actions = <ActionItem>[
      ActionItem(
        id: 'action-monthly-checklist-1',
        goalId: goal.id,
        title: 'Acao 1',
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
        order: 0,
      ),
      ActionItem(
        id: 'action-monthly-checklist-2',
        goalId: goal.id,
        title: 'Acao 2',
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
        order: 1,
      ),
    ];
    final List<ActionDayConfirmation> confirmations = <ActionDayConfirmation>[
      ActionDayConfirmation.create(
        goalId: goal.id,
        actionId: 'action-monthly-checklist-1',
        now: DateTime(2026, 3, 10, 8, 0),
      ),
    ];

    final FakeInMemoryGoalsRepository repository = FakeInMemoryGoalsRepository(
      initialGoals: <Goal>[goal],
      initialActions: actions,
      initialActionDayConfirmations: confirmations,
    );
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        goalsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final GoalMonthlyHistory snapshot = await container.read(
      goalMonthlyHistoryProvider(
        GoalMonthlyHistoryArgs(
          goalId: 'goal-monthly-checklist',
          year: 2026,
          month: 3,
          focusModeEnabled: false,
          referenceDate: now,
        ),
      ).future,
    );

    expect(snapshot.days, hasLength(31));
    expect(snapshot.rows, hasLength(2));
    expect(snapshot.rows[0].statuses[9], WeeklyActionDayStatus.done);
    expect(snapshot.rows[1].statuses[9], WeeklyActionDayStatus.missed);
  });

  test(
    'builds monthly history in focus mode with eligible sessions only',
    () async {
      final DateTime now = DateTime(2026, 3, 15, 10, 0);
      final Goal goal = Goal(
        id: 'goal-monthly-focus',
        title: 'Meta mensal foco',
        description: null,
        createdAt: now,
        updatedAt: now,
        completedActions: 0,
        totalActions: 2,
      );
      final List<ActionItem> actions = <ActionItem>[
        ActionItem(
          id: 'action-monthly-focus-1',
          goalId: goal.id,
          title: 'Acao foco 1',
          isCompleted: false,
          createdAt: now,
          updatedAt: now,
          order: 0,
        ),
        ActionItem(
          id: 'action-monthly-focus-2',
          goalId: goal.id,
          title: 'Acao foco 2',
          isCompleted: false,
          createdAt: now,
          updatedAt: now,
          order: 1,
        ),
      ];
      final List<FocusSession> sessions = <FocusSession>[
        FocusSession(
          id: 'session-monthly-focus-1',
          goalId: goal.id,
          actionId: 'action-monthly-focus-1',
          startedAt: DateTime(2026, 3, 5, 7, 0),
          endedAt: DateTime(2026, 3, 5, 7, 6),
          durationMinutes: 25,
          status: FocusSessionStatus.completed,
          createdAt: DateTime(2026, 3, 5, 7, 0),
          updatedAt: DateTime(2026, 3, 5, 7, 6),
        ),
        FocusSession(
          id: 'session-monthly-focus-2',
          goalId: goal.id,
          actionId: 'action-monthly-focus-2',
          startedAt: DateTime(2026, 3, 6, 7, 0),
          endedAt: DateTime(2026, 3, 6, 7, 4),
          durationMinutes: 25,
          status: FocusSessionStatus.completed,
          createdAt: DateTime(2026, 3, 6, 7, 0),
          updatedAt: DateTime(2026, 3, 6, 7, 4),
        ),
      ];
      final List<ActionDayConfirmation> confirmations = <ActionDayConfirmation>[
        ActionDayConfirmation.create(
          goalId: goal.id,
          actionId: 'action-monthly-focus-2',
          now: DateTime(2026, 3, 6, 10, 0),
        ),
      ];

      final FakeInMemoryGoalsRepository repository =
          FakeInMemoryGoalsRepository(
            initialGoals: <Goal>[goal],
            initialActions: actions,
            initialFocusSessions: sessions,
            initialActionDayConfirmations: confirmations,
          );
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          goalsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final GoalMonthlyHistory snapshot = await container.read(
        goalMonthlyHistoryProvider(
          GoalMonthlyHistoryArgs(
            goalId: 'goal-monthly-focus',
            year: 2026,
            month: 3,
            focusModeEnabled: true,
            referenceDate: now,
          ),
        ).future,
      );

      expect(snapshot.days, hasLength(31));
      expect(snapshot.rows, hasLength(2));
      expect(snapshot.rows[0].statuses[4], WeeklyActionDayStatus.done);
      expect(snapshot.rows[1].statuses[5], WeeklyActionDayStatus.done);
    },
  );

  test(
    'completeFocusSession >=5 marks action done and reflects in month board',
    () async {
      final DateTime now = DateTime.now();
      final Goal goal = Goal(
        id: 'goal-monthly-focus-complete',
        title: 'Meta mensal foco concluido',
        description: null,
        createdAt: now,
        updatedAt: now,
        completedActions: 0,
        totalActions: 1,
      );
      final ActionItem action = ActionItem(
        id: 'action-monthly-focus-complete-1',
        goalId: goal.id,
        title: 'Acao foco concluida',
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
        order: 0,
      );

      final FakeInMemoryGoalsRepository repository =
          FakeInMemoryGoalsRepository(
            initialGoals: <Goal>[goal],
            initialActions: <ActionItem>[action],
          );
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          goalsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final GoalActionsController controller = container.read(
        goalActionsControllerProvider(goal.id).notifier,
      );
      await container.read(goalActionsControllerProvider(goal.id).future);

      final FocusSession session = await controller.startFocusSession(
        goalId: goal.id,
        actionId: action.id,
        durationMinutes: 15,
        now: now,
      );

      await controller.completeFocusSession(
        session,
        elapsedMinutes: 5,
        sessionDurationMinutes: 15,
        now: now.add(const Duration(minutes: 5)),
      );

      final List<ActionItem> actions = await repository.listActions(goal.id);
      expect(actions, hasLength(1));
      expect(actions.first.isCompleted, isTrue);
      expect(actions.first.completedAt, isNotNull);
      expect(actions.first.totalFocusMinutes, 5);

      final List<ActionDayConfirmation> confirmations = await repository
          .listActionDayConfirmations(goalId: goal.id, actionId: action.id);
      expect(confirmations, hasLength(1));

      final GoalMonthlyHistory monthSnapshot = await container.read(
        goalMonthlyHistoryProvider(
          GoalMonthlyHistoryArgs(
            goalId: goal.id,
            year: now.year,
            month: now.month,
            focusModeEnabled: true,
            referenceDate: now,
          ),
        ).future,
      );
      expect(monthSnapshot.rows, hasLength(1));
      expect(
        monthSnapshot.rows.first.statuses[now.day - 1],
        WeeklyActionDayStatus.done,
      );
    },
  );
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
