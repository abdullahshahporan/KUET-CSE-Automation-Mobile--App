import 'package:flutter/material.dart';
import '../../models/student_attendance_data.dart';
import '../../../theme/app_colors.dart';

/// Reusable widget: overall attendance summary bar across all courses.
///
/// Shows total present / late / absent and a weighted average percentage.
class OverallAttendanceSummary extends StatelessWidget {
  final List<CourseAttendanceSummary> courses;

  const OverallAttendanceSummary({super.key, required this.courses});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    int totalSessions = 0, totalPresent = 0, totalLate = 0, totalAbsent = 0;
    for (final c in courses) {
      totalSessions += c.totalSessions;
      totalPresent += c.presentCount;
      totalLate += c.lateCount;
      totalAbsent += c.absentCount;
    }
    final attended = totalPresent + totalLate;
    final percentage =
        totalSessions > 0 ? (attended / totalSessions * 100) : 0.0;
    final color = _colorForPercentage(percentage);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(isDarkMode ? 0.15 : 0.08),
            color.withOpacity(isDarkMode ? 0.05 : 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // --- Percentage display ---
          Row(
            children: [
              _buildCircle(percentage, color, isDarkMode),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overall Attendance',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(isDarkMode),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$attended attended out of $totalSessions classes',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary(isDarkMode),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // --- Stat chips ---
          Row(
            children: [
              _chip(Icons.check_circle_rounded, 'Present', '$totalPresent',
                  AppColors.success, isDarkMode),
              const SizedBox(width: 8),
              _chip(Icons.access_time_rounded, 'Late', '$totalLate',
                  AppColors.warning, isDarkMode),
              const SizedBox(width: 8),
              _chip(Icons.cancel_rounded, 'Absent', '$totalAbsent',
                  AppColors.danger, isDarkMode),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircle(double pct, Color color, bool isDarkMode) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: pct / 100,
            strokeWidth: 5,
            backgroundColor: AppColors.border(isDarkMode),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            strokeCap: StrokeCap.round,
          ),
          Text(
            '${pct.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(
      IconData icon, String label, String value, Color color, bool isDarkMode) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _colorForPercentage(double p) {
    if (p >= 80) return AppColors.success;
    if (p >= 70) return AppColors.warning;
    if (p >= 60) return const Color(0xFFF97316);
    return AppColors.danger;
  }
}
