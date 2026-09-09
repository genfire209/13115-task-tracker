enum UserRole { captain, member }

enum Subteam { mechanical, outreach, programming, strategy }

Subteam? subteamFromString(String? s) {
  switch (s) {
    case 'mechanical':
      return Subteam.mechanical;
    case 'outreach':
      return Subteam.outreach;
    case 'programming':
      return Subteam.programming;
    case 'strategy':
      return Subteam.strategy;
    default:
      return null;
  }
}

String subteamToString(Subteam s) {
  switch (s) {
    case Subteam.mechanical:
      return 'mechanical';
    case Subteam.outreach:
      return 'outreach';
    case Subteam.programming:
      return 'programming';
    case Subteam.strategy:
      return 'strategy';
  }
}

String subteamLabel(Subteam s) {
  switch (s) {
    case Subteam.mechanical:
      return 'Mechanical';
    case Subteam.outreach:
      return 'Outreach';
    case Subteam.programming:
      return 'Programming';
    case Subteam.strategy:
      return 'Strategy';
  }
}

List<Subteam> subteamsFromJson(dynamic json) {
  if (json == null) return [];
  return (json as List<dynamic>)
      .map((s) => subteamFromString(s as String?))
      .whereType<Subteam>()
      .toList();
}

/// A user with no subteam yet shows "Onboarding pending"; otherwise their
/// subteam labels joined for display, e.g. "Mechanical, Outreach".
String subteamsLabel(List<Subteam> subteams) {
  if (subteams.isEmpty) return 'Onboarding pending';
  return subteams.map(subteamLabel).join(', ');
}

class AppUser {
  final String id;
  final String name;
  final String email;
  final String authProvider; // "google" or "apple"
  final UserRole role;
  final List<Subteam> subteams; // empty = onboarding not complete yet
  final bool isAdmin; // full captain-level access, independent of the public role label
  final bool approved; // false = waiting on a captain/admin to let them in
  final bool isJunior; // freshman/junior team: only sees tasks assigned to them, no roster, no self-claiming

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.authProvider,
    required this.role,
    this.subteams = const [],
    this.isAdmin = false,
    this.approved = true,
    this.isJunior = false,
  });

  /// True if this account should see captain-only tools, regardless of
  /// what role is publicly displayed for them.
  bool get hasCaptainAccess => role == UserRole.captain || isAdmin;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      authProvider: json['authProvider'] as String,
      role: (json['role'] as String) == 'captain'
          ? UserRole.captain
          : UserRole.member,
      subteams: subteamsFromJson(json['subteams']),
      isAdmin: json['isAdmin'] as bool? ?? false,
      approved: json['approved'] as bool? ?? true,
      isJunior: json['isJunior'] as bool? ?? false,
    );
  }

  AppUser copyWith({String? name, List<Subteam>? subteams, bool? isJunior}) => AppUser(
        id: id,
        name: name ?? this.name,
        email: email,
        authProvider: authProvider,
        role: role,
        subteams: subteams ?? this.subteams,
        isAdmin: isAdmin,
        approved: approved,
        isJunior: isJunior ?? this.isJunior,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'authProvider': authProvider,
        'role': role == UserRole.captain ? 'captain' : 'member',
        'subteams': subteams.map(subteamToString).toList(),
        'isAdmin': isAdmin,
        'approved': approved,
        'isJunior': isJunior,
      };
}
