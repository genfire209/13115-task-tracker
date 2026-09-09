import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../state/task_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/gear_spinner.dart';
import '../widgets/responsive_center.dart';
import '../widgets/subteam_multi_select.dart';
import '../widgets/task_list.dart';
import 'task_detail_screen.dart';

/// Portal for junior-team members (freshmen proving their commitment before
/// joining the main roster). Deliberately much smaller than TaskBoardScreen:
/// only the tasks a captain assigned directly to them, no full task board,
/// no team roster, and no self-service claiming/volunteering — those stay
/// gated in TaskDetailScreen even if reached some other way.
class JuniorDashboardScreen extends StatefulWidget {
  const JuniorDashboardScreen({super.key});

  @override
  State<JuniorDashboardScreen> createState() => _JuniorDashboardScreenState();
}

class _JuniorDashboardScreenState extends State<JuniorDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskRepository>().loadAll();
    });
  }

  Future<void> _editMySubteams(AuthService auth) async {
    var selected = Set<Subteam>.from(auth.currentUser!.subteams);
    final newSubteams = await showDialog<Set<Subteam>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('My subteam(s)'),
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
      await auth.updateMySubteams(newSubteams.toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final repo = context.watch<TaskRepository>();
    final user = auth.currentUser!;
    final myTasks = repo.tasks.where((t) => t.assignedTo == user.id).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('13115 Task Tracker'),
        actions: [
          IconButton(
            tooltip: 'My Subteam(s)',
            icon: const Icon(Icons.groups_2_outlined),
            onPressed: () => _editMySubteams(auth),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: repo.loadAll),
          IconButton(icon: const Icon(Icons.logout), onPressed: auth.signOut),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppTheme.onSurfaceMuted),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Junior team — tasks a captain assigns you show up here.',
                    style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          if (repo.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: GearSpinner(color: AppTheme.primary, size: 24),
            ),
          if (repo.loadError != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Could not load tasks: ${repo.loadError}',
                style: const TextStyle(color: AppTheme.statusDeclined),
              ),
            ),
          Expanded(
            child: ResponsiveCenter(
              child: TaskList(
                tasks: myTasks,
                nameFor: repo.nameFor,
                showCategoryLabel: true,
                onTapTask: (task) => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: task.id)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
