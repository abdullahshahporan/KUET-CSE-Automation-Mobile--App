import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

/// Compact stats row showing Present / Late / Absent / Total counts.
class AttendanceStatsHeader extends StatelessWidget {
  final int presentCount;
  final int lateCount;
  final int absentCount;
  final int totalCount;

  const AttendanceStatsHeader({
    super.key,
    required this.presentCount,
    required this.lateCount,
    required this.absentCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface(isDarkMode),
        border: Border(bottom: BorderSide(color: AppColors.border(isDarkMode))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(label: 'Present', value: presentCount, color: AppColors.present),
          _Divider(isDarkMode: isDarkMode),
          _StatItem(label: 'Late', value: lateCount, color: AppColors.late),
          _Divider(isDarkMode: isDarkMode),
          _StatItem(label: 'Absent', value: absentCount, color: AppColors.absent),
          _Divider(isDarkMode: isDarkMode),
          _StatItem(label: 'Total', value: totalCount, color: AppColors.primary),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Center(
            child: Text(
              value.toString(),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary(isDarkMode),
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDarkMode;
  const _Divider({required this.isDarkMode});

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 40, color: AppColors.border(isDarkMode));
}
