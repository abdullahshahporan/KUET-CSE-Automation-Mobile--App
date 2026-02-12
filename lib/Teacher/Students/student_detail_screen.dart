import 'package:flutter/material.dart';
import '../models/enrolled_student.dart';
import '../../theme/app_colors.dart';

/// Student Detail screen - view individual student details
class StudentDetailScreen extends StatelessWidget {
  final EnrolledStudent student;
  final String? courseCode;

  const StudentDetailScreen({
    super.key,
    required this.student,
    this.courseCode,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      appBar: AppBar(
        title: Text(student.rollNo),
        backgroundColor: AppColors.surface(isDarkMode),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal[600]!, Colors.cyan[500]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      student.initial,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    student.fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    student.rollNo,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildBadge(
                        'Section ${student.derivedSection}',
                        Colors.white.withOpacity(0.2),
                      ),
                      const SizedBox(width: 8),
                      _buildBadge(
                        'Batch ${student.batch}',
                        Colors.white.withOpacity(0.2),
                      ),
                      if (student.cgpa > 0) ...[
                        const SizedBox(width: 8),
                        _buildBadge(
                          'CGPA ${student.cgpa.toStringAsFixed(2)}',
                          Colors.white.withOpacity(0.2),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Info Cards
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    'Section',
                    student.derivedSection,
                    Icons.group,
                    AppColors.primary,
                    isDarkMode,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoCard(
                    'Semester',
                    student.termDisplay,
                    Icons.school,
                    AppColors.info,
                    isDarkMode,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Academic Details
            Text(
              'Academic Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(isDarkMode),
              ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Department', 'CSE', isDarkMode),
            _buildDetailRow('Semester', student.termDisplay, isDarkMode),
            _buildDetailRow('Session', student.session, isDarkMode),
            _buildDetailRow('Batch', student.batch ?? '', isDarkMode),
            _buildDetailRow('Status', student.enrollmentStatus, isDarkMode),
            if (student.phone.isNotEmpty)
              _buildDetailRow('Phone', student.phone, isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDarkMode,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(isDarkMode),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary(isDarkMode),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface(isDarkMode),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.textSecondary(isDarkMode)),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary(isDarkMode),
            ),
          ),
        ],
      ),
    );
  }
}
