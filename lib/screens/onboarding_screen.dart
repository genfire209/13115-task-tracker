import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/background_gear.dart';
import '../widgets/gear_spinner.dart';

/// Shown once, right after a user's first sign-in (subteam is still null).
/// Collects their real full name and which subteam they're on.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final TextEditingController _nameController;
  Subteam? _subteam;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _subteam == null) {
      setState(() => _error = 'Please enter your name and pick a subteam.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await context.read<AuthService>().completeProfile(
        name: name,
        subteam: _subteam!,
      );
    } catch (e) {
      setState(() => _error = 'Could not save your profile: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const BackgroundGear(alignment: Alignment.topRight, size: 260),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const GearSpinner(
                          icon: Icons.badge_outlined,
                          size: 36,
                          color: AppTheme.primary,
                          duration: Duration(seconds: 14),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Welcome to the team',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tell us who you are so your captain knows who\'s who.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.onSurfaceMuted),
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<Subteam>(
                        initialValue: _subteam,
                        decoration: const InputDecoration(labelText: 'Subteam'),
                        hint: const Text('Choose your subteam'),
                        items: Subteam.values
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: AppTheme.subteamColor(s),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(subteamLabel(s)),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _subteam = v),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: const TextStyle(
                            color: AppTheme.statusDeclined,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _submitting ? null : _submit,
                        child: _submitting
                            ? const GearSpinner(size: 20)
                            : const Text('Continue'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
