class TaskEvent {
  final String id;
  final String taskId;
  final String action; // assigned, claimed, accepted, declined, extension_requested, extension_approved, extension_denied, completed
  final String actorId;
  final String? reason;
  final DateTime timestamp;

  TaskEvent({
    required this.id,
    required this.taskId,
    required this.action,
    required this.actorId,
    this.reason,
    required this.timestamp,
  });

  factory TaskEvent.fromJson(Map<String, dynamic> json) {
    return TaskEvent(
      id: json['id'] as String,
      taskId: json['taskId'] as String,
      action: json['action'] as String,
      actorId: json['actorId'] as String,
      reason: json['reason'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'taskId': taskId,
        'action': action,
        'actorId': actorId,
        'reason': reason,
        'timestamp': timestamp.toIso8601String(),
      };
}
