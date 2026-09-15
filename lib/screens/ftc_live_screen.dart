import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/ftc_live.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gear_spinner.dart';
import '../widgets/responsive_center.dart';

const _redColor = AppTheme.statusDeclined;
const _blueColor = AppTheme.statusActive;

/// Hidden feature: live FTC match tracking pulled from FTCScout via our own
/// backend. Reachable only via a tap-gesture elsewhere (see
/// task_board_screen.dart) — not in any normal nav.
class FtcLiveScreen extends StatefulWidget {
  const FtcLiveScreen({super.key});

  @override
  State<FtcLiveScreen> createState() => _FtcLiveScreenState();
}

class _FtcLiveScreenState extends State<FtcLiveScreen> {
  final _api = ApiService();
  late final TextEditingController _seasonController;
  final _codeController = TextEditingController();

  FtcEventLive? _event;
  String? _loadedCode;
  int? _loadedSeason;
  bool _loading = false;
  String? _error;

  List<WatchedFtcEvent> _watched = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _seasonController = TextEditingController(text: '${currentFtcSeason()}');
    _loadWatched();
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (_loadedCode != null) _load(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _seasonController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadWatched() async {
    try {
      final watched = await _api.fetchWatchedFtcEvents();
      if (mounted) setState(() => _watched = watched);
    } catch (e) {
      debugPrint('Could not load watched FTC events: $e');
    }
  }

  bool get _isTrackingLoadedEvent => _loadedCode != null &&
      _watched.any((w) => w.season == _loadedSeason && w.eventCode == _loadedCode);

  Future<void> _load({bool silent = false}) async {
    final season = int.tryParse(_seasonController.text.trim());
    final code = _codeController.text.trim().isEmpty ? _loadedCode : _codeController.text.trim();
    if (season == null || code == null || code.isEmpty) {
      setState(() => _error = 'Enter a season and event code');
      return;
    }
    if (!silent) setState(() => _loading = true);
    try {
      final event = await _api.fetchFtcEventLive(season: season, eventCode: code);
      if (!mounted) return;
      setState(() {
        _event = event;
        _loadedCode = code.toUpperCase();
        _loadedSeason = season;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  Future<void> _toggleTracking() async {
    final requesterId = context.read<AuthService>().currentUser?.id;
    if (requesterId == null || _loadedCode == null || _loadedSeason == null) return;
    try {
      if (_isTrackingLoadedEvent) {
        final match = _watched.firstWhere(
          (w) => w.season == _loadedSeason && w.eventCode == _loadedCode,
        );
        await _api.removeWatchedFtcEvent(match.id);
      } else {
        await _api.addWatchedFtcEvent(
          season: _loadedSeason!,
          eventCode: _loadedCode!,
          requesterId: requesterId,
        );
      }
      await _loadWatched();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppTheme.statusDeclined),
        );
      }
    }
  }

  Future<void> _stopTracking(WatchedFtcEvent w) async {
    try {
      await _api.removeWatchedFtcEvent(w.id);
      await _loadWatched();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppTheme.statusDeclined),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = _event;
    final upNext = event?.matches.where((m) => !m.hasBeenPlayed).toList();
    final results = event?.matches.where((m) => m.hasBeenPlayed).toList();
    results?.sort((a, b) => b.matchNum.compareTo(a.matchNum));

    return Scaffold(
      appBar: AppBar(title: const Text('FTC Live')),
      body: ResponsiveCenter(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _seasonController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Season'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'Event code',
                      hintText: _loadedCode ?? 'e.g. USNYLI1',
                    ),
                    onSubmitted: (_) => _load(),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: _loading ? null : () => _load(),
                  child: _loading
                      ? const GearSpinner(size: 18, color: Colors.white)
                      : const Text('Load'),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppTheme.statusDeclined)),
            ],
            if (event != null) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      event.name,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _toggleTracking,
                    icon: Icon(
                      _isTrackingLoadedEvent ? Icons.notifications_active : Icons.notifications_none,
                      size: 18,
                    ),
                    label: Text(_isTrackingLoadedEvent ? 'Tracking' : 'Track'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Up Next', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 8),
              if (upNext == null || upNext.isEmpty)
                const Text('No unplayed matches.', style: TextStyle(color: AppTheme.onSurfaceMuted))
              else
                _MatchCard(match: upNext.first),
              const SizedBox(height: 20),
              const Text('Recent Results', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 8),
              if (results == null || results.isEmpty)
                const Text('No results yet.', style: TextStyle(color: AppTheme.onSurfaceMuted))
              else
                ...results.take(10).map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _MatchCard(match: m),
                    )),
            ],
            if (_watched.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(),
              const Text('Tracked events', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 8),
              ..._watched.map((w) => Card(
                    child: ListTile(
                      dense: true,
                      title: Text('${w.eventCode} (${w.season})'),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => _stopTracking(w),
                      ),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final FtcMatch match;
  const _MatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final winner = match.winningAlliance;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(match.description, style: const TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(),
                if (match.scheduledStartTime != null)
                  Text(
                    DateFormat.jm().format(match.scheduledStartTime!.toLocal()),
                    style: const TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 12),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _AllianceRow(
              label: 'Red',
              color: _redColor,
              teams: match.teamsFor('Red'),
              score: match.redScore,
              isWinner: winner == 'Red',
            ),
            const SizedBox(height: 4),
            _AllianceRow(
              label: 'Blue',
              color: _blueColor,
              teams: match.teamsFor('Blue'),
              score: match.blueScore,
              isWinner: winner == 'Blue',
            ),
          ],
        ),
      ),
    );
  }
}

class _AllianceRow extends StatelessWidget {
  final String label;
  final Color color;
  final List<int> teams;
  final int? score;
  final bool isWinner;

  const _AllianceRow({
    required this.label,
    required this.color,
    required this.teams,
    required this.score,
    required this.isWinner,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 4, height: 20, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            teams.join(', '),
            style: TextStyle(
              color: color,
              fontWeight: isWinner ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
        if (score != null)
          Text(
            '$score',
            style: TextStyle(
              color: isWinner ? AppTheme.onSurface : AppTheme.onSurfaceMuted,
              fontWeight: isWinner ? FontWeight.w800 : FontWeight.w500,
              fontSize: 16,
            ),
          ),
      ],
    );
  }
}
