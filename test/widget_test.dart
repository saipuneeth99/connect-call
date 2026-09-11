import 'package:flutter_test/flutter_test.dart';
import 'package:connect_call/app/app.dart';

void main() {
  testWidgets('App builds without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const ConnectCallApp());
    // Verify splash screen renders
    expect(find.text('ConnectCall'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
