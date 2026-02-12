import 'package:flutter/material.dart';
import '../../models/enrolled_student.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/animated_components.dart';

/// Attendance status for a single student.
enum AttendanceStatus { present, late, absent }

extension AttendanceStatusX on AttendanceStatus {
  String get label => switch (this) {
        AttendanceStatus.present => 'P',
        AttendanceStatus.late => 'L',
        AttendanceStatus.absent => 'A',
      };

  Color get color => switch (this) {
        AttendanceStatus.present => AppColors.present,
        AttendanceStatus.late => AppColors.late,
        AttendanceStatus.absent => AppColors.absent,
      };

  String get apiValue => name.toUpperCase(); // "PRESENT", "LATE", "ABSENT"
}

/// A single student row in the roll-call list with P / L / A buttons.
class StudentAttendanceCard extends StatelessWidget {
  final EnrolledStudent student;
  final AttendanceStatus status;
  final int index;
  final ValueChanged<AttendanceStatus> onStatusChanged;

  const StudentAttendanceCard({
    super.key,
    required this.student,
    required this.status,
    required this.index,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final statusColor = status.color;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 30).clamp(0, 300)),
      curve: Curves.easeOut,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, 20 * (1 - value)),
        child: Opacity(opacity: value, child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated(isDarkMode),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Roll badge
            Container(
              width: 72,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Text(
                student.rollNo.substring(student.rollNo.length - 3),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: statusColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.fullName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.textPrimary(isDarkMode),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Roll: ${student.rollNo}',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            // Status buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: AttendanceStatus.values.map((s) {
                return Padding(
                  padding: EdgeInsets.only(left: s == AttendanceStatus.present ? 0 : 8),
                  child: AnimatedStatusButton(
                    label: s.label,
                    color: s.color,
                    isSelected: status == s,
                    onTap: () => onStatusChanged(s),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
