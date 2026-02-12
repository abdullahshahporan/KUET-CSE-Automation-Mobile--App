import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

/// Animated progress bar showing attendance rate percentage.
class AttendanceProgressBar extends StatelessWidget {
  final double percentage;

  const AttendanceProgressBar({super.key, required this.percentage});

  Color get _color => percentage >= 80
      ? AppColors.success
      : percentage >= 60
          ? AppColors.warning
          : AppColors.danger;

  IconData get _icon => percentage >= 80
      ? Icons.trending_up
      : percentage >= 60
          ? Icons.trending_flat
          : Icons.trending_down;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface(isDarkMode)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Attendance Rate',
                style: TextStyle(
                  color: AppColors.textSecondary(isDarkMode),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _color),
                  ),
                  const SizedBox(width: 4),
                  Icon(_icon, color: _color, size: 20),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.border(isDarkMode),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 8,
                    width: constraints.maxWidth * (percentage / 100).clamp(0, 1),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_color.withOpacity(0.8), _color],
                      ),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: _color.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
