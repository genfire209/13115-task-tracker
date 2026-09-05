import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/auth_service.dart';
import 'state/task_repository.dart';
import 'screens/login_screen.dart';
import 'screens/task_board_screen.dart';

void main() {
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
        title: '13115 Task Tracker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFFC8102E),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFC8102E),
            foregroundColor: Colors.white,
          ),
        ),
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
    return auth.isLoggedIn ? const TaskBoardScreen() : const LoginScreen();
  }
}
