@Tags(['full'])
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quebrando_metas/app/router.dart';
import 'package:quebrando_metas/features/goals/domain/action.dart';
import 'package:quebrando_metas/features/goals/domain/goal.dart';
import 'package:quebrando_metas/features/goals/domain/title_validator.dart';

import '../fakes/fake_in_memory_goals_repository.dart';
import '../support/widget_test_helpers.dart';

void main() {
  testWidgets('Shows prioritized goal in continue section', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, repository: FakeInMemoryGoalsRepository());
    await tester.pumpAndSettle();

    await tapCreateGoalFab(tester);
    await tester.enterText(find.byType(TextField).first, 'Meta prioridade');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    // single-home layout: no tab switch needed

    await tester.pumpAndSettle();
    await tapPriorityForGoal(tester, 'Meta prioridade');
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

    await pumpApp(
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

    await pumpApp(
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

    await pumpApp(
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
      await pumpApp(tester, repository: FakeInMemoryGoalsRepository());
      await tester.pumpAndSettle();

      await tapCreateGoalFab(tester);

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

      expect(find.text('Meta rotacao'), findsAtLeastNWidgets(1));
      expect(find.text('Descricao rotacao'), findsOneWidget);

      tester.view.physicalSize = const Size(500, 900);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      AppRouter.router.go(AppRoutes.goals);
      await tester.pumpAndSettle();
      expect(find.text('Meta rotacao'), findsAtLeastNWidgets(1));
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

    await pumpApp(
      tester,
      repository: FakeInMemoryGoalsRepository(initialGoals: <Goal>[goal]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Meta rotacao acao'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton).last);
    await tester.pumpAndSettle();

    expect(find.textContaining('Nova'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Acao rotacao');
    await tester.pump();

    tester.view.physicalSize = const Size(900, 360);
    await tester.pumpAndSettle();

    expect(find.textContaining('Nova'), findsOneWidget);
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

      await pumpApp(tester, repository: FakeInMemoryGoalsRepository());
      await tester.pumpAndSettle();

      await tapCreateGoalFab(tester);
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
    await pumpApp(tester, repository: FakeInMemoryGoalsRepository());
    await tester.pumpAndSettle();

    await tapCreateGoalFab(tester);
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

    await pumpApp(
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
    await pumpApp(tester, repository: FakeInMemoryGoalsRepository());
    await tester.pumpAndSettle();

    await tapCreateGoalFab(tester);
    await tester.enterText(
      find.byType(TextField).first,
      'Meta prioridade duplicada',
    );
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    // single-home layout: no tab switch needed

    await tester.pumpAndSettle();

    await tapPriorityForGoal(tester, 'Meta prioridade duplicada');
    await tester.pumpAndSettle();
    expect(find.textContaining('Meta adicionada'), findsOneWidget);

    await tapPriorityForGoal(tester, 'Meta prioridade duplicada');
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

    await pumpApp(
      tester,
      repository: FakeInMemoryGoalsRepository(
        initialGoals: <Goal>[goal],
        initialActions: <ActionItem>[action],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Meta prioritaria concluida').last);
    await tester.pumpAndSettle();

    await swipeFirstActionToComplete(tester);

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

      await pumpApp(
        tester,
        repository: FakeInMemoryGoalsRepository(
          initialGoals: <Goal>[completedWithPriority, ...activeGoals],
          initialActions: actions,
        ),
      );
      await tester.pumpAndSettle();
      // single-home layout: no tab switch needed

      await tester.pumpAndSettle();

      await tapPriorityForGoal(tester, 'Nova prioridade 1');
      await tester.pumpAndSettle();
      await tapPriorityForGoal(tester, 'Nova prioridade 2');
      await tester.pumpAndSettle();
      await tapPriorityForGoal(tester, 'Nova prioridade 3');
      await tester.pumpAndSettle();

      expect(find.textContaining('3 metas'), findsNothing);
      // single-home layout: already on home

      await tester.pumpAndSettle();
      expect(find.byTooltip('Remover prioridade'), findsAtLeastNWidgets(2));
    },
  );

  testWidgets('Allows adding an action to a goal that was completed', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, repository: FakeInMemoryGoalsRepository());
    await tester.pumpAndSettle();

    await tapCreateGoalFab(tester);
    await tester.enterText(find.byType(TextField).first, 'Meta reaberta');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    // single-home layout: no tab switch needed

    await tester.pumpAndSettle();
    await tester.tap(find.text('Meta reaberta').first);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton).last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Acao 1');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    await completeFocusForSingleAction(tester);
    await swipeFirstActionToComplete(tester);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.textContaining('1 de 1'), findsOneWidget);

    await tester.tap(find.text('Meta reaberta').first);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton).last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Acao 2');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.textContaining('1 de 2'), findsOneWidget);
    expect(find.text('Meta reaberta'), findsOneWidget);
  });

  testWidgets('Handles very large title/description input without crashing', (
    WidgetTester tester,
  ) async {
    final String hugeTitle = _repeat('T', 200);
    final String hugeDescription = _repeat('D', 600);
    final String hugeActionTitle = _repeat('A', 200);
    final String truncatedTitle = _repeat('T', TitleValidator.maxLength);

    await pumpApp(tester, repository: FakeInMemoryGoalsRepository());
    await tester.pumpAndSettle();

    await tapCreateGoalFab(tester);

    await tester.enterText(find.byType(TextField).at(0), hugeTitle);
    await tester.enterText(find.byType(TextField).at(1), hugeDescription);
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    // single-home layout: no tab switch needed

    await tester.pumpAndSettle();
    expect(find.text(truncatedTitle), findsOneWidget);

    await tester.tap(find.text(truncatedTitle).first);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton).last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, hugeActionTitle);
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Salvar'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

String _repeat(String value, int count) =>
    List<String>.filled(count, value).join();
