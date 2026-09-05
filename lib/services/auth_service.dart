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

  Future<void> completeProfile({required String name, required Subteam subteam}) async {
    final user = _currentUser;
    if (user == null) return;
    _currentUser = await _api.completeProfile(userId: user.id, name: name, subteam: subteam);
    notifyListeners();
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    notifyListeners();
  }
}
