enum UserRole { captain, member }

class AppUser {
  final String id;
  final String name;
  final String email;
  final String authProvider; // "google" or "apple"
  final UserRole role;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.authProvider,
    required this.role,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      authProvider: json['authProvider'] as String,
      role: (json['role'] as String) == 'captain'
          ? UserRole.captain
          : UserRole.member,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'authProvider': authProvider,
        'role': role == UserRole.captain ? 'captain' : 'member',
      };
}
