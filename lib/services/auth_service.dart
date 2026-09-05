import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user.dart';
import 'api_service.dart';

/// Handles Google sign-in and exposes the current logged-in user.
class AuthService extends ChangeNotifier {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  final ApiService _api = ApiService();

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  Future<void> signInWithGoogle() async {
    final account = await _googleSignIn.signIn();
    if (account == null) return; // user cancelled

    final auth = await account.authentication;
    _currentUser = await _api.login(
      provider: 'google',
      idToken: auth.idToken ?? '',
      name: account.displayName ?? account.email,
    );
    notifyListeners();
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    notifyListeners();
  }

  /// Dev-only helper to flip between captain/member views before the
  /// backend actually assigns roles. Remove once real roles are wired up.
  void toggleRoleForTesting() {
    final user = _currentUser;
    if (user == null) return;
    _currentUser = AppUser(
      id: user.id,
      name: user.name,
      email: user.email,
      authProvider: user.authProvider,
      role: user.role == UserRole.captain ? UserRole.member : UserRole.captain,
    );
    notifyListeners();
  }
}
