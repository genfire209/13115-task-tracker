import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/ftc_live.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gear_spinner.dart';
import '../widgets/responsive_center.dart';
import 'meet_detail_screen.dart';

/// Every NJ meet this season — live, upcoming and past — with the ones
/// we're registered for starred. Tapping one shows its matches, results and
/// rankings (no notifications; those are only for the meet in meet mode).
class MeetsScreen extends StatefulWidget {
  const MeetsScreen({super.key});

  @override
  State<MeetsScreen> createState() => _MeetsScreenState();
}

class _MeetsScreenState extends State<MeetsScreen> {
  final _api = ApiService();
  MeetList? _meets;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final meets = await _api.fetchMeets(season: currentFtcSeason());
      if (mounted) {
        setState(() {
          _meets = meets;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  void _open(int season, String code) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MeetDetailScreen(season: season, code: code)),
      ).then((_) => _load());

  @override
  Widget build(BuildContext context) {
    final meets = _meets;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    bool isPast(MeetSummary m) => (m.dateEnd ?? m.dateStart)?.isBefore(today) ?? false;
    bool isLive(MeetSummary m) =>
        !isPast(m) && m.dateStart != null && !m.dateStart!.isAfter(today);

    final live = meets?.events.where(isLive).toList() ?? [];
    final upcoming = meets?.events.where((m) => !isPast(m) && !isLive(m)).toList() ?? [];
    final past = meets?.events.where(isPast).toList().reversed.toList() ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Meets')),
      body: ResponsiveCenter(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_error != null)
                Text('Could not load meets: $_error', style: const TextStyle(color: AppTheme.statusDeclined)),
              if (meets == null && _error == null)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: GearSpinner(color: AppTheme.primary, size: 32)),
                ),
              if (meets?.active != null) ...[
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.notifications_active, color: AppTheme.primary),
                    title: Text(meets!.active!.eventName ?? meets.active!.eventCode),
                    subtitle: Text(meets.active!.testOnly
                        ? 'Meet mode test run (alerts only to you)'
                        : 'Meet mode on: alerts for ${meets.active!.teamNumber}\'s matches'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _open(meets.active!.season, meets.active!.eventCode),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              ..._section('Live now', live, meets),
              ..._section('Upcoming', upcoming, meets),
              ..._section('Past', past, meets),
              if (meets != null && meets.events.isEmpty)
                const Text('No meets listed yet for this season.',
                    style: TextStyle(color: AppTheme.onSurfaceMuted)),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _section(String title, List<MeetSummary> meets, MeetList? all) {
    if (meets.isEmpty || all == null) return [];
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      ),
      ...meets.map((m) => Card(
            child: ListTile(
              leading: Icon(
                m.weAttend ? Icons.star : Icons.event_outlined,
                color: m.weAttend ? AppTheme.statusPending : AppTheme.onSurfaceMuted,
              ),
              title: Text(m.name),
              subtitle: Text([
                if (m.dateStart != null) DateFormat.MMMd().format(m.dateStart!),
                if (m.venue != null && m.venue!.isNotEmpty) m.venue!,
                if (m.weAttend) "We're competing",
              ].join(' · ')),
              trailing: m.isActive
                  ? const Icon(Icons.notifications_active, color: AppTheme.primary, size: 20)
                  : const Icon(Icons.chevron_right),
              onTap: () => _open(all.season, m.code),
            ),
          )),
    ];
  }
}
