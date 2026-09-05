import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/background_gear.dart';
import '../widgets/gear_spinner.dart';

/// Shown after onboarding completes, until a captain/admin approves the
/// account. Lets the student re-check without having to sign out/in.
class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  bool _checking = false;

  Future<void> _checkAgain() async {
    setState(() => _checking = true);
    try {
      await context.read<AuthService>().refreshCurrentUser();
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
              child: Padding(
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
                      child: const GearSpinner(
                        size: 40,
                        color: AppTheme.primary,
                        duration: Duration(seconds: 3),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Waiting for approval',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "You're all set up — a captain just needs to approve your account "
                      'before you can see the task board.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.onSurfaceMuted),
                    ),
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: _checking ? null : _checkAgain,
                      child: _checking
                          ? const GearSpinner(size: 20)
                          : const Text('Check again'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.read<AuthService>().signOut(),
                      child: const Text('Sign out'),
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
