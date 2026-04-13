import 'package:flutter_test/flutter_test.dart';
import 'package:mingpan_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MingPanApp());
    expect(find.text('命盘排盘'), findsOneWidget);
  });
}
