import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';

Color statusColor(TaskStatus status) {
  switch (status) {
    case TaskStatus.open:
      return Colors.grey;
    case TaskStatus.pendingAcceptance:
      return Colors.orange;
    case TaskStatus.accepted:
    case TaskStatus.inProgress:
      return const Color(0xFF1976D2);
    case TaskStatus.declined:
      return Colors.red;
    case TaskStatus.completed:
      return Colors.green;
  }
}

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

  const TaskCard({super.key, required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final overdue = task.dueDate.isBefore(DateTime.now()) &&
        task.status != TaskStatus.completed;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: onTap,
        title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.assignedTo != null) Text('Assigned: ${task.assignedTo}'),
            Text(
              'Due ${DateFormat.yMMMd().format(task.dueDate)}',
              style: TextStyle(color: overdue ? Colors.red : Colors.grey[600]),
            ),
          ],
        ),
        trailing: Chip(
          label: Text(statusLabel(task.status),
              style: const TextStyle(color: Colors.white, fontSize: 11)),
          backgroundColor: statusColor(task.status),
          padding: EdgeInsets.zero,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
