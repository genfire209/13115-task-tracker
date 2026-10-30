import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app_version.dart';
import 'notification_routing.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'state/task_repository.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/pending_approval_screen.dart';
import 'screens/update_required_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/gear_spinner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await NotificationService.initializeFirebase();
  await AppVersion.load();
  runApp(const TaskTrackerApp());
  unawaited(AppVersion.check());
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
        navigatorKey: NotificationService.navigatorKey,
        home: const _RootRouter(),
        // A build the server no longer allows is locked until it's updated.
        builder: lockWhenUpdateRequired,
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
  StreamSubscription<Map<String, dynamic>>? _tapSub;
  // Re-checks the required build whenever the app comes back to the
  // foreground, since it can sit open across a release.
  late final AppLifecycleListener _lifecycle;
  bool _pendingHandled = false;

  @override
  void initState() {
    super.initState();
    context.read<AuthService>().tryRestoreSession();
    _lifecycle = AppLifecycleListener(onResume: AppVersion.check);
    // Taps that happen while the app is already running.
    _tapSub = NotificationService.onNotificationTap.listen((data) {
      if (mounted && _readyForDeepLink()) handleNotificationTap(data);
    });
  }

  @override
  void dispose() {
    _tapSub?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  /// Only deep-link once the user is past login/onboarding/approval — a
  /// TaskDetailScreen pushed before then would have no data and nowhere sane
  /// to pop back to.
  bool _readyForDeepLink() {
    final auth = context.read<AuthService>();
    if (auth.isRestoring || !auth.isLoggedIn) return false;
    final user = auth.currentUser!;
    return user.subteams.isNotEmpty && user.approved;
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

    // Now that the user is fully in, follow any notification tap that
    // cold-launched the app. Runs after this frame so the board (which
    // kicks off the task load) is mounted first.
    if (!_pendingHandled) {
      _pendingHandled = true;
      final pending = NotificationService.takePending();
      if (pending != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          handleNotificationTap(pending);
        });
      }
    }

    // Tabs for each section; juniors get the smaller set (see HomeScreen).
    return const HomeScreen();
  }
}
