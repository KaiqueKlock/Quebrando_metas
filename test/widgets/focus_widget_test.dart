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
  testWidgets('Starts focus flow from selected action', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime(2026, 3, 18, 9, 0);
    final Goal goal = Goal(
      id: 'goal-focus-test',
      title: 'Meta com foco',
      description: null,
      createdAt: now,
      updatedAt: now,
      completedActions: 0,
      totalActions: 1,
    );
    final ActionItem action = ActionItem(
      id: 'action-focus-test',
      goalId: goal.id,
      title: 'Acao para foco',
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
      order: 0,
      completedAt: null,
    );
    final FakeInMemoryGoalsRepository repository = FakeInMemoryGoalsRepository(
      initialGoals: <Goal>[goal],
      initialActions: <ActionItem>[action],
    );

    await pumpApp(tester, repository: repository);
    await tester.pumpAndSettle();

    AppRouter.router.goNamed(
      'goal-actions',
      pathParameters: {'goalId': goal.id},
    );
    await tester.pumpAndSettle();

    FilledButton startFocusButton = tester.widget<FilledButton>(
      find.byKey(const Key('start-focus-button')),
    );
    expect(startFocusButton.onPressed, isNull);

    await tester.tap(
      find.byKey(const ValueKey<String>('select-focus-action-focus-test')),
    );
    await tester.pumpAndSettle();

    startFocusButton = tester.widget<FilledButton>(
      find.byKey(const Key('start-focus-button')),
    );
    expect(startFocusButton.onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('start-focus-button')));
    await tester.pumpAndSettle();
    expect(find.text('Escolha a duração do foco'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('focus-duration-15')));
    await tester.pumpAndSettle();

    expect(find.text('Modo Foco'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Acao para foco'), findsOneWidget);
    expect(find.text('Meta com foco'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            RegExp(r'^\d{2}:\d{2}$').hasMatch(widget.data ?? ''),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('Acao para foco'), findsOneWidget);

    final List<FocusSession> sessions = await repository.listFocusSessions(
      goalId: goal.id,
      actionId: action.id,
    );
    expect(sessions, hasLength(1));
    expect(sessions.first.durationMinutes, 15);
    expect(sessions.first.status, FocusSessionStatus.canceled);
    final List<ActionItem> actions = await repository.listActions(goal.id);
    expect(actions, hasLength(1));
    expect(actions.first.totalFocusMinutes, 0);
    expect(actions.first.isCompleted, isFalse);
  });

  testWidgets('Enables Concluir agora only after five focus minutes', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime(2026, 3, 18, 9, 10);
    final Goal goal = Goal(
      id: 'goal-focus-complete-threshold',
      title: 'Meta limite concluir foco',
      description: null,
      createdAt: now,
      updatedAt: now,
      completedActions: 0,
      totalActions: 1,
    );
    final ActionItem action = ActionItem(
      id: 'action-focus-complete-threshold',
      goalId: goal.id,
      title: 'Acao limite concluir foco',
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
      order: 0,
      completedAt: null,
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

    await selectFocusForAction(tester, action.id);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('start-focus-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('focus-duration-15')));
    await tester.pumpAndSettle();

    FilledButton concludeButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Concluir agora'),
    );
    expect(concludeButton.onPressed, isNull);

    await tester.pump(const Duration(minutes: 4));
    concludeButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Concluir agora'),
    );
    expect(concludeButton.onPressed, isNull);

    await tester.pump(const Duration(minutes: 1));
    concludeButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Concluir agora'),
    );
    expect(concludeButton.onPressed, isNotNull);
  });

  testWidgets(
    'Completes focus and accumulates time without auto-completing action',
    (WidgetTester tester) async {
      final DateTime now = DateTime(2026, 3, 18, 9, 30);
      final Goal goal = Goal(
        id: 'goal-focus-completed-test',
        title: 'Meta foco completo',
        description: null,
        createdAt: now,
        updatedAt: now,
        completedActions: 0,
        totalActions: 1,
      );
      final ActionItem action = ActionItem(
        id: 'action-focus-completed-test',
        goalId: goal.id,
        title: 'Acao foco completo',
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
        order: 0,
        completedAt: null,
      );
      final FakeInMemoryGoalsRepository repository =
          FakeInMemoryGoalsRepository(
            initialGoals: <Goal>[goal],
            initialActions: <ActionItem>[action],
          );

      await pumpApp(tester, repository: repository);
      await tester.pumpAndSettle();

      AppRouter.router.goNamed(
        'goal-actions',
        pathParameters: {'goalId': goal.id},
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          const ValueKey<String>('select-focus-action-focus-completed-test'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('start-focus-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('focus-duration-60')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(minutes: 5));

      await tester.tap(find.text('Concluir agora'));
      await tester.pumpAndSettle();
      expect(find.text('Tempo investido: 5 min'), findsOneWidget);

      await tester.tap(find.text('Fechar'));
      await tester.pumpAndSettle();

      final List<FocusSession> sessions = await repository.listFocusSessions(
        goalId: goal.id,
        actionId: action.id,
      );
      expect(sessions, hasLength(1));
      expect(sessions.first.status, FocusSessionStatus.completed);
      expect(sessions.first.durationMinutes, 60);

      final List<ActionItem> actions = await repository.listActions(goal.id);
      expect(actions, hasLength(1));
      expect(actions.first.totalFocusMinutes, 5);
      expect(actions.first.isCompleted, isFalse);

      final List<Goal> goals = await repository.listGoals();
      expect(goals, hasLength(1));
      expect(goals.first.totalFocusMinutes, 5);

      expect(find.text('Tempo de foco: 5min'), findsOneWidget);
    },
  );

  testWidgets(
    'Accumulates minutes beyond original duration after adding five minutes and completing',
    (WidgetTester tester) async {
      final DateTime now = DateTime(2026, 3, 18, 9, 35);
      final Goal goal = Goal(
        id: 'goal-focus-completed-extended',
        title: 'Meta foco completo estendido',
        description: null,
        createdAt: now,
        updatedAt: now,
        completedActions: 0,
        totalActions: 1,
      );
      final ActionItem action = ActionItem(
        id: 'action-focus-completed-extended',
        goalId: goal.id,
        title: 'Acao foco completa estendida',
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
        order: 0,
        completedAt: null,
      );
      final FakeInMemoryGoalsRepository repository =
          FakeInMemoryGoalsRepository(
            initialGoals: <Goal>[goal],
            initialActions: <ActionItem>[action],
          );

      await pumpApp(tester, repository: repository);
      await tester.pumpAndSettle();

      AppRouter.router.goNamed(
        'goal-actions',
        pathParameters: {'goalId': goal.id},
      );
      await tester.pumpAndSettle();

      await selectFocusForAction(tester, action.id);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('start-focus-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('focus-duration-15')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('focus-add-five-minutes-button')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(minutes: 16));

      await tester.tap(find.text('Concluir agora'));
      await tester.pumpAndSettle();

      expect(find.text('Tempo investido: 16 min'), findsOneWidget);

      await tester.tap(find.text('Fechar'));
      await tester.pumpAndSettle();

      final List<ActionItem> actions = await repository.listActions(goal.id);
      expect(actions, hasLength(1));
      expect(actions.first.totalFocusMinutes, 16);

      final List<Goal> goals = await repository.listGoals();
      expect(goals, hasLength(1));
      expect(goals.first.totalFocusMinutes, 16);
    },
  );

  testWidgets('Does not overflow pixels on focus page in small screen', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(320, 500);

    final DateTime now = DateTime(2026, 3, 18, 11, 0);
    final Goal goal = Goal(
      id: 'goal-focus-overflow',
      title: 'Meta foco pequena',
      description: null,
      createdAt: now,
      updatedAt: now,
      completedActions: 0,
      totalActions: 1,
    );
    final ActionItem action = ActionItem(
      id: 'action-focus-overflow',
      goalId: goal.id,
      title: 'Acao foco pequena',
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
      order: 0,
      completedAt: null,
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

    await selectFocusForAction(tester, action.id);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('start-focus-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('focus-duration-60')));
    await tester.pumpAndSettle();

    expect(find.text('Modo Foco'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Completes focus automatically when timer reaches zero', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime(2026, 3, 18, 12, 0);
    final Goal goal = Goal(
      id: 'goal-focus-auto-zero',
      title: 'Meta foco auto zero',
      description: null,
      createdAt: now,
      updatedAt: now,
      completedActions: 0,
      totalActions: 1,
    );
    final ActionItem action = ActionItem(
      id: 'action-focus-auto-zero',
      goalId: goal.id,
      title: 'Acao foco auto zero',
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
      order: 0,
      completedAt: null,
    );
    final FakeInMemoryGoalsRepository repository = FakeInMemoryGoalsRepository(
      initialGoals: <Goal>[goal],
      initialActions: <ActionItem>[action],
    );

    await pumpApp(tester, repository: repository);
    await tester.pumpAndSettle();

    AppRouter.router.goNamed(
      'goal-actions',
      pathParameters: {'goalId': goal.id},
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('select-focus-action-focus-auto-zero')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('start-focus-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('focus-duration-15')));
    await tester.pumpAndSettle();

    await tester.pump(const Duration(minutes: 15));
    await tester.pump();

    expect(find.text('Sessão concluída'), findsOneWidget);
    expect(find.text('Tempo investido: 15 min'), findsOneWidget);

    await tester.tap(find.text('Fechar'));
    await tester.pumpAndSettle();

    final List<FocusSession> sessions = await repository.listFocusSessions(
      goalId: goal.id,
      actionId: action.id,
    );
    expect(sessions, hasLength(1));
    expect(sessions.first.status, FocusSessionStatus.completed);
    expect(sessions.first.durationMinutes, 15);

    final List<ActionItem> actions = await repository.listActions(goal.id);
    expect(actions, hasLength(1));
    expect(actions.first.totalFocusMinutes, 15);
    expect(actions.first.isCompleted, isFalse);
  });

  testWidgets('Blocks completing an action without recorded focus time', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime(2026, 3, 18, 10, 0);
    final Goal goal = Goal(
      id: 'goal-no-focus-complete',
      title: 'Meta sem foco',
      description: null,
      createdAt: now,
      updatedAt: now,
      completedActions: 0,
      totalActions: 1,
    );
    final ActionItem action = ActionItem(
      id: 'action-no-focus-complete',
      goalId: goal.id,
      title: 'Acao sem foco',
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
      order: 0,
      completedAt: null,
    );
    final FakeInMemoryGoalsRepository repository = FakeInMemoryGoalsRepository(
      initialGoals: <Goal>[goal],
      initialActions: <ActionItem>[action],
    );

    await pumpApp(tester, repository: repository);
    await tester.pumpAndSettle();

    AppRouter.router.goNamed(
      'goal-actions',
      pathParameters: {'goalId': goal.id},
    );
    await tester.pumpAndSettle();

    await swipeFirstActionToComplete(tester);

    expect(find.text('Sem tempo gasto na ação.'), findsOneWidget);

    final List<ActionItem> actions = await repository.listActions(goal.id);
    expect(actions, hasLength(1));
    expect(actions.first.isCompleted, isFalse);
  });

  testWidgets('Keeps action pending after canceled focus session', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime(2026, 3, 18, 10, 30);
    final Goal goal = Goal(
      id: 'goal-canceled-focus',
      title: 'Meta foco cancelado',
      description: null,
      createdAt: now,
      updatedAt: now,
      completedActions: 0,
      totalActions: 1,
    );
    final ActionItem action = ActionItem(
      id: 'action-canceled-focus',
      goalId: goal.id,
      title: 'Acao cancelada',
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
      order: 0,
      completedAt: null,
    );
    final FakeInMemoryGoalsRepository repository = FakeInMemoryGoalsRepository(
      initialGoals: <Goal>[goal],
      initialActions: <ActionItem>[action],
    );

    await pumpApp(tester, repository: repository);
    await tester.pumpAndSettle();

    AppRouter.router.goNamed(
      'goal-actions',
      pathParameters: {'goalId': goal.id},
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('select-focus-action-canceled-focus')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('start-focus-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('focus-duration-15')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    await swipeFirstActionToComplete(tester);
    expect(find.text('Sem tempo gasto na ação.'), findsOneWidget);

    final List<ActionItem> actions = await repository.listActions(goal.id);
    expect(actions, hasLength(1));
    expect(actions.first.isCompleted, isFalse);
  });

  testWidgets('Accumulates one minute when canceled focus reaches one minute', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime(2026, 3, 18, 10, 45);
    final Goal goal = Goal(
      id: 'goal-canceled-focus-one-minute',
      title: 'Meta foco cancelado 1 minuto',
      description: null,
      createdAt: now,
      updatedAt: now,
      completedActions: 0,
      totalActions: 1,
    );
    final ActionItem action = ActionItem(
      id: 'action-canceled-focus-one-minute',
      goalId: goal.id,
      title: 'Acao cancelada 1 minuto',
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
      order: 0,
      completedAt: null,
    );
    final FakeInMemoryGoalsRepository repository = FakeInMemoryGoalsRepository(
      initialGoals: <Goal>[goal],
      initialActions: <ActionItem>[action],
    );

    await pumpApp(tester, repository: repository);
    await tester.pumpAndSettle();

    AppRouter.router.goNamed(
      'goal-actions',
      pathParameters: {'goalId': goal.id},
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        const ValueKey<String>('select-focus-action-canceled-focus-one-minute'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('start-focus-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('focus-duration-15')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(minutes: 1));

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    final List<FocusSession> sessions = await repository.listFocusSessions(
      goalId: goal.id,
      actionId: action.id,
    );
    expect(sessions, hasLength(1));
    expect(sessions.first.status, FocusSessionStatus.canceled);

    final List<ActionItem> actions = await repository.listActions(goal.id);
    expect(actions, hasLength(1));
    expect(actions.first.totalFocusMinutes, 1);
    expect(actions.first.isCompleted, isFalse);
    expect(find.text('Tempo de foco: 1min'), findsOneWidget);
  });

  testWidgets(
    'Does not increment streak when canceled focus is below five minutes',
    (WidgetTester tester) async {
      final DateTime now = DateTime(2026, 3, 18, 10, 46);
      final Goal goal = Goal(
        id: 'goal-canceled-focus-under-five-streak',
        title: 'Meta streak abaixo de cinco',
        description: null,
        createdAt: now,
        updatedAt: now,
        completedActions: 0,
        totalActions: 1,
      );
      final ActionItem action = ActionItem(
        id: 'action-canceled-focus-under-five-streak',
        goalId: goal.id,
        title: 'Acao streak abaixo de cinco',
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
        order: 0,
        completedAt: null,
      );
      final FakeInMemoryGoalsRepository repository =
          FakeInMemoryGoalsRepository(
            initialGoals: <Goal>[goal],
            initialActions: <ActionItem>[action],
          );

      await pumpApp(tester, repository: repository);
      await tester.pumpAndSettle();

      AppRouter.router.goNamed(
        'goal-actions',
        pathParameters: {'goalId': goal.id},
      );
      await tester.pumpAndSettle();

      await selectFocusForAction(tester, action.id);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('start-focus-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('focus-duration-15')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(minutes: 4));

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      AppRouter.router.go(AppRoutes.dashboard);
      await tester.pumpAndSettle();

      expect(find.text('0 dias seguidos'), findsOneWidget);

      final List<ActionItem> actions = await repository.listActions(goal.id);
      expect(actions.first.totalFocusMinutes, 4);
    },
  );

  testWidgets(
    'Shows calculated focus minutes when canceling after more than two minutes',
    (WidgetTester tester) async {
      final DateTime now = DateTime(2026, 3, 18, 10, 48);
      final Goal goal = Goal(
        id: 'goal-canceled-focus-message-over-two',
        title: 'Meta cancelar acima de 2 minutos',
        description: null,
        createdAt: now,
        updatedAt: now,
        completedActions: 0,
        totalActions: 1,
      );
      final ActionItem action = ActionItem(
        id: 'action-canceled-focus-message-over-two',
        goalId: goal.id,
        title: 'Acao cancelar acima de 2 minutos',
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
        order: 0,
        completedAt: null,
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

      await selectFocusForAction(tester, action.id);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('start-focus-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('focus-duration-15')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(minutes: 3));

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(
        find.text('Foco cancelado: 3 min contabilizados.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Accumulates canceled minutes beyond original duration after adding five minutes',
    (WidgetTester tester) async {
      final DateTime now = DateTime(2026, 3, 18, 10, 49);
      final Goal goal = Goal(
        id: 'goal-canceled-focus-extended',
        title: 'Meta cancelar foco estendido',
        description: null,
        createdAt: now,
        updatedAt: now,
        completedActions: 0,
        totalActions: 1,
      );
      final ActionItem action = ActionItem(
        id: 'action-canceled-focus-extended',
        goalId: goal.id,
        title: 'Acao cancelar foco estendida',
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
        order: 0,
        completedAt: null,
      );
      final FakeInMemoryGoalsRepository repository =
          FakeInMemoryGoalsRepository(
            initialGoals: <Goal>[goal],
            initialActions: <ActionItem>[action],
          );

      await pumpApp(tester, repository: repository);
      await tester.pumpAndSettle();

      AppRouter.router.goNamed(
        'goal-actions',
        pathParameters: {'goalId': goal.id},
      );
      await tester.pumpAndSettle();

      await selectFocusForAction(tester, action.id);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('start-focus-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('focus-duration-15')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('focus-add-five-minutes-button')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(minutes: 16));

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(
        find.text('Foco cancelado: 16 min contabilizados.'),
        findsOneWidget,
      );

      final List<ActionItem> actions = await repository.listActions(goal.id);
      expect(actions, hasLength(1));
      expect(actions.first.totalFocusMinutes, 16);
    },
  );

  testWidgets(
    'Does not accumulate focus time when canceled before one minute',
    (WidgetTester tester) async {
      final DateTime now = DateTime(2026, 3, 18, 10, 50);
      final Goal goal = Goal(
        id: 'goal-canceled-focus-under-one-minute',
        title: 'Meta foco cancelado menos de 1 minuto',
        description: null,
        createdAt: now,
        updatedAt: now,
        completedActions: 0,
        totalActions: 1,
      );
      final ActionItem action = ActionItem(
        id: 'action-canceled-focus-under-one-minute',
        goalId: goal.id,
        title: 'Acao cancelada menos de 1 minuto',
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
        order: 0,
        completedAt: null,
      );
      final FakeInMemoryGoalsRepository repository =
          FakeInMemoryGoalsRepository(
            initialGoals: <Goal>[goal],
            initialActions: <ActionItem>[action],
          );

      await pumpApp(tester, repository: repository);
      await tester.pumpAndSettle();

      AppRouter.router.goNamed(
        'goal-actions',
        pathParameters: {'goalId': goal.id},
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          const ValueKey<String>(
            'select-focus-action-canceled-focus-under-one-minute',
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('start-focus-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('focus-duration-15')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 45));

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      final List<ActionItem> actions = await repository.listActions(goal.id);
      expect(actions, hasLength(1));
      expect(actions.first.totalFocusMinutes, 0);
      expect(actions.first.isCompleted, isFalse);

      await swipeFirstActionToComplete(tester);
      expect(find.text('Sem tempo gasto na ação.'), findsOneWidget);
    },
  );

  testWidgets(
    'Blocks back navigation during active focus and exits only with Cancelar',
    (WidgetTester tester) async {
      final DateTime now = DateTime(2026, 3, 18, 13, 0);
      final Goal goal = Goal(
        id: 'goal-focus-back-blocked-active',
        title: 'Meta bloqueio back ativa',
        description: null,
        createdAt: now,
        updatedAt: now,
        completedActions: 0,
        totalActions: 1,
      );
      final ActionItem action = ActionItem(
        id: 'action-focus-back-blocked-active',
        goalId: goal.id,
        title: 'Acao bloqueio back ativa',
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
        order: 0,
        completedAt: null,
      );
      final FakeInMemoryGoalsRepository repository =
          FakeInMemoryGoalsRepository(
            initialGoals: <Goal>[goal],
            initialActions: <ActionItem>[action],
          );

      await pumpApp(tester, repository: repository);
      await tester.pumpAndSettle();

      AppRouter.router.goNamed(
        'goal-actions',
        pathParameters: {'goalId': goal.id},
      );
      await tester.pumpAndSettle();

      await selectFocusForAction(tester, action.id);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('start-focus-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('focus-duration-15')));
      await tester.pumpAndSettle();

      expect(find.text('Modo Foco'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Modo Foco'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.text('Ações da meta'), findsOneWidget);

      final List<FocusSession> sessions = await repository.listFocusSessions(
        goalId: goal.id,
        actionId: action.id,
      );
      expect(sessions, hasLength(1));
      expect(sessions.first.status, FocusSessionStatus.canceled);
    },
  );

  testWidgets(
    'Blocks back navigation after completed focus and exits only with Fechar',
    (WidgetTester tester) async {
      final DateTime now = DateTime(2026, 3, 18, 13, 30);
      final Goal goal = Goal(
        id: 'goal-focus-back-blocked-completed',
        title: 'Meta bloqueio back concluida',
        description: null,
        createdAt: now,
        updatedAt: now,
        completedActions: 0,
        totalActions: 1,
      );
      final ActionItem action = ActionItem(
        id: 'action-focus-back-blocked-completed',
        goalId: goal.id,
        title: 'Acao bloqueio back concluida',
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
        order: 0,
        completedAt: null,
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

      await selectFocusForAction(tester, action.id);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('start-focus-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('focus-duration-15')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(minutes: 5));

      await tester.tap(find.text('Concluir agora'));
      await tester.pumpAndSettle();
      expect(find.text('Fechar'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Modo Foco'), findsOneWidget);
      expect(find.text('Fechar'), findsOneWidget);

      await tester.tap(find.text('Fechar'));
      await tester.pumpAndSettle();
      expect(find.text('Ações da meta'), findsOneWidget);
    },
  );

  testWidgets('Recalculates focus timer after returning from background', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime(2026, 3, 18, 14, 0);
    final Goal goal = Goal(
      id: 'goal-focus-background-resume',
      title: 'Meta foco background',
      description: null,
      createdAt: now,
      updatedAt: now,
      completedActions: 0,
      totalActions: 1,
    );
    final ActionItem action = ActionItem(
      id: 'action-focus-background-resume',
      goalId: goal.id,
      title: 'Acao foco background',
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
      order: 0,
      completedAt: null,
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

    await selectFocusForAction(tester, action.id);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('start-focus-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('focus-duration-15')));
    await tester.pumpAndSettle();

    final int beforeBackground = readFocusCountdownSeconds(tester);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(seconds: 3));
    });
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    final int afterResume = readFocusCountdownSeconds(tester);
    expect(afterResume, lessThan(beforeBackground));
    expect(find.text('Modo Foco'), findsOneWidget);
  });

  testWidgets(
    'Adds five minutes to focus timer and keeps real-clock countdown after background resume',
    (WidgetTester tester) async {
      final DateTime now = DateTime(2026, 3, 18, 14, 30);
      final Goal goal = Goal(
        id: 'goal-focus-add-five',
        title: 'Meta foco +5',
        description: null,
        createdAt: now,
        updatedAt: now,
        completedActions: 0,
        totalActions: 1,
      );
      final ActionItem action = ActionItem(
        id: 'action-focus-add-five',
        goalId: goal.id,
        title: 'Acao foco +5',
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
        order: 0,
        completedAt: null,
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

      await selectFocusForAction(tester, action.id);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('start-focus-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('focus-duration-15')));
      await tester.pumpAndSettle();

      final int beforeAdd = readFocusCountdownSeconds(tester);

      await tester.tap(find.byKey(const Key('focus-add-five-minutes-button')));
      await tester.pumpAndSettle();

      final int afterAdd = readFocusCountdownSeconds(tester);
      expect(afterAdd, greaterThan(beforeAdd + 295));

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(seconds: 3));
      });
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      final int afterResume = readFocusCountdownSeconds(tester);
      expect(afterResume, lessThan(afterAdd));
      expect(
        find.byKey(const Key('focus-add-five-minutes-button')),
        findsOneWidget,
      );
    },
  );

}


