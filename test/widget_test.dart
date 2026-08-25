// Basic smoke test: verifies the app boots and the dashboard renders.
import 'package:flutter_test/flutter_test.dart';

import 'package:integriscan/main.dart';

void main() {
  testWidgets('App boots and shows the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const IntegriScanApp());

    expect(find.text('IntegriScan'), findsOneWidget);
  });
}
