import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user.dart';
import 'api_service.dart';
import 'notification_service.dart';

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
    unawaited(_registerPushToken());
  }

  /// Best-effort: failures here (permission denied, no APNs token yet on a
  /// simulator, etc.) shouldn't block sign-in.
  Future<void> _registerPushToken() async {
    try {
      final token = await NotificationService.requestPermissionAndGetToken();
      if (token != null && _currentUser != null) {
        await _api.setPushToken(_currentUser!.id, token);
        debugPrint('[push] token registered with backend for ${_currentUser!.id}');
      } else {
        debugPrint('[push] skipping backend registration (token=$token, user=${_currentUser?.id})');
      }
    } catch (e) {
      debugPrint('Could not register push token: $e');
    }
  }

  Future<void> completeProfile({required String name, required Subteam subteam}) async {
    final user = _currentUser;
    if (user == null) return;
    _currentUser = await _api.completeProfile(userId: user.id, name: name, subteam: subteam);
    notifyListeners();
  }

  /// Re-fetches the current user's own record, e.g. to check whether a
  /// captain/admin has approved them yet.
  Future<void> refreshCurrentUser() async {
    final user = _currentUser;
    if (user == null) return;
    _currentUser = await _api.fetchUserById(user.id);
    notifyListeners();
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    notifyListeners();
  }
}
