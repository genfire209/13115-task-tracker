import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../state/task_repository.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final ApiService _api = ApiService();

  TaskCategory _category = TaskCategory.mechanical;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  String? _assigneeId; // null = leave open

  List<AppUser> _users = [];
  bool _loadingUsers = true;
  String? _usersError;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _api.fetchUsers();
      setState(() {
        _users = users;
        _loadingUsers = false;
      });
    } catch (e) {
      setState(() {
        _usersError = e.toString();
        _loadingUsers = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<TaskRepository>();
    final user = context.read<AuthService>().currentUser!;

    return Scaffold(
      appBar: AppBar(title: const Text('New Task')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(labelText: 'Description (optional)'),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<TaskCategory>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: TaskCategory.values
                .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                .toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 12),
          if (_loadingUsers) const LinearProgressIndicator(),
          if (_usersError != null)
            Text('Could not load team members: $_usersError', style: const TextStyle(color: Colors.red)),
          if (!_loadingUsers && _usersError == null)
            DropdownButtonFormField<String?>(
              initialValue: _assigneeId,
              decoration: const InputDecoration(labelText: 'Assign to'),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('Leave open (anyone can claim)')),
                ..._users.map((u) => DropdownMenuItem<String?>(value: u.id, child: Text(u.name))),
              ],
              onChanged: (v) => setState(() => _assigneeId = v),
            ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Due: ${DateFormat.yMMMd().format(_dueDate)}'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _dueDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => _dueDate = picked);
            },
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              if (_titleController.text.trim().isEmpty) return;
              repo.createTask(
                title: _titleController.text.trim(),
                description: _descController.text.trim(),
                category: _category,
                createdBy: user.id,
                assignedTo: _assigneeId,
                dueDate: _dueDate,
              );
              Navigator.pop(context);
            },
            child: const Text('Create Task'),
          ),
        ],
      ),
    );
  }
}
