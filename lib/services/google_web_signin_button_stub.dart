import 'package:flutter/widgets.dart';

/// Non-web platforms don't need a rendered button — they use the app's own
/// "Continue with Google" button via [AuthService.signInWithGoogle] instead.
Widget buildGoogleWebSignInButton() => const SizedBox.shrink();
