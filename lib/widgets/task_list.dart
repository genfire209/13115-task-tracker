import 'package:flutter/material.dart';

import '../models/task.dart';
import '../theme/app_theme.dart';
import 'task_card.dart';

/// A vertical, fade/slide-in list of [TaskCard]s. Shared by the main task
/// board and the junior dashboard so both get the same look and entrance
/// animation without duplicating it.
class TaskList extends StatefulWidget {
  final List<Task> tasks;
  final String Function(String) nameFor;
  final bool showCategoryLabel;
  final ValueChanged<Task>? onTapTask;

  const TaskList({
    super.key,
    required this.tasks,
    required this.nameFor,
    this.showCategoryLabel = false,
    this.onTapTask,
  });

  @override
  State<TaskList> createState() => _TaskListState();
}

class _TaskListState extends State<TaskList> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void didUpdateWidget(covariant TaskList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tasks.length != widget.tasks.length) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = widget.tasks;
    if (tasks.isEmpty) {
      return const Center(
        child: Text(
          'No tasks here yet.',
          style: TextStyle(color: AppTheme.onSurfaceMuted),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: tasks.length,
      itemBuilder: (context, i) {
        final task = tasks[i];
        final start = (i / tasks.length * 0.6).clamp(0.0, 1.0);
        final end = (start + 0.4).clamp(0.0, 1.0);
        final animation = CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOut),
        );
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) => Opacity(
            opacity: animation.value,
            child: Transform.translate(
              offset: Offset(0, (1 - animation.value) * 16),
              child: child,
            ),
          ),
          child: TaskCard(
            task: task,
            nameFor: widget.nameFor,
            showCategoryLabel: widget.showCategoryLabel,
            onTap: () => widget.onTapTask?.call(task),
          ),
        );
      },
    );
  }
}
