import 'dart:async';

import 'package:flutter/material.dart';

import '../models/ftc_live.dart';
import '../screens/meet_detail_screen.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'match_card.dart';

/// A strip at the top of the task board while meet mode is on: the meet
/// and our next match. Hidden otherwise. Tapping it opens the meet.
class ActiveMeetBanner extends StatefulWidget {
  const ActiveMeetBanner({super.key});

  @override
  State<ActiveMeetBanner> createState() => _ActiveMeetBannerState();
}

class _ActiveMeetBannerState extends State<ActiveMeetBanner> {
  final _api = ApiService();
  ActiveMeet? _active;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final active = await _api.fetchActiveMeet();
      if (mounted) setState(() => _active = active);
    } catch (e) {
      // A blip shouldn't flash an error on the task board; keep what we had.
      debugPrint('Could not load meet mode: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _active;
    if (active == null) return const SizedBox.shrink();
    final next = active.nextMatch;
    final alliance = next?.allianceOf(active.teamNumber);
    final nextLine = next == null
        ? 'No more matches for ${active.teamNumber}'
        : active.waitingForFirstMatch
            ? 'Next: ${next.shortLabel} ($alliance) · waiting for the first match'
            : 'Next: ${next.shortLabel} ($alliance) ${matchTimeLabel(next)}';

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      color: AppTheme.surfaceVariant,
      child: ListTile(
        leading: const Icon(Icons.emoji_events, color: AppTheme.primary),
        title: Text(
          '${active.testOnly ? '[Test] ' : ''}${active.eventName ?? active.eventCode}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(nextLine),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MeetDetailScreen(season: active.season, code: active.eventCode),
          ),
        ).then((_) => _load()),
      ),
    );
  }
}
