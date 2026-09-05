import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'services/auth_service.dart';
import 'state/task_repository.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/pending_approval_screen.dart';
import 'screens/task_board_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const TaskTrackerApp());
}

class TaskTrackerApp extends StatelessWidget {
  const TaskTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => TaskRepository()),
      ],
      child: MaterialApp(
        title: '13115 Robotics',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const _RootRouter(),
      ),
    );
  }
}

class _RootRouter extends StatelessWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    if (!auth.isLoggedIn) return const LoginScreen();
    final user = auth.currentUser!;
    if (user.subteam == null) return const OnboardingScreen();
    if (!user.approved) return const PendingApprovalScreen();
    return const TaskBoardScreen();
  }
}
