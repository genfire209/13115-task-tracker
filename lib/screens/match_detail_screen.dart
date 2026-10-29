import 'dart:async';

import 'package:flutter/material.dart';

import '../models/ftc_live.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gear_spinner.dart';
import '../widgets/match_card.dart';
import '../widgets/responsive_center.dart';
import '../friendly_error.dart';

// Alliance panels: a dark tint of each alliance color, so white text keeps
// 13:1+ contrast and the alliance color itself still reads at 5.6:1+.
const _redTint = Color(0xFF3A1A1E);
const _blueTint = Color(0xFF172A40);
const _winnerColor = AppTheme.statusPending;
const _pollenColor = AppTheme.statusPending;

/// One match in full, like its page on ftc-events.firstinspires.org: both
/// alliances and the winner, the ranking points each earned, the score
/// comparison, what each robot did, and what's in each FLOWER. Nothing here
/// relies on color alone — every state also has an icon or a word.
class MatchDetailScreen extends StatefulWidget {
  final int season;
  final String code;
  final String matchKey;
  final FtcMatch? preview; // shown while the full match loads

  const MatchDetailScreen({super.key, required this.season, required this.code, required this.matchKey, this.preview});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  final _api = ApiService();
  MatchDetail? _detail;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _load();
    // Until the result and its breakdown are in, keep checking.
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (_detail == null || _detail!.red == null) _load();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final detail = await _api.fetchMatchDetail(season: widget.season, code: widget.code, matchKey: widget.matchKey);
      if (mounted) {
        setState(() {
          _detail = detail;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    final match = detail?.match ?? widget.preview;
    return Scaffold(
      appBar: AppBar(title: Text(match?.description ?? 'Match')),
      body: ResponsiveCenter(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (match != null)
                _ScoreHeader(match: match, ourTeam: detail?.ourTeam, red: detail?.red, blue: detail?.blue),
              if (_error != null && detail == null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(_error!, style: const TextStyle(color: AppTheme.statusDeclined)),
                ),
              if (detail == null && _error == null)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Center(child: GearSpinner(color: AppTheme.primary, size: 28)),
                ),
              if (detail != null) ..._body(detail),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _body(MatchDetail detail) {
    final match = detail.match;
    if (!match.hasBeenPlayed) {
      return [
        const SizedBox(height: 16),
        _Note(
          icon: Icons.schedule,
          text: match.estimatedStartTime != null
              ? 'Not played yet. Expected around ${matchTimeLabel(match).substring(1)} (venue time).'
              : 'Not played yet. ${matchTimeLabel(match)}'.trim(),
        ),
      ];
    }
    return [
      _heading('Ranking points'),
      _RankingPointsCard(red: detail.redRankingPoints!, blue: detail.blueRankingPoints!),
      if (detail.red == null) ...[
        const SizedBox(height: 12),
        const _Note(
          icon: Icons.hourglass_top,
          text: "FIRST hasn't posted the full breakdown for this match yet. It usually follows the score.",
        ),
      ] else ...[
        _heading('Score comparison'),
        _ComparisonTable(red: detail.red!, blue: detail.blue!),
        _heading('Robots'),
        _AllianceRobotsCard(alliance: 'Red', breakdown: detail.red!, match: match, ourTeam: detail.ourTeam),
        _AllianceRobotsCard(alliance: 'Blue', breakdown: detail.blue!, match: match, ourTeam: detail.ourTeam),
        _heading('Flowers'),
        _FlowersCard(flowers: detail.flowers!),
      ],
    ];
  }

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
  );
}

Color _allianceColor(String alliance) => alliance == 'Red' ? redAllianceColor : blueAllianceColor;

/// Red and blue side by side — or stacked when large text sizes leave too
/// little room — with label, winner, teams and final score.
class _ScoreHeader extends StatelessWidget {
  final FtcMatch match;
  final int? ourTeam;
  final AllianceBreakdown? red;
  final AllianceBreakdown? blue;

  const _ScoreHeader({required this.match, this.ourTeam, this.red, this.blue});

  // Each panel needs about this much width at 1x text to fit side by side.
  static const _minPanelWidth = 150.0;

  @override
  Widget build(BuildContext context) {
    final winner = match.winningAlliance;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide = (constraints.maxWidth - 10) / 2 / textScale >= _minPanelWidth;
        final redPanel = _panel('Red', _redTint, match.redScore, red, winner == 'Red', fill: sideBySide);
        final bluePanel = _panel('Blue', _blueTint, match.blueScore, blue, winner == 'Blue', fill: sideBySide);
        if (!sideBySide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [redPanel, const SizedBox(height: 10), bluePanel],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: redPanel),
              const SizedBox(width: 10),
              Expanded(child: bluePanel),
            ],
          ),
        );
      },
    );
  }

  /// [fill]: side by side, so the scores line up at the bottom of both panels.
  Widget _panel(
    String alliance,
    Color tint,
    int? score,
    AllianceBreakdown? breakdown,
    bool isWinner, {
    required bool fill,
  }) {
    final color = _allianceColor(alliance);
    final tie = match.hasBeenPlayed && match.winningAlliance == null;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(16),
        border: Border(top: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wraps so WINNER drops to its own line on narrow phones / large text.
          Wrap(
            spacing: 8,
            runSpacing: 2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                alliance.toUpperCase(),
                style: TextStyle(color: color, fontWeight: FontWeight.w800, letterSpacing: 1.2),
              ),
              if (isWinner)
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emoji_events, color: _winnerColor, size: 18),
                    SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'WINNER',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: _winnerColor, fontWeight: FontWeight.w800, fontSize: 12),
                      ),
                    ),
                  ],
                )
              else if (tie)
                const Text(
                  'TIE',
                  style: TextStyle(color: AppTheme.onSurfaceMuted, fontWeight: FontWeight.w800, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ...match.teamsOn(alliance).map((t) => _TeamLine(team: t, isUs: t.teamNumber == ourTeam)),
          if (fill) const Spacer(),
          const SizedBox(height: 8),
          Text(score?.toString() ?? '–', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, height: 1)),
          if (breakdown != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Auto ${breakdown.autoPoints} · TeleOp ${breakdown.teleopPoints} · Pen ${breakdown.penaltyPoints}',
                style: const TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _TeamLine extends StatelessWidget {
  final FtcMatchTeam team;
  final bool isUs;

  const _TeamLine({required this.team, required this.isUs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${team.teamNumber}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              if (isUs) ...[const SizedBox(width: 6), const _UsBadge()],
            ],
          ),
          if (team.teamName != null)
            Text(
              team.teamName!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 12),
            ),
        ],
      ),
    );
  }
}

class _UsBadge extends StatelessWidget {
  const _UsBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(color: AppTheme.onSurface, borderRadius: BorderRadius.circular(6)),
      child: const Text(
        'US',
        style: TextStyle(color: AppTheme.background, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}

/// Win/tie plus SWARM and POLLINATOR 1/2 for each alliance. Earned or not is
/// shown by the icon shape (check vs. empty circle), not just its color.
class _RankingPointsCard extends StatelessWidget {
  final AllianceRankingPoints red;
  final AllianceRankingPoints blue;

  const _RankingPointsCard({required this.red, required this.blue});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [_row('Red', red), const Divider(height: 20), _row('Blue', blue)]),
      ),
    );
  }

  Widget _row(String alliance, AllianceRankingPoints rp) {
    final color = _allianceColor(alliance);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              alliance,
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            Text(
              rp.bonusKnown ? '+${rp.total} RP' : '+${rp.win} RP so far',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _RpChip(label: rp.win == 1 ? 'Tie +1' : 'Win +3', earned: rp.win > 0, color: color),
            if (rp.bonusKnown) ...[
              _RpChip(label: 'SWARM', earned: rp.swarm, color: color),
              _RpChip(label: 'POLLINATOR 1', earned: rp.pollinator1, color: color),
              _RpChip(label: 'POLLINATOR 2', earned: rp.pollinator2, color: color),
            ] else
              const Text('Bonus RP not posted yet', style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 12)),
          ],
        ),
      ],
    );
  }
}

class _RpChip extends StatelessWidget {
  final String label;
  final bool earned;
  final Color color;

  const _RpChip({required this.label, required this.earned, required this.color});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label ranking point ${earned ? 'earned' : 'not earned'}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: earned ? color.withValues(alpha: 0.18) : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: earned ? color : AppTheme.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              earned ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 16,
              color: earned ? color : AppTheme.onSurfaceMuted,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: earned ? FontWeight.w700 : FontWeight.w500,
                  color: earned ? AppTheme.onSurface : AppTheme.onSurfaceMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// FIRST's "Score Comparisons" table: red | what | blue, subtotals in bold.
class _ComparisonTable extends StatelessWidget {
  final AllianceBreakdown red;
  final AllianceBreakdown blue;

  const _ComparisonTable({required this.red, required this.blue});

  @override
  Widget build(BuildContext context) {
    final rows = <(String, int, int, bool)>[
      ('Auto Leave', red.autoLeavePoints, blue.autoLeavePoints, false),
      ('Auto Park', red.autoParkPoints, blue.autoParkPoints, false),
      ('Auto Hive', red.autoHivePoints, blue.autoHivePoints, false),
      ('Autonomous', red.autoPoints, blue.autoPoints, true),
      ('TeleOp Hive', red.teleopHivePoints, blue.teleopHivePoints, false),
      ('TeleOp Flowers', red.teleopFlowerPoints, blue.teleopFlowerPoints, false),
      ('TeleOp Garden', red.teleopGardenPoints, blue.teleopGardenPoints, false),
      ('TeleOp Park', red.teleopParkPoints, blue.teleopParkPoints, false),
      ('TeleOp', red.teleopPoints, blue.teleopPoints, true),
      ('Penalties from opponent', red.penaltyPoints, blue.penaltyPoints, false),
      ('Total', red.total, blue.total, true),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            _line('Red', '', 'Blue', header: true),
            for (final (label, r, b, bold) in rows) ...[
              if (bold) const Divider(height: 8),
              _line('$r', label, '$b', bold: bold, total: label == 'Total'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _line(String red, String label, String blue, {bool header = false, bool bold = false, bool total = false}) {
    TextStyle value(Color? color) => TextStyle(
      color: color,
      fontWeight: header || bold ? FontWeight.w800 : FontWeight.w500,
      fontSize: total ? 18 : 15,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(width: 52, child: Text(red, style: value(header ? redAllianceColor : null))),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: bold ? AppTheme.onSurface : AppTheme.onSurfaceMuted,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                fontSize: 13,
              ),
            ),
          ),
          SizedBox(
            width: 52,
            child: Text(blue, textAlign: TextAlign.end, style: value(header ? blueAllianceColor : null)),
          ),
        ],
      ),
    );
  }
}

/// One alliance: what each robot did, then the alliance's counts and fouls.
class _AllianceRobotsCard extends StatelessWidget {
  final String alliance;
  final AllianceBreakdown breakdown;
  final FtcMatch match;
  final int ourTeam;

  const _AllianceRobotsCard({
    required this.alliance,
    required this.breakdown,
    required this.match,
    required this.ourTeam,
  });

  @override
  Widget build(BuildContext context) {
    final color = _allianceColor(alliance);
    final names = {for (final t in match.teams) t.teamNumber: t.teamName};
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$alliance alliance',
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
            for (var i = 0; i < breakdown.autoRobots.length; i++) ...[
              const SizedBox(height: 10),
              _robot(
                i,
                breakdown.autoRobots[i],
                i < breakdown.teleopRobots.length ? breakdown.teleopRobots[i] : null,
                names,
              ),
            ],
            const Divider(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _stat('TIPS (auto)', breakdown.autoTips),
                _stat('TIPS (TeleOp)', breakdown.teleopTips),
                _stat('In HIVE', breakdown.hiveBalls),
                _stat('In GARDEN', breakdown.gardenBalls),
                _stat('Minor fouls', breakdown.minorFouls),
                _stat('Major fouls', breakdown.majorFouls),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _robot(int index, RobotActions auto, RobotActions? teleop, Map<int, String?> names) {
    final team = auto.teamNumber;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Wraps: the team name drops to its own line when there's no room.
        Wrap(
          spacing: 6,
          runSpacing: 2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Robot ${index + 1}${team != null ? ' · $team' : ''}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (team == ourTeam) const _UsBadge(),
            if (team != null && names[team] != null)
              Text(names[team]!, style: const TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 14,
          runSpacing: 4,
          children: [
            _Check(label: 'Auto leave', done: auto.leave),
            _Check(label: 'Auto park', done: auto.park),
            if (teleop != null) _Check(label: 'End park', done: teleop.park),
          ],
        ),
      ],
    );
  }

  Widget _stat(String label, int value) => Text.rich(
    TextSpan(
      children: [
        TextSpan(
          text: '$value ',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        TextSpan(
          text: label,
          style: const TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 12),
        ),
      ],
    ),
  );
}

class _Check extends StatelessWidget {
  final String label;
  final bool done;

  const _Check({required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: ${done ? 'yes' : 'no'}',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            done ? Icons.check_box : Icons.check_box_outline_blank,
            size: 18,
            color: done ? AppTheme.statusCompleted : AppTheme.onSurfaceMuted,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: done ? AppTheme.onSurface : AppTheme.onSurfaceMuted),
            ),
          ),
        ],
      ),
    );
  }
}

/// The four FLOWERS, balls stacked bottom to top as FIRST lists them, each
/// with a letter (P = POLLEN, N = NECTAR) so colors aren't the only clue.
/// The alliance whose NECTAR is top-most owns that FLOWER.
class _FlowersCard extends StatelessWidget {
  final Flowers flowers;

  const _FlowersCard({required this.flowers});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _flower('Red wall', flowers.redWall),
            _flower('Scoring', flowers.scoring),
            _flower('Blue wall', flowers.blueWall),
            _flower('Audience', flowers.audience),
          ],
        ),
      ),
    );
  }

  Widget _flower(String name, List<String> balls) {
    String? owner;
    for (final b in balls.reversed) {
      if (b == 'RED_NECTAR') {
        owner = 'Red';
        break;
      }
      if (b == 'BLUE_NECTAR') {
        owner = 'Blue';
        break;
      }
    }
    return Expanded(
      child: Column(
        children: [
          if (balls.isEmpty)
            const Text('Empty', style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 12))
          else
            ...balls.reversed.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: _Ball(kind: b),
              ),
            ),
          const SizedBox(height: 6),
          Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          Text(
            owner != null ? '$owner owns' : 'No owner',
            style: TextStyle(fontSize: 11, color: owner != null ? _allianceColor(owner) : AppTheme.onSurfaceMuted),
          ),
        ],
      ),
    );
  }
}

class _Ball extends StatelessWidget {
  final String kind; // 'RED_NECTAR' | 'BLUE_NECTAR' | 'POLLEN'

  const _Ball({required this.kind});

  @override
  Widget build(BuildContext context) {
    final (color, letter, name) = switch (kind) {
      'RED_NECTAR' => (redAllianceColor, 'N', 'Red NECTAR'),
      'BLUE_NECTAR' => (blueAllianceColor, 'N', 'Blue NECTAR'),
      _ => (_pollenColor, 'P', 'POLLEN'),
    };
    return Semantics(
      label: name,
      excludeSemantics: true,
      child: Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Text(
          letter,
          style: const TextStyle(color: AppTheme.background, fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Note({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.onSurfaceMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 13)),
        ),
      ],
    );
  }
}
