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
import 'package:quebrando_metas/features/goals/presentation/goals_controller.dart';
import 'package:quebrando_metas/main.dart';
import 'fakes/fake_in_memory_goals_repository.dart';

void main() {
  testWidgets('Shows empty home state on startup', (WidgetTester tester) async {
    await _pumpApp(tester, repository: FakeInMemoryGoalsRepository());
    await tester.pumpAndSettle();

    expect(find.text('Quebrando Metas'), findsOneWidget);
    expect(find.text('Olá!'), findsOneWidget);
    expect(find.text('Defina uma meta como prioridade.'), findsOneWidget);
    expect(find.byKey(const Key('create-goal-fab')), findsOneWidget);
    expect(find.byKey(const Key('priority-content-switcher')), findsOneWidget);
    // single-home layout: no tab switch needed

    await tester.pumpAndSettle();
    expect(find.text('Olá!'), findsOneWidget);
    expect(find.text('Suas Metas'), findsOneWidget);
  });

  testWidgets('Shows create button on single-home layout', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester, repository: FakeInMemoryGoalsRepository());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('create-goal-fab')), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('Create button opens goal form on single-home layout', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester, repository: FakeInMemoryGoalsRepository());
    await tester.pumpAndSettle();
    // single-home layout: no tab switch needed

    await tester.pumpAndSettle();
    await _tapCreateGoalFab(tester);

    expect(find.text('Nova Meta'), findsOneWidget);
    expect(find.text('Salvar'), findsOneWidget);
  });

  testWidgets('Opens theme drawer and toggles theme mode with icon', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester, repository: FakeInMemoryGoalsRepository());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('toggle-theme-icon')), findsOneWidget);
    expect(find.byIcon(Icons.wb_sunny_outlined), findsOneWidget);

    await tester.tap(find.byKey(const Key('toggle-theme-icon')));
    await tester.pumpAndSettle();

    final MaterialApp materialApp = tester.widget<MaterialApp>(
      find.byType(MaterialApp),
    );
    expect(materialApp.themeMode, ThemeMode.dark);
    expect(find.byIcon(Icons.nightlight_round), findsOneWidget);
  });

  testWidgets('Keeps drawer open after screen rotation', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester, repository: FakeInMemoryGoalsRepository());
    await tester.pumpAndSettle();

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(500, 900);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('toggle-theme-icon')), findsOneWidget);

    tester.view.physicalSize = const Size(900, 500);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('toggle-theme-icon')), findsOneWidget);
  });

  testWidgets('Opens theme drawer and changes seed color', (
    WidgetTester tester,
  ) async {
    expect(AppThemeSettings.colorOptions.length, greaterThan(1));

    await _pumpApp(tester, repository: FakeInMemoryGoalsRepository());
    await tester.pumpAndSettle();

    final MaterialApp before = tester.widget<MaterialApp>(
      find.byType(MaterialApp),
    );
    final Color initialPrimaryColor = before.theme!.colorScheme.primary;

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Definir cor'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('theme-color-1')));
    await tester.pumpAndSettle();

    final MaterialApp after = tester.widget<MaterialApp>(
      find.byType(MaterialApp),
    );
    expect(
      after.theme!.colorScheme.primary,
      isNot(equals(initialPrimaryColor)),
    );
  });

  testWidgets('Updates greeting after changing name in drawer', (
    WidgetTester tester,
  ) async {
    OnboardingStatus.instance.debugUseInMemoryMode(true);
    addTearDown(() {
      OnboardingStatus.instance.debugSeed(
        hasCompletedOnboarding: true,
        displayName: '',
        greetingIndex: 0,
      );
      OnboardingStatus.instance.debugUseInMemoryMode(false);
    });

    await _pumpApp(tester, repository: FakeInMemoryGoalsRepository());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('edit-name-tile')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('edit-name-input')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('edit-name-input')), 'Kaique');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('edit-name-save')));
    await tester.pumpAndSettle();

    expect(find.text('Nome atualizado.'), findsOneWidget);
    expect(find.textContaining('Kaique'), findsOneWidget);
  });

  testWidgets('Creates a goal and shows it in Suas Metas page', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester, repository: FakeInMemoryGoalsRepository());
    await tester.pumpAndSettle();

    await _tapCreateGoalFab(tester);

    expect(find.text('Nova Meta'), findsOneWidget);
    expect(find.text('Salvar'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Meta de teste');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    // single-home layout: no tab switch needed

    await tester.pumpAndSettle();

    expect(find.text('Meta de teste'), findsOneWidget);
  });

  testWidgets('Edits and deletes a goal from Suas Metas card menu', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester, repository: FakeInMemoryGoalsRepository());
    await tester.pumpAndSettle();

    await _tapCreateGoalFab(tester);
    await tester.enterText(find.byType(TextField).first, 'Meta original');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    // single-home layout: no tab switch needed

    await tester.pumpAndSettle();
    expect(find.text('Meta original'), findsOneWidget);

    await _openGoalMenuForTitle(tester, 'Meta original');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Meta editada');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Meta editada'), findsOneWidget);

    await _openGoalMenuForTitle(tester, 'Meta editada');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();

    expect(find.text('Meta editada'), findsNothing);
    expect(find.textContaining('Nenhuma meta criada ainda'), findsOneWidget);
  });

  testWidgets('Creates, edits and deletes actions for a goal', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime(2026, 3, 17);
    final Goal goal = Goal(
      id: 'goal-actions-test',
      title: 'Meta com acoes',
      description: null,
      createdAt: now,
      updatedAt: now,
      completedActions: 0,
      totalActions: 0,
    );
    await _pumpApp(
      tester,
      repository: FakeInMemoryGoalsRepository(initialGoals: <Goal>[goal]),
    );
    await tester.pumpAndSettle();

    AppRouter.router.goNamed(
      'goal-actions',
      pathParameters: {'goalId': goal.id},
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Meta com acoes'), findsOneWidget);
    expect(find.text('Descrição da meta'), findsOneWidget);
    expect(find.text('Sem descrição para esta meta.'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add).last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Primeira acao');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Primeira acao'), findsOneWidget);

    await _openActionMenuForTitle(tester, 'Primeira acao');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Acao editada');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Acao editada'), findsOneWidget);

    await _openActionMenuForTitle(tester, 'Acao editada');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    expect(find.text('Acao editada'), findsNothing);
  });

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

    await _pumpApp(tester, repository: repository);
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

    await _pumpApp(
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

    await _selectFocusForAction(tester, action.id);
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

      await _pumpApp(tester, repository: repository);
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

      await _pumpApp(tester, repository: repository);
      await tester.pumpAndSettle();

      AppRouter.router.goNamed(
        'goal-actions',
        pathParameters: {'goalId': goal.id},
      );
      await tester.pumpAndSettle();

      await _selectFocusForAction(tester, action.id);
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

    await _pumpApp(
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

    await _selectFocusForAction(tester, action.id);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('start-focus-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('focus-duration-60')));
    await tester.pumpAndSettle();

    expect(find.text('Modo Foco'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Does not overflow pixels when user completes focus on small screen',
    (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(320, 500);

      final DateTime now = DateTime(2026, 3, 18, 11, 30);
      final Goal goal = Goal(
        id: 'goal-focus-overflow-complete',
        title: 'Meta foco concluir pequena',
        description: null,
        createdAt: now,
        updatedAt: now,
        completedActions: 0,
        totalActions: 1,
      );
      final ActionItem action = ActionItem(
        id: 'action-focus-overflow-complete',
        goalId: goal.id,
        title: 'Acao concluir pequena',
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

      await _pumpApp(tester, repository: repository);
      await tester.pumpAndSettle();

      AppRouter.router.goNamed(
        'goal-actions',
        pathParameters: {'goalId': goal.id},
      );
      await tester.pumpAndSettle();

      await _selectFocusForAction(tester, action.id);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('start-focus-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('focus-duration-15')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(minutes: 5));

      await tester.tap(find.text('Concluir agora'));
      await tester.pumpAndSettle();

      expect(find.text('Tempo investido: 5 min'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

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

    await _pumpApp(tester, repository: repository);
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

    await _pumpApp(tester, repository: repository);
    await tester.pumpAndSettle();

    AppRouter.router.goNamed(
      'goal-actions',
      pathParameters: {'goalId': goal.id},
    );
    await tester.pumpAndSettle();

    await _swipeFirstActionToComplete(tester);

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

    await _pumpApp(tester, repository: repository);
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

    await _swipeFirstActionToComplete(tester);
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

    await _pumpApp(tester, repository: repository);
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

      await _pumpApp(tester, repository: repository);
      await tester.pumpAndSettle();

      AppRouter.router.goNamed(
        'goal-actions',
        pathParameters: {'goalId': goal.id},
      );
      await tester.pumpAndSettle();

      await _selectFocusForAction(tester, action.id);
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

      await _pumpApp(
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

      await _selectFocusForAction(tester, action.id);
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

      await _pumpApp(tester, repository: repository);
      await tester.pumpAndSettle();

      AppRouter.router.goNamed(
        'goal-actions',
        pathParameters: {'goalId': goal.id},
      );
      await tester.pumpAndSettle();

      await _selectFocusForAction(tester, action.id);
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

      await _pumpApp(tester, repository: repository);
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

      await _swipeFirstActionToComplete(tester);
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

      await _pumpApp(tester, repository: repository);
      await tester.pumpAndSettle();

      AppRouter.router.goNamed(
        'goal-actions',
        pathParameters: {'goalId': goal.id},
      );
      await tester.pumpAndSettle();

      await _selectFocusForAction(tester, action.id);
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

      await _pumpApp(
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

      await _selectFocusForAction(tester, action.id);
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

    await _pumpApp(
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

    await _selectFocusForAction(tester, action.id);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('start-focus-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('focus-duration-15')));
    await tester.pumpAndSettle();

    final int beforeBackground = _readFocusCountdownSeconds(tester);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(seconds: 3));
    });
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    final int afterResume = _readFocusCountdownSeconds(tester);
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

      await _pumpApp(
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

      await _selectFocusForAction(tester, action.id);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('start-focus-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('focus-duration-15')));
      await tester.pumpAndSettle();

      final int beforeAdd = _readFocusCountdownSeconds(tester);

      await tester.tap(find.byKey(const Key('focus-add-five-minutes-button')));
      await tester.pumpAndSettle();

      final int afterAdd = _readFocusCountdownSeconds(tester);
      expect(afterAdd, greaterThan(beforeAdd + 295));

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(seconds: 3));
      });
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      final int afterResume = _readFocusCountdownSeconds(tester);
      expect(afterResume, lessThan(afterAdd));
      expect(
        find.byKey(const Key('focus-add-five-minutes-button')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Shows correct summary for long-time user with many completed and active goals',
    (WidgetTester tester) async {
      final DateTime now = DateTime(2026, 3, 12);
      final DateTime streakNow = DateTime.now();
      final List<Goal> seededGoals = <Goal>[];
      final List<ActionItem> seededActions = <ActionItem>[];
      final List<FocusSession> seededSessions = <FocusSession>[
        _completedSession(
          id: 'summary-streak-1',
          goalId: 'active-0',
          actionId: 'active-a-0-2',
          startedAt: streakNow.subtract(const Duration(days: 1)),
          durationMinutes: 25,
        ),
        _completedSession(
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

      await _pumpApp(
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

    await _pumpApp(
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

    await _pumpApp(tester, repository: FakeInMemoryGoalsRepository());
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
    await _pumpApp(
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

      await _pumpApp(
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

    await _pumpApp(
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

    await _pumpApp(
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
      _completedSession(
        id: 'scope-a-today',
        goalId: firstGoal.id,
        actionId: 'goal-streak-scope-a-action',
        startedAt: now.subtract(const Duration(hours: 1)),
        durationMinutes: 25,
      ),
      _completedSession(
        id: 'scope-a-yesterday',
        goalId: firstGoal.id,
        actionId: 'goal-streak-scope-a-action',
        startedAt: now.subtract(const Duration(days: 1, hours: 1)),
        durationMinutes: 25,
      ),
      _completedSession(
        id: 'scope-b-today',
        goalId: secondGoal.id,
        actionId: 'goal-streak-scope-b-action',
        startedAt: now.subtract(const Duration(hours: 2)),
        durationMinutes: 25,
      ),
      _completedSession(
        id: 'scope-b-day-1',
        goalId: secondGoal.id,
        actionId: 'goal-streak-scope-b-action',
        startedAt: now.subtract(const Duration(days: 1, hours: 2)),
        durationMinutes: 25,
      ),
      _completedSession(
        id: 'scope-b-day-2',
        goalId: secondGoal.id,
        actionId: 'goal-streak-scope-b-action',
        startedAt: now.subtract(const Duration(days: 2, hours: 2)),
        durationMinutes: 25,
      ),
      _completedSession(
        id: 'scope-b-day-3',
        goalId: secondGoal.id,
        actionId: 'goal-streak-scope-b-action',
        startedAt: now.subtract(const Duration(days: 3, hours: 2)),
        durationMinutes: 25,
      ),
    ];

    await _pumpApp(
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

  testWidgets('Shows prioritized goal in continue section', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester, repository: FakeInMemoryGoalsRepository());
    await tester.pumpAndSettle();

    await _tapCreateGoalFab(tester);
    await tester.enterText(find.byType(TextField).first, 'Meta prioridade');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    // single-home layout: no tab switch needed

    await tester.pumpAndSettle();
    await _tapPriorityForGoal(tester, 'Meta prioridade');
    await tester.pumpAndSettle();
    // single-home layout: already on home

    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const Key('priority-content-switcher')),
        matching: find.byKey(const Key('continue-goal-title')),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Shows up to three prioritized goals in continue section', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime(2026, 3, 19, 10);
    final Goal goal1 = Goal(
      id: 'continue-priority-1',
      title: 'Prioridade 1',
      description: null,
      priorityRank: 1,
      createdAt: now,
      updatedAt: now,
      completedActions: 0,
      totalActions: 1,
    );
    final Goal goal2 = Goal(
      id: 'continue-priority-2',
      title: 'Prioridade 2',
      description: null,
      priorityRank: 2,
      createdAt: now.add(const Duration(minutes: 1)),
      updatedAt: now.add(const Duration(minutes: 1)),
      completedActions: 0,
      totalActions: 1,
    );
    final Goal goal3 = Goal(
      id: 'continue-priority-3',
      title: 'Prioridade 3',
      description: null,
      priorityRank: 3,
      createdAt: now.add(const Duration(minutes: 2)),
      updatedAt: now.add(const Duration(minutes: 2)),
      completedActions: 0,
      totalActions: 1,
    );
    final List<ActionItem> actions = <ActionItem>[
      ActionItem(
        id: 'continue-priority-1-action',
        goalId: goal1.id,
        title: 'Acao 1',
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
        order: 0,
      ),
      ActionItem(
        id: 'continue-priority-2-action',
        goalId: goal2.id,
        title: 'Acao 2',
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
        order: 0,
      ),
      ActionItem(
        id: 'continue-priority-3-action',
        goalId: goal3.id,
        title: 'Acao 3',
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
        order: 0,
      ),
    ];

    await _pumpApp(
      tester,
      repository: FakeInMemoryGoalsRepository(
        initialGoals: <Goal>[goal1, goal2, goal3],
        initialActions: actions,
      ),
    );
    await tester.pumpAndSettle();

    final Finder continueCard = find.byKey(
      const Key('priority-content-switcher'),
    );
    expect(
      find.descendant(
        of: continueCard,
        matching: find.byKey(
          const ValueKey<String>('continue-goal-item-continue-priority-1'),
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: continueCard,
        matching: find.byKey(
          const ValueKey<String>('continue-goal-item-continue-priority-2'),
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: continueCard,
        matching: find.byKey(
          const ValueKey<String>('continue-goal-item-continue-priority-3'),
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Shows pending action with least focus time in continue card', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime(2026, 3, 19, 10);
    final Goal goal = Goal(
      id: 'goal-next-action-focus',
      title: 'Meta prioridade com acoes',
      description: null,
      priorityRank: 1,
      createdAt: now,
      updatedAt: now,
      completedActions: 0,
      totalActions: 3,
    );
    final List<ActionItem> actions = <ActionItem>[
      ActionItem(
        id: 'next-action-focus-0',
        goalId: goal.id,
        title: 'Acao mais antiga',
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
        order: 0,
        totalFocusMinutes: 20,
      ),
      ActionItem(
        id: 'next-action-focus-1',
        goalId: goal.id,
        title: 'Acao com menos foco',
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
        order: 1,
        totalFocusMinutes: 5,
      ),
      ActionItem(
        id: 'next-action-focus-2',
        goalId: goal.id,
        title: 'Acao concluida',
        isCompleted: true,
        createdAt: now,
        updatedAt: now,
        order: 2,
        totalFocusMinutes: 0,
        completedAt: now,
      ),
    ];

    await _pumpApp(
      tester,
      repository: FakeInMemoryGoalsRepository(
        initialGoals: <Goal>[goal],
        initialActions: actions,
      ),
    );
    await tester.pumpAndSettle();

    final Finder continueCard = find.byKey(
      const Key('priority-content-switcher'),
    );
    expect(
      find.descendant(
        of: continueCard,
        matching: find.text('Acao com menos foco'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: continueCard,
        matching: find.text('Acao mais antiga'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(of: continueCard, matching: find.text('Acao concluida')),
      findsNothing,
    );
  });

  testWidgets('Keeps priority items left-aligned with mixed title lengths', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(360, 800);

    const String shortTitle = 'Meta curta';
    const String longTitle =
        'Meta com titulo bem maior para validar quebra e alinhamento';
    const String mediumTitle = 'Meta media';
    final DateTime now = DateTime(2026, 3, 17);
    final List<Goal> seededGoals = <Goal>[
      Goal(
        id: 'align-short',
        title: shortTitle,
        description: null,
        priorityRank: 1,
        createdAt: now,
        updatedAt: now,
        completedActions: 0,
        totalActions: 1,
      ),
      Goal(
        id: 'align-medium',
        title: mediumTitle,
        description: null,
        priorityRank: 2,
        createdAt: now.add(const Duration(minutes: 1)),
        updatedAt: now.add(const Duration(minutes: 1)),
        completedActions: 0,
        totalActions: 1,
      ),
      Goal(
        id: 'align-long',
        title: longTitle,
        description: null,
        priorityRank: 3,
        createdAt: now.add(const Duration(minutes: 2)),
        updatedAt: now.add(const Duration(minutes: 2)),
        completedActions: 0,
        totalActions: 1,
      ),
    ];

    await _pumpApp(
      tester,
      repository: FakeInMemoryGoalsRepository(initialGoals: seededGoals),
    );
    await tester.pumpAndSettle();

    final Finder shortCard = find.byKey(
      const ValueKey<String>('continue-goal-item-align-short'),
    );
    final Finder mediumCard = find.byKey(
      const ValueKey<String>('continue-goal-item-align-medium'),
    );
    final Finder longCard = find.byKey(
      const ValueKey<String>('continue-goal-item-align-long'),
    );

    final double shortLeft = tester.getTopLeft(shortCard).dx;
    final double mediumLeft = tester.getTopLeft(mediumCard).dx;
    final double longLeft = tester.getTopLeft(longCard).dx;

    expect((shortLeft - mediumLeft).abs(), lessThanOrEqualTo(1.0));
    expect((shortLeft - longLeft).abs(), lessThanOrEqualTo(1.0));
  });

  testWidgets(
    'Keeps title and description after screen rotation while keyboard is open',
    (WidgetTester tester) async {
      await _pumpApp(tester, repository: FakeInMemoryGoalsRepository());
      await tester.pumpAndSettle();

      await _tapCreateGoalFab(tester);

      await tester.enterText(find.byType(TextField).at(0), 'Meta rotacao');
      await tester.enterText(find.byType(TextField).at(1), 'Descricao rotacao');
      await tester.pump();

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(900, 500);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      expect(find.text('Meta rotacao'), findsOneWidget);
      expect(find.text('Descricao rotacao'), findsOneWidget);

      tester.view.physicalSize = const Size(500, 900);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      AppRouter.router.go(AppRoutes.goals);
      await tester.pumpAndSettle();
      expect(find.text('Meta rotacao'), findsOneWidget);
    },
  );

  testWidgets('Keeps new action dialog stable after screen rotation', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(500, 900);

    final DateTime now = DateTime(2026, 3, 20, 10);
    final Goal goal = Goal(
      id: 'goal-action-dialog-rotation',
      title: 'Meta rotacao acao',
      createdAt: now,
      updatedAt: now,
      completedActions: 0,
      totalActions: 0,
    );

    await _pumpApp(
      tester,
      repository: FakeInMemoryGoalsRepository(initialGoals: <Goal>[goal]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Meta rotacao acao'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Nova ação'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Acao rotacao');
    await tester.pump();

    tester.view.physicalSize = const Size(900, 360);
    await tester.pumpAndSettle();

    expect(find.text('Nova ação'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Does not overflow pixels on create goal page with small screen height',
    (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 320);

      await _pumpApp(tester, repository: FakeInMemoryGoalsRepository());
      await tester.pumpAndSettle();

      await _tapCreateGoalFab(tester);
      await tester.enterText(find.byType(TextField).at(0), 'Meta pequena');
      await tester.enterText(find.byType(TextField).at(1), 'Descricao');
      await tester.pumpAndSettle();

      expect(find.text('Nova Meta'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Limits goal description to five lines', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester, repository: FakeInMemoryGoalsRepository());
    await tester.pumpAndSettle();

    await _tapCreateGoalFab(tester);
    final Finder descriptionFieldFinder = find.byType(TextField).at(1);
    const String sixLines = 'L1\nL2\nL3\nL4\nL5\nL6';
    await tester.enterText(descriptionFieldFinder, sixLines);
    await tester.pumpAndSettle();

    final TextField descriptionField = tester.widget<TextField>(
      descriptionFieldFinder,
    );
    final String currentText = descriptionField.controller?.text ?? '';
    final int lines = currentText.split('\n').length;
    expect(lines, lessThanOrEqualTo(5));
    expect(currentText, 'L1\nL2\nL3\nL4\nL5');
  });

  testWidgets('Does not overflow pixels on small goals list with long title', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(320, 720);

    final DateTime now = DateTime(2026, 3, 16);
    final Goal longGoal = Goal(
      id: 'goal-long-title',
      title: '${_repeat('Meta muito longa ', 6)}final',
      description: null,
      createdAt: now,
      updatedAt: now,
      completedActions: 0,
      totalActions: 0,
    );

    final List<ActionItem> longGoalActions = <ActionItem>[
      ActionItem(
        id: 'action-long-1',
        goalId: longGoal.id,
        title: 'Acao 1',
        isCompleted: true,
        createdAt: now,
        updatedAt: now,
        order: 0,
        completedAt: now,
      ),
      ActionItem(
        id: 'action-long-2',
        goalId: longGoal.id,
        title: 'Acao 2',
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
        order: 1,
        completedAt: null,
      ),
    ];

    await _pumpApp(
      tester,
      repository: FakeInMemoryGoalsRepository(
        initialGoals: <Goal>[longGoal],
        initialActions: longGoalActions,
      ),
    );
    await tester.pumpAndSettle();
    // single-home layout: no tab switch needed

    await tester.pumpAndSettle();

    expect(find.textContaining('Meta muito longa'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Handles selecting priority on an already prioritized goal', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester, repository: FakeInMemoryGoalsRepository());
    await tester.pumpAndSettle();

    await _tapCreateGoalFab(tester);
    await tester.enterText(
      find.byType(TextField).first,
      'Meta prioridade duplicada',
    );
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    // single-home layout: no tab switch needed

    await tester.pumpAndSettle();

    await _tapPriorityForGoal(tester, 'Meta prioridade duplicada');
    await tester.pumpAndSettle();
    expect(find.text('Meta adicionada às prioridades.'), findsOneWidget);

    await _tapPriorityForGoal(tester, 'Meta prioridade duplicada');
    await tester.pumpAndSettle();
    expect(find.byTooltip('Definir prioridade'), findsOneWidget);
    // single-home layout: already on home

    await tester.pumpAndSettle();
    expect(find.text('Defina uma meta como prioridade.'), findsOneWidget);
  });

  testWidgets('Handles completing a goal that was prioritized', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime(2026, 3, 19, 9);
    final Goal goal = Goal(
      id: 'goal-priority-completed',
      title: 'Meta prioritaria concluida',
      description: null,
      priorityRank: 1,
      createdAt: now,
      updatedAt: now,
      completedActions: 0,
      totalActions: 1,
    );
    final ActionItem action = ActionItem(
      id: 'goal-priority-completed-action',
      goalId: goal.id,
      title: 'Acao unica',
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
      order: 0,
      totalFocusMinutes: 1,
    );

    await _pumpApp(
      tester,
      repository: FakeInMemoryGoalsRepository(
        initialGoals: <Goal>[goal],
        initialActions: <ActionItem>[action],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Meta prioritaria concluida').last);
    await tester.pumpAndSettle();

    await _swipeFirstActionToComplete(tester);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Defina uma meta como prioridade.'), findsOneWidget);
    expect(find.text('Suas Metas'), findsOneWidget);
  });

  testWidgets(
    'Does not block third active priority when a completed legacy priority exists',
    (WidgetTester tester) async {
      final DateTime now = DateTime(2026, 3, 17);
      final Goal completedWithPriority = Goal(
        id: 'completed-priority-goal',
        title: 'Meta concluida antiga',
        description: null,
        priorityRank: 1,
        createdAt: now,
        updatedAt: now,
        completedActions: 0,
        totalActions: 0,
      );
      final List<Goal> activeGoals = <Goal>[
        Goal(
          id: 'new-priority-1',
          title: 'Nova prioridade 1',
          description: null,
          createdAt: now.add(const Duration(minutes: 1)),
          updatedAt: now.add(const Duration(minutes: 1)),
          completedActions: 0,
          totalActions: 0,
        ),
        Goal(
          id: 'new-priority-2',
          title: 'Nova prioridade 2',
          description: null,
          createdAt: now.add(const Duration(minutes: 2)),
          updatedAt: now.add(const Duration(minutes: 2)),
          completedActions: 0,
          totalActions: 0,
        ),
        Goal(
          id: 'new-priority-3',
          title: 'Nova prioridade 3',
          description: null,
          createdAt: now.add(const Duration(minutes: 3)),
          updatedAt: now.add(const Duration(minutes: 3)),
          completedActions: 0,
          totalActions: 0,
        ),
      ];
      final List<ActionItem> actions = <ActionItem>[
        ActionItem(
          id: 'completed-priority-action-1',
          goalId: completedWithPriority.id,
          title: 'Acao concluida',
          isCompleted: true,
          createdAt: now,
          updatedAt: now,
          order: 0,
          completedAt: now,
        ),
      ];

      await _pumpApp(
        tester,
        repository: FakeInMemoryGoalsRepository(
          initialGoals: <Goal>[completedWithPriority, ...activeGoals],
          initialActions: actions,
        ),
      );
      await tester.pumpAndSettle();
      // single-home layout: no tab switch needed

      await tester.pumpAndSettle();

      await _tapPriorityForGoal(tester, 'Nova prioridade 1');
      await tester.pumpAndSettle();
      await _tapPriorityForGoal(tester, 'Nova prioridade 2');
      await tester.pumpAndSettle();
      await _tapPriorityForGoal(tester, 'Nova prioridade 3');
      await tester.pumpAndSettle();

      expect(find.text('Você pode priorizar no máximo 3 metas.'), findsNothing);
      // single-home layout: already on home

      await tester.pumpAndSettle();
      expect(find.byTooltip('Remover prioridade'), findsAtLeastNWidgets(2));
    },
  );

  testWidgets('Allows adding an action to a goal that was completed', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester, repository: FakeInMemoryGoalsRepository());
    await tester.pumpAndSettle();

    await _tapCreateGoalFab(tester);
    await tester.enterText(find.byType(TextField).first, 'Meta reaberta');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    // single-home layout: no tab switch needed

    await tester.pumpAndSettle();
    await tester.tap(find.text('Meta reaberta').first);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add).last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Acao 1');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    await _completeFocusForSingleAction(tester);
    await _swipeFirstActionToComplete(tester);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('1 de 1 ações'), findsOneWidget);

    await tester.tap(find.text('Meta reaberta').first);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add).last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Acao 2');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('1 de 2 ações'), findsOneWidget);
    expect(find.text('Meta reaberta'), findsOneWidget);
  });

  testWidgets('Handles very large title/description input without crashing', (
    WidgetTester tester,
  ) async {
    final String hugeTitle = _repeat('T', 200);
    final String hugeDescription = _repeat('D', 600);
    final String hugeActionTitle = _repeat('A', 200);
    final String truncatedTitle = _repeat('T', TitleValidator.maxLength);

    await _pumpApp(tester, repository: FakeInMemoryGoalsRepository());
    await tester.pumpAndSettle();

    await _tapCreateGoalFab(tester);

    await tester.enterText(find.byType(TextField).at(0), hugeTitle);
    await tester.enterText(find.byType(TextField).at(1), hugeDescription);
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    // single-home layout: no tab switch needed

    await tester.pumpAndSettle();
    expect(find.text(truncatedTitle), findsOneWidget);

    await tester.tap(find.text(truncatedTitle).first);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add).last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, hugeActionTitle);
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Salvar'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Does not show retry state after returning from goal screen multiple times',
    (WidgetTester tester) async {
      await _pumpApp(tester, repository: FakeInMemoryGoalsRepository());
      await tester.pumpAndSettle();

      await _tapCreateGoalFab(tester);
      await tester.enterText(find.byType(TextField).first, 'Meta estabilidade');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();
      // single-home layout: no tab switch needed

      await tester.pumpAndSettle();

      for (int i = 0; i < 10; i++) {
        await tester.tap(find.text('Meta estabilidade').first);
        await tester.pumpAndSettle();
        expect(find.text('Ações da meta'), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.text('Tentar novamente'), findsNothing);
        expect(find.text('Meta estabilidade'), findsOneWidget);
      }
    },
  );
}

String _repeat(String value, int count) =>
    List<String>.filled(count, value).join();

FocusSession _completedSession({
  required String id,
  required String goalId,
  required String actionId,
  required DateTime startedAt,
  required int durationMinutes,
}) {
  final DateTime endedAt = startedAt.add(Duration(minutes: durationMinutes));
  return FocusSession(
    id: id,
    actionId: actionId,
    goalId: goalId,
    startedAt: startedAt,
    endedAt: endedAt,
    durationMinutes: durationMinutes,
    status: FocusSessionStatus.completed,
    createdAt: startedAt,
    updatedAt: endedAt,
  );
}

Future<void> _tapCreateGoalFab(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('create-goal-fab')));
  await tester.pumpAndSettle();
}

int _readFocusCountdownSeconds(WidgetTester tester) {
  final Finder timerFinder = find.byWidgetPredicate(
    (widget) =>
        widget is Text && RegExp(r'^\d{2}:\d{2}$').hasMatch(widget.data ?? ''),
  );
  expect(timerFinder, findsOneWidget);
  final Text timerText = tester.widget<Text>(timerFinder);
  final String value = timerText.data!;
  final List<String> parts = value.split(':');
  final int minutes = int.parse(parts[0]);
  final int seconds = int.parse(parts[1]);
  return (minutes * 60) + seconds;
}

Future<void> _completeFocusForSingleAction(WidgetTester tester) async {
  await _scrollToActionListIfNeeded(tester);
  Finder selectButton = find.byTooltip('Selecionar para foco').hitTestable();
  if (selectButton.evaluate().isEmpty) {
    selectButton = find.byTooltip('Ação selecionada para foco').hitTestable();
  }
  if (selectButton.evaluate().isEmpty) {
    selectButton = find
        .byWidgetPredicate(
          (widget) =>
              widget is IconButton &&
              widget.onPressed != null &&
              widget.key is ValueKey<String> &&
              (widget.key as ValueKey<String>).value.startsWith(
                'select-focus-action-',
              ),
        )
        .hitTestable();
  }
  if (selectButton.evaluate().isEmpty) {
    selectButton = find
        .byWidgetPredicate(
          (widget) =>
              widget is IconButton &&
              widget.onPressed != null &&
              (widget.tooltip?.contains('foco') ?? false),
        )
        .hitTestable();
  }
  if (selectButton.evaluate().isNotEmpty) {
    await tester.ensureVisible(selectButton.first);
    await tester.tap(selectButton.first);
    await tester.pumpAndSettle();
  }

  FilledButton startFocusButton = tester.widget<FilledButton>(
    find.byKey(const Key('start-focus-button')),
  );
  if (startFocusButton.onPressed == null) {
    final Finder anySelectable = find
        .byWidgetPredicate(
          (widget) =>
              widget is IconButton &&
              widget.onPressed != null &&
              (widget.tooltip?.contains('foco') ?? false),
        )
        .hitTestable();
    if (anySelectable.evaluate().isNotEmpty) {
      await tester.ensureVisible(anySelectable.first);
      await tester.tap(anySelectable.first);
      await tester.pumpAndSettle();
      startFocusButton = tester.widget<FilledButton>(
        find.byKey(const Key('start-focus-button')),
      );
    }
  }
  expect(startFocusButton.onPressed, isNotNull);

  await tester.tap(find.byKey(const Key('start-focus-button')));
  await tester.pumpAndSettle();
  expect(
    find.byKey(const ValueKey<String>('focus-duration-15')),
    findsOneWidget,
  );

  await tester.tap(find.byKey(const ValueKey<String>('focus-duration-15')));
  await tester.pumpAndSettle();
  await tester.pump(const Duration(minutes: 5));

  await tester.tap(find.text('Concluir agora'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Fechar'));
  await tester.pumpAndSettle();
}

Future<void> _swipeFirstActionToComplete(WidgetTester tester) async {
  await tester.drag(find.byType(Dismissible).first, const Offset(500, 0));
  await tester.pumpAndSettle();
}

Future<void> _tapPriorityForGoal(WidgetTester tester, String goalTitle) async {
  final Finder goalTitleFinder = find.text(goalTitle).last;
  await tester.ensureVisible(goalTitleFinder);
  await tester.pumpAndSettle();
  final Finder goalCard = find.ancestor(
    of: goalTitleFinder,
    matching: find.byType(Card),
  );
  Finder priorityButton = find.descendant(
    of: goalCard,
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is IconButton &&
          (widget.tooltip == 'Definir prioridade' ||
              widget.tooltip == 'Remover prioridade'),
    ),
  );
  if (priorityButton.evaluate().isEmpty) {
    priorityButton = find.descendant(
      of: goalCard,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is IconButton &&
            (widget.icon is Icon) &&
            (((widget.icon as Icon).icon == Icons.star_border) ||
                ((widget.icon as Icon).icon == Icons.star)),
      ),
    );
  }
  await tester.tap(priorityButton.first);
}

Future<void> _openActionMenuForTitle(
  WidgetTester tester,
  String actionTitle,
) async {
  await _scrollToActionListIfNeeded(tester);
  final Finder titleFinder = find.text(actionTitle).first;
  await tester.ensureVisible(titleFinder);
  await tester.pumpAndSettle();

  final Finder actionCard = find.ancestor(
    of: titleFinder,
    matching: find.byType(Card),
  );
  final Finder menuButton = find.descendant(
    of: actionCard,
    matching: find.byIcon(Icons.more_vert),
  );
  await tester.tap(menuButton.first);
}

Future<void> _openGoalMenuForTitle(
  WidgetTester tester,
  String goalTitle,
) async {
  final Finder goalTitleFinder = find.text(goalTitle).first;
  await tester.ensureVisible(goalTitleFinder);
  await tester.pumpAndSettle();
  final Finder goalCard = find.ancestor(
    of: goalTitleFinder,
    matching: find.byType(Card),
  );
  final Finder menuButton = find.descendant(
    of: goalCard,
    matching: find.byType(PopupMenuButton<String>),
  );
  await tester.tap(menuButton.first);
}

Future<void> _selectFocusForAction(WidgetTester tester, String actionId) async {
  await _scrollToActionListIfNeeded(tester);
  String buildKey(String id) {
    final String normalized = id.startsWith('action-')
        ? id.substring('action-'.length)
        : id;
    return 'select-focus-action-$normalized';
  }

  final Finder selectorByKey = find.byKey(ValueKey<String>(buildKey(actionId)));
  if (selectorByKey.evaluate().isNotEmpty) {
    await tester.ensureVisible(selectorByKey.first);
    await tester.tap(selectorByKey.first);
    return;
  }

  final Finder selectorByTooltip = find.byTooltip('Selecionar para foco');
  if (selectorByTooltip.evaluate().isNotEmpty) {
    await tester.ensureVisible(selectorByTooltip.first);
    await tester.tap(selectorByTooltip.first);
    return;
  }

  final Finder selectorByAnyFocusTooltip = find.byWidgetPredicate(
    (widget) =>
        widget is IconButton &&
        widget.onPressed != null &&
        (widget.tooltip?.contains('foco') ?? false),
  );
  if (selectorByAnyFocusTooltip.evaluate().isNotEmpty) {
    await tester.ensureVisible(selectorByAnyFocusTooltip.first);
    await tester.tap(selectorByAnyFocusTooltip.first);
    return;
  }

  final Finder firstActionCard = find.byType(Dismissible);
  if (firstActionCard.evaluate().isNotEmpty) {
    final Finder fallbackInCard = find.descendant(
      of: firstActionCard.first,
      matching: find.byType(IconButton),
    );
    await tester.tap(fallbackInCard.first);
    return;
  }

  await tester.tap(find.byIcon(Icons.radio_button_unchecked).first);
}

Future<void> _scrollToActionListIfNeeded(WidgetTester tester) async {
  for (int i = 0; i < 8; i++) {
    if (find.byType(Dismissible).evaluate().isNotEmpty) return;
    final Finder scrollable = find.byType(Scrollable);
    if (scrollable.evaluate().isEmpty) return;
    await tester.drag(scrollable.first, const Offset(0, -240));
    await tester.pumpAndSettle();
  }

  if (find.byType(Dismissible).evaluate().isNotEmpty) return;
  if (find.byIcon(Icons.add).evaluate().isEmpty) return;

  await tester.tap(find.byIcon(Icons.add).last);
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).first, 'Acao fallback');
  await tester.tap(find.text('Salvar'));
  await tester.pumpAndSettle();
}

Future<void> _pumpApp(
  WidgetTester tester, {
  required FakeInMemoryGoalsRepository repository,
}) async {
  AppRouter.router.go(AppRoutes.dashboard);
  await tester.pumpWidget(
    MyApp(overrides: [goalsRepositoryProvider.overrideWithValue(repository)]),
  );
}
