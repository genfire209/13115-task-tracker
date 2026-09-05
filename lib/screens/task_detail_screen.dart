import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../state/task_repository.dart';
import '../widgets/task_card.dart';

class TaskDetailScreen extends StatelessWidget {
  final String taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  Future<String?> _promptForReason(BuildContext context, String title) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Reason'),
          autofocus: true,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<DateTime?> _promptForDate(BuildContext context, DateTime initial) {
    return showDatePicker(
      context: context,
      initialDate: initial.add(const Duration(days: 3)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<TaskRepository, AuthService>(
      builder: (context, repo, auth, _) {
        final task = repo.tasks.firstWhere((t) => t.id == taskId);
        final user = auth.currentUser!;
        final isAssignee = task.assignedTo == user.name;
        final isCaptain = user.role == UserRole.captain;
        final events = repo.eventsFor(taskId);
        final pendingExtensions = repo.pendingExtensionRequests
            .where((r) => r.taskId == taskId)
            .toList();

        return Scaffold(
          appBar: AppBar(title: Text(task.title)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Chip(
                label: Text(statusLabel(task.status),
                    style: const TextStyle(color: Colors.white)),
                backgroundColor: statusColor(task.status),
              ),
              const SizedBox(height: 12),
              if (task.description.isNotEmpty) ...[
                Text(task.description),
                const SizedBox(height: 12),
              ],
              Text('Assigned to: ${task.assignedTo ?? "Unassigned"}'),
              Text('Due: ${DateFormat.yMMMd().format(task.dueDate)}'),
              const SizedBox(height: 24),

              // --- Actions available to the current user ---
              if (task.status == TaskStatus.open)
                FilledButton(
                  onPressed: () => repo.claimTask(taskId, user.name),
                  child: const Text('Claim this task'),
                ),

              if (task.status == TaskStatus.pendingAcceptance && isAssignee) ...[
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () => repo.acceptTask(taskId, user.name),
                        child: const Text('Accept'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final reason = await _promptForReason(
                              context, 'Why are you declining?');
                          if (reason != null && reason.isNotEmpty) {
                            repo.declineTask(taskId, user.name, reason);
                          }
                        },
                        child: const Text('Decline'),
                      ),
                    ),
                  ],
                ),
              ],

              if ((task.status == TaskStatus.accepted ||
                      task.status == TaskStatus.inProgress) &&
                  isAssignee) ...[
                FilledButton(
                  onPressed: () => repo.completeTask(taskId, user.name),
                  child: const Text('Mark Completed'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.schedule),
                  label: const Text('Request Extension'),
                  onPressed: () async {
                    final newDate = await _promptForDate(context, task.dueDate);
                    if (newDate == null || !context.mounted) return;
                    final reason = await _promptForReason(
                        context, 'Why do you need more time?');
                    if (reason != null && reason.isNotEmpty) {
                      repo.requestExtension(
                        taskId: taskId,
                        requestedBy: user.name,
                        newDueDate: newDate,
                        reason: reason,
                      );
                    }
                  },
                ),
              ],

              if (isCaptain && pendingExtensions.isNotEmpty) ...[
                const Divider(height: 32),
                const Text('Pending extension requests',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...pendingExtensions.map((r) => Card(
                      child: ListTile(
                        title: Text(
                            'New due date: ${DateFormat.yMMMd().format(r.newDueDate)}'),
                        subtitle: Text('${r.requestedBy}: ${r.reason}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () =>
                                  repo.decideExtension(r.id, true, user.name),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () =>
                                  repo.decideExtension(r.id, false, user.name),
                            ),
                          ],
                        ),
                      ),
                    )),
              ],

              if (events.isNotEmpty) ...[
                const Divider(height: 32),
                const Text('History', style: TextStyle(fontWeight: FontWeight.bold)),
                ...events.reversed.map((e) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.circle, size: 8),
                      title: Text('${e.actorId} ${e.action.replaceAll('_', ' ')}'),
                      subtitle: e.reason != null ? Text(e.reason!) : null,
                      trailing: Text(DateFormat.MMMd().add_jm().format(e.timestamp)),
                    )),
              ],
            ],
          ),
        );
      },
    );
  }
}
