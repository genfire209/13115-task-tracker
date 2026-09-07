import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user.dart';
import 'api_service.dart';
import 'notification_service.dart';

const _kExpectedAccountKey = 'expected_google_account_email';

/// Handles Google sign-in and exposes the current logged-in user.
class AuthService extends ChangeNotifier {
  // serverClientId requests an id token audienced to the shared web OAuth
  // client rather than a platform-specific one, so the same token can be
  // verified server-side regardless of whether it came from iOS or Android.
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: '842144934667-s17d17dsjagqg8qkjel9ankn4ndcbip4.apps.googleusercontent.com',
  );
  final ApiService _api = ApiService();
  final _secureStorage = const FlutterSecureStorage();

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  bool _isRestoring = true;
  bool get isRestoring => _isRestoring;

  /// Called once at app startup. Google Sign-In keeps its own persisted
  /// session (survives app updates and normal closes), so this normally lets
  /// a returning member skip straight past the login screen.
  ///
  /// On a device that's ever had more than one Google account signed into
  /// this app (shared/test devices, or someone with both a personal and a
  /// school account), the native SDK's silent restore isn't guaranteed to
  /// return the account *this app* was last explicitly signed in as — it can
  /// resurrect a different, previously-authorized one instead. We guard
  /// against that by remembering which account we last explicitly signed in
  /// as, and refusing to silently proceed as anyone else: if the restored
  /// account doesn't match, we sign out of it and fall back to the login
  /// screen, so at least the mismatch is visible instead of silently
  /// operating as the wrong person.
  Future<void> tryRestoreSession() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account != null) {
        final expectedEmail = await _secureStorage.read(key: _kExpectedAccountKey);
        if (expectedEmail != null && expectedEmail != account.email) {
          debugPrint(
            '[auth] silent restore returned ${account.email}, expected $expectedEmail — '
            'signing out and requiring an explicit sign-in instead.',
          );
          await _googleSignIn.signOut();
        } else {
          final auth = await account.authentication;
          _currentUser = await _api.login(
            provider: 'google',
            idToken: auth.idToken ?? '',
            name: account.displayName ?? account.email,
          );
          unawaited(_registerPushToken());
        }
      }
    } catch (e) {
      debugPrint('Silent sign-in failed: $e');
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle() async {
    final account = await _googleSignIn.signIn();
    if (account == null) return; // user cancelled

    // On a shared device (e.g. siblings taking turns), the account signing
    // in now is about to start using this device's push token — clear it
    // from whoever used it last, or both accounts would receive each
    // other's notifications on this one physical device.
    final previousEmail = await _secureStorage.read(key: _kExpectedAccountKey);
    if (previousEmail != null && previousEmail != account.email) {
      unawaited(_clearTokenBestEffort(previousEmail));
    }

    final auth = await account.authentication;
    _currentUser = await _api.login(
      provider: 'google',
      idToken: auth.idToken ?? '',
      name: account.displayName ?? account.email,
    );
    await _secureStorage.write(key: _kExpectedAccountKey, value: account.email);
    notifyListeners();
    unawaited(_registerPushToken());
  }

  Future<void> _clearTokenBestEffort(String userId) async {
    try {
      await _api.clearPushToken(userId);
    } catch (e) {
      debugPrint('Could not clear previous account\'s push token: $e');
    }
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
    // Clear this device's token from the outgoing account right away, in
    // case the device sits signed-out for a while before anyone else signs
    // in — otherwise it would keep receiving that account's notifications
    // in the meantime.
    final outgoingUser = _currentUser;
    if (outgoingUser != null) {
      unawaited(_clearTokenBestEffort(outgoingUser.id));
    }
    await _googleSignIn.signOut();
    _currentUser = null;
    notifyListeners();
  }
}
