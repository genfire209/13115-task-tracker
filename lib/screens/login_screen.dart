import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/background_gear.dart';
import '../widgets/gear_spinner.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _handle(Future<void> Function() signIn) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await signIn();
    } catch (e) {
      setState(() => _error = 'Sign-in failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF17171F), AppTheme.background],
          ),
        ),
        child: Stack(
          children: [
            const BackgroundGear(alignment: Alignment.topLeft, size: 280),
            const BackgroundGear(
              alignment: Alignment.bottomRight,
              size: 360,
              reverse: true,
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppTheme.primary, Color(0xFF8B1029)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.35),
                                blurRadius: 32,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const GearSpinner(
                            icon: Icons.precision_manufacturing,
                            size: 44,
                            duration: Duration(seconds: 12),
                          ),
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'FTC TEAM 13115',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Task Tracker',
                          style: TextStyle(
                            color: AppTheme.onSurfaceMuted,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 56),
                        if (_loading)
                          const GearSpinner(color: AppTheme.primary, size: 36),
                        if (!_loading)
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _handle(auth.signInWithGoogle),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.g_mobiledata,
                                        size: 28,
                                        color: Colors.black87,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Continue with Google',
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (_error != null) ...[
                          const SizedBox(height: 20),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppTheme.statusDeclined,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
