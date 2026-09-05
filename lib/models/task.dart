enum TaskCategory { mechanical, outreach, programming }

enum TaskStatus {
  open,
  pendingAcceptance,
  accepted,
  declined,
  inProgress,
  completed,
}

TaskCategory categoryFromString(String s) {
  switch (s) {
    case 'mechanical':
      return TaskCategory.mechanical;
    case 'outreach':
      return TaskCategory.outreach;
    default:
      return TaskCategory.programming;
  }
}

String categoryToString(TaskCategory c) {
  switch (c) {
    case TaskCategory.mechanical:
      return 'mechanical';
    case TaskCategory.outreach:
      return 'outreach';
    case TaskCategory.programming:
      return 'programming';
  }
}

TaskStatus statusFromString(String s) {
  switch (s) {
    case 'open':
      return TaskStatus.open;
    case 'pending_acceptance':
      return TaskStatus.pendingAcceptance;
    case 'accepted':
      return TaskStatus.accepted;
    case 'declined':
      return TaskStatus.declined;
    case 'in_progress':
      return TaskStatus.inProgress;
    default:
      return TaskStatus.completed;
  }
}

String statusToString(TaskStatus s) {
  switch (s) {
    case TaskStatus.open:
      return 'open';
    case TaskStatus.pendingAcceptance:
      return 'pending_acceptance';
    case TaskStatus.accepted:
      return 'accepted';
    case TaskStatus.declined:
      return 'declined';
    case TaskStatus.inProgress:
      return 'in_progress';
    case TaskStatus.completed:
      return 'completed';
  }
}

class Task {
  final String id;
  final String title;
  final String description;
  final TaskCategory category;
  final String createdBy;
  String? assignedTo;
  TaskStatus status;
  DateTime dueDate;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.createdBy,
    this.assignedTo,
    required this.status,
    required this.dueDate,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      category: categoryFromString(json['category'] as String),
      createdBy: json['createdBy'] as String,
      assignedTo: json['assignedTo'] as String?,
      status: statusFromString(json['status'] as String),
      dueDate: DateTime.parse(json['dueDate'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': categoryToString(category),
        'createdBy': createdBy,
        'assignedTo': assignedTo,
        'status': statusToString(status),
        'dueDate': dueDate.toIso8601String(),
      };
}
