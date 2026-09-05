import 'package:flutter/foundation.dart';

import '../models/task.dart';
import '../models/task_event.dart';
import '../models/extension_request.dart';

/// Holds all tasks/events/extension-requests in memory.
///
/// This is a mock data layer seeded from the team's existing planning sheet
/// so the app is usable right away. Once the Azure backend exists, swap the
/// method bodies here to call [ApiService] instead of mutating local lists.
class TaskRepository extends ChangeNotifier {
  final List<Task> _tasks = [];
  final List<TaskEvent> _events = [];
  final List<ExtensionRequest> _extensionRequests = [];

  List<Task> get tasks => List.unmodifiable(_tasks);
  List<TaskEvent> eventsFor(String taskId) =>
      _events.where((e) => e.taskId == taskId).toList();
  List<ExtensionRequest> get pendingExtensionRequests => _extensionRequests
      .where((r) => r.status == ExtensionStatus.pending)
      .toList();

  int _idCounter = 0;
  String _nextId(String prefix) => '$prefix-${_idCounter++}';

  TaskRepository() {
    _seed();
  }

  void _seed() {
    _tasks.addAll([
      Task(
        id: _nextId('task'),
        title: 'Brainstorm Bot Function',
        description: '',
        category: TaskCategory.mechanical,
        createdBy: 'captain',
        assignedTo: 'Cesar Misku',
        status: TaskStatus.inProgress,
        dueDate: DateTime.now().add(const Duration(days: 5)),
      ),
      Task(
        id: _nextId('task'),
        title: 'CAD Chassis',
        description: '',
        category: TaskCategory.mechanical,
        createdBy: 'captain',
        status: TaskStatus.open,
        dueDate: DateTime.now().add(const Duration(days: 10)),
      ),
      Task(
        id: _nextId('task'),
        title: 'Test Robot',
        description: '',
        category: TaskCategory.mechanical,
        createdBy: 'captain',
        assignedTo: 'Avvin Budhiraja',
        status: TaskStatus.pendingAcceptance,
        dueDate: DateTime.now().add(const Duration(days: 14)),
      ),
      Task(
        id: _nextId('task'),
        title: 'Contact Local Businesses',
        description: '',
        category: TaskCategory.outreach,
        createdBy: 'captain',
        status: TaskStatus.completed,
        dueDate: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Task(
        id: _nextId('task'),
        title: 'Reach Out To Other Teams',
        description: '',
        category: TaskCategory.outreach,
        createdBy: 'captain',
        status: TaskStatus.inProgress,
        dueDate: DateTime.now().add(const Duration(days: 7)),
      ),
      Task(
        id: _nextId('task'),
        title: '13115 Website',
        description: 'Published on the 30th',
        category: TaskCategory.programming,
        createdBy: 'captain',
        assignedTo: 'Aarjith Kotilingala',
        status: TaskStatus.inProgress,
        dueDate: DateTime(2026, 9, 30),
      ),
    ]);
  }

  void _logEvent(String taskId, String action, String actorId, {String? reason}) {
    _events.add(TaskEvent(
      id: _nextId('evt'),
      taskId: taskId,
      action: action,
      actorId: actorId,
      reason: reason,
      timestamp: DateTime.now(),
    ));
  }

  Task createTask({
    required String title,
    required String description,
    required TaskCategory category,
    required String createdBy,
    String? assignedTo,
    required DateTime dueDate,
  }) {
    // A member publishing a task they're already doing (assignee == creator)
    // is auto-accepted; a captain assigning to someone else needs their
    // acceptance first.
    final selfPublished = assignedTo != null && assignedTo == createdBy;
    final status = assignedTo == null
        ? TaskStatus.open
        : (selfPublished ? TaskStatus.accepted : TaskStatus.pendingAcceptance);

    final task = Task(
      id: _nextId('task'),
      title: title,
      description: description,
      category: category,
      createdBy: createdBy,
      assignedTo: assignedTo,
      status: status,
      dueDate: dueDate,
    );
    _tasks.add(task);
    _logEvent(
      task.id,
      assignedTo == null
          ? 'created_open'
          : (selfPublished ? 'self_published' : 'assigned'),
      createdBy,
    );
    notifyListeners();
    return task;
  }

  /// A member claims an open task, or publishes a task they're already doing.
  /// Self-claimed work is auto-accepted.
  void claimTask(String taskId, String userName) {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    task.assignedTo = userName;
    task.status = TaskStatus.accepted;
    _logEvent(taskId, 'claimed', userName);
    notifyListeners();
  }

  void acceptTask(String taskId, String userName) {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    task.status = TaskStatus.accepted;
    _logEvent(taskId, 'accepted', userName);
    notifyListeners();
  }

  void declineTask(String taskId, String userName, String reason) {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    task.status = TaskStatus.declined;
    task.assignedTo = null;
    _logEvent(taskId, 'declined', userName, reason: reason);
    notifyListeners();
  }

  void completeTask(String taskId, String userName) {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    task.status = TaskStatus.completed;
    _logEvent(taskId, 'completed', userName);
    notifyListeners();
  }

  ExtensionRequest requestExtension({
    required String taskId,
    required String requestedBy,
    required DateTime newDueDate,
    required String reason,
  }) {
    final req = ExtensionRequest(
      id: _nextId('ext'),
      taskId: taskId,
      requestedBy: requestedBy,
      newDueDate: newDueDate,
      reason: reason,
      status: ExtensionStatus.pending,
    );
    _extensionRequests.add(req);
    _logEvent(taskId, 'extension_requested', requestedBy, reason: reason);
    notifyListeners();
    return req;
  }

  void decideExtension(String extensionId, bool approve, String actorId) {
    final req = _extensionRequests.firstWhere((r) => r.id == extensionId);
    req.status = approve ? ExtensionStatus.approved : ExtensionStatus.denied;
    if (approve) {
      final task = _tasks.firstWhere((t) => t.id == req.taskId);
      task.dueDate = req.newDueDate;
    }
    _logEvent(
      req.taskId,
      approve ? 'extension_approved' : 'extension_denied',
      actorId,
    );
    notifyListeners();
  }
}
