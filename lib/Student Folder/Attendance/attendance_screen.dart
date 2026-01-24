import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../data/static_data.dart';
import 'widgets/course_attendance_card.dart';
import '../../theme/app_colors.dart';

/// Main Attendance Tracker screen
class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      appBar: AppBar(
        title: Text(
          'Attendance Tracker',
          style: TextStyle(color: AppColors.textPrimary(isDarkMode)),
        ),
        backgroundColor: AppColors.surface(isDarkMode),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary(isDarkMode),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course-wise attendance header
            Row(
              children: [
                Text(
                  'Course-wise Attendance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(isDarkMode),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${sampleAttendanceRecords.length} Courses',
                    style: TextStyle(fontSize: 12, color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Course attendance cards
            ...sampleAttendanceRecords.map(
              (record) => CourseAttendanceCard(record: record),
            ),

            // Legend
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface(isDarkMode),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border(isDarkMode)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attendance Guide',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(isDarkMode),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildLegendItem(
                    AppColors.success,
                    '≥ 80%',
                    'Safe',
                    isDarkMode,
                  ),
                  _buildLegendItem(
                    AppColors.warning,
                    '70-80%',
                    'Acceptable',
                    isDarkMode,
                  ),
                  _buildLegendItem(
                    const Color(0xFFF97316),
                    '60-70%',
                    'Edging',
                    isDarkMode,
                  ),
                  _buildLegendItem(
                    AppColors.danger,
                    '< 60%',
                    'Cannot sit in Term Final',
                    isDarkMode,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(
    Color color,
    String range,
    String label,
    bool isDarkMode,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            range,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(isDarkMode),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '- $label',
            style: TextStyle(color: AppColors.textSecondary(isDarkMode)),
          ),
        ],
      ),
    );
  }
}
