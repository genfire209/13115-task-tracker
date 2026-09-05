import 'package:flutter/material.dart';

/// A continuously-rotating gear, used everywhere the app would otherwise
/// show a generic circular spinner — keeps the mechanical theme going even
/// in loading states.
class GearSpinner extends StatefulWidget {
  final double size;
  final Color color;
  final IconData icon;
  final Duration duration;

  const GearSpinner({
    super.key,
    this.size = 32,
    this.color = Colors.white,
    this.icon = Icons.settings,
    this.duration = const Duration(milliseconds: 1400),
  });

  @override
  State<GearSpinner> createState() => _GearSpinnerState();
}

class _GearSpinnerState extends State<GearSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Icon(widget.icon, size: widget.size, color: widget.color),
    );
  }
}
