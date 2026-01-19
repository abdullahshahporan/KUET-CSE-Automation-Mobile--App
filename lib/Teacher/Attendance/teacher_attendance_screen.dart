import 'package:flutter/material.dart';
import '../data/teacher_static_data.dart';
import '../../Student Folder/models/course_model.dart';
import '../../theme/app_colors.dart';
import 'roll_call_screen.dart';

/// Teacher Attendance screen - Course-specific with date picker
class TeacherAttendanceScreen extends StatefulWidget {
  final TeacherCourse? preSelectedCourse;
  
  const TeacherAttendanceScreen({super.key, this.preSelectedCourse});

  @override
  State<TeacherAttendanceScreen> createState() => _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  
  TeacherCourse get course => widget.preSelectedCourse!;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final color = course.type == CourseType.theory ? AppColors.primary : AppColors.accent;

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      appBar: AppBar(
        title: Text(
          '${course.code} - Attendance',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface(isDarkMode),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showAttendanceHistory(context, isDarkMode),
            tooltip: 'View History',
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Selector
            _buildDateCard(isDarkMode),
            const SizedBox(height: 20),
            
            // Progress info
            _buildProgressCard(isDarkMode, color),
            const SizedBox(height: 20),
            
            // Select Section/Group
            Text(
              course.type == CourseType.theory ? 'Select Section' : 'Select Group',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(isDarkMode),
              ),
            ),
            const SizedBox(height: 12),
            
            if (course.type == CourseType.theory)
              _buildSectionSelector(isDarkMode)
            else
              _buildGroupSelector(isDarkMode),
            
            const SizedBox(height: 24),
            
            // Recent Attendance
            Text(
              'Recent Records',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(isDarkMode),
              ),
            ),
            const SizedBox(height: 12),
            _buildRecentRecords(isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildDateCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(isDarkMode),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(isDarkMode)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.calendar_today, color: AppColors.success, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary(isDarkMode),
                  ),
                ),
                Text(
                  _formatDate(_selectedDate),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(isDarkMode),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _selectDate(context),
            child: Text(
              'Change',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(bool isDarkMode, Color color) {
    final attendanceCount = course.type == CourseType.theory
        ? getAttendanceCount(course.code, course.sections.first)
        : getAttendanceCount(course.code, course.groups.first);
    final progress = attendanceCount / course.expectedClasses;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(isDarkMode),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(isDarkMode)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Classes Progress',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary(isDarkMode),
                ),
              ),
              Text(
                '$attendanceCount of ${course.expectedClasses}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.border(isDarkMode),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionSelector(bool isDarkMode) {
    return Row(
      children: course.sections.map((section) {
        final color = section == 'A' ? AppColors.primary : AppColors.accent;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: section == course.sections.last ? 0 : 10),
            child: _buildSelectorCard(
              title: 'Section $section',
              subtitle: section == 'A' ? 'Roll 001-060' : 'Roll 061-120',
              count: '60 students',
              color: color,
              isDarkMode: isDarkMode,
              onTap: () => _navigateToRollCall(section),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGroupSelector(bool isDarkMode) {
    final colors = {
      'A1': AppColors.primary,
      'A2': AppColors.info,
      'B1': AppColors.accent,
      'B2': AppColors.teal,
    };
    final rollRanges = {
      'A1': '001-030',
      'A2': '031-060',
      'B1': '061-090',
      'B2': '091-120',
    };

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.3,
      children: course.groups.map((group) {
        return _buildSelectorCard(
          title: 'Group $group',
          subtitle: 'Roll ${rollRanges[group]}',
          count: '30 students',
          color: colors[group]!,
          isDarkMode: isDarkMode,
          onTap: () => _navigateToRollCall(group),
        );
      }).toList(),
    );
  }

  Widget _buildSelectorCard({
    required String title,
    required String subtitle,
    required String count,
    required Color color,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(Icons.groups, color: color, size: 22),
                const Spacer(),
                Icon(Icons.arrow_forward_ios, color: color, size: 14),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.8),
              ),
            ),
            Text(
              count,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary(isDarkMode),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentRecords(bool isDarkMode) {
    final courseRecords = attendanceSessions
        .where((s) => s.courseCode == course.code)
        .take(5)
        .toList();

    if (courseRecords.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface(isDarkMode),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border(isDarkMode)),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.event_busy, size: 40, color: AppColors.textMuted),
              const SizedBox(height: 8),
              Text(
                'No attendance records yet',
                style: TextStyle(color: AppColors.textSecondary(isDarkMode)),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: courseRecords.map((session) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface(isDarkMode),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border(isDarkMode)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.check_circle, color: AppColors.success, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${course.type == CourseType.theory ? "Section" : "Group"} ${session.sectionOrGroup}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary(isDarkMode),
                      ),
                    ),
                    Text(
                      _formatDate(session.date),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary(isDarkMode),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${session.attendanceRate.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: session.attendanceRate >= 80
                      ? AppColors.success
                      : session.attendanceRate >= 60
                          ? AppColors.warning
                          : AppColors.danger,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  void _navigateToRollCall(String sectionOrGroup) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RollCallScreen(
          course: course,
          sectionOrGroup: sectionOrGroup,
          date: _selectedDate,
        ),
      ),
    );
  }

  void _showAttendanceHistory(BuildContext context, bool isDarkMode) {
    final courseRecords = attendanceSessions
        .where((s) => s.courseCode == course.code)
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface(isDarkMode),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border(isDarkMode),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Attendance History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(isDarkMode),
                ),
              ),
              const SizedBox(height: 16),
              if (courseRecords.isEmpty)
                Center(
                  child: Text(
                    'No records yet',
                    style: TextStyle(color: AppColors.textSecondary(isDarkMode)),
                  ),
                )
              else
                ...courseRecords.map((session) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated(isDarkMode),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border(isDarkMode)),
                    ),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${session.sectionOrGroup} - ${_formatDate(session.date)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary(isDarkMode),
                              ),
                            ),
                            Text(
                              'P: ${session.presentCount} | L: ${session.lateCount} | A: ${session.absentCount}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary(isDarkMode),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: (session.attendanceRate >= 80
                                    ? AppColors.success
                                    : session.attendanceRate >= 60
                                        ? AppColors.warning
                                        : AppColors.danger)
                                .withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${session.attendanceRate.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: session.attendanceRate >= 80
                                  ? AppColors.success
                                  : session.attendanceRate >= 60
                                      ? AppColors.warning
                                      : AppColors.danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
