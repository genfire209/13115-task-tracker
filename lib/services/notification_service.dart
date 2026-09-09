import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Thin wrapper around Firebase Cloud Messaging: init, permission request,
/// and device token retrieval. The backend does the actual sending.
///
/// Push isn't wired up for the web build (no service worker/VAPID key
/// configured) — every method here is a no-op on web rather than crashing or
/// prompting for a permission that would never lead anywhere. Everything
/// else about the app works the same in a browser; web users just don't get
/// push notifications yet.
class NotificationService {
  static Future<void> initializeFirebase() async {
    if (kIsWeb) return;
    await Firebase.initializeApp();
    // Without this, iOS silently delivers foreground pushes to onMessage
    // with no system banner — only background/terminated ones show by
    // default. This makes foreground behave the same as background.
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  /// Requests notification permission (iOS requires this explicitly) and
  /// returns this device's FCM token, or null if permission was denied.
  static Future<String?> requestPermissionAndGetToken() async {
    if (kIsWeb) return null;
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[push] permission status: ${settings.authorizationStatus}');
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[push] permission denied, not registering');
      return null;
    }

    // On iOS, the native APNs registration completes asynchronously; calling
    // getToken() before it's done throws apns-token-not-set. Give it a
    // moment to show up.
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      String? apnsToken = await messaging.getAPNSToken();
      var attempts = 0;
      while (apnsToken == null && attempts < 15) {
        await Future.delayed(const Duration(seconds: 1));
        apnsToken = await messaging.getAPNSToken();
        attempts++;
      }
      debugPrint('[push] APNS token after $attempts attempt(s): $apnsToken');
      if (apnsToken == null) {
        debugPrint('[push] giving up waiting for APNS token');
        return null;
      }
    }

    final fcmToken = await messaging.getToken();
    debugPrint('[push] FCM token: $fcmToken');
    return fcmToken;
  }
}
