import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';
import '../theme/app_theme.dart';
import 'pulsing_badge.dart';

String statusLabel(TaskStatus status) {
  switch (status) {
    case TaskStatus.open:
      return 'Open';
    case TaskStatus.pendingAcceptance:
      return 'Pending acceptance';
    case TaskStatus.accepted:
      return 'Accepted';
    case TaskStatus.inProgress:
      return 'In progress';
    case TaskStatus.declined:
      return 'Declined';
    case TaskStatus.completed:
      return 'Completed';
  }
}

/// A task in a list: category, status, title, who has it and when it's due.
/// The title always gets the full width; the status chip sits beside the
/// category on the top line and drops below it when there's no room (large
/// text sizes), so nothing gets squeezed into a sliver.
class TaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback onTap;
  final String Function(String userId)? nameFor;
  final bool showCategoryLabel;

  const TaskCard({super.key, required this.task, required this.onTap, this.nameFor, this.showCategoryLabel = false});

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  // Cards only respond to hover on a mouse-driven surface (web/desktop) —
  // touch users never trigger onEnter/onExit, so this is a no-op on phones.
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final overdue = task.dueDate.isBefore(DateTime.now()) && task.status != TaskStatus.completed;
    final categoryColor = AppTheme.categoryColor(task.category);
    final assignee = task.assignedTo == null
        ? null
        : (widget.nameFor != null ? widget.nameFor!(task.assignedTo!) : task.assignedTo!);
    final categoryName = task.category.name;
    final categoryLabel = categoryName[0].toUpperCase() + categoryName.substring(1);
    final hover = _hovering && !reduceMotion;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        offset: hover ? const Offset(0, -0.02) : Offset.zero,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: hover
                ? [BoxShadow(color: categoryColor.withValues(alpha: 0.28), blurRadius: 20, offset: const Offset(0, 8))]
                : const [],
          ),
          child: Card(
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 4,
                        decoration: BoxDecoration(color: categoryColor, borderRadius: BorderRadius.circular(4)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: double.infinity, // full width, so spaceBetween pushes the second item right
                              child: Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  if (widget.showCategoryLabel)
                                    Text(
                                      categoryLabel.toUpperCase(),
                                      style: TextStyle(
                                        color: categoryColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  PulsingBadge(
                                    active: task.status == TaskStatus.pendingAcceptance,
                                    child: _StatusChip(status: task.status),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(task.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                            const SizedBox(height: 6),
                            if (assignee != null)
                              Text(
                                'Assigned: $assignee',
                                style: const TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 13),
                              ),
                            Text(
                              overdue
                                  ? 'Overdue · was due ${DateFormat.yMMMd().format(task.dueDate)}'
                                  : 'Due ${DateFormat.yMMMd().format(task.dueDate)}',
                              style: TextStyle(
                                color: overdue ? AppTheme.statusDeclined : AppTheme.onSurfaceMuted,
                                fontSize: 13,
                                fontWeight: overdue ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final TaskStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(20)),
      child: Text(
        statusLabel(status),
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
