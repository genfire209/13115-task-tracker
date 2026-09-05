import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
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
  final _assigneeController = TextEditingController();
  TaskCategory _category = TaskCategory.mechanical;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));

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
          TextField(
            controller: _assigneeController,
            decoration: const InputDecoration(
              labelText: 'Assign to (leave blank to leave it open)',
            ),
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
                createdBy: user.name,
                assignedTo: _assigneeController.text.trim().isEmpty
                    ? null
                    : _assigneeController.text.trim(),
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
