import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'state/task_repository.dart';
import 'screens/junior_dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/pending_approval_screen.dart';
import 'screens/task_board_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/gear_spinner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await NotificationService.initializeFirebase();
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

class _RootRouter extends StatefulWidget {
  const _RootRouter();

  @override
  State<_RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<_RootRouter> {
  @override
  void initState() {
    super.initState();
    context.read<AuthService>().tryRestoreSession();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    if (auth.isRestoring) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: GearSpinner(size: 48, color: AppTheme.primary)),
      );
    }
    if (!auth.isLoggedIn) return const LoginScreen();
    final user = auth.currentUser!;
    if (user.subteams.isEmpty) return const OnboardingScreen();
    if (!user.approved) return const PendingApprovalScreen();
    // Admins/captains always get the full portal, even if isJunior was ever
    // mistakenly set on their account.
    if (user.isJunior && !user.hasCaptainAccess) return const JuniorDashboardScreen();
    return const TaskBoardScreen();
  }
}
