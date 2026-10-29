import 'package:flutter/material.dart';

/// Wraps a widget with a slow, subtle breathing pulse — used to draw the eye
/// to things that need action (e.g. a task pending acceptance) without being
/// distracting.
class PulsingBadge extends StatefulWidget {
  final Widget child;
  final bool active;

  const PulsingBadge({super.key, required this.child, this.active = true});

  @override
  State<PulsingBadge> createState() => _PulsingBadgeState();
}

class _PulsingBadgeState extends State<PulsingBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _scale = Tween(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  // Reduce Motion: hold still. The status text still says what's needed.
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active || _reduceMotion) return widget.child;
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}
