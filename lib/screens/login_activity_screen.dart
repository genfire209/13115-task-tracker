import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../state/task_repository.dart';
import '../theme/app_theme.dart';

/// Shows login activity. Captains see every team member's; everyone else
/// sees only their own (the backend scopes the response by requesterId).
class LoginActivityScreen extends StatefulWidget {
  const LoginActivityScreen({super.key});

  @override
  State<LoginActivityScreen> createState() => _LoginActivityScreenState();
}

class _LoginActivityScreenState extends State<LoginActivityScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthService>().currentUser!.id;
      context.read<TaskRepository>().loadLoginLog(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final loginLog = context.watch<TaskRepository>().loginLog;

    return Scaffold(
      appBar: AppBar(title: const Text('Login Activity')),
      body: loginLog == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  '${loginLog.accountCount} account${loginLog.accountCount == 1 ? '' : 's'} on the team',
                  style: const TextStyle(color: AppTheme.onSurfaceMuted),
                ),
                const SizedBox(height: 12),
                if (loginLog.accounts.isEmpty)
                  const Text('No login activity yet.', style: TextStyle(color: AppTheme.onSurfaceMuted))
                else
                  ...loginLog.accounts.map((a) => Card(
                        child: ListTile(
                          title: Text(a.email),
                          subtitle: Text(a.name),
                          trailing: Text(
                            a.lastLoginAt != null
                                ? DateFormat.MMMd().add_jm().format(a.lastLoginAt!)
                                : 'never',
                            style: const TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 12),
                          ),
                        ),
                      )),
              ],
            ),
    );
  }
}
