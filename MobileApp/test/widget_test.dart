import 'package:flutter_test/flutter_test.dart';
import 'package:call_alyze_mobile/main.dart';

void main() {
  testWidgets('CallalyzeApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CallalyzeApp());
    expect(find.text('Callalyze'), findsOneWidget);
  });
}
