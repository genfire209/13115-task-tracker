import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';
import '../theme/app_theme.dart';

String statusLabel(TaskStatus status) {
  switch (status) {
    case TaskStatus.open:
      return 'Open';
    case TaskStatus.pendingAcceptance:
      return 'Pending Acceptance';
    case TaskStatus.accepted:
      return 'Accepted';
    case TaskStatus.inProgress:
      return 'In Progress';
    case TaskStatus.declined:
      return 'Declined';
    case TaskStatus.completed:
      return 'Completed';
  }
}

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final String Function(String userId)? nameFor;
  final bool showCategoryLabel;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    this.nameFor,
    this.showCategoryLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final overdue = task.dueDate.isBefore(DateTime.now()) &&
        task.status != TaskStatus.completed;
    final categoryColor = AppTheme.categoryColor(task.category);
    final assignee = task.assignedTo == null
        ? null
        : (nameFor != null ? nameFor!(task.assignedTo!) : task.assignedTo!);
    final categoryName = task.category.name;
    final categoryLabel = categoryName[0].toUpperCase() + categoryName.substring(1);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 44,
                decoration: BoxDecoration(
                  color: categoryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showCategoryLabel) ...[
                      Text(
                        categoryLabel.toUpperCase(),
                        style: TextStyle(
                          color: categoryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      task.title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 6),
                    if (assignee != null)
                      Text('Assigned: $assignee',
                          style: const TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 13)),
                    Text(
                      'Due ${DateFormat.yMMMd().format(task.dueDate)}',
                      style: TextStyle(
                        color: overdue ? AppTheme.statusDeclined : AppTheme.onSurfaceMuted,
                        fontSize: 13,
                        fontWeight: overdue ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text(statusLabel(task.status)),
                backgroundColor: AppTheme.statusColor(task.status).withValues(alpha: 0.18),
                labelStyle: TextStyle(
                  color: AppTheme.statusColor(task.status),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
