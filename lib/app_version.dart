import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'services/api_service.dart';

/// Forced updates. The server keeps the oldest build still allowed; an
/// admin raises it from Profile once a new build is out. Older builds get
/// 426 from every request, and the app shows UpdateRequiredScreen until
/// it's updated.
class AppVersion {
  /// This install's build number (the +N in pubspec.yaml), sent with every
  /// request as X-App-Build.
  static int build = 0;

  /// True once the server says this build is too old.
  static final updateRequired = ValueNotifier<bool>(false);

  static Future<void> load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      build = int.tryParse(info.buildNumber) ?? 0;
    } catch (e) {
      debugPrint('[version] could not read the build number: $e');
    }
  }

  /// Asks the server for the minimum build. Offline is fine: every request
  /// still gets 426 if this build is too old.
  static Future<void> check() async {
    try {
      updateRequired.value = build < await ApiService().fetchMinimumBuild();
    } catch (e) {
      debugPrint('[version] check failed: $e');
    }
  }
}
