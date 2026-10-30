import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app_version.dart';
import '../theme/app_theme.dart';
import '../widgets/background_gear.dart';
import '../widgets/gear_spinner.dart';

/// For MaterialApp.builder: covers every screen, including ones already
/// open, with UpdateRequiredScreen while AppVersion.updateRequired is set.
Widget lockWhenUpdateRequired(BuildContext context, Widget? child) => ValueListenableBuilder<bool>(
      valueListenable: AppVersion.updateRequired,
      builder: (context, updateRequired, _) => updateRequired ? const UpdateRequiredScreen() : child!,
    );

/// Covers the whole app when the server says this build is too old (see
/// AppVersion). Nothing else works until the app is updated; "Check again"
/// is for when an admin lowers the requirement.
class UpdateRequiredScreen extends StatefulWidget {
  const UpdateRequiredScreen({super.key});

  @override
  State<UpdateRequiredScreen> createState() => _UpdateRequiredScreenState();
}

class _UpdateRequiredScreenState extends State<UpdateRequiredScreen> {
  bool _checking = false;

  Future<void> _checkAgain() async {
    setState(() => _checking = true);
    try {
      await AppVersion.check();
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const BackgroundGear(alignment: Alignment.bottomLeft, size: 300),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.system_update, size: 40, color: AppTheme.primary),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Update required',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      kIsWeb
                          ? 'A new version of the app is out. Reload this page to get it.'
                          : 'A new version of the app is out. Open the TestFlight app, tap Update '
                              'next to 13115 Task Tracker, then open this app again.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.onSurfaceMuted),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This is build ${AppVersion.build}.',
                      style: const TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: _checking ? null : _checkAgain,
                      child: _checking ? const GearSpinner(size: 20) : const Text('Check again'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
