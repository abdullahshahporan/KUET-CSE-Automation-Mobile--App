import 'package:flutter/material.dart';
import '../../../utils/time_utils.dart';
import '../../models/student_attendance_data.dart';
import '../../../theme/app_colors.dart';

/// Displays a chronological list of class sessions with attendance status.
///
/// Used inside the expanded section of [CourseAttendanceCard].
class SessionHistoryList extends StatelessWidget {
  final List<SessionAttendanceEntry> sessions;

  const SessionHistoryList({super.key, required this.sessions});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (sessions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            'No class sessions yet',
            style: TextStyle(color: AppColors.textSecondary(isDarkMode)),
          ),
        ),
      );
    }

    // Show most recent first
    final sorted = List<SessionAttendanceEntry>.from(sessions)
      ..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Class History',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(isDarkMode),
            ),
          ),
        ),
        ...sorted.map((s) => _buildRow(s, isDarkMode)),
      ],
    );
  }

  Widget _buildRow(SessionAttendanceEntry entry, bool isDarkMode) {
    final statusColor = _statusColor(entry.status);
    final statusIcon = _statusIcon(entry.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Status dot
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(statusIcon, size: 16, color: statusColor),
          ),
          const SizedBox(width: 12),
          // Date & topic
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(entry.date),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary(isDarkMode),
                  ),
                ),
                if (entry.topic != null && entry.topic!.isNotEmpty)
                  Text(
                    entry.topic!,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary(isDarkMode),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              entry.displayStatus,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'PRESENT':
        return AppColors.success;
      case 'LATE':
        return AppColors.warning;
      default:
        return AppColors.danger;
    }
  }

  static IconData _statusIcon(String status) {
    switch (status) {
      case 'PRESENT':
        return Icons.check_circle_rounded;
      case 'LATE':
        return Icons.access_time_rounded;
      default:
        return Icons.cancel_rounded;
    }
  }

  static String _formatDate(DateTime d) => TimeUtils.formatDateTimeUS(d);
}
