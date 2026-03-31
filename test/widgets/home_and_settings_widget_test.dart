@Tags(['full'])
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quebrando_metas/app/app_usage_settings.dart';
import 'package:quebrando_metas/app/onboarding_status.dart';
import 'package:quebrando_metas/app/router.dart';
import 'package:quebrando_metas/app/theme/app_theme_settings.dart';
import 'package:quebrando_metas/features/goals/domain/action.dart';
import 'package:quebrando_metas/features/goals/domain/goal.dart';

import '../fakes/fake_in_memory_goals_repository.dart';
import '../support/widget_test_helpers.dart';

void main() {
  testWidgets('Shows empty home state on startup', (WidgetTester tester) async {
    await pumpApp(tester, repository: FakeInMemoryGoalsRepository());
    await tester.pumpAndSettle();

    expect(find.text('Quebrando Metas'), findsOneWidget);
    expect(find.byIcon(Icons.waving_hand_outlined), findsOneWidget);
    expect(find.text('Defina uma meta como prioridade.'), findsOneWidget);
    expect(find.byKey(const Key('create-goal-fab')), findsOneWidget);
    expect(find.byKey(const Key('priority-content-switcher')), findsOneWidget);
    // single-home layout: no tab switch needed

    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.waving_hand_outlined), findsOneWidget);
    expect(find.text('Suas Metas'), findsOneWidget);
  });

  testWidgets('Shows create button on single-home layout', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, repository: FakeInMemoryGoalsRepository());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('create-goal-fab')), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('Create button opens goal form on single-home layout', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, repository: FakeInMemoryGoalsRepository());
    await tester.pumpAndSettle();
    // single-home layout: no tab switch needed

    await tester.pumpAndSettle();
    await tapCreateGoalFab(tester);

    expect(find.text('Nova Meta'), findsOneWidget);
    expect(find.text('Salvar'), findsOneWidget);
  });

  testWidgets('Opens theme drawer and toggles theme mode with icon', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, repository: FakeInMemoryGoalsRepository());
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
    await pumpApp(tester, repository: FakeInMemoryGoalsRepository());
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

    await pumpApp(tester, repository: FakeInMemoryGoalsRepository());
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

  testWidgets('Toggles focus mode from drawer', (WidgetTester tester) async {
    await AppUsageSettings.instance.setFocusModeEnabled(true);
    addTearDown(() async {
      await AppUsageSettings.instance.setFocusModeEnabled(true);
    });

    await pumpApp(tester, repository: FakeInMemoryGoalsRepository());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('toggle-focus-mode-switch')), findsOneWidget);
    expect(find.text('Ativado'), findsOneWidget);

    await tester.tap(find.byKey(const Key('toggle-focus-mode-switch')));
    await tester.pumpAndSettle();

    expect(AppUsageSettings.instance.isFocusModeEnabled, isFalse);
    expect(find.text('Desativado'), findsOneWidget);
  });

  testWidgets('Shows checklist metrics chip when focus mode is disabled', (
    WidgetTester tester,
  ) async {
    await AppUsageSettings.instance.setFocusModeEnabled(false);
    addTearDown(() async {
      await AppUsageSettings.instance.setFocusModeEnabled(true);
    });

    final DateTime now = DateTime(2026, 3, 30, 8, 0);
    final Goal goal = Goal(
      id: 'goal-hours-focus-disabled',
      title: 'Meta com horas',
      description: null,
      createdAt: now,
      updatedAt: now,
      completedActions: 0,
      totalActions: 1,
    );
    final ActionItem action = ActionItem(
      id: 'action-hours-focus-disabled',
      goalId: goal.id,
      title: 'Acao com horas',
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
      order: 0,
      totalFocusMinutes: 90,
    );

    await pumpApp(
      tester,
      repository: FakeInMemoryGoalsRepository(
        initialGoals: <Goal>[goal],
        initialActions: <ActionItem>[action],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1.5 horas'), findsNothing);
    expect(find.byIcon(Icons.timer_outlined), findsNothing);
    expect(find.text('0 ações hoje'), findsOneWidget);
    expect(find.byIcon(Icons.task_alt_outlined), findsOneWidget);

    AppRouter.router.goNamed(
      'goal-actions',
      pathParameters: {'goalId': goal.id},
    );
    await tester.pumpAndSettle();

    expect(find.text('Tempo de foco: 1h 30min'), findsOneWidget);
  });

  testWidgets('Updates daily completed actions chip after checklist confirm', (
    WidgetTester tester,
  ) async {
    await AppUsageSettings.instance.setFocusModeEnabled(false);
    addTearDown(() async {
      await AppUsageSettings.instance.setFocusModeEnabled(true);
    });

    final DateTime now = DateTime(2026, 3, 30, 8, 0);
    final Goal goal = Goal(
      id: 'goal-checklist-daily-chip',
      title: 'Meta checklist diaria',
      description: null,
      createdAt: now,
      updatedAt: now,
      completedActions: 0,
      totalActions: 1,
    );
    final ActionItem action = ActionItem(
      id: 'action-checklist-daily-chip',
      goalId: goal.id,
      title: 'Acao checklist diaria',
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

    expect(find.text('0 ações hoje'), findsOneWidget);

    AppRouter.router.goNamed(
      'goal-actions',
      pathParameters: {'goalId': goal.id},
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        const ValueKey<String>(
          'confirm-daily-action-action-checklist-daily-chip',
        ),
      ),
    );
    await tester.pumpAndSettle();

    AppRouter.router.go(AppRoutes.dashboard);
    await tester.pumpAndSettle();

    expect(find.text('1 ação hoje'), findsOneWidget);
    expect(find.text('0.0 horas'), findsNothing);
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

    await pumpApp(tester, repository: FakeInMemoryGoalsRepository());
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
    await pumpApp(tester, repository: FakeInMemoryGoalsRepository());
    await tester.pumpAndSettle();

    await tapCreateGoalFab(tester);

    expect(find.text('Nova Meta'), findsOneWidget);
    expect(find.text('Salvar'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Meta de teste');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    // single-home layout: no tab switch needed

    await tester.pumpAndSettle();

    expect(find.text('Meta de teste'), findsAtLeastNWidgets(1));
  });

  testWidgets('Edits and deletes a goal from Suas Metas card menu', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, repository: FakeInMemoryGoalsRepository());
    await tester.pumpAndSettle();

    await tapCreateGoalFab(tester);
    await tester.enterText(find.byType(TextField).first, 'Meta original');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    // single-home layout: no tab switch needed

    await tester.pumpAndSettle();
    expect(find.text('Meta original'), findsAtLeastNWidgets(1));

    await openGoalMenuForTitle(tester, 'Meta original');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Meta editada');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Meta editada'), findsAtLeastNWidgets(1));

    await openGoalMenuForTitle(tester, 'Meta editada');
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
    final FakeInMemoryGoalsRepository repository = FakeInMemoryGoalsRepository(
      initialGoals: <Goal>[goal],
    );
    await pumpApp(tester, repository: repository);
    await tester.pumpAndSettle();

    AppRouter.router.goNamed(
      'goal-actions',
      pathParameters: {'goalId': goal.id},
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Meta com acoes'), findsAtLeastNWidgets(1));
    expect(find.textContaining('Descri'), findsOneWidget);
    expect(find.textContaining('Sem descri'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton).last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Primeira acao');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Primeira acao'), findsAtLeastNWidgets(1));

    await openActionMenuForTitle(tester, 'Primeira acao');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Acao editada');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Acao editada'), findsAtLeastNWidgets(1));

    await openActionMenuForTitle(tester, 'Acao editada');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    expect(find.text('Acao editada'), findsNothing);
  });
}
