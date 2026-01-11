import 'package:flutter_test/flutter_test.dart';

import 'package:sms_grouping_app/main.dart';

void main() {
  testWidgets('SMS Grouping App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SmsGroupingApp());

    // Verify that app starts properly
    expect(find.byType(SmsGroupingApp), findsOneWidget);
  });
}