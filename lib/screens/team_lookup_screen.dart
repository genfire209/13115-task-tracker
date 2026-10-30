import 'package:flutter/material.dart';

import '../models/ftc_live.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gear_spinner.dart';
import '../widgets/match_card.dart';
import '../widgets/responsive_center.dart';
import '../friendly_error.dart';
import 'match_detail_screen.dart';

/// Look up any FTC team by number or name: its info, every event it's
/// attended this season with its ranking there, and its matches — tapping
/// one opens the same match-detail screen a meet's matches do.
class TeamLookupScreen extends StatefulWidget {
  const TeamLookupScreen({super.key});

  @override
  State<TeamLookupScreen> createState() => _TeamLookupScreenState();
}

class _TeamLookupScreenState extends State<TeamLookupScreen> {
  final _api = ApiService();
  final _controller = TextEditingController();
  List<TeamSearchHit>? _hits;
  TeamLookupResult? _result;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    setState(() {
      _hits = null;
      _result = null;
      _error = null;
    });
  }

  Future<void> _search(String raw) async {
    final query = raw.trim();
    setState(() {
      _error = null;
      _result = null;
      _hits = null;
    });
    if (query.isEmpty) return;
    setState(() => _busy = true);
    try {
      final hits = await _api.searchTeams(query);
      if (!mounted) return;
      if (hits.length == 1) {
        await _select(hits.first);
      } else {
        setState(() {
          _hits = hits;
          _busy = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = friendlyError(e);
          _busy = false;
        });
      }
    }
  }

  Future<void> _select(TeamSearchHit hit) async {
    setState(() {
      _busy = true;
      _error = null;
      _hits = null;
    });
    try {
      final result = await _api.lookupTeam(teamNumber: hit.number);
      if (mounted) {
        setState(() {
          _result = result;
          _busy = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = friendlyError(e);
          _busy = false;
        });
      }
    }
  }

  void _openMatch(int season, String code, FtcMatch match) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MatchDetailScreen(season: season, code: code, matchKey: match.matchKey, preview: match),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Lookup'),
        actions: [
          if (_result != null || _hits != null)
            IconButton(icon: const Icon(Icons.close), tooltip: 'New search', onPressed: _clear),
        ],
      ),
      body: ResponsiveCenter(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Team number or name',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onSubmitted: _search,
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(_error!, style: const TextStyle(color: AppTheme.statusDeclined)),
              ),
            if (_busy) const Padding(padding: EdgeInsets.all(24), child: GearSpinner(color: AppTheme.primary, size: 32)),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_busy) return const SizedBox.shrink();
    final result = _result;
    if (result != null) return _teamResult(result);
    final hits = _hits;
    if (hits != null) return _hitList(hits);
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Search for any FTC team by its number or name.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.onSurfaceMuted),
        ),
      ),
    );
  }

  Widget _hitList(List<TeamSearchHit> hits) {
    if (hits.isEmpty) {
      return const Center(child: Text('No teams found.', style: TextStyle(color: AppTheme.onSurfaceMuted)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: hits.length,
      itemBuilder: (_, i) {
        final hit = hits[i];
        return Card(
          child: ListTile(
            title: Text(hit.name ?? 'Team ${hit.number}'),
            subtitle: hit.name != null ? Text('#${hit.number}') : null,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _select(hit),
          ),
        );
      },
    );
  }

  Widget _teamResult(TeamLookupResult result) {
    final info = result.info;
    final title = info.nameShort ?? info.nameFull ?? 'Team ${result.teamNumber}';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${result.teamNumber}  $title', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                if (info.schoolName != null && info.schoolName!.isNotEmpty)
                  Text(info.schoolName!, style: const TextStyle(color: AppTheme.onSurfaceMuted)),
                if (info.displayLocation != null)
                  Text(info.displayLocation!, style: const TextStyle(color: AppTheme.onSurfaceMuted)),
                if (info.rookieYear != null)
                  Text('Rookie year ${info.rookieYear}', style: const TextStyle(color: AppTheme.onSurfaceMuted)),
              ],
            ),
          ),
        ),
        if (result.events.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Text(
              'No matches found for the ${result.season}-${result.season + 1} season.',
              style: const TextStyle(color: AppTheme.onSurfaceMuted),
            ),
          )
        else
          for (final event in result.events) ...[
            _heading(event.name),
            if (event.ranking != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Rank ${event.ranking!.rank} · ${event.ranking!.wins}-${event.ranking!.losses}-${event.ranking!.ties}'
                  '${event.ranking!.rankingScore != null ? ' · RS ${event.ranking!.rankingScore!.toStringAsFixed(2)}' : ''}',
                  style: const TextStyle(color: AppTheme.onSurfaceMuted),
                ),
              ),
            ...event.matches.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: MatchCard(
                    match: m,
                    ourTeam: result.teamNumber,
                    onTap: () => _openMatch(result.season, event.code, m),
                  ),
                )),
          ],
      ],
    );
  }

  Widget _heading(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      );
}
