import 'package:flutter/material.dart';
import '../../models/attendance_model.dart';

/// Card widget displaying attendance for a single course
class CourseAttendanceCard extends StatelessWidget {
  final AttendanceRecord record;

  const CourseAttendanceCard({
    super.key,
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colors = _getStatusColors();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colors[0].withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  record.courseCode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  record.courseName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(
                  height: 12,
                  width: double.infinity,
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                ),
                FractionallySizedBox(
                  widthFactor: record.percentage / 100,
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: colors,
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: colors[0],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${record.attendedClasses}/${record.totalClasses} Classes',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors[0].withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${record.percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: colors[0],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Color> _getStatusColors() {
    switch (record.status) {
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
