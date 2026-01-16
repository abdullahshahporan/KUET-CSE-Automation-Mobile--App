import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../data/static_data.dart';
import 'widgets/attendance_progress_widget.dart';
import 'widgets/course_attendance_card.dart';

/// Main Attendance Tracker screen
class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final overallPercentage = calculateOverallAttendance(sampleAttendanceRecords);
    final overallStatus = _getOverallStatus(overallPercentage);

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey[100],
      appBar: AppBar(
        title: const Text('Attendance Tracker'),
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Overall attendance card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _getStatusGradient(overallStatus),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _getStatusGradient(overallStatus)[0].withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Overall Attendance',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentStudent.semesterName,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Circular progress
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: AttendanceProgressWidget(
                      percentage: overallPercentage,
                      status: overallStatus,
                      size: 180,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Warning message if attendance is low
                  if (overallStatus == AttendanceStatus.alarming)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'You may not sit in Term Final!',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Course-wise attendance header
            Row(
              children: [
                Text(
                  'Course-wise Attendance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${sampleAttendanceRecords.length} Courses',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
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
                color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attendance Guide',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildLegendItem(Colors.green[600]!, '≥ 80%', 'Safe', isDarkMode),
                  _buildLegendItem(Colors.amber[600]!, '70-80%', 'Acceptable', isDarkMode),
                  _buildLegendItem(Colors.orange[600]!, '60-70%', 'Edging', isDarkMode),
                  _buildLegendItem(Colors.red[600]!, '< 60%', 'Cannot sit in Term Final', isDarkMode),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String range, String label, bool isDarkMode) {
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
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '- $label',
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  AttendanceStatus _getOverallStatus(double percentage) {
    if (percentage >= 80) return AttendanceStatus.safe;
    if (percentage >= 70) return AttendanceStatus.acceptable;
    if (percentage >= 60) return AttendanceStatus.edging;
    return AttendanceStatus.alarming;
  }

  List<Color> _getStatusGradient(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.safe:
        return [Colors.green[600]!, Colors.teal[400]!];
      case AttendanceStatus.acceptable:
        return [Colors.amber[600]!, Colors.orange[400]!];
      case AttendanceStatus.edging:
        return [Colors.orange[600]!, Colors.deepOrange[400]!];
      case AttendanceStatus.alarming:
        return [Colors.red[600]!, Colors.red[400]!];
    }
  }
}
