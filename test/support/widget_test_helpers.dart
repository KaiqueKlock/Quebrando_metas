import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quebrando_metas/app/router.dart';
import 'package:quebrando_metas/features/goals/domain/focus_session.dart';
import 'package:quebrando_metas/features/goals/presentation/goals_controller.dart';
import 'package:quebrando_metas/main.dart';

import '../fakes/fake_in_memory_goals_repository.dart';

FocusSession completedSession({
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

Future<void> tapCreateGoalFab(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('create-goal-fab')));
  await tester.pumpAndSettle();
}

int readFocusCountdownSeconds(WidgetTester tester) {
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

Future<void> completeFocusForSingleAction(WidgetTester tester) async {
  await scrollToActionListIfNeeded(tester);
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

Future<void> swipeFirstActionToComplete(WidgetTester tester) async {
  await tester.drag(find.byType(Dismissible).first, const Offset(500, 0));
  await tester.pumpAndSettle();
}

Future<void> tapPriorityForGoal(WidgetTester tester, String goalTitle) async {
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

Future<void> openActionMenuForTitle(
  WidgetTester tester,
  String actionTitle,
) async {
  await scrollToActionListIfNeeded(tester);
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

Future<void> openGoalMenuForTitle(WidgetTester tester, String goalTitle) async {
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

Future<void> selectFocusForAction(WidgetTester tester, String actionId) async {
  await scrollToActionListIfNeeded(tester);
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

Future<void> scrollToActionListIfNeeded(WidgetTester tester) async {
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

Future<void> pumpApp(
  WidgetTester tester, {
  required FakeInMemoryGoalsRepository repository,
}) async {
  AppRouter.router.go(AppRoutes.dashboard);
  await tester.pumpWidget(
    MyApp(overrides: [goalsRepositoryProvider.overrideWithValue(repository)]),
  );
}

Future<void> pumpUi(
  WidgetTester tester, [
  Duration duration = const Duration(milliseconds: 300),
]) async {
  await tester.pump();
  await tester.pump(duration);
}
