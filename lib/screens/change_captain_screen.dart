import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../state/task_repository.dart';
import '../theme/app_theme.dart';

/// Only reachable via the hidden gesture on the Captain Portal's title (see
/// captain_dashboard_screen.dart). Requires the PIN entered there for every
/// change - it's intentionally inconvenient, not a screen to leave open.
class ChangeCaptainScreen extends StatefulWidget {
  final String requesterId;
  final String pin;

  const ChangeCaptainScreen({super.key, required this.requesterId, required this.pin});

  @override
  State<ChangeCaptainScreen> createState() => _ChangeCaptainScreenState();
}

class _ChangeCaptainScreenState extends State<ChangeCaptainScreen> {
  String? _busyUserId;

  Future<void> _toggle(TaskRepository repo, AppUser u) async {
    setState(() => _busyUserId = u.id);
    try {
      await repo.setUserRole(
        u.id,
        u.role == UserRole.captain ? UserRole.member : UserRole.captain,
        requesterId: widget.requesterId,
        pin: widget.pin,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppTheme.statusDeclined),
        );
      }
    } finally {
      if (mounted) setState(() => _busyUserId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<TaskRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('Change Captain')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: repo.users.length,
        itemBuilder: (context, i) {
          final u = repo.users[i];
          final isCaptain = u.role == UserRole.captain;
          return Card(
            child: ListTile(
              title: Text(u.name),
              subtitle: Text(u.email),
              trailing: _busyUserId == u.id
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : FilterChip(
                      label: Text(isCaptain ? 'Captain' : 'Member'),
                      selected: isCaptain,
                      onSelected: (_) => _toggle(repo, u),
                    ),
            ),
          );
        },
      ),
    );
  }
}
