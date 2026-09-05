import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../models/user.dart';

/// Handles Google / Apple sign-in and exposes the current logged-in user.
///
/// TODO before this works end-to-end:
///  - Add your Google OAuth client ID (google-services.json for Android,
///    GoogleService-Info.plist / URL scheme for iOS).
///  - Enable "Sign in with Apple" capability in the Xcode project.
///  - Point `_verifyWithBackend` at your real Azure Functions endpoint,
///    which should verify the id token server-side and return your own
///    app user record (creating one on first login).
class AuthService extends ChangeNotifier {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  Future<void> signInWithGoogle() async {
    final account = await _googleSignIn.signIn();
    if (account == null) return; // user cancelled

    final auth = await account.authentication;
    _currentUser = await _verifyWithBackend(
      idToken: auth.idToken ?? '',
      provider: 'google',
      name: account.displayName ?? account.email,
      email: account.email,
    );
    notifyListeners();
  }

  Future<void> signInWithApple() async {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final name = [credential.givenName, credential.familyName]
        .where((s) => s != null && s.isNotEmpty)
        .join(' ');

    _currentUser = await _verifyWithBackend(
      idToken: credential.identityToken ?? '',
      provider: 'apple',
      name: name.isNotEmpty ? name : (credential.email ?? 'Apple User'),
      email: credential.email ?? '',
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

  /// Sends the provider's id token to our backend for verification and
  /// gets back our own app user record (id, name, email, role).
  ///
  /// Currently mocked locally so the app runs before the backend exists.
  Future<AppUser> _verifyWithBackend({
    required String idToken,
    required String provider,
    required String name,
    required String email,
  }) async {
    // TODO: replace with a real call, e.g.:
    // final res = await http.post(Uri.parse('$apiBaseUrl/auth/login'), ...);
    // return AppUser.fromJson(jsonDecode(res.body));
    return AppUser(
      id: email,
      name: name,
      email: email,
      authProvider: provider,
      role: UserRole.member,
    );
  }
}
