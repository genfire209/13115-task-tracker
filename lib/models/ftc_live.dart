// Models for the Meets feature — every NJ meet's matches, results and
// rankings, pulled from FIRST's official FTC Events API via our own backend
// (see api_service.dart), plus meet mode's match alerts.

/// The backend sends match times as the raw venue-local wall-clock string
/// FIRST's API gives it (no UTC offset at all — "all times are listed in
/// the local time to the event venue" per their docs). DateTime.parse would
/// silently reinterpret an offset-less string as *this device's* local
/// time, which is wrong for anyone not literally in the venue's timezone.
/// This just reads the y/m/d/h/m fields as-is with no conversion, so
/// formatting it always shows the venue's actual wall-clock time.
DateTime? parseVenueLocalTime(String? raw) {
  if (raw == null) return null;
  final m = RegExp(r'^(\d+)-(\d+)-(\d+)T(\d+):(\d+)').firstMatch(raw);
  if (m == null) return null;
  return DateTime(
    int.parse(m.group(1)!),
    int.parse(m.group(2)!),
    int.parse(m.group(3)!),
    int.parse(m.group(4)!),
    int.parse(m.group(5)!),
  );
}

class FtcMatchTeam {
  final String alliance; // 'Red' or 'Blue'
  final int teamNumber;
  final String? teamName;

  FtcMatchTeam({required this.alliance, required this.teamNumber, this.teamName});

  factory FtcMatchTeam.fromJson(Map<String, dynamic> json) => FtcMatchTeam(
        alliance: json['alliance'] as String,
        teamNumber: json['teamNumber'] as int,
        teamName: json['teamName'] as String?,
      );
}

class FtcMatch {
  final String matchKey;
  final int matchNum;
  final String tournamentLevel;
  final String description;
  final bool hasBeenPlayed;
  final DateTime? scheduledStartTime; // venue-local wall clock, see parseVenueLocalTime
  // Published schedule times are often placeholders; once play has begun
  // the backend estimates when each unplayed match will really start.
  final DateTime? estimatedStartTime;
  final DateTime? postResultTime;
  final List<FtcMatchTeam> teams;
  final int? redScore;
  final int? blueScore;

  FtcMatch({
    required this.matchKey,
    required this.matchNum,
    required this.tournamentLevel,
    required this.description,
    required this.hasBeenPlayed,
    this.scheduledStartTime,
    this.estimatedStartTime,
    this.postResultTime,
    required this.teams,
    this.redScore,
    this.blueScore,
  });

  /// "Q12" for qualifications, the full description for playoffs.
  String get shortLabel => tournamentLevel == 'QUALIFICATION' ? 'Q$matchNum' : description;

  List<FtcMatchTeam> teamsOn(String alliance) => teams.where((t) => t.alliance == alliance).toList();

  bool involves(int teamNumber) => teams.any((t) => t.teamNumber == teamNumber);

  /// 'Red' or 'Blue', or null if [teamNumber] isn't in this match.
  String? allianceOf(int teamNumber) {
    for (final t in teams) {
      if (t.teamNumber == teamNumber) return t.alliance;
    }
    return null;
  }

  /// null = tie or not played yet.
  String? get winningAlliance {
    if (redScore == null || blueScore == null || redScore == blueScore) return null;
    return redScore! > blueScore! ? 'Red' : 'Blue';
  }

  factory FtcMatch.fromJson(Map<String, dynamic> json) => FtcMatch(
        matchKey: json['matchKey'] as String,
        matchNum: json['matchNum'] as int,
        tournamentLevel: json['tournamentLevel'] as String,
        description: json['description'] as String,
        hasBeenPlayed: json['hasBeenPlayed'] as bool,
        scheduledStartTime: parseVenueLocalTime(json['scheduledStartTime'] as String?),
        estimatedStartTime: parseVenueLocalTime(json['estimatedStartTime'] as String?),
        postResultTime: parseVenueLocalTime(json['postResultTime'] as String?),
        teams: (json['teams'] as List<dynamic>)
            .map((t) => FtcMatchTeam.fromJson(t as Map<String, dynamic>))
            .toList(),
        redScore: json['redScore'] as int?,
        blueScore: json['blueScore'] as int?,
      );
}

class RankingRow {
  final int rank;
  final int teamNumber;
  final String? teamName;
  final int wins;
  final int losses;
  final int ties;
  final int matchesPlayed;
  final double? rankingScore;

  RankingRow({
    required this.rank,
    required this.teamNumber,
    this.teamName,
    required this.wins,
    required this.losses,
    required this.ties,
    required this.matchesPlayed,
    this.rankingScore,
  });

  factory RankingRow.fromJson(Map<String, dynamic> json) => RankingRow(
        rank: json['rank'] as int,
        teamNumber: json['teamNumber'] as int,
        teamName: json['teamName'] as String?,
        wins: json['wins'] as int? ?? 0,
        losses: json['losses'] as int? ?? 0,
        ties: json['ties'] as int? ?? 0,
        matchesPlayed: json['matchesPlayed'] as int? ?? 0,
        rankingScore: (json['rankingScore'] as num?)?.toDouble(),
      );
}

/// One meet in the season list.
class MeetSummary {
  final String code;
  final String name;
  final DateTime? dateStart; // venue-local date
  final DateTime? dateEnd;
  final String? venue;
  final String? city;
  final bool weAttend;
  final bool isActive;

  MeetSummary({
    required this.code,
    required this.name,
    this.dateStart,
    this.dateEnd,
    this.venue,
    this.city,
    this.weAttend = false,
    this.isActive = false,
  });

  factory MeetSummary.fromJson(Map<String, dynamic> json) => MeetSummary(
        code: json['code'] as String,
        name: json['name'] as String,
        dateStart: parseVenueLocalTime(json['dateStart'] as String?),
        dateEnd: parseVenueLocalTime(json['dateEnd'] as String?),
        venue: json['venue'] as String?,
        city: json['city'] as String?,
        weAttend: json['weAttend'] as bool? ?? false,
        isActive: json['isActive'] as bool? ?? false,
      );
}

/// The meet a captain/admin has put in meet mode.
class ActiveMeet {
  final int season;
  final String eventCode;
  final String? eventName;
  final int teamNumber;
  final bool testOnly;
  final bool waitingForFirstMatch;
  final FtcMatch? nextMatch;

  ActiveMeet({
    required this.season,
    required this.eventCode,
    this.eventName,
    required this.teamNumber,
    this.testOnly = false,
    this.waitingForFirstMatch = false,
    this.nextMatch,
  });

  factory ActiveMeet.fromJson(Map<String, dynamic> json) => ActiveMeet(
        season: json['season'] as int,
        eventCode: json['eventCode'] as String,
        eventName: json['eventName'] as String?,
        teamNumber: json['teamNumber'] as int,
        testOnly: json['testOnly'] as bool? ?? false,
        waitingForFirstMatch: json['waitingForFirstMatch'] as bool? ?? false,
        nextMatch: json['nextMatch'] == null
            ? null
            : FtcMatch.fromJson(json['nextMatch'] as Map<String, dynamic>),
      );
}

class MeetList {
  final int season;
  final int ourTeam;
  final List<MeetSummary> events;
  final ActiveMeet? active;

  MeetList({required this.season, required this.ourTeam, required this.events, this.active});

  factory MeetList.fromJson(Map<String, dynamic> json) => MeetList(
        season: json['season'] as int,
        ourTeam: json['ourTeam'] as int,
        events: (json['events'] as List<dynamic>)
            .map((e) => MeetSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
        active: json['active'] == null
            ? null
            : ActiveMeet.fromJson(json['active'] as Map<String, dynamic>),
      );
}

/// Everything about one meet.
class MeetDetail {
  final int season;
  final String code;
  final String name;
  final String? timezone;
  final String? venue;
  final String? city;
  final int ourTeam; // the team meet mode is following, normally 13115
  final bool isActive;
  final bool waitingForFirstMatch;
  final List<FtcMatch> matches;
  final List<RankingRow> rankings;

  MeetDetail({
    required this.season,
    required this.code,
    required this.name,
    this.timezone,
    this.venue,
    this.city,
    required this.ourTeam,
    required this.isActive,
    required this.waitingForFirstMatch,
    required this.matches,
    required this.rankings,
  });

  FtcMatch? get ourNextMatch {
    for (final m in matches) {
      if (!m.hasBeenPlayed && m.involves(ourTeam)) return m;
    }
    return null;
  }

  factory MeetDetail.fromJson(Map<String, dynamic> json) => MeetDetail(
        season: json['season'] as int,
        code: json['code'] as String,
        name: json['name'] as String,
        timezone: json['timezone'] as String?,
        venue: json['venue'] as String?,
        city: json['city'] as String?,
        ourTeam: json['ourTeam'] as int,
        isActive: json['isActive'] as bool? ?? false,
        waitingForFirstMatch: json['waitingForFirstMatch'] as bool? ?? false,
        matches: (json['matches'] as List<dynamic>)
            .map((m) => FtcMatch.fromJson(m as Map<String, dynamic>))
            .toList(),
        rankings: (json['rankings'] as List<dynamic>? ?? [])
            .map((r) => RankingRow.fromJson(r as Map<String, dynamic>))
            .toList(),
      );
}

/// FTC seasons run roughly September to April and are named by the year
/// they start — e.g. the season that kicks off in September 2026 is
/// "season 2026" even though most of it plays out in 2027.
int currentFtcSeason() {
  final now = DateTime.now();
  return now.month >= 9 ? now.year : now.year - 1;
}
