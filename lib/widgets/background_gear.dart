import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A large, very faint, slowly-rotating gear used as a decorative watermark
/// on auth-adjacent screens (login/onboarding/pending-approval) to keep the
/// mechanical theme alive without competing with the actual content.
class BackgroundGear extends StatefulWidget {
  final double size;
  final Alignment alignment;
  final bool reverse;

  const BackgroundGear({
    super.key,
    this.size = 320,
    this.alignment = Alignment.bottomRight,
    this.reverse = false,
  });

  @override
  State<BackgroundGear> createState() => _BackgroundGearState();
}

class _BackgroundGearState extends State<BackgroundGear>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat(reverse: false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: widget.alignment,
        child: FractionalTranslation(
          translation: Offset(
            widget.alignment.x > 0 ? 0.35 : -0.35,
            widget.alignment.y > 0 ? 0.35 : -0.35,
          ),
          child: RotationTransition(
            turns: widget.reverse
                ? Tween(begin: 1.0, end: 0.0).animate(_controller)
                : _controller,
            child: Icon(
              Icons.settings,
              size: widget.size,
              color: AppTheme.primary.withValues(alpha: 0.06),
            ),
          ),
        ),
      ),
    );
  }
}
