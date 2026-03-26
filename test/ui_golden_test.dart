import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quebrando_metas/app/router.dart';
import 'package:quebrando_metas/app/theme/app_theme_settings.dart';
import 'package:quebrando_metas/features/goals/domain/action.dart';
import 'package:quebrando_metas/features/goals/domain/goal.dart';
import 'package:quebrando_metas/features/goals/presentation/goals_controller.dart';
import 'package:quebrando_metas/main.dart';

import 'fakes/fake_in_memory_goals_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Golden - Home dashboard (Sprint 6 UI)', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);

    final DateTime now = DateTime(2026, 3, 19, 10);
    final List<Goal> goals = <Goal>[
      Goal(
        id: 'golden-goal-1',
        title: 'Estudar Flutter',
        description: 'Praticar todos os dias.',
        priorityRank: 1,
        createdAt: now,
        updatedAt: now,
        completedActions: 1,
        totalActions: 3,
        totalFocusMinutes: 35,
      ),
      Goal(
        id: 'golden-goal-2',
        title: 'Melhorar rotina de sono',
        description: null,
        priorityRank: 2,
        createdAt: now.add(const Duration(minutes: 1)),
        updatedAt: now.add(const Duration(minutes: 1)),
        completedActions: 0,
        totalActions: 2,
        totalFocusMinutes: 20,
      ),
      Goal(
        id: 'golden-goal-3',
        title: 'Projeto pessoal',
        description: null,
        priorityRank: 3,
        createdAt: now.add(const Duration(minutes: 2)),
        updatedAt: now.add(const Duration(minutes: 2)),
        completedActions: 2,
        totalActions: 5,
        totalFocusMinutes: 55,
      ),
      Goal(
        id: 'golden-goal-4',
        title: 'Meta nao priorizada',
        description: null,
        createdAt: now.add(const Duration(minutes: 3)),
        updatedAt: now.add(const Duration(minutes: 3)),
        completedActions: 1,
        totalActions: 4,
      ),
    ];
    final List<ActionItem> actions = <ActionItem>[
      ActionItem(
        id: 'golden-goal-1-action-0',
        goalId: 'golden-goal-1',
        title: 'Revisar conceitos',
        isCompleted: true,
        createdAt: now,
        updatedAt: now,
        order: 0,
        totalFocusMinutes: 20,
        completedAt: now,
      ),
      ActionItem(
        id: 'golden-goal-1-action-1',
        goalId: 'golden-goal-1',
        title: 'Construir tela de login',
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
        order: 1,
        totalFocusMinutes: 5,
      ),
      ActionItem(
        id: 'golden-goal-1-action-2',
        goalId: 'golden-goal-1',
        title: 'Refatorar widgets',
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
        order: 2,
        totalFocusMinutes: 10,
      ),
      ActionItem(
        id: 'golden-goal-2-action-0',
        goalId: 'golden-goal-2',
        title: 'Dormir antes das 23h',
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
        order: 0,
      ),
      ActionItem(
        id: 'golden-goal-2-action-1',
        goalId: 'golden-goal-2',
        title: 'Evitar cafe a noite',
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
        order: 1,
      ),
      ActionItem(
        id: 'golden-goal-3-action-0',
        goalId: 'golden-goal-3',
        title: 'Planejar backlog',
        isCompleted: true,
        createdAt: now,
        updatedAt: now,
        order: 0,
        completedAt: now,
      ),
      ActionItem(
        id: 'golden-goal-3-action-1',
        goalId: 'golden-goal-3',
        title: 'Criar prototipo',
        isCompleted: true,
        createdAt: now,
        updatedAt: now,
        order: 1,
        completedAt: now,
      ),
      ActionItem(
        id: 'golden-goal-3-action-2',
        goalId: 'golden-goal-3',
        title: 'Implementar fluxo',
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
        order: 2,
      ),
    ];

    await _setDeterministicTheme();
    await _pumpApp(
      tester,
      repository: FakeInMemoryGoalsRepository(
        initialGoals: goals,
        initialActions: actions,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('priority-content-switcher')), findsOneWidget);
    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('goldens/dashboard_home_sprint6.png'),
    );
  });

  testWidgets('Golden - Goal detail (Sprint 6 UI)', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);

    final DateTime now = DateTime(2026, 3, 19, 11);
    final Goal goal = Goal(
      id: 'golden-detail-goal',
      title: 'Aprender design de produto',
      description: 'Focar em leitura, benchmark e execucao.',
      createdAt: now,
      updatedAt: now,
      completedActions: 1,
      totalActions: 3,
      totalFocusMinutes: 95,
    );
    final List<ActionItem> actions = <ActionItem>[
      ActionItem(
        id: 'golden-detail-action-0',
        goalId: goal.id,
        title: 'Ler estudo de caso',
        isCompleted: true,
        createdAt: now,
        updatedAt: now,
        order: 0,
        totalFocusMinutes: 35,
        completedAt: now,
      ),
      ActionItem(
        id: 'golden-detail-action-1',
        goalId: goal.id,
        title: 'Analisar concorrentes',
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
        order: 1,
        totalFocusMinutes: 25,
      ),
      ActionItem(
        id: 'golden-detail-action-2',
        goalId: goal.id,
        title: 'Desenhar solucao',
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
        order: 2,
        totalFocusMinutes: 35,
      ),
    ];

    await _setDeterministicTheme();
    await _pumpApp(
      tester,
      repository: FakeInMemoryGoalsRepository(
        initialGoals: <Goal>[goal],
        initialActions: actions,
      ),
    );
    await tester.pumpAndSettle();

    AppRouter.router.goNamed(
      'goal-actions',
      pathParameters: {'goalId': goal.id},
    );
    await tester.pumpAndSettle();

    expect(find.text('Ações da meta'), findsOneWidget);
    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('goldens/goal_detail_sprint6.png'),
    );
  });
}

Future<void> _setDeterministicTheme() async {
  final AppThemeSettings settings = AppThemeSettings.instance;
  await settings.setThemeMode(ThemeMode.light);
  await settings.setSeedColor(AppThemeSettings.colorOptions.first.color);
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
