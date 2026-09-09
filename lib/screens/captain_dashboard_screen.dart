import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../state/task_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_fab.dart';
import '../widgets/responsive_center.dart';
import '../widgets/subteam_multi_select.dart';
import 'create_task_screen.dart';
import 'login_activity_screen.dart';

class CaptainDashboardScreen extends StatefulWidget {
  const CaptainDashboardScreen({super.key});

  @override
  State<CaptainDashboardScreen> createState() => _CaptainDashboardScreenState();
}

class _CaptainDashboardScreenState extends State<CaptainDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskRepository>().loadPendingApprovals();
    });
  }

  Future<void> _confirmRemove(
    TaskRepository repo,
    String userId,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove team member?'),
        content: Text(
          '$name will no longer be able to sign in or appear on the roster.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.statusDeclined,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await repo.removeUser(userId);
    }
  }

  Future<void> _editName(
    TaskRepository repo,
    String userId,
    String currentName,
  ) async {
    final controller = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit name'),
        content: SingleChildScrollView(
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Full name'),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty && newName != currentName) {
      await repo.renameUser(userId, newName);
    }
  }

  Future<void> _editSubteams(
    TaskRepository repo,
    String userId,
    List<Subteam> currentSubteams,
  ) async {
    var selected = Set<Subteam>.from(currentSubteams);
    final newSubteams = await showDialog<Set<Subteam>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit subteams'),
          content: SingleChildScrollView(
            child: SubteamMultiSelect(
              selected: selected,
              onChanged: (next) => setDialogState(() => selected = next),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: selected.isEmpty ? null : () => Navigator.pop(ctx, selected),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (newSubteams != null) {
      await repo.updateUserSubteams(userId, newSubteams.toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<TaskRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('Captain Portal')),
      floatingActionButton: GradientFab(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateTaskScreen()),
        ),
        icon: Icons.add,
        label: 'Assign Task',
      ),
      body: ResponsiveCenter(
        child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader(
            icon: Icons.person_add_alt_1_outlined,
            title: 'Pending approval',
            count: repo.pendingApprovals.length,
          ),
          if (repo.pendingApprovals.isEmpty)
            const _EmptyHint('No new members waiting on approval.')
          else
            ...repo.pendingApprovals.map(
              (u) => Card(
                child: ListTile(
                  title: Text(u.name),
                  subtitle: Text(
                    '${u.email}${u.subteams.isNotEmpty ? " · ${subteamsLabel(u.subteams)}" : ""}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Approve',
                        icon: const Icon(
                          Icons.check_circle_outline,
                          color: AppTheme.statusCompleted,
                        ),
                        onPressed: () => repo.approveUser(u.id),
                      ),
                      IconButton(
                        tooltip: 'Deny',
                        icon: const Icon(
                          Icons.cancel_outlined,
                          color: AppTheme.statusDeclined,
                        ),
                        onPressed: () => _confirmRemove(repo, u.id, u.name),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),
          _SectionHeader(
            icon: Icons.pending_actions,
            title: 'Pending extension requests',
            count: repo.pendingExtensionRequests.length,
          ),
          if (repo.pendingExtensionRequests.isEmpty)
            const _EmptyHint('No pending extension requests.')
          else
            ...repo.pendingExtensionRequests.map((r) {
              final matches = repo.tasks.where((t) => t.id == r.taskId);
              final taskTitle = matches.isEmpty
                  ? r.taskId
                  : matches.first.title;
              return Card(
                child: ListTile(
                  title: Text(taskTitle),
                  subtitle: Text(
                    '${repo.nameFor(r.requestedBy)} wants ${DateFormat.yMMMd().format(r.newDueDate)}\n${r.reason}',
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.check,
                          color: AppTheme.statusCompleted,
                        ),
                        onPressed: () =>
                            repo.decideExtension(r.id, true, 'captain-portal'),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: AppTheme.statusDeclined,
                        ),
                        onPressed: () =>
                            repo.decideExtension(r.id, false, 'captain-portal'),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 24),
          _SectionHeader(
            icon: Icons.groups_outlined,
            title: 'Team roster',
            count: repo.users.length,
          ),
          ...repo.users.map((u) {
            final isSelf = u.id == context.read<AuthService>().currentUser!.id;
            final avatarColor = u.subteams.isNotEmpty
                ? AppTheme.subteamColor(u.subteams.first)
                : AppTheme.onSurfaceMuted;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: avatarColor.withValues(alpha: 0.2),
                          child: Text(
                            u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: avatarColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                u.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                u.email,
                                style: const TextStyle(
                                  color: AppTheme.onSurfaceMuted,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                subteamsLabel(u.subteams),
                                style: const TextStyle(
                                  color: AppTheme.onSurfaceMuted,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Edit name',
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: AppTheme.onSurfaceMuted,
                          ),
                          onPressed: () => _editName(repo, u.id, u.name),
                        ),
                        IconButton(
                          tooltip: 'Edit subteams',
                          icon: const Icon(
                            Icons.groups_2_outlined,
                            size: 18,
                            color: AppTheme.onSurfaceMuted,
                          ),
                          onPressed: () => _editSubteams(repo, u.id, u.subteams),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FilterChip(
                          label: Text(
                            u.role == UserRole.captain ? 'Captain' : 'Member',
                          ),
                          selected: u.role == UserRole.captain,
                          onSelected: (_) => repo.setUserRole(
                            u.id,
                            u.role == UserRole.captain
                                ? UserRole.member
                                : UserRole.captain,
                          ),
                        ),
                        if (!isSelf) ...[
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () => _confirmRemove(repo, u.id, u.name),
                            icon: const Icon(
                              Icons.person_remove_outlined,
                              size: 16,
                              color: AppTheme.statusDeclined,
                            ),
                            label: const Text(
                              'Remove',
                              style: TextStyle(color: AppTheme.statusDeclined),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: AppTheme.statusDeclined,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Login activity'),
              subtitle: const Text(
                'See every account and when they last signed in',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginActivityScreen()),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final int? count;
  const _SectionHeader({required this.icon, required this.title, this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.onSurfaceMuted),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Chip(
              label: Text('$count'),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: const TextStyle(color: AppTheme.onSurfaceMuted)),
    );
  }
}
