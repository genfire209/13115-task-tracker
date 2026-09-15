// Models for the hidden "FTC Live" feature — live match tracking pulled
// from FTCScout's public API via our own backend (see api_service.dart).

class FtcMatchTeam {
  final String alliance; // 'Red' or 'Blue'
  final int teamNumber;

  FtcMatchTeam({required this.alliance, required this.teamNumber});

  factory FtcMatchTeam.fromJson(Map<String, dynamic> json) => FtcMatchTeam(
        alliance: json['alliance'] as String,
        teamNumber: json['teamNumber'] as int,
      );
}

class FtcMatch {
  final int id;
  final int matchNum;
  final String tournamentLevel;
  final String description;
  final bool hasBeenPlayed;
  final DateTime? scheduledStartTime;
  final DateTime? postResultTime;
  final List<FtcMatchTeam> teams;
  final int? redScore;
  final int? blueScore;

  FtcMatch({
    required this.id,
    required this.matchNum,
    required this.tournamentLevel,
    required this.description,
    required this.hasBeenPlayed,
    this.scheduledStartTime,
    this.postResultTime,
    required this.teams,
    this.redScore,
    this.blueScore,
  });

  List<int> teamsFor(String alliance) =>
      teams.where((t) => t.alliance == alliance).map((t) => t.teamNumber).toList();

  /// null = tie or not played yet.
  String? get winningAlliance {
    if (redScore == null || blueScore == null || redScore == blueScore) return null;
    return redScore! > blueScore! ? 'Red' : 'Blue';
  }

  factory FtcMatch.fromJson(Map<String, dynamic> json) => FtcMatch(
        id: json['id'] as int,
        matchNum: json['matchNum'] as int,
        tournamentLevel: json['tournamentLevel'] as String,
        description: json['description'] as String,
        hasBeenPlayed: json['hasBeenPlayed'] as bool,
        scheduledStartTime: json['scheduledStartTime'] != null
            ? DateTime.parse(json['scheduledStartTime'] as String)
            : null,
        postResultTime: json['postResultTime'] != null
            ? DateTime.parse(json['postResultTime'] as String)
            : null,
        teams: (json['teams'] as List<dynamic>)
            .map((t) => FtcMatchTeam.fromJson(t as Map<String, dynamic>))
            .toList(),
        redScore: json['redScore'] as int?,
        blueScore: json['blueScore'] as int?,
      );
}

class FtcEventLive {
  final String name;
  final List<FtcMatch> matches;

  FtcEventLive({required this.name, required this.matches});

  factory FtcEventLive.fromJson(Map<String, dynamic> json) => FtcEventLive(
        name: json['name'] as String,
        matches: (json['matches'] as List<dynamic>)
            .map((m) => FtcMatch.fromJson(m as Map<String, dynamic>))
            .toList(),
      );
}

class WatchedFtcEvent {
  final String id;
  final int season;
  final String eventCode;

  WatchedFtcEvent({required this.id, required this.season, required this.eventCode});

  factory WatchedFtcEvent.fromJson(Map<String, dynamic> json) => WatchedFtcEvent(
        id: json['id'] as String,
        season: json['season'] as int,
        eventCode: json['eventCode'] as String,
      );
}

/// FTC seasons run roughly September to April and are named by the year
/// they start — e.g. the season that kicks off in September 2026 is
/// "season 2026" even though most of it plays out in 2027.
int currentFtcSeason() {
  final now = DateTime.now();
  return now.month >= 9 ? now.year : now.year - 1;
}
