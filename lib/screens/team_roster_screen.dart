import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/task_repository.dart';
import '../theme/app_theme.dart';

/// Read-only roster for every team member: names only, no email, role, or
/// management actions (that's the captain-only dashboard).
class TeamRosterScreen extends StatelessWidget {
  const TeamRosterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final users = context.watch<TaskRepository>().users;
    return Scaffold(
      appBar: AppBar(title: const Text('Team Roster')),
      body: users.isEmpty
          ? const Center(
              child: Text('No team members yet.', style: TextStyle(color: AppTheme.onSurfaceMuted)),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: users.length,
              itemBuilder: (context, i) {
                final u = users[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.surfaceVariant,
                    child: Text(
                      u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  title: Text(u.name),
                );
              },
            ),
    );
  }
}
