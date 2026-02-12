import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class CourseStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDarkMode;

  const CourseStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface(isDarkMode),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(isDarkMode)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDarkMode),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary(isDarkMode),
            ),
          ),
        ],
      ),
    );
  }
}
