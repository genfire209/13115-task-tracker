import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../state/task_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/task_card.dart';
import 'captain_dashboard_screen.dart';
import 'create_task_screen.dart';
import 'login_activity_screen.dart';
import 'task_detail_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final repo = context.watch<TaskRepository>();
    final user = auth.currentUser!;
    final isCaptain = user.role == UserRole.captain;

    List<Task> filterFor(TaskCategory? category) {
      var tasks = category == null ? repo.tasks : repo.tasks.where((t) => t.category == category);
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
                MaterialPageRoute(builder: (_) => const CaptainDashboardScreen()),
              ),
            ),
          IconButton(
            tooltip: 'Login Activity',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginActivityScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: repo.loadAll,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: auth.signOut,
          ),
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
          if (repo.isLoading) const LinearProgressIndicator(),
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
                      _TaskList(tasks: filterFor(TaskCategory.mechanical), nameFor: repo.nameFor),
                      _TaskList(tasks: filterFor(TaskCategory.outreach), nameFor: repo.nameFor),
                      _TaskList(tasks: filterFor(TaskCategory.programming), nameFor: repo.nameFor),
                    ],
                  )
                : _TaskList(
                    tasks: filterFor(null),
                    nameFor: repo.nameFor,
                    showCategoryLabel: true,
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateTaskScreen()),
        ),
        icon: const Icon(Icons.add),
        label: Text(isCaptain ? 'Assign Task' : 'Publish Task'),
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  final List<Task> tasks;
  final String Function(String) nameFor;
  final bool showCategoryLabel;
  const _TaskList({required this.tasks, required this.nameFor, this.showCategoryLabel = false});

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const Center(
        child: Text('No tasks here yet.', style: TextStyle(color: AppTheme.onSurfaceMuted)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: tasks.length,
      itemBuilder: (context, i) {
        final task = tasks[i];
        return TaskCard(
          task: task,
          nameFor: nameFor,
          showCategoryLabel: showCategoryLabel,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TaskDetailScreen(taskId: task.id),
            ),
          ),
        );
      },
    );
  }
}
