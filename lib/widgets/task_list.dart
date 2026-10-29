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
  /// Pull-to-refresh; also lets an empty list be pulled.
  final Future<void> Function()? onRefresh;
  /// Shown when there are no tasks; should say what to do next.
  final String emptyMessage;

  const TaskList({
    super.key,
    required this.tasks,
    required this.nameFor,
    this.showCategoryLabel = false,
    this.onTapTask,
    this.onRefresh,
    this.emptyMessage = 'No tasks here yet.',
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
    );
  }

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduce Motion: no entrance animation at all (not even running unseen).
    if (_reduceMotion) {
      _controller.value = 1;
    } else if (_controller.isDismissed) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant TaskList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tasks.length != widget.tasks.length && !_reduceMotion) {
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
    final reduceMotion = _reduceMotion;
    final Widget list;
    if (tasks.isEmpty) {
      // Still a scrollable, so the empty state can be pulled to refresh.
      list = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(32, 64, 32, 96),
        children: [
          Text(
            widget.emptyMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.onSurfaceMuted),
          ),
        ],
      );
    } else {
      list = ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        // Bottom room so the floating "add task" button never covers the last card.
        padding: const EdgeInsets.only(top: 8, bottom: 96),
        itemCount: tasks.length,
        itemBuilder: (context, i) {
          final task = tasks[i];
          final card = TaskCard(
            task: task,
            nameFor: widget.nameFor,
            showCategoryLabel: widget.showCategoryLabel,
            onTap: () => widget.onTapTask?.call(task),
          );
          if (reduceMotion) return card;
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
            child: card,
          );
        },
      );
    }
    if (widget.onRefresh == null) return list;
    return RefreshIndicator(onRefresh: widget.onRefresh!, child: list);
  }
}
