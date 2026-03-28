@Tags(['full'])
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_in_memory_goals_repository.dart';
import 'support/widget_test_helpers.dart';

void main() {
  testWidgets('Legacy widget entrypoint remains valid', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, repository: FakeInMemoryGoalsRepository());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('create-goal-fab')), findsOneWidget);
  });
}




