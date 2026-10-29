import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ftc_live.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gear_spinner.dart';
import '../widgets/match_card.dart';
import '../widgets/responsive_center.dart';
import 'match_detail_screen.dart';

/// One meet: our next match, every upcoming match and result (team numbers
/// and names, alliance scores), and rankings. Captains/admins turn meet mode
/// on here for the meet we're at, which pushes the team ~10 and ~5 minutes
/// before each of our matches and the result after.
class MeetDetailScreen extends StatefulWidget {
  final int season;
  final String code;

  const MeetDetailScreen({super.key, required this.season, required this.code});

  @override
  State<MeetDetailScreen> createState() => _MeetDetailScreenState();
}

class _MeetDetailScreenState extends State<MeetDetailScreen> {
  final _api = ApiService();
  MeetDetail? _meet;
  String? _error;
  bool _busy = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (_) => _load());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final meet = await _api.fetchMeet(season: widget.season, code: widget.code);
      if (mounted) {
        setState(() {
          _meet = meet;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppTheme.statusDeclined),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _start(MeetDetail meet, {bool testOnly = false}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(testOnly ? 'Test meet mode?' : 'Start meet mode?'),
        content: Text(testOnly
            ? 'Only you will get the alerts for ${meet.name}. Use this to check the timing at a meet.'
            : 'Everyone on the team will get a push ~10 and ~5 minutes before each '
                '${meet.ourTeam} match at ${meet.name}, and the result after. '
                'It turns itself off after the meet.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Start')),
        ],
      ),
    );
    if (confirmed == true) {
      await _run(() => _api.startMeet(season: meet.season, eventCode: meet.code, testOnly: testOnly));
    }
  }

  @override
  Widget build(BuildContext context) {
    final meet = _meet;
    final user = context.watch<AuthService>().currentUser!;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(meet?.name ?? widget.code),
          bottom: const TabBar(tabs: [Tab(text: 'Matches'), Tab(text: 'Rankings')]),
        ),
        body: meet == null
            ? Center(
                child: _error != null
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(_error!, style: const TextStyle(color: AppTheme.statusDeclined)),
                      )
                    : const GearSpinner(color: AppTheme.primary, size: 32),
              )
            : TabBarView(
                children: [
                  _matchesTab(meet, user.hasCaptainAccess, user.isAdmin),
                  _rankingsTab(meet),
                ],
              ),
      ),
    );
  }

  Widget _matchesTab(MeetDetail meet, bool isCaptain, bool isAdmin) {
    final upNext = meet.matches.where((m) => !m.hasBeenPlayed).toList();
    final results = meet.matches.where((m) => m.hasBeenPlayed).toList().reversed.toList();
    final next = meet.ourNextMatch;

    return ResponsiveCenter(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _meetModeCard(meet, isCaptain, isAdmin),
            if (next != null) ...[
              _heading('Our next match'),
              MatchCard(match: next, ourTeam: meet.ourTeam, onTap: () => _openMatch(meet, next)),
            ],
            if (meet.waitingForFirstMatch && upNext.isNotEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Waiting for the first match. Published times are often placeholders, '
                  'so real estimates (~) start once play begins.',
                  style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 13),
                ),
              ),
            _heading('Up next'),
            if (upNext.isEmpty)
              const Text('No upcoming matches.', style: TextStyle(color: AppTheme.onSurfaceMuted))
            else
              ...upNext.map((m) => MatchCard(match: m, ourTeam: meet.ourTeam, onTap: () => _openMatch(meet, m))),
            _heading('Results'),
            if (results.isEmpty)
              const Text('No results yet.', style: TextStyle(color: AppTheme.onSurfaceMuted))
            else
              ...results.map((m) => MatchCard(match: m, ourTeam: meet.ourTeam, onTap: () => _openMatch(meet, m))),
            if (meet.timezone != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'Times are the venue\'s local time (${meet.timezone}).',
                  style: const TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _meetModeCard(MeetDetail meet, bool isCaptain, bool isAdmin) {
    if (!isCaptain && !meet.isActive) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  meet.isActive ? Icons.notifications_active : Icons.notifications_none,
                  color: meet.isActive ? AppTheme.primary : AppTheme.onSurfaceMuted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    meet.isActive
                        ? 'Meet mode is on: alerts before each ${meet.ourTeam} match'
                        : 'Meet mode is off',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            if (isCaptain) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: meet.isActive
                    ? [
                        OutlinedButton(
                          onPressed: _busy ? null : () => _run(_api.endMeet),
                          child: const Text('End meet mode'),
                        ),
                      ]
                    : [
                        FilledButton(
                          onPressed: _busy ? null : () => _start(meet),
                          child: const Text('Start meet mode'),
                        ),
                        if (isAdmin)
                          OutlinedButton(
                            onPressed: _busy ? null : () => _start(meet, testOnly: true),
                            child: const Text('Test (only me)'),
                          ),
                      ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _rankingsTab(MeetDetail meet) {
    if (meet.rankings.isEmpty) {
      return const Center(
        child: Text('No rankings yet.', style: TextStyle(color: AppTheme.onSurfaceMuted)),
      );
    }
    return ResponsiveCenter(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: meet.rankings.length,
          itemBuilder: (_, i) {
            final r = meet.rankings[i];
            final isUs = r.teamNumber == meet.ourTeam;
            return Card(
              child: ListTile(
                leading: Text(
                  '${r.rank}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                title: Text(
                  '${r.teamNumber}${r.teamName != null ? '  ${r.teamName}' : ''}',
                  style: TextStyle(
                    fontWeight: isUs ? FontWeight.w800 : FontWeight.w500,
                    color: isUs ? AppTheme.primary : null,
                  ),
                ),
                subtitle: Text('${r.wins}-${r.losses}-${r.ties} · ${r.matchesPlayed} played'),
                trailing: r.rankingScore != null
                    ? Text('RS ${r.rankingScore!.toStringAsFixed(2)}',
                        style: const TextStyle(color: AppTheme.onSurfaceMuted))
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }

  void _openMatch(MeetDetail meet, FtcMatch match) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MatchDetailScreen(
            season: meet.season,
            code: meet.code,
            matchKey: match.matchKey,
            preview: match,
          ),
        ),
      );

  Widget _heading(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      );
}
