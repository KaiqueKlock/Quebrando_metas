import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quebrando_metas/app/router.dart';
import 'package:quebrando_metas/features/goals/domain/action.dart';
import 'package:quebrando_metas/features/goals/domain/goal.dart';
import 'package:quebrando_metas/features/goals/domain/title_validator.dart';
import 'package:quebrando_metas/features/goals/presentation/goals_controller.dart';
import 'package:quebrando_metas/main.dart';
import 'fakes/fake_in_memory_goals_repository.dart';

void main() {
  testWidgets('Shows empty home state on startup', (WidgetTester tester) async {
    await _pumpApp(
      tester,
      repository: FakeInMemoryGoalsRepository(),
    );
    await tester.pumpAndSettle();

    expect(find.text('Quebrando Metas'), findsOneWidget);
    expect(find.text('Ola!'), findsOneWidget);
    expect(find.textContaining('Nenhuma meta ativa'), findsOneWidget);
    expect(find.text('Nova Meta'), findsOneWidget);
  });

  testWidgets('Creates a goal from home form flow', (WidgetTester tester) async {
    await _pumpApp(
      tester,
      repository: FakeInMemoryGoalsRepository(),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nova Meta'));
    await tester.pumpAndSettle();

    expect(find.text('Nova Meta'), findsOneWidget);
    expect(find.text('Salvar'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Meta de teste');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Meta de teste'), findsOneWidget);
  });

  testWidgets('Edits and deletes a goal from home card menu', (WidgetTester tester) async {
    await _pumpApp(
      tester,
      repository: FakeInMemoryGoalsRepository(),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nova Meta'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Meta original');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Meta original'), findsOneWidget);

    await tester.drag(find.byType(ListView).first, const Offset(0, -160));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byIcon(Icons.more_vert).first);
    await tester.ensureVisible(find.byIcon(Icons.more_vert).first);
    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Meta editada');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Meta editada'), findsOneWidget);

    await tester.ensureVisible(find.byIcon(Icons.more_vert).first);
    await tester.ensureVisible(find.byIcon(Icons.more_vert).first);
    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();

    expect(find.text('Meta editada'), findsNothing);
    expect(find.textContaining('Nenhuma meta ativa'), findsOneWidget);
  });

  testWidgets('Creates, edits and deletes actions for a goal', (WidgetTester tester) async {
    await _pumpApp(
      tester,
      repository: FakeInMemoryGoalsRepository(),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nova Meta'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Meta com acoes');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continuar').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Ações: Meta com acoes'), findsOneWidget);
    expect(find.text('Descricao da meta'), findsOneWidget);
    expect(find.text('Sem descricao para esta meta.'), findsOneWidget);

    await tester.tap(find.text('Nova Ação'));
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

      expect(find.text('Metas concluidas: 10'), findsOneWidget);
      expect(find.text('Voce tem 5 metas ativas'), findsOneWidget);
      expect(find.text('Progresso medio: 50%'), findsOneWidget);
    },
  );

  testWidgets('Shows goal description section on actions page', (WidgetTester tester) async {
    await _pumpApp(
      tester,
      repository: FakeInMemoryGoalsRepository(),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nova Meta'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Meta com descricao');
    await tester.enterText(find.byType(TextFormField).at(1), 'Descricao de teste');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continuar').first);
    await tester.pumpAndSettle();

    expect(find.text('Descricao da meta'), findsOneWidget);
    expect(find.text('Descricao de teste'), findsOneWidget);
  });

  testWidgets('Handles very large title/description input without crashing', (
    WidgetTester tester,
  ) async {
    final String hugeTitle = _repeat('T', 200);
    final String hugeDescription = _repeat('D', 600);
    final String hugeActionTitle = _repeat('A', 200);
    final String truncatedTitle = _repeat('T', TitleValidator.maxLength);
    final String truncatedActionTitle = _repeat('A', TitleValidator.maxLength);

    await _pumpApp(
      tester,
      repository: FakeInMemoryGoalsRepository(),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nova Meta'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), hugeTitle);
    await tester.enterText(find.byType(TextFormField).at(1), hugeDescription);
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text(truncatedTitle), findsOneWidget);

    await tester.tap(find.text('Continuar').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nova Ação'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, hugeActionTitle);
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text(truncatedActionTitle), findsOneWidget);
  });

  testWidgets('Does not show retry state after returning from goal screen multiple times', (
    WidgetTester tester,
  ) async {
    await _pumpApp(
      tester,
      repository: FakeInMemoryGoalsRepository(),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nova Meta'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Meta estabilidade');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    for (int i = 0; i < 10; i++) {
      await tester.tap(find.text('Continuar').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('cadastrada'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Tentar novamente'), findsNothing);
      expect(find.text('Meta estabilidade'), findsOneWidget);
    }
  });
}

String _repeat(String value, int count) => List<String>.filled(count, value).join();

Future<void> _pumpApp(
  WidgetTester tester, {
  required FakeInMemoryGoalsRepository repository,
}) async {
  AppRouter.router.go(AppRoutes.dashboard);
  await tester.pumpWidget(
    MyApp(
      overrides: [
        goalsRepositoryProvider.overrideWithValue(repository),
      ],
    ),
  );
}
