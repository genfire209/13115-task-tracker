import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/task.dart';
import '../models/task_event.dart';
import '../models/extension_request.dart';
import '../models/user.dart';

/// Thin wrapper around the deployed Azure App Service backend.
class ApiService {
  static const String baseUrl = 'https://app-13115-tasktracker.azurewebsites.net/api';

  Future<AppUser> login({
    required String provider,
    required String idToken,
    String? name,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'provider': provider, 'idToken': idToken, 'name': name}),
    );
    if (res.statusCode >= 400) {
      throw Exception('Login failed: ${res.body}');
    }
    return AppUser.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<Task>> fetchTasks() async {
    final res = await http.get(Uri.parse('$baseUrl/tasks'));
    final List<dynamic> data = jsonDecode(res.body) as List<dynamic>;
    return data.map((j) => Task.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<List<TaskEvent>> fetchTaskEvents(String taskId) async {
    final res = await http.get(Uri.parse('$baseUrl/tasks/$taskId/events'));
    final List<dynamic> data = jsonDecode(res.body) as List<dynamic>;
    return data.map((j) => TaskEvent.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<List<AppUser>> fetchUsers() async {
    final res = await http.get(Uri.parse('$baseUrl/users'));
    final List<dynamic> data = jsonDecode(res.body) as List<dynamic>;
    return data.map((j) => AppUser.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<AppUser> completeProfile({
    required String userId,
    required String name,
    required Subteam subteam,
  }) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/users/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'subteam': subteamToString(subteam)}),
    );
    if (res.statusCode >= 400) {
      throw Exception('Failed to complete profile: ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return AppUser(
      id: userId,
      name: name,
      email: userId,
      authProvider: 'google',
      role: UserRole.values.firstWhere(
        (r) => (r == UserRole.captain ? 'captain' : 'member') == data['role'],
        orElse: () => UserRole.member,
      ),
      subteam: subteam,
    );
  }

  Future<void> setUserRole({required String userId, required UserRole role}) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/users/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'role': role == UserRole.captain ? 'captain' : 'member'}),
    );
    if (res.statusCode >= 400) {
      throw Exception('Failed to update role: ${res.body}');
    }
  }

  Future<void> removeUser(String userId) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/users/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'banned': true}),
    );
    if (res.statusCode >= 400) {
      throw Exception('Failed to remove team member: ${res.body}');
    }
  }

  Future<LoginLog> fetchLoginLog({required String requesterId}) async {
    final res = await http.get(Uri.parse('$baseUrl/users/login-log?requesterId=$requesterId'));
    if (res.statusCode >= 400) {
      throw Exception('Failed to load login log: ${res.body}');
    }
    return LoginLog.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<Task> createTask({
    required String title,
    required String description,
    required TaskCategory category,
    required String createdBy,
    String? assignedTo,
    required DateTime dueDate,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/tasks'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'description': description,
        'category': categoryToString(category),
        'createdBy': createdBy,
        'assignedTo': assignedTo,
        'dueDate': dueDate.toIso8601String(),
      }),
    );
    if (res.statusCode >= 400) {
      throw Exception('Failed to create task: ${res.body}');
    }
    return Task.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// action: 'claim' | 'accept' | 'decline' | 'complete' | 'reassign' | 'volunteer'
  Future<void> updateTask({
    required String taskId,
    required String action,
    required String actorId,
    String? reason,
    String? newAssigneeId,
  }) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/tasks/$taskId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'action': action,
        'actorId': actorId,
        'reason': reason,
        'newAssigneeId': newAssigneeId,
      }),
    );
    if (res.statusCode >= 400) {
      throw Exception('Failed to update task: ${res.body}');
    }
  }

  Future<ExtensionRequest> requestExtension({
    required String taskId,
    required String requestedBy,
    required DateTime newDueDate,
    required String reason,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/extension-requests'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'taskId': taskId,
        'requestedBy': requestedBy,
        'newDueDate': newDueDate.toIso8601String(),
        'reason': reason,
      }),
    );
    if (res.statusCode >= 400) {
      throw Exception('Failed to request extension: ${res.body}');
    }
    return ExtensionRequest.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<ExtensionRequest>> fetchPendingExtensionRequests() async {
    final res = await http.get(Uri.parse('$baseUrl/extension-requests?status=pending'));
    final List<dynamic> data = jsonDecode(res.body) as List<dynamic>;
    return data.map((j) => ExtensionRequest.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<void> decideExtension({
    required String extensionId,
    required bool approve,
    required String actorId,
  }) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/extension-requests/$extensionId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': approve ? 'approved' : 'denied', 'actorId': actorId}),
    );
    if (res.statusCode >= 400) {
      throw Exception('Failed to decide extension: ${res.body}');
    }
  }
}
