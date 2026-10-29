import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:task_tracker/screens/login_screen.dart';
import 'package:task_tracker/services/auth_service.dart';
import 'package:task_tracker/theme/app_theme.dart';

void main() {
  // The whole app can't start in a test: its first step, Google's silent
  // sign-in, needs the phone's plugin and never finishes here. So this
  // checks the screen a logged-out user lands on directly.
  testWidgets('Login screen shows for a logged-out user', (WidgetTester tester) async {
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: MaterialApp(theme: AppTheme.dark, home: const LoginScreen()),
    ));

    expect(find.text('FTC TEAM 13115'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
