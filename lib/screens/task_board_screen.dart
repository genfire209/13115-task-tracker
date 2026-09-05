import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../state/task_repository.dart';
import '../widgets/task_card.dart';
import 'create_task_screen.dart';
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

    List<Task> filterFor(TaskCategory category) {
      var tasks = repo.tasks.where((t) => t.category == category);
      if (_myTasksOnly) {
        tasks = tasks.where((t) => t.assignedTo == user.id);
      }
      return tasks.toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('13115 Task Tracker'),
        actions: [
          // Dev-only role switch until real roles come from the backend.
          IconButton(
            tooltip: isCaptain ? 'Viewing as Captain (tap to switch)' : 'Viewing as Member (tap to switch)',
            icon: Icon(isCaptain ? Icons.shield : Icons.person),
            onPressed: auth.toggleRoleForTesting,
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mechanical'),
            Tab(text: 'Outreach'),
            Tab(text: 'Programming'),
          ],
        ),
      ),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('My tasks only'),
            value: _myTasksOnly,
            onChanged: (v) => setState(() => _myTasksOnly = v),
          ),
          if (repo.isLoading) const LinearProgressIndicator(),
          if (repo.loadError != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Could not load tasks: ${repo.loadError}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TaskList(tasks: filterFor(TaskCategory.mechanical)),
                _TaskList(tasks: filterFor(TaskCategory.outreach)),
                _TaskList(tasks: filterFor(TaskCategory.programming)),
              ],
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
  const _TaskList({required this.tasks});

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const Center(child: Text('No tasks here yet.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: tasks.length,
      itemBuilder: (context, i) {
        final task = tasks[i];
        return TaskCard(
          task: task,
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
