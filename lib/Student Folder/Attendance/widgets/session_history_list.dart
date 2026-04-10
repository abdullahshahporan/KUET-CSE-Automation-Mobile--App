import 'package:flutter/material.dart';
import 'package:kuet_cse_automation/app_theme.dart';
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
        ...sorted.indexed.map((entry) {
          final i = entry.$1;
          final s = entry.$2;
          return _TimelineRow(
            entry: s,
            isFirst: i == 0,
            isLast: i == sorted.length - 1,
            isDarkMode: isDarkMode,
          );
        }),
      ],
    );
  }

  static Color _dotColor(String status) {
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
        return Icons.check_rounded;
      case 'LATE':
        return Icons.access_time_rounded;
      default:
        return Icons.close_rounded;
    }
  }

  static String _formatDate(DateTime d) => TimeUtils.formatDateTimeUS(d);
}

// ── Timeline row ─────────────────────────────────────────────────────────────
class _TimelineRow extends StatelessWidget {
  final SessionAttendanceEntry entry;
  final bool isFirst;
  final bool isLast;
  final bool isDarkMode;

  const _TimelineRow({
    required this.entry,
    required this.isFirst,
    required this.isLast,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final dotColor = SessionHistoryList._dotColor(entry.status);
    final icon = SessionHistoryList._statusIcon(entry.status);
    final lineColor = AppColors.primary.withValues(alpha: 0.2);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Left: vertical line + dot ──────────────────────────
          SizedBox(
            width: 24,
            child: Column(
              children: [
                // Top connector (transparent for first row, colored for rest)
                Expanded(
                  child: Center(
                    child: Container(
                      width: 2,
                      color: isFirst ? Colors.transparent : lineColor,
                    ),
                  ),
                ),
                // Dot with embedded icon
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Icon(icon, size: 6, color: Colors.white),
                  ],
                ),
                // Bottom connector (hidden for last row)
                Expanded(
                  child: Center(
                    child: Container(
                      width: 2,
                      color: isLast ? Colors.transparent : lineColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Right: content ──────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 12, top: 2, bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    SessionHistoryList._formatDate(entry.date),
                    style: AppTheme.monoStyle.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary(isDarkMode),
                    ),
                  ),
                  if (entry.topic != null && entry.topic!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        entry.topic!,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary(isDarkMode),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (entry.roomNumber != null &&
                      entry.roomNumber!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        entry.roomNumber!,
                        style: AppTheme.monoStyle.copyWith(
                          fontSize: 11,
                          color: AppColors.textSecondary(isDarkMode),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
