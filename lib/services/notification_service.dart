import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Thin wrapper around Firebase Cloud Messaging: init, permission request,
/// and device token retrieval. The backend does the actual sending.
class NotificationService {
  static Future<void> initializeFirebase() async {
    await Firebase.initializeApp();
    // Without this, iOS silently delivers foreground pushes to onMessage
    // with no system banner — only background/terminated ones show by
    // default. This makes foreground behave the same as background.
    if (Platform.isIOS) {
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
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return null;
    }

    // On iOS, the native APNs registration completes asynchronously; calling
    // getToken() before it's done throws apns-token-not-set. Give it a
    // moment to show up.
    if (Platform.isIOS) {
      String? apnsToken = await messaging.getAPNSToken();
      var attempts = 0;
      while (apnsToken == null && attempts < 10) {
        await Future.delayed(const Duration(seconds: 1));
        apnsToken = await messaging.getAPNSToken();
        attempts++;
      }
      if (apnsToken == null) return null;
    }

    return messaging.getToken();
  }
}
