import 'package:flutter/material.dart';

/// Caps content width and centers it on wide viewports (desktop/web) while
/// staying a no-op on phone-width screens. Without this, list-based screens
/// stretch edge-to-edge on a browser window and look unfinished.
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveCenter({super.key, required this.child, this.maxWidth = 760});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
