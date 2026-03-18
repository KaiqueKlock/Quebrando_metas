import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
    expect(find.text('Ola!'), findsNothing);
    expect(find.text('Defina uma meta como prioridade.'), findsOneWidget);
    expect(find.byKey(const Key('create-goal-fab')), findsOneWidget);
    expect(find.byKey(const Key('priority-content-switcher')), findsOneWidget);

    await tester.tap(find.text('Suas Metas'));
    await tester.pumpAndSettle();
    expect(find.text('Ola!'), findsOneWidget);
    expect(find.text('Voce tem 0 metas ativas'), findsOneWidget);
  });

  testWidgets('Shows centered create button above navigation bar', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester, repository: FakeInMemoryGoalsRepository());
    await tester.pumpAndSettle();

    final Finder fabFinder = find.byKey(const Key('create-goal-fab'));
    final Finder navFinder = find.byType(NavigationBar);

    final Offset fabCenter = tester.getCenter(fabFinder);
    final double navTop = tester.getTopLeft(navFinder).dy;
    final double screenCenterX =
        tester.getSize(find.byType(MaterialApp).first).width / 2;

    expect((fabCenter.dx - screenCenterX).abs(), lessThanOrEqualTo(2.0));
    expect(fabCenter.dy, lessThan(navTop - 4));
  });

  testWidgets('Create button opens goal form from Suas Metas tab', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester, repository: FakeInMemoryGoalsRepository());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Suas Metas'));
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

    await tester.tap(find.text('Suas Metas'));
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

    await tester.tap(find.text('Suas Metas'));
    await tester.pumpAndSettle();
    expect(find.text('Meta original'), findsOneWidget);

    await tester.ensureVisible(find.byIcon(Icons.more_vert).first);
    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Meta editada');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Meta editada'), findsOneWidget);

    await tester.ensureVisible(find.byIcon(Icons.more_vert).first);
    await tester.tap(find.byIcon(Icons.more_vert).first);
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

    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Acao editada');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Acao editada'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert).first);
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

    await tester.tap(find.byKey(const ValueKey<String>('select-focus-action-focus-test')));
    await tester.pumpAndSettle();

    startFocusButton = tester.widget<FilledButton>(
      find.byKey(const Key('start-focus-button')),
    );
    expect(startFocusButton.onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('start-focus-button')));
    await tester.pumpAndSettle();
    expect(find.text('Escolha a duracao do foco'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('focus-duration-15')));
    await tester.pump();

    expect(find.text('Modo foco'), findsOneWidget);
    expect(find.text('Acao: Acao para foco'), findsOneWidget);
    expect(find.text('Meta: Meta com foco'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    final List<FocusSession> sessions = await repository.listFocusSessions(
      goalId: goal.id,
      actionId: action.id,
    );
    expect(sessions, hasLength(1));
    expect(sessions.first.durationMinutes, 15);
    expect(sessions.first.status, FocusSessionStatus.canceled);
  });

  testWidgets(
    'Shows correct summary for long-time user with many completed and active goals',
    (WidgetTester tester) async {
      final DateTime now = DateTime(2026, 3, 12);
      final List<Goal> seededGoals = <Goal>[];
      final List<ActionItem> seededActions = <ActionItem>[];

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
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Suas Metas'));
      await tester.pumpAndSettle();

      expect(find.text('Metas concluidas: 10'), findsOneWidget);
      expect(find.text('Voce tem 5 metas ativas'), findsOneWidget);
      expect(find.text('Progresso medio: 50%'), findsOneWidget);
    },
  );

  testWidgets('Keeps goals summary fixed while goals list scrolls', (
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

    await tester.tap(find.text('Suas Metas'));
    await tester.pumpAndSettle();

    final Finder summaryFinder = find.text('Metas concluidas: 0');
    final double summaryTopBefore = tester.getTopLeft(summaryFinder).dy;
    final ScrollableState scrollableBefore = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    final double listOffsetBefore = scrollableBefore.position.pixels;

    await tester.drag(
      find.byKey(const Key('goals-list-scroll')),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();

    final double summaryTopAfter = tester.getTopLeft(summaryFinder).dy;
    final ScrollableState scrollableAfter = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    final double listOffsetAfter = scrollableAfter.position.pixels;

    expect((summaryTopAfter - summaryTopBefore).abs(), lessThanOrEqualTo(1.0));
    expect(listOffsetAfter, greaterThan(listOffsetBefore));
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

  testWidgets('Shows prioritized goal in continue section', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester, repository: FakeInMemoryGoalsRepository());
    await tester.pumpAndSettle();

    await _tapCreateGoalFab(tester);
    await tester.enterText(find.byType(TextField).first, 'Meta prioridade');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Suas Metas'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.star_border).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Prioridade 1: Meta prioridade'),
      findsOneWidget,
    );
  });

  testWidgets(
    'Keeps priority items left-aligned with mixed title lengths',
    (WidgetTester tester) async {
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

      final double shortLeft = tester
          .getTopLeft(find.textContaining(shortTitle))
          .dx;
      final double mediumLeft = tester
          .getTopLeft(find.textContaining(mediumTitle))
          .dx;
      final double longLeft = tester
          .getTopLeft(find.textContaining(longTitle))
          .dx;

      expect((shortLeft - mediumLeft).abs(), lessThanOrEqualTo(1.0));
      expect((shortLeft - longLeft).abs(), lessThanOrEqualTo(1.0));
    },
  );

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

      expect(find.text('Meta rotacao'), findsOneWidget);
      expect(find.text('Descricao rotacao'), findsOneWidget);

      tester.view.physicalSize = const Size(500, 900);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      AppRouter.router.go(AppRoutes.goals);
      await tester.pumpAndSettle();
      expect(find.text('Meta rotacao'), findsOneWidget);
    },
  );

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

  testWidgets('Does not overflow pixels on narrow goals list with long title', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(280, 720);

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

    await tester.tap(find.text('Suas Metas'));
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

    await tester.tap(find.text('Suas Metas'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.star_border).first);
    await tester.pumpAndSettle();
    expect(find.text('Meta adicionada as prioridades.'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.star).first);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.star_border), findsOneWidget);

    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();
    expect(find.text('Defina uma meta como prioridade.'), findsOneWidget);
  });

  testWidgets('Handles completing a goal that was prioritized', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester, repository: FakeInMemoryGoalsRepository());
    await tester.pumpAndSettle();

    await _tapCreateGoalFab(tester);
    await tester.enterText(
      find.byType(TextField).first,
      'Meta prioritaria concluida',
    );
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Suas Metas'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.star_border).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Meta prioritaria concluida').first);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add).last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Acao unica');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CheckboxListTile).first);
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('Defina uma meta como prioridade.'), findsOneWidget);
    await tester.tap(find.text('Suas Metas'));
    await tester.pumpAndSettle();
    expect(find.text('Voce tem 0 metas ativas'), findsOneWidget);
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

      await tester.tap(find.text('Suas Metas'));
      await tester.pumpAndSettle();

      await _tapPriorityForGoal(tester, 'Nova prioridade 1');
      await tester.pumpAndSettle();
      await _tapPriorityForGoal(tester, 'Nova prioridade 2');
      await tester.pumpAndSettle();
      await _tapPriorityForGoal(tester, 'Nova prioridade 3');
      await tester.pumpAndSettle();

      expect(find.text('Voce pode priorizar no maximo 3 metas.'), findsNothing);

      await tester.tap(find.text('Dashboard'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Prioridade 1: Nova prioridade 1'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Prioridade 2: Nova prioridade 2'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Prioridade 3: Nova prioridade 3'),
        findsOneWidget,
      );
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

    await tester.tap(find.text('Suas Metas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Meta reaberta').first);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add).last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Acao 1');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CheckboxListTile).first);
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('1 de 1 acoes concluidas'), findsOneWidget);

    await tester.tap(find.text('Meta reaberta').first);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add).last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Acao 2');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('1 de 2 acoes concluidas'), findsOneWidget);
    expect(find.text('Voce tem 1 metas ativas'), findsOneWidget);
  });

  testWidgets('Handles very large title/description input without crashing', (
    WidgetTester tester,
  ) async {
    final String hugeTitle = _repeat('T', 200);
    final String hugeDescription = _repeat('D', 600);
    final String hugeActionTitle = _repeat('A', 200);
    final String truncatedTitle = _repeat('T', TitleValidator.maxLength);
    final String truncatedActionTitle = _repeat('A', TitleValidator.maxLength);

    await _pumpApp(tester, repository: FakeInMemoryGoalsRepository());
    await tester.pumpAndSettle();

    await _tapCreateGoalFab(tester);

    await tester.enterText(find.byType(TextField).at(0), hugeTitle);
    await tester.enterText(find.byType(TextField).at(1), hugeDescription);
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Suas Metas'));
    await tester.pumpAndSettle();
    expect(find.text(truncatedTitle), findsOneWidget);

    await tester.tap(find.text(truncatedTitle).first);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add).last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, hugeActionTitle);
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text(truncatedActionTitle), findsOneWidget);
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
      await tester.tap(find.text('Suas Metas'));
      await tester.pumpAndSettle();

      for (int i = 0; i < 10; i++) {
        await tester.tap(find.text('Meta estabilidade').first);
        await tester.pumpAndSettle();
        expect(find.textContaining('cadastrada'), findsOneWidget);
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

Future<void> _tapCreateGoalFab(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('create-goal-fab')));
  await tester.pumpAndSettle();
}

Future<void> _tapPriorityForGoal(WidgetTester tester, String goalTitle) async {
  final Finder goalTitleFinder = find.text(goalTitle).first;
  await tester.ensureVisible(goalTitleFinder);
  await tester.pumpAndSettle();
  final Finder goalCard = find.ancestor(
    of: goalTitleFinder,
    matching: find.byType(Card),
  );
  final Finder priorityButton = find.descendant(
    of: goalCard,
    matching: find.byTooltip('Definir prioridade'),
  );
  await tester.tap(priorityButton.first);
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
