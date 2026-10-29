import 'package:flutter/material.dart';

import 'screens/captain_dashboard_screen.dart';
import 'screens/meet_detail_screen.dart';
import 'screens/task_detail_screen.dart';
import 'services/notification_service.dart';

/// Turns a notification-tap payload into a screen. Lives here (next to
/// main.dart) rather than in the service layer so NotificationService stays
/// free of screen imports.
///
/// Every payload the backend sends carries either a `taskId` (all the
/// task/extension notifications) or `type == 'member_needs_approval'` (a new
/// member finished onboarding), or is a meet-mode alert (`type` starting
/// `meet_`, with `season` + `eventCode`). Anything else — e.g. a broadcast —
/// just opens the app with no extra navigation.
void handleNotificationTap(Map<String, dynamic> data) {
  final nav = NotificationService.navigatorKey.currentState;
  if (nav == null) return;

  final taskId = data['taskId'] as String?;
  if (taskId != null && taskId.isNotEmpty) {
    nav.push(MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: taskId)));
    return;
  }

  final season = int.tryParse('${data['season']}');
  final eventCode = data['eventCode'] as String?;
  if ('${data['type']}'.startsWith('meet_') && season != null && eventCode != null) {
    nav.push(MaterialPageRoute(builder: (_) => MeetDetailScreen(season: season, code: eventCode)));
    return;
  }

  if (data['type'] == 'member_needs_approval') {
    nav.push(MaterialPageRoute(builder: (_) => const CaptainDashboardScreen()));
  }
}
