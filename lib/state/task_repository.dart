import 'package:flutter/foundation.dart';

import '../models/task.dart';
import '../models/task_event.dart';
import '../models/extension_request.dart';
import '../services/api_service.dart';

/// Loads and mutates tasks/events/extension-requests via [ApiService],
/// caching the results locally so the UI has something to render between
/// network round-trips.
class TaskRepository extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Task> _tasks = [];
  final Map<String, List<TaskEvent>> _eventsByTask = {};
  List<ExtensionRequest> _pendingExtensionRequests = [];

  bool isLoading = false;
  String? loadError;

  List<Task> get tasks => List.unmodifiable(_tasks);
  List<TaskEvent> eventsFor(String taskId) => List.unmodifiable(_eventsByTask[taskId] ?? const []);
  List<ExtensionRequest> get pendingExtensionRequests => List.unmodifiable(_pendingExtensionRequests);

  Future<void> loadAll() async {
    isLoading = true;
    loadError = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _api.fetchTasks(),
        _api.fetchPendingExtensionRequests(),
      ]);
      _tasks = results[0] as List<Task>;
      _pendingExtensionRequests = results[1] as List<ExtensionRequest>;
    } catch (e) {
      loadError = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadEventsForTask(String taskId) async {
    _eventsByTask[taskId] = await _api.fetchTaskEvents(taskId);
    notifyListeners();
  }

  Future<Task> createTask({
    required String title,
    required String description,
    required TaskCategory category,
    required String createdBy,
    String? assignedTo,
    required DateTime dueDate,
  }) async {
    final task = await _api.createTask(
      title: title,
      description: description,
      category: category,
      createdBy: createdBy,
      assignedTo: assignedTo,
      dueDate: dueDate,
    );
    await loadAll();
    return task;
  }

  /// A member claims an open task, or publishes a task they're already doing.
  Future<void> claimTask(String taskId, String userName) async {
    await _api.updateTask(taskId: taskId, action: 'claim', actorId: userName);
    await loadAll();
  }

  Future<void> acceptTask(String taskId, String userName) async {
    await _api.updateTask(taskId: taskId, action: 'accept', actorId: userName);
    await loadAll();
  }

  Future<void> declineTask(String taskId, String userName, String reason) async {
    await _api.updateTask(taskId: taskId, action: 'decline', actorId: userName, reason: reason);
    await loadAll();
  }

  Future<void> completeTask(String taskId, String userName) async {
    await _api.updateTask(taskId: taskId, action: 'complete', actorId: userName);
    await loadAll();
  }

  Future<void> requestExtension({
    required String taskId,
    required String requestedBy,
    required DateTime newDueDate,
    required String reason,
  }) async {
    await _api.requestExtension(
      taskId: taskId,
      requestedBy: requestedBy,
      newDueDate: newDueDate,
      reason: reason,
    );
    await loadAll();
  }

  Future<void> decideExtension(String extensionId, bool approve, String actorId) async {
    await _api.decideExtension(extensionId: extensionId, approve: approve, actorId: actorId);
    await loadAll();
  }
}
