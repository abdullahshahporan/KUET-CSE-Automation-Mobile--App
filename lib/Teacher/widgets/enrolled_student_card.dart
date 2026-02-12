import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../models/enrolled_student.dart';

class EnrolledStudentCard extends StatelessWidget {
  final EnrolledStudent student;
  final bool isDarkMode;
  final VoidCallback? onTap;

  const EnrolledStudentCard({
    super.key,
    required this.student,
    required this.isDarkMode,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface(isDarkMode),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border(isDarkMode)),
        ),
        child: Row(
          children: [
            // Avatar with initial
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  student.initial,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Student info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.fullName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(isDarkMode),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Roll: ${student.rollNo}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary(isDarkMode),
                        ),
                      ),
                      if (student.cgpa > 0) ...[
                        Text(
                          ' • ',
                          style: TextStyle(
                            color: AppColors.textMuted,
                          ),
                        ),
                        Text(
                          'CGPA: ${student.cgpa.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary(isDarkMode),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Section badge (derived from roll number)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                student.derivedSection,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
