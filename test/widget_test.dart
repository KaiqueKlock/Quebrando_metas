import 'package:flutter_test/flutter_test.dart';
import 'package:quebrando_metas/main.dart';

void main() {
  testWidgets('Shows home summary and goals list on startup', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Quebrando Metas'), findsOneWidget);
    expect(find.text('Ola!'), findsOneWidget);
    expect(find.text('Suas metas'), findsOneWidget);
    expect(find.text('Nova Meta'), findsOneWidget);
  });
}
