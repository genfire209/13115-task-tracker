import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../state/task_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/gear_spinner.dart';
import '../widgets/gradient_fab.dart';
import '../widgets/responsive_center.dart';
import '../widgets/subteam_multi_select.dart';
import '../widgets/task_list.dart';
import 'captain_dashboard_screen.dart';
import 'create_task_screen.dart';
import 'task_detail_screen.dart';
import 'team_roster_screen.dart';

class TaskBoardScreen extends StatefulWidget {
  const TaskBoardScreen({super.key});

  @override
  State<TaskBoardScreen> createState() => _TaskBoardScreenState();
}

class _TaskBoardScreenState extends State<TaskBoardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _myTasksOnly = false;
  bool _pendingOnly = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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

  void _openTask(Task task) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: task.id)),
      );

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final repo = context.watch<TaskRepository>();
    final user = auth.currentUser!;
    final isCaptain = user.hasCaptainAccess;

    List<Task> filterFor(TaskCategory? category) {
      var tasks = category == null
          ? repo.tasks
          : repo.tasks.where((t) => t.category == category);
      if (_myTasksOnly) {
        tasks = tasks.where((t) => t.assignedTo == user.id);
      }
      if (_pendingOnly) {
        tasks = tasks.where((t) => t.status != TaskStatus.completed);
      }
      return tasks.toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('13115 Task Tracker'),
        actions: [
          if (isCaptain)
            IconButton(
              tooltip: 'Captain Portal',
              icon: const Icon(Icons.admin_panel_settings_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CaptainDashboardScreen(),
                ),
              ),
            ),
          if (!isCaptain)
            IconButton(
              tooltip: 'Team Roster',
              icon: const Icon(Icons.people_outline),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TeamRosterScreen()),
              ),
            ),
          IconButton(
            tooltip: 'My Subteam(s)',
            icon: const Icon(Icons.groups_2_outlined),
            onPressed: () => _editMySubteams(auth),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: repo.loadAll),
          IconButton(icon: const Icon(Icons.logout), onPressed: auth.signOut),
        ],
        bottom: isCaptain
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Mechanical'),
                  Tab(text: 'Outreach'),
                  Tab(text: 'Programming'),
                ],
              )
            : null,
      ),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('My tasks only'),
            value: _myTasksOnly,
            onChanged: (v) => setState(() => _myTasksOnly = v),
          ),
          SwitchListTile(
            title: const Text('Pending only'),
            subtitle: const Text('Hide completed tasks'),
            value: _pendingOnly,
            onChanged: (v) => setState(() => _pendingOnly = v),
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
            child: isCaptain
                ? TabBarView(
                    controller: _tabController,
                    children: [
                      ResponsiveCenter(
                        child: TaskList(
                          tasks: filterFor(TaskCategory.mechanical),
                          nameFor: repo.nameFor,
                          onTapTask: _openTask,
                        ),
                      ),
                      ResponsiveCenter(
                        child: TaskList(
                          tasks: filterFor(TaskCategory.outreach),
                          nameFor: repo.nameFor,
                          onTapTask: _openTask,
                        ),
                      ),
                      ResponsiveCenter(
                        child: TaskList(
                          tasks: filterFor(TaskCategory.programming),
                          nameFor: repo.nameFor,
                          onTapTask: _openTask,
                        ),
                      ),
                    ],
                  )
                : ResponsiveCenter(
                    child: TaskList(
                      tasks: filterFor(null),
                      nameFor: repo.nameFor,
                      showCategoryLabel: true,
                      onTapTask: _openTask,
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: GradientFab(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateTaskScreen()),
        ),
        icon: Icons.add,
        label: isCaptain ? 'Assign Task' : 'Publish Task',
      ),
    );
  }
}
