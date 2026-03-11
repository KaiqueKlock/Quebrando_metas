import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quebrando_metas/features/goals/presentation/goals_controller.dart';
import 'package:quebrando_metas/main.dart';
import 'fakes/fake_in_memory_goals_repository.dart';

void main() {
  testWidgets('Shows empty home state on startup', (WidgetTester tester) async {
    await tester.pumpWidget(
      MyApp(
        overrides: [
          goalsRepositoryProvider
              .overrideWithValue(FakeInMemoryGoalsRepository()),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Quebrando Metas'), findsOneWidget);
    expect(find.text('Ola!'), findsOneWidget);
    expect(find.textContaining('Nenhuma meta ativa'), findsOneWidget);
    expect(find.text('Nova Meta'), findsOneWidget);
  });

  testWidgets('Creates a goal from home form flow', (WidgetTester tester) async {
    await tester.pumpWidget(
      MyApp(
        overrides: [
          goalsRepositoryProvider
              .overrideWithValue(FakeInMemoryGoalsRepository()),
        ],
      ),
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
    await tester.pumpWidget(
      MyApp(
        overrides: [
          goalsRepositoryProvider
              .overrideWithValue(FakeInMemoryGoalsRepository()),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nova Meta'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Meta original');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Meta original'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Meta editada');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Meta editada'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();

    expect(find.text('Meta editada'), findsNothing);
    expect(find.textContaining('Nenhuma meta ativa'), findsOneWidget);
  });
}
