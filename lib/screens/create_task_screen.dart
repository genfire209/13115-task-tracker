import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../services/auth_service.dart';
import '../state/task_repository.dart';
import '../theme/app_theme.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  TaskCategory _category = TaskCategory.mechanical;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  String? _assigneeId; // null = leave open (captain only)

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<TaskRepository>();
    final user = context.read<AuthService>().currentUser!;
    final isCaptain = user.hasCaptainAccess;

    return Scaffold(
      appBar: AppBar(title: Text(isCaptain ? 'Assign Task' : 'Publish Task')),
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
                .map((c) => DropdownMenuItem(
                      value: c,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppTheme.categoryColor(c),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(c.name),
                        ],
                      ),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 12),
          if (isCaptain)
            DropdownButtonFormField<String?>(
              initialValue: _assigneeId,
              decoration: const InputDecoration(labelText: 'Assign to'),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('Leave open (anyone can claim)')),
                ...repo.users.map((u) => DropdownMenuItem<String?>(value: u.id, child: Text(u.name))),
              ],
              onChanged: (v) => setState(() => _assigneeId = v),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: const [
                  Icon(Icons.person_outline, size: 18, color: AppTheme.onSurfaceMuted),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This task will be published as yours and auto-accepted.',
                      style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 13),
                    ),
                  ),
                ],
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
                createdBy: user.id,
                assignedTo: isCaptain ? _assigneeId : user.id,
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
