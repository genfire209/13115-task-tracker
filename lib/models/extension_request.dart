enum ExtensionStatus { pending, approved, denied }

ExtensionStatus extensionStatusFromString(String s) {
  switch (s) {
    case 'approved':
      return ExtensionStatus.approved;
    case 'denied':
      return ExtensionStatus.denied;
    default:
      return ExtensionStatus.pending;
  }
}

String extensionStatusToString(ExtensionStatus s) {
  switch (s) {
    case ExtensionStatus.approved:
      return 'approved';
    case ExtensionStatus.denied:
      return 'denied';
    case ExtensionStatus.pending:
      return 'pending';
  }
}

class ExtensionRequest {
  final String id;
  final String taskId;
  final String requestedBy;
  final DateTime newDueDate;
  final String reason;
  ExtensionStatus status;

  ExtensionRequest({
    required this.id,
    required this.taskId,
    required this.requestedBy,
    required this.newDueDate,
    required this.reason,
    required this.status,
  });

  factory ExtensionRequest.fromJson(Map<String, dynamic> json) {
    return ExtensionRequest(
      id: json['id'] as String,
      taskId: json['taskId'] as String,
      requestedBy: json['requestedBy'] as String,
      newDueDate: DateTime.parse(json['newDueDate'] as String),
      reason: json['reason'] as String,
      status: extensionStatusFromString(json['status'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'taskId': taskId,
        'requestedBy': requestedBy,
        'newDueDate': newDueDate.toIso8601String(),
        'reason': reason,
        'status': extensionStatusToString(status),
      };
}
