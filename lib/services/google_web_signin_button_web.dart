import 'package:flutter/material.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart';

/// Renders Google's actual "Sign in with Google" button.
///
/// This is required on web, not a style choice: `GoogleSignIn.signIn()`
/// can't reliably return an ID token in a browser (Google's own package
/// warns about this — the newer Identity Services API only hands out a real
/// ID token through this rendered button or a silent one-tap prompt, not an
/// imperative popup call). The resulting sign-in surfaces through
/// AuthService's `onCurrentUserChanged` listener, same as everywhere else.
Widget buildGoogleWebSignInButton() {
  final web = GoogleSignInPlatform.instance as GoogleSignInPlugin;
  return SizedBox(
    height: 44,
    width: double.infinity,
    child: web.renderButton(
      configuration: GSIButtonConfiguration(
        type: GSIButtonType.standard,
        theme: GSIButtonTheme.filledBlack,
        size: GSIButtonSize.large,
        shape: GSIButtonShape.pill,
        logoAlignment: GSIButtonLogoAlignment.center,
        text: GSIButtonText.signinWith,
      ),
    ),
  );
}
