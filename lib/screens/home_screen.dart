import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import 'captain_dashboard_screen.dart';
import 'junior_dashboard_screen.dart';
import 'meets_screen.dart';
import 'profile_screen.dart';
import 'task_board_screen.dart';
import 'team_roster_screen.dart';

/// The signed-in app: a bottom tab bar for the top-level sections (HIG: a
/// tab bar for navigation, kept visible), instead of a row of icon-only
/// buttons crowded into the task board's title bar.
///
///   Members:  Tasks · Meets · Team (roster) · Profile
///   Captains/admins: Team opens the Captain portal
///   Juniors:  Tasks (just theirs) · Meets · Profile — no roster
///
/// Each tab keeps its place while you visit the others; a tab's screen is
/// only built the first time it's opened.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  final _opened = <int>{0};

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser!;
    final junior = user.isJunior && !user.hasCaptainAccess;

    final tabs = <(NavigationDestination, Widget)>[
      (
        const NavigationDestination(icon: Icon(Icons.checklist_outlined), selectedIcon: Icon(Icons.checklist), label: 'Tasks'),
        junior ? const JuniorDashboardScreen() : const TaskBoardScreen(),
      ),
      (
        const NavigationDestination(
          icon: Icon(Icons.emoji_events_outlined),
          selectedIcon: Icon(Icons.emoji_events),
          label: 'Meets',
        ),
        const MeetsScreen(),
      ),
      if (!junior)
        (
          const NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Team'),
          user.hasCaptainAccess ? const CaptainDashboardScreen() : const TeamRosterScreen(),
        ),
      (
        const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        const ProfileScreen(),
      ),
    ];
    final index = _index.clamp(0, tabs.length - 1);

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: [
          for (var i = 0; i < tabs.length; i++) _opened.contains(i) ? tabs[i].$2 : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() {
          _index = i;
          _opened.add(i);
        }),
        destinations: [for (final t in tabs) t.$1],
      ),
    );
  }
}
