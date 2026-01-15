import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../models/attendance_model.dart';

/// Circular progress widget for displaying attendance percentage
class AttendanceProgressWidget extends StatelessWidget {
  final double percentage;
  final AttendanceStatus status;
  final double size;

  const AttendanceProgressWidget({
    super.key,
    required this.percentage,
    required this.status,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colors = _getStatusColors();

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          CustomPaint(
            size: Size(size, size),
            painter: _CircleProgressPainter(
              progress: percentage / 100,
              backgroundColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
              progressColor: colors[0],
              gradientColor: colors[1],
              strokeWidth: 15,
            ),
          ),
          // Center content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: size * 0.18,
                  fontWeight: FontWeight.bold,
                  color: colors[0],
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: colors[0].withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusText(),
                  style: TextStyle(
                    fontSize: size * 0.07,
                    fontWeight: FontWeight.w600,
                    color: colors[0],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Color> _getStatusColors() {
    switch (status) {
      case AttendanceStatus.safe:
        return [Colors.green[600]!, Colors.teal[400]!];
      case AttendanceStatus.acceptable:
        return [Colors.amber[600]!, Colors.orange[400]!];
      case AttendanceStatus.edging:
        return [Colors.orange[600]!, Colors.deepOrange[400]!];
      case AttendanceStatus.alarming:
        return [Colors.red[600]!, Colors.red[400]!];
    }
  }

  String _getStatusText() {
    switch (status) {
      case AttendanceStatus.safe:
        return 'SAFE';
      case AttendanceStatus.acceptable:
        return 'ACCEPTABLE';
      case AttendanceStatus.edging:
        return 'EDGING';
      case AttendanceStatus.alarming:
        return 'ALARMING';
    }
  }
}

class _CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final Color gradientColor;
  final double strokeWidth;

  _CircleProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.gradientColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: [progressColor, gradientColor, progressColor],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor;
  }
}
