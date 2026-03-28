@Tags(['full'])
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quebrando_metas/app/onboarding_status.dart';
import 'package:quebrando_metas/app/router.dart';
import 'package:quebrando_metas/app/theme/app_theme_settings.dart';
import 'package:quebrando_metas/features/goals/domain/action.dart';
import 'package:quebrando_metas/features/goals/domain/focus_session.dart';
import 'package:quebrando_metas/features/goals/domain/goal.dart';
import 'package:quebrando_metas/features/goals/domain/title_validator.dart';

import '../fakes/fake_in_memory_goals_repository.dart';
import '../support/widget_test_helpers.dart';

void main() {
  testWidgets(
    'Shows correct summary for long-time user with many completed and active goals',
    (WidgetTester tester) async {
      final DateTime now = DateTime(2026, 3, 12);
      final DateTime streakNow = DateTime.now();
      final List<Goal> seededGoals = <Goal>[];
      final List<ActionItem> seededActions = <ActionItem>[];
      final List<FocusSession> seededSessions = <FocusSession>[
        completedSession(
          id: 'summary-streak-1',
          goalId: 'active-0',
          actionId: 'active-a-0-2',
          startedAt: streakNow.subtract(const Duration(days: 1)),
          durationMinutes: 25,
        ),
        completedSession(
          id: 'summary-streak-2',
          goalId: 'active-0',
          actionId: 'active-a-0-2',
          startedAt: streakNow,
          durationMinutes: 15,
        ),
      ];

      for (int i = 0; i < 10; i++) {
        final String goalId = 'done-$i';
        seededGoals.add(
          Goal(
            id: goalId,
            title: 'Meta concluida $i',
            description: null,
            createdAt: now.add(Duration(minutes: i)),
            updatedAt: now.add(Duration(minutes: i)),
            completedActions: 0,
            totalActions: 0,
          ),
        );
        seededActions.addAll([
          ActionItem(
            id: 'done-a-$i-1',
            goalId: goalId,
            title: 'Acao 1',
            isCompleted: true,
            createdAt: now,
            updatedAt: now,
            order: 0,
            completedAt: now,
          ),
          ActionItem(
            id: 'done-a-$i-2',
            goalId: goalId,
            title: 'Acao 2',
            isCompleted: true,
            createdAt: now,
            updatedAt: now,
            order: 1,
            completedAt: now,
          ),
        ]);
      }

      for (int i = 0; i < 5; i++) {
        final String goalId = 'active-$i';
        seededGoals.add(
          Goal(
            id: goalId,
            title: 'Meta ativa $i',
            description: null,
            createdAt: now.add(Duration(hours: i)),
            updatedAt: now.add(Duration(hours: i)),
            completedActions: 0,
            totalActions: 0,
          ),
        );
        seededActions.addAll([
          ActionItem(
            id: 'active-a-$i-1',
            goalId: goalId,
            title: 'Acao 1',
            isCompleted: true,
            createdAt: now,
            updatedAt: now,
            order: 0,
            completedAt: now,
          ),
          ActionItem(
            id: 'active-a-$i-2',
            goalId: goalId,
            title: 'Acao 2',
            isCompleted: false,
            createdAt: now,
            updatedAt: now,
            order: 1,
            completedAt: null,
          ),
        ]);
      }

      await pumpApp(
        tester,
        repository: FakeInMemoryGoalsRepository(
          initialGoals: seededGoals,
          initialActions: seededActions,
          initialFocusSessions: seededSessions,
          initialBestFocusStreak: 3,
        ),
      );
      await tester.pumpAndSettle();
      // single-home layout: no tab switch needed

      await tester.pumpAndSettle();

      expect(find.text('Suas Metas'), findsOneWidget);
      expect(find.text('2 dias seguidos'), findsOneWidget);
      expect(find.text('0.0 horas'), findsOneWidget);
      expect(find.text('Meta ativa 0'), findsOneWidget);
      await tester.drag(
        find.byKey(const Key('goals-list-scroll')),
        const Offset(0, -1800),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Meta concluida'), findsWidgets);
    },
  );

  testWidgets('Scrolls home header together with goals list', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 640);

    final DateTime now = DateTime(2026, 3, 17);
    final List<Goal> seededGoals = List<Goal>.generate(
      12,
      (int index) => Goal(
        id: 'fixed-summary-$index',
        title: 'Meta fixa $index',
        description: null,
        createdAt: now.add(Duration(minutes: index)),
        updatedAt: now.add(Duration(minutes: index)),
        completedActions: 0,
        totalActions: 1,
      ),
    );

    await pumpApp(
      tester,
      repository: FakeInMemoryGoalsRepository(initialGoals: seededGoals),
    );
    await tester.pumpAndSettle();
    expect(find.text('Olá!'), findsOneWidget);
    final ScrollableState scrollableBefore = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    final double listOffsetBefore = scrollableBefore.position.pixels;

    await tester.drag(
      find.byKey(const Key('goals-list-scroll')),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();

    final ScrollableState scrollableAfter = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    final double listOffsetAfter = scrollableAfter.position.pixels;

    expect(find.text('Olá!'), findsNothing);
    expect(listOffsetAfter, greaterThan(listOffsetBefore));
  });

  testWidgets('Centers greeting and summary chips in home header', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);

    await pumpApp(tester, repository: FakeInMemoryGoalsRepository());
    await tester.pumpAndSettle();

    final Finder scroll = find.byKey(const Key('goals-list-scroll'));
    final double contentCenterX =
        tester.getTopLeft(scroll).dx + (tester.getSize(scroll).width / 2);
    final double greetingCenterX = tester.getCenter(find.text('Olá!')).dx;

    final Finder streakChipText = find.text('0 dias seguidos');
    final Finder hoursChipText = find.text('0.0 horas');
    final double chipsLeft = tester.getTopLeft(streakChipText).dx;
    final double chipsRight = tester.getTopRight(hoursChipText).dx;
    final double chipsGroupCenterX = (chipsLeft + chipsRight) / 2;

    expect((greetingCenterX - contentCenterX).abs(), lessThanOrEqualTo(20));
    expect((chipsGroupCenterX - contentCenterX).abs(), lessThanOrEqualTo(20));
  });

  testWidgets('Shows goal description section on actions page', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime(2026, 3, 17);
    final Goal goal = Goal(
      id: 'goal-description-test',
      title: 'Meta com descricao',
      description: 'Descricao de teste',
      createdAt: now,
      updatedAt: now,
      completedActions: 0,
      totalActions: 0,
    );
    await pumpApp(
      tester,
      repository: FakeInMemoryGoalsRepository(initialGoals: <Goal>[goal]),
    );
    await tester.pumpAndSettle();

    AppRouter.router.goNamed(
      'goal-actions',
      pathParameters: {'goalId': goal.id},
    );
    await tester.pumpAndSettle();

    expect(find.text('Descrição da meta'), findsOneWidget);
    expect(find.text('Descricao de teste'), findsOneWidget);
  });

  testWidgets(
    'Goal detail keeps description above progress and uses compact action UI',
    (WidgetTester tester) async {
      final DateTime now = DateTime(2026, 3, 17, 9);
      final Goal goal = Goal(
        id: 'goal-ui-68',
        title: 'Meta UI 6.8',
        description: 'Descricao UI',
        createdAt: now,
        updatedAt: now,
        completedActions: 0,
        totalActions: 1,
      );
      final ActionItem action = ActionItem(
        id: 'goal-ui-68-action',
        goalId: goal.id,
        title: 'Acao UI',
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
        order: 0,
      );

      await pumpApp(
        tester,
        repository: FakeInMemoryGoalsRepository(
          initialGoals: <Goal>[goal],
          initialActions: <ActionItem>[action],
        ),
      );
      await tester.pumpAndSettle();

      AppRouter.router.goNamed(
        'goal-actions',
        pathParameters: {'goalId': goal.id},
      );
      await tester.pumpAndSettle();

      final double descriptionTop = tester
          .getTopLeft(find.text('Descrição da meta'))
          .dy;
      final double progressTop = tester
          .getTopLeft(find.text('Progresso da meta'))
          .dy;
      expect(descriptionTop, lessThan(progressTop));

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
      expect(find.byKey(const Key('start-focus-button')), findsOneWidget);
    },
  );

  testWidgets('Shows total focus time on goal card in Suas Metas', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime(2026, 3, 18, 14);
    final Goal goal = Goal(
      id: 'goal-total-focus-card',
      title: 'Meta total foco',
      description: null,
      createdAt: now,
      updatedAt: now,
      completedActions: 0,
      totalActions: 0,
    );
    final List<ActionItem> actions = <ActionItem>[
      ActionItem(
        id: 'goal-total-focus-card-a1',
        goalId: goal.id,
        title: 'Acao 1',
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
        order: 0,
        totalFocusMinutes: 45,
      ),
      ActionItem(
        id: 'goal-total-focus-card-a2',
        goalId: goal.id,
        title: 'Acao 2',
        isCompleted: true,
        createdAt: now,
        updatedAt: now,
        order: 1,
        totalFocusMinutes: 30,
        completedAt: now,
      ),
    ];

    await pumpApp(
      tester,
      repository: FakeInMemoryGoalsRepository(
        initialGoals: <Goal>[goal],
        initialActions: actions,
      ),
    );
    await tester.pumpAndSettle();
    // single-home layout: no tab switch needed

    await tester.pumpAndSettle();

    expect(find.text('1.3 horas'), findsOneWidget);
  });

  testWidgets('Shows zero accumulated focus time per action', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime(2026, 3, 18, 8);
    final Goal goal = Goal(
      id: 'goal-action-focus-zero',
      title: 'Meta foco zero',
      description: null,
      createdAt: now,
      updatedAt: now,
      completedActions: 0,
      totalActions: 1,
    );
    final ActionItem action = ActionItem(
      id: 'action-focus-zero',
      goalId: goal.id,
      title: 'Acao foco zero',
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
      order: 0,
      totalFocusMinutes: 0,
    );

    await pumpApp(
      tester,
      repository: FakeInMemoryGoalsRepository(
        initialGoals: <Goal>[goal],
        initialActions: <ActionItem>[action],
      ),
    );
    await tester.pumpAndSettle();

    AppRouter.router.goNamed(
      'goal-actions',
      pathParameters: {'goalId': goal.id},
    );
    await tester.pumpAndSettle();

    expect(find.text('Tempo de foco: 0min'), findsOneWidget);
  });

  testWidgets('Shows goal-specific streak on goal detail metrics card', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime.now();
    final Goal firstGoal = Goal(
      id: 'goal-streak-scope-a',
      title: 'Meta streak A',
      description: null,
      createdAt: now.subtract(const Duration(days: 10)),
      updatedAt: now.subtract(const Duration(days: 10)),
      completedActions: 0,
      totalActions: 1,
    );
    final Goal secondGoal = Goal(
      id: 'goal-streak-scope-b',
      title: 'Meta streak B',
      description: null,
      createdAt: now.subtract(const Duration(days: 9)),
      updatedAt: now.subtract(const Duration(days: 9)),
      completedActions: 0,
      totalActions: 1,
    );
    final List<ActionItem> actions = <ActionItem>[
      ActionItem(
        id: 'goal-streak-scope-a-action',
        goalId: firstGoal.id,
        title: 'Acao A',
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
        order: 0,
      ),
      ActionItem(
        id: 'goal-streak-scope-b-action',
        goalId: secondGoal.id,
        title: 'Acao B',
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
        order: 0,
      ),
    ];
    final List<FocusSession> sessions = <FocusSession>[
      completedSession(
        id: 'scope-a-today',
        goalId: firstGoal.id,
        actionId: 'goal-streak-scope-a-action',
        startedAt: now.subtract(const Duration(hours: 1)),
        durationMinutes: 25,
      ),
      completedSession(
        id: 'scope-a-yesterday',
        goalId: firstGoal.id,
        actionId: 'goal-streak-scope-a-action',
        startedAt: now.subtract(const Duration(days: 1, hours: 1)),
        durationMinutes: 25,
      ),
      completedSession(
        id: 'scope-b-today',
        goalId: secondGoal.id,
        actionId: 'goal-streak-scope-b-action',
        startedAt: now.subtract(const Duration(hours: 2)),
        durationMinutes: 25,
      ),
      completedSession(
        id: 'scope-b-day-1',
        goalId: secondGoal.id,
        actionId: 'goal-streak-scope-b-action',
        startedAt: now.subtract(const Duration(days: 1, hours: 2)),
        durationMinutes: 25,
      ),
      completedSession(
        id: 'scope-b-day-2',
        goalId: secondGoal.id,
        actionId: 'goal-streak-scope-b-action',
        startedAt: now.subtract(const Duration(days: 2, hours: 2)),
        durationMinutes: 25,
      ),
      completedSession(
        id: 'scope-b-day-3',
        goalId: secondGoal.id,
        actionId: 'goal-streak-scope-b-action',
        startedAt: now.subtract(const Duration(days: 3, hours: 2)),
        durationMinutes: 25,
      ),
    ];

    await pumpApp(
      tester,
      repository: FakeInMemoryGoalsRepository(
        initialGoals: <Goal>[firstGoal, secondGoal],
        initialActions: actions,
        initialFocusSessions: sessions,
      ),
    );
    await tester.pumpAndSettle();

    AppRouter.router.goNamed(
      'goal-actions',
      pathParameters: {'goalId': firstGoal.id},
    );
    await tester.pumpAndSettle();

    expect(find.text('Sequência'), findsOneWidget);
    expect(find.text('2 dias'), findsOneWidget);
    expect(find.text('4 dias'), findsNothing);
  });

}


