import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../models/task_event.dart';
import '../services/auth_service.dart';
import '../state/task_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/task_card.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  String get taskId => widget.taskId;
  String? _reassignSelection;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskRepository>().loadEventsForTask(taskId);
    });
  }

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

  /// Used when backing out of a task already in progress: unlike declining
  /// before ever starting, we also need progress/handoff notes to forward to
  /// whoever takes it on next.
  Future<String?> _promptForGiveUp(BuildContext context) {
    final reasonController = TextEditingController();
    final progressController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Can't complete this task?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(labelText: 'Why can\'t you finish it?'),
              autofocus: true,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: progressController,
              decoration: const InputDecoration(
                labelText: 'Progress so far / notes for whoever takes over',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              final progress = progressController.text.trim();
              if (reason.isEmpty || progress.isEmpty) return;
              Navigator.pop(ctx, 'Reason: $reason\nProgress so far: $progress');
            },
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
        final isAssignee = task.assignedTo == user.id; // assignedTo stores the user's id (email)
        final isCaptain = user.hasCaptainAccess;
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
                label: Text(statusLabel(task.status)),
                backgroundColor: AppTheme.statusColor(task.status).withValues(alpha: 0.18),
                labelStyle: TextStyle(
                  color: AppTheme.statusColor(task.status),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              if (task.description.isNotEmpty) ...[
                Text(task.description),
                const SizedBox(height: 12),
              ],
              Text('Assigned to: ${task.assignedTo != null ? repo.nameFor(task.assignedTo!) : "Unassigned"}'),
              Text('Due: ${DateFormat.yMMMd().format(task.dueDate)}'),
              const SizedBox(height: 24),

              // --- Actions available to the current user ---
              if (task.status == TaskStatus.open)
                FilledButton(
                  onPressed: () => repo.claimTask(taskId, user.id),
                  child: const Text('Claim this task'),
                ),

              if (task.status == TaskStatus.pendingAcceptance && isAssignee) ...[
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () => repo.acceptTask(taskId, user.id),
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
                            repo.declineTask(taskId, user.id, reason);
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
                  onPressed: () => repo.completeTask(taskId, user.id),
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
                        requestedBy: user.id,
                        newDueDate: newDate,
                        reason: reason,
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.flag_outlined, color: AppTheme.statusDeclined),
                  label: const Text("Can't complete this",
                      style: TextStyle(color: AppTheme.statusDeclined)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.statusDeclined),
                  ),
                  onPressed: () async {
                    final combined = await _promptForGiveUp(context);
                    if (combined != null) {
                      repo.declineTask(taskId, user.id, combined);
                    }
                  },
                ),
              ],

              if (task.status == TaskStatus.declined) ...[
                _DeclinedTaskSection(
                  repo: repo,
                  events: events,
                  isCaptain: isCaptain,
                  currentUserId: user.id,
                  onApproveVolunteer: (assigneeId) =>
                      repo.approveVolunteer(taskId, user.id, assigneeId),
                  onVolunteer: () => repo.volunteerForTask(taskId, user.id),
                ),
                const SizedBox(height: 8),
              ],

              if (isCaptain && task.status != TaskStatus.completed) ...[
                _CaptainReassignSection(
                  repo: repo,
                  selection: _reassignSelection,
                  onSelectionChanged: (v) => setState(() => _reassignSelection = v),
                  onAssign: (assigneeId) => repo.reassignTask(taskId, user.id, assigneeId),
                ),
                const SizedBox(height: 8),
              ],

              if (isCaptain && pendingExtensions.isNotEmpty) ...[
                const Divider(),
                const Text('Pending extension requests',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...pendingExtensions.map((r) => Card(
                      child: ListTile(
                        title: Text(
                            'New due date: ${DateFormat.yMMMd().format(r.newDueDate)}'),
                        subtitle: Text('${repo.nameFor(r.requestedBy)}: ${r.reason}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: AppTheme.statusCompleted),
                              onPressed: () =>
                                  repo.decideExtension(r.id, true, user.id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: AppTheme.statusDeclined),
                              onPressed: () =>
                                  repo.decideExtension(r.id, false, user.id),
                            ),
                          ],
                        ),
                      ),
                    )),
              ],

              if (events.isNotEmpty) ...[
                const Divider(),
                const Text('History', style: TextStyle(fontWeight: FontWeight.bold)),
                ...events.reversed.map((e) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.circle, size: 8, color: AppTheme.onSurfaceMuted),
                      title: Text('${repo.nameFor(e.actorId)} ${e.action.replaceAll('_', ' ')}'),
                      subtitle: e.reason != null ? Text(e.reason!) : null,
                      trailing: Text(
                        DateFormat.MMMd().add_jm().format(e.timestamp),
                        style: const TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 12),
                      ),
                    )),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Shown on a declined task: who declined it and why, a way for other
/// students to flag they're willing to take it on, and (captain-only) a way
/// to approve one of those volunteers, skipping the redundant accept step
/// since they already asked for it.
class _DeclinedTaskSection extends StatelessWidget {
  final TaskRepository repo;
  final List<TaskEvent> events;
  final bool isCaptain;
  final String currentUserId;
  final ValueChanged<String> onApproveVolunteer;
  final VoidCallback onVolunteer;

  const _DeclinedTaskSection({
    required this.repo,
    required this.events,
    required this.isCaptain,
    required this.currentUserId,
    required this.onApproveVolunteer,
    required this.onVolunteer,
  });

  @override
  Widget build(BuildContext context) {
    final declineEvents = events.where((e) => e.action == 'decline').toList();
    final TaskEvent? declinedBy = declineEvents.isEmpty ? null : declineEvents.last;

    final volunteersByActor = <String, TaskEvent>{};
    for (final e in events.where((e) => e.action == 'volunteer')) {
      volunteersByActor[e.actorId] = e;
    }
    final alreadyVolunteered = volunteersByActor.containsKey(currentUserId);
    final canVolunteer = !isCaptain && currentUserId != declinedBy?.actorId && !alreadyVolunteered;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.info_outline, size: 18, color: AppTheme.statusDeclined),
              SizedBox(width: 8),
              Text('This task was declined', style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          if (declinedBy != null)
            Text(
              '${repo.nameFor(declinedBy.actorId)}: "${declinedBy.reason}"',
              style: const TextStyle(color: AppTheme.onSurfaceMuted),
            ),
          if (canVolunteer) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onVolunteer,
              icon: const Icon(Icons.pan_tool_outlined, size: 16),
              label: const Text("I'll take this on"),
            ),
          ],
          if (alreadyVolunteered && !isCaptain) ...[
            const SizedBox(height: 12),
            const Text(
              "You've let your captain know you're willing to take this on.",
              style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 13),
            ),
          ],
          if (isCaptain && volunteersByActor.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Volunteered to take this on',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 8),
            ...volunteersByActor.keys.map((actorId) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(child: Text(repo.nameFor(actorId))),
                      FilledButton(
                        onPressed: () => onApproveVolunteer(actorId),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: const Text('Approve'),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

/// Captain-only: reassign this task to anyone, regardless of its current
/// status. The new assignee still has to accept, since unlike a volunteer
/// they didn't ask for it.
class _CaptainReassignSection extends StatelessWidget {
  final TaskRepository repo;
  final String? selection;
  final ValueChanged<String?> onSelectionChanged;
  final ValueChanged<String> onAssign;

  const _CaptainReassignSection({
    required this.repo,
    required this.selection,
    required this.onSelectionChanged,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Reassign this task', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: selection,
                  decoration: const InputDecoration(labelText: 'Team member'),
                  items: repo.users
                      .map((u) => DropdownMenuItem(value: u.id, child: Text(u.name)))
                      .toList(),
                  onChanged: onSelectionChanged,
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: selection == null ? null : () => onAssign(selection!),
                child: const Text('Assign'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
