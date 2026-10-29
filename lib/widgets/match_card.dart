import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/ftc_live.dart';
import '../theme/app_theme.dart';

const redAllianceColor = AppTheme.statusDeclined;
const blueAllianceColor = AppTheme.statusActive;

/// One FTC match: both alliances with team numbers and names, the scores
/// once played (winner in bold), and otherwise when it should start.
/// [ourTeam] is highlighted wherever it appears.
class MatchCard extends StatelessWidget {
  final FtcMatch match;
  final int? ourTeam;

  const MatchCard({super.key, required this.match, this.ourTeam});

  @override
  Widget build(BuildContext context) {
    final winner = match.winningAlliance;
    final ours = ourTeam != null && match.involves(ourTeam!);
    return Card(
      shape: ours
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppTheme.primary, width: 1.5),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(match.description, style: const TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(),
                Text(
                  matchTimeLabel(match),
                  style: const TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _AllianceRow(
              color: redAllianceColor,
              teams: match.teamsOn('Red'),
              score: match.redScore,
              isWinner: winner == 'Red',
              ourTeam: ourTeam,
            ),
            const SizedBox(height: 6),
            _AllianceRow(
              color: blueAllianceColor,
              teams: match.teamsOn('Blue'),
              score: match.blueScore,
              isWinner: winner == 'Blue',
              ourTeam: ourTeam,
            ),
          ],
        ),
      ),
    );
  }
}

/// Times are the venue's own wall clock (see parseVenueLocalTime). Before a
/// meet gets going only the published schedule exists, and it's often a
/// placeholder, so it's marked as such.
String matchTimeLabel(FtcMatch match) {
  if (match.hasBeenPlayed) {
    return match.postResultTime != null ? 'Posted ${DateFormat.jm().format(match.postResultTime!)}' : '';
  }
  if (match.estimatedStartTime != null) return '~${DateFormat.jm().format(match.estimatedStartTime!)}';
  if (match.scheduledStartTime != null) return 'Sched. ${DateFormat.jm().format(match.scheduledStartTime!)}';
  return '';
}

class _AllianceRow extends StatelessWidget {
  final Color color;
  final List<FtcMatchTeam> teams;
  final int? score;
  final bool isWinner;
  final int? ourTeam;

  const _AllianceRow({
    required this.color,
    required this.teams,
    required this.score,
    required this.isWinner,
    this.ourTeam,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(width: 4, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: teams.map((t) {
                final isUs = t.teamNumber == ourTeam;
                return Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${t.teamNumber}',
                        style: TextStyle(
                          color: color,
                          fontWeight: isWinner || isUs ? FontWeight.w800 : FontWeight.w600,
                          decoration: isUs ? TextDecoration.underline : null,
                        ),
                      ),
                      if (t.teamName != null)
                        TextSpan(
                          text: '  ${t.teamName}',
                          style: const TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 12),
                        ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                );
              }).toList(),
            ),
          ),
          if (score != null)
            Center(
              child: Text(
                '$score',
                style: TextStyle(
                  color: isWinner ? AppTheme.onSurface : AppTheme.onSurfaceMuted,
                  fontWeight: isWinner ? FontWeight.w800 : FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
