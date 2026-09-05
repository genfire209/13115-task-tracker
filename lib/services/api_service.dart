import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/task.dart';
import '../models/extension_request.dart';

/// Thin wrapper around the Azure Functions backend.
///
/// TODO: set [baseUrl] to your deployed Azure Function App, e.g.
/// "https://task-tracker-13115.azurewebsites.net/api"
class ApiService {
  static const String baseUrl = 'https://REPLACE-ME.azurewebsites.net/api';

  Future<List<Task>> fetchTasks() async {
    final res = await http.get(Uri.parse('$baseUrl/tasks'));
    final List<dynamic> data = jsonDecode(res.body) as List<dynamic>;
    return data.map((j) => Task.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<Task> createTask(Task task) async {
    final res = await http.post(
      Uri.parse('$baseUrl/tasks'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(task.toJson()),
    );
    return Task.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> updateTaskStatus({
    required String taskId,
    required String status,
    String? reason,
  }) async {
    await http.patch(
      Uri.parse('$baseUrl/tasks/$taskId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': status, 'reason': reason}),
    );
  }

  Future<ExtensionRequest> requestExtension(ExtensionRequest req) async {
    final res = await http.post(
      Uri.parse('$baseUrl/extension-requests'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(req.toJson()),
    );
    return ExtensionRequest.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> decideExtension({
    required String extensionId,
    required bool approve,
  }) async {
    await http.patch(
      Uri.parse('$baseUrl/extension-requests/$extensionId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': approve ? 'approved' : 'denied'}),
    );
  }
}
