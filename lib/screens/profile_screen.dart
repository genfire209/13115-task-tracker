import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_center.dart';
import '../widgets/subteam_multi_select.dart';

/// Your account: who you're signed in as, your subteams (editable), and
/// sign out. These used to be icon-only buttons in the task board's title
/// bar, next to refresh, where sign out was one mis-tap away.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _editSubteams(BuildContext context, AuthService auth) async {
    var selected = Set<Subteam>.from(auth.currentUser!.subteams);
    final newSubteams = await showDialog<Set<Subteam>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Subteams'),
          content: SingleChildScrollView(
            child: SubteamMultiSelect(
              selected: selected,
              onChanged: (next) => setDialogState(() => selected = next),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: selected.isEmpty ? null : () => Navigator.pop(ctx, selected),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (newSubteams != null) {
      await auth.updateMySubteams(newSubteams.toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser!;
    final roles = [
      if (user.role == UserRole.captain) 'Captain',
      if (user.isAdmin) 'Admin',
      if (user.isJunior) 'Junior team' else 'Main team',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ResponsiveCenter(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppTheme.primaryFill,
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(user.email, style: const TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 13)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: roles.map((r) => Chip(label: Text(r))).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(
                  child: Text('Subteams', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
                TextButton.icon(
                  onPressed: () => _editSubteams(context, auth),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: user.subteams
                  .map((s) => Chip(
                        avatar: CircleAvatar(backgroundColor: AppTheme.subteamColor(s), radius: 6),
                        label: Text(subteamLabel(s)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 40),
            OutlinedButton.icon(
              onPressed: auth.signOut,
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}
