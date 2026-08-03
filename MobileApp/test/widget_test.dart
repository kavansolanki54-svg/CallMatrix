import 'package:flutter_test/flutter_test.dart';
import 'package:call_matrix_mobile/main.dart';

void main() {
  testWidgets('CallMatrixApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CallMatrixApp());
    expect(find.text('CallMatrix'), findsOneWidget);
  });
}
