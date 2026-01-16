import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kuet_cse_automation/Student%20Folder/providers/app_providers.dart';

class AttendanceTrackerScreen extends ConsumerWidget {
  const AttendanceTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final attendanceRecords = ref.watch(attendanceProvider);

    // Calculate overall attendance
    int totalClasses = 0;
    int totalAttended = 0;
    for (var record in attendanceRecords) {
      totalClasses += record.totalClasses;
      totalAttended += record.attendedClasses;
    }
    final overallPercentage = (totalAttended / totalClasses * 100).toStringAsFixed(2);

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey[100],
      appBar: AppBar(
        title: const Text('Attendance Tracker'),
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Overall Attendance Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[700]!, Colors.cyan[500]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
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
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '$overallPercentage%',
                  style: const TextStyle(
                    fontSize: 48,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$totalAttended / $totalClasses classes attended',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),

          // Course-wise Attendance
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: attendanceRecords.length,
              itemBuilder: (context, index) {
                final record = attendanceRecords[index];
                final percentage = record.percentage;
                final isLow = percentage < 80;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: isLow
                        ? Border.all(color: Colors.red.withOpacity(0.5), width: 2)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  record.courseName,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  record.courseCode,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _getPercentageColor(percentage).withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${percentage.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _getPercentageColor(percentage),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Present: ${record.attendedClasses}',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Icon(
                            Icons.cancel,
                            size: 16,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Absent: ${record.totalClasses - record.attendedClasses}',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          minHeight: 8,
                          backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getPercentageColor(percentage),
                          ),
                        ),
                      ),
                      if (isLow)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            children: [
                              Icon(Icons.warning, size: 16, color: Colors.red[700]),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Attendance below 80%! Need ${_calculateRequiredClasses(record)} consecutive classes.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getPercentageColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 80) return Colors.blue;
    if (percentage >= 70) return Colors.orange;
    return Colors.red;
  }

  int _calculateRequiredClasses(record) {
    if (record.percentage >= 80) return 0;
    int required = 0;
    int attended = record.attendedClasses;
    int total = record.totalClasses;

    while ((attended / total * 100) < 80) {
      attended++;
      total++;
      required++;
    }
    return required;
  }
}
