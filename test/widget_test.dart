import 'package:flutter_test/flutter_test.dart';

import 'package:task_tracker/main.dart';

void main() {
  testWidgets('Login screen shows for a logged-out user', (WidgetTester tester) async {
    await tester.pumpWidget(const TaskTrackerApp());

    expect(find.text('FTC TEAM 13115'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
