import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../services/auth_service.dart';
import '../state/task_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/active_meet_banner.dart';
import '../widgets/gear_spinner.dart';
import '../widgets/gradient_fab.dart';
import '../widgets/responsive_center.dart';
import '../widgets/task_list.dart';
import 'create_task_screen.dart';
import 'task_detail_screen.dart';

/// The Tasks tab. Captains/admins get one tab per category; members get
/// every task in one list with its category on each card. Pull down to
/// refresh; the other sections (Meets, Team, Profile) live in the bottom
/// tab bar (see HomeScreen).
class TaskBoardScreen extends StatefulWidget {
  const TaskBoardScreen({super.key});

  @override
  State<TaskBoardScreen> createState() => _TaskBoardScreenState();
}

class _TaskBoardScreenState extends State<TaskBoardScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _myTasksOnly = false;
  bool _hideCompleted = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskRepository>().loadAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      var tasks = category == null ? repo.tasks : repo.tasks.where((t) => t.category == category);
      if (_myTasksOnly) {
        tasks = tasks.where((t) => t.assignedTo == user.id);
      }
      if (_hideCompleted) {
        tasks = tasks.where((t) => t.status != TaskStatus.completed);
      }
      return tasks.toList();
    }

    final emptyMessage = isCaptain
        ? 'No tasks here yet. Tap Assign task to add one.'
        : 'No tasks here yet. Tap Publish task to add one, or pull down to refresh.';
    Widget list(TaskCategory? category) => ResponsiveCenter(
          child: TaskList(
            tasks: filterFor(category),
            nameFor: repo.nameFor,
            showCategoryLabel: category == null,
            onTapTask: _openTask,
            onRefresh: repo.loadAll,
            emptyMessage: emptyMessage,
          ),
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
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
          const ActiveMeetBanner(),
          Container(
            width: double.infinity, // chips line up with the cards' left edge
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('My tasks'),
                  selected: _myTasksOnly,
                  onSelected: (v) => setState(() => _myTasksOnly = v),
                ),
                FilterChip(
                  label: const Text('Hide completed'),
                  selected: _hideCompleted,
                  onSelected: (v) => setState(() => _hideCompleted = v),
                ),
              ],
            ),
          ),
          if (repo.isLoading && repo.tasks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: GearSpinner(color: AppTheme.primary, size: 24),
            ),
          if (repo.loadError != null)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                "Couldn't load tasks. Check your connection, then pull down to try again.",
                style: TextStyle(color: AppTheme.statusDeclined),
              ),
            ),
          Expanded(
            child: isCaptain
                ? TabBarView(
                    controller: _tabController,
                    children: [
                      list(TaskCategory.mechanical),
                      list(TaskCategory.outreach),
                      list(TaskCategory.programming),
                    ],
                  )
                : list(null),
          ),
        ],
      ),
      floatingActionButton: GradientFab(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateTaskScreen()),
        ),
        icon: Icons.add,
        label: isCaptain ? 'Assign task' : 'Publish task',
      ),
    );
  }
}
