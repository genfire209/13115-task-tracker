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
  final int? station; // 1 or 2 — FIRST's "Robot 1" / "Robot 2"
  final int teamNumber;
  final String? teamName;

  FtcMatchTeam({required this.alliance, this.station, required this.teamNumber, this.teamName});

  factory FtcMatchTeam.fromJson(Map<String, dynamic> json) => FtcMatchTeam(
        alliance: json['alliance'] as String,
        station: json['station'] as int?,
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

/// What one robot did, from FIRST's score breakdown. [leave] is only
/// scored in auto.
class RobotActions {
  final int? teamNumber;
  final bool leave;
  final bool park;

  RobotActions({this.teamNumber, this.leave = false, required this.park});

  factory RobotActions.fromJson(Map<String, dynamic> json) => RobotActions(
        teamNumber: json['teamNumber'] as int?,
        leave: json['leave'] as bool? ?? false,
        park: json['park'] as bool,
      );
}

/// One alliance's half of a match breakdown — the numbers on its FIRST
/// match page (ScoreDetailAllianceModel_2026).
class AllianceBreakdown {
  final int autoTips;
  final List<RobotActions> autoRobots;
  final int autoLeavePoints;
  final int autoParkPoints;
  final int autoHivePoints;
  final int autoPoints;
  final int teleopTips;
  final int hiveBalls; // POLLEN/NECTAR left in the up CELL
  final int gardenBalls;
  final List<RobotActions> teleopRobots;
  final int teleopHivePoints;
  final int teleopFlowerPoints;
  final int teleopGardenPoints;
  final int teleopParkPoints;
  final int teleopPoints;
  final int penaltyPoints; // awarded to this alliance for the other's fouls
  final int minorFouls; // committed by this alliance
  final int majorFouls;
  final int total;

  AllianceBreakdown.fromJson(Map<String, dynamic> json)
      : autoTips = (json['auto'] as Map<String, dynamic>)['tips'] as int,
        autoRobots = _robots(json['auto']),
        autoLeavePoints = (json['auto'] as Map<String, dynamic>)['leavePoints'] as int,
        autoParkPoints = (json['auto'] as Map<String, dynamic>)['parkPoints'] as int,
        autoHivePoints = (json['auto'] as Map<String, dynamic>)['hivePoints'] as int,
        autoPoints = (json['auto'] as Map<String, dynamic>)['points'] as int,
        teleopTips = (json['teleop'] as Map<String, dynamic>)['tips'] as int,
        hiveBalls = (json['teleop'] as Map<String, dynamic>)['hiveBalls'] as int,
        gardenBalls = (json['teleop'] as Map<String, dynamic>)['gardenBalls'] as int,
        teleopRobots = _robots(json['teleop']),
        teleopHivePoints = (json['teleop'] as Map<String, dynamic>)['hivePoints'] as int,
        teleopFlowerPoints = (json['teleop'] as Map<String, dynamic>)['flowerPoints'] as int,
        teleopGardenPoints = (json['teleop'] as Map<String, dynamic>)['gardenPoints'] as int,
        teleopParkPoints = (json['teleop'] as Map<String, dynamic>)['parkPoints'] as int,
        teleopPoints = (json['teleop'] as Map<String, dynamic>)['points'] as int,
        penaltyPoints = json['penaltyPoints'] as int? ?? 0,
        minorFouls = json['minorFouls'] as int? ?? 0,
        majorFouls = json['majorFouls'] as int? ?? 0,
        total = json['total'] as int;

  static List<RobotActions> _robots(dynamic period) => ((period as Map<String, dynamic>)['robots'] as List<dynamic>)
      .map((r) => RobotActions.fromJson(r as Map<String, dynamic>))
      .toList();
}

/// Ranking points an alliance earned from a played match. The bonus RPs
/// are only known once FIRST posts the breakdown ([bonusKnown]).
class AllianceRankingPoints {
  final int win; // 3 win, 1 tie, 0 loss
  final bool swarm;
  final bool pollinator1;
  final bool pollinator2;
  final int total;
  final bool bonusKnown;

  AllianceRankingPoints.fromJson(Map<String, dynamic> json)
      : win = json['win'] as int,
        swarm = json['swarm'] as bool? ?? false,
        pollinator1 = json['pollinator1'] as bool? ?? false,
        pollinator2 = json['pollinator2'] as bool? ?? false,
        total = json['total'] as int,
        bonusKnown = json['bonusKnown'] as bool? ?? false;
}

/// What's in each FLOWER, bottom to top: 'RED_NECTAR', 'BLUE_NECTAR' or 'POLLEN'.
class Flowers {
  final List<String> redWall;
  final List<String> scoring;
  final List<String> blueWall;
  final List<String> audience;

  Flowers.fromJson(Map<String, dynamic> json)
      : redWall = _list(json['redWall']),
        scoring = _list(json['scoring']),
        blueWall = _list(json['blueWall']),
        audience = _list(json['audience']);

  static List<String> _list(dynamic v) => (v as List<dynamic>? ?? []).cast<String>();
}

/// One match in full, like its page on ftc-events.firstinspires.org.
class MatchDetail {
  final int season;
  final String eventCode;
  final String eventName;
  final int ourTeam;
  final FtcMatch match;
  final AllianceBreakdown? red; // null until FIRST posts the breakdown
  final AllianceBreakdown? blue;
  final Flowers? flowers;
  final AllianceRankingPoints? redRankingPoints; // null until played
  final AllianceRankingPoints? blueRankingPoints;

  MatchDetail({
    required this.season,
    required this.eventCode,
    required this.eventName,
    required this.ourTeam,
    required this.match,
    this.red,
    this.blue,
    this.flowers,
    this.redRankingPoints,
    this.blueRankingPoints,
  });

  factory MatchDetail.fromJson(Map<String, dynamic> json) {
    final breakdown = json['breakdown'] as Map<String, dynamic>?;
    final rp = json['rankingPoints'] as Map<String, dynamic>?;
    return MatchDetail(
      season: json['season'] as int,
      eventCode: json['eventCode'] as String,
      eventName: json['eventName'] as String,
      ourTeam: json['ourTeam'] as int,
      match: FtcMatch.fromJson(json['match'] as Map<String, dynamic>),
      red: breakdown == null ? null : AllianceBreakdown.fromJson(breakdown['red'] as Map<String, dynamic>),
      blue: breakdown == null ? null : AllianceBreakdown.fromJson(breakdown['blue'] as Map<String, dynamic>),
      flowers: breakdown == null ? null : Flowers.fromJson(breakdown['flowers'] as Map<String, dynamic>),
      redRankingPoints: rp == null ? null : AllianceRankingPoints.fromJson(rp['red'] as Map<String, dynamic>),
      blueRankingPoints: rp == null ? null : AllianceRankingPoints.fromJson(rp['blue'] as Map<String, dynamic>),
    );
  }
}

/// FTC seasons run roughly September to April and are named by the year
/// they start — e.g. the season that kicks off in September 2026 is
/// "season 2026" even though most of it plays out in 2027.
int currentFtcSeason() {
  final now = DateTime.now();
  return now.month >= 9 ? now.year : now.year - 1;
}
