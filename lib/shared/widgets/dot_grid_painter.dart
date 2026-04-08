import 'package:flutter/material.dart';

/// Draws a subtle dot-grid pattern as a scaffold background.
/// Use only on home screen — dark mode uses slightly higher opacity
/// so dots remain visible on the near-black surface.
class DotGridPainter extends CustomPainter {
  final Color dotColor;
  final double spacing;
  final double radius;

  const DotGridPainter({
    required this.dotColor,
    this.spacing = 20.0,
    this.radius = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(DotGridPainter oldDelegate) =>
      oldDelegate.dotColor != dotColor ||
      oldDelegate.spacing != spacing ||
      oldDelegate.radius != radius;
}
