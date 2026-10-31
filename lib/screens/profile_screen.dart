import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_version.dart';
import '../models/user.dart';
import '../services/api_service.dart';
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
            if (user.isAdmin) ...[
              const SizedBox(height: 24),
              const RequiredVersionCard(),
            ],
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

/// Admins only: make everyone on an older build update before they can use
/// the app again. One build number, enforced the same way for iOS, Android
/// and the web build alike - so "require build N" locks out stragglers on
/// all three at once, not just whichever platform this is opened from. Only
/// up to the build this device is running, so it can't require one that
/// isn't out yet.
class RequiredVersionCard extends StatefulWidget {
  const RequiredVersionCard({super.key});

  @override
  State<RequiredVersionCard> createState() => _RequiredVersionCardState();
}

class _RequiredVersionCardState extends State<RequiredVersionCard> {
  int? _minimum;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final minimum = await ApiService().fetchMinimumBuild();
      if (mounted) setState(() => _minimum = minimum);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not check the required version');
    }
  }

  Future<void> _require(int build) async {
    final lockingOut = build > (_minimum ?? 0);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(lockingOut ? 'Require build $build?' : 'Allow older builds?'),
        content: Text(lockingOut
            ? 'Anyone on an older build is locked out until they update - on iOS, Android '
                'and the web app alike. Only do this once build $build has gone out '
                'everywhere: approved for testers in TestFlight, rolled out on the Play '
                'Store, and redeployed to the website.'
            : 'Every build will work again, including old ones.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(lockingOut ? 'Require update' : 'Allow'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ApiService().setMinimumBuild(build);
      if (mounted) setState(() => _minimum = build);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final minimum = _minimum;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Required app version', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 4),
            Text(
              'This app: build ${AppVersion.build}. Required: '
              '${minimum == null ? '…' : minimum == 0 ? 'any build' : 'build $minimum or newer'}.',
              style: const TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 13),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppTheme.statusDeclined, fontSize: 13)),
            ],
            if (minimum != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (minimum < AppVersion.build)
                    FilledButton(
                      onPressed: _saving ? null : () => _require(AppVersion.build),
                      child: Text('Require build ${AppVersion.build}'),
                    ),
                  if (minimum > 0)
                    TextButton(
                      onPressed: _saving ? null : () => _require(0),
                      child: const Text('Allow older builds'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
