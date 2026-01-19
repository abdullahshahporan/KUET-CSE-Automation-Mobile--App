import 'package:flutter/material.dart';
import 'data/teacher_static_data.dart';
import '../Student Folder/models/course_model.dart';
import '../theme/app_colors.dart';
import 'Attendance/teacher_attendance_screen.dart';
import 'Grading/teacher_grading_screen.dart';
import 'Schedule/teacher_schedule_screen.dart';
import 'Announcements/announcements_screen.dart';
import 'Students/students_list_screen.dart';

/// Course Detail Screen - All actions for a specific course
class CourseDetailScreen extends StatelessWidget {
  final TeacherCourse course;

  const CourseDetailScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final color = course.type == CourseType.theory ? AppColors.primary : AppColors.accent;

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      appBar: AppBar(
        backgroundColor: AppColors.surface(isDarkMode),
        elevation: 0,
        title: Text(
          course.code,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary(isDarkMode),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary(isDarkMode)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Header Card
            _buildCourseHeader(isDarkMode, color),
            const SizedBox(height: 24),
            
            // Quick Stats Row
            _buildQuickStats(isDarkMode, color),
            const SizedBox(height: 24),
            
            // Actions Section
            Text(
              'Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(isDarkMode),
              ),
            ),
            const SizedBox(height: 12),
            
            _buildActionCard(
              context: context,
              icon: Icons.fact_check,
              title: 'Take Attendance',
              subtitle: 'Mark present, late, or absent',
              color: AppColors.success,
              isDarkMode: isDarkMode,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CourseAttendanceScreen(course: course),
                ),
              ),
            ),
            
            _buildActionCard(
              context: context,
              icon: Icons.grading,
              title: 'Enter Marks',
              subtitle: 'CT, Assignment, Quiz, Lab marks',
              color: AppColors.primary,
              isDarkMode: isDarkMode,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CourseGradingScreen(course: course),
                ),
              ),
            ),
            
            _buildActionCard(
              context: context,
              icon: Icons.campaign,
              title: 'Announcements',
              subtitle: 'Notify students in this course',
              color: AppColors.warning,
              isDarkMode: isDarkMode,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CourseAnnouncementsScreen(course: course),
                ),
              ),
            ),
            
            _buildActionCard(
              context: context,
              icon: Icons.schedule,
              title: 'Class Schedule',
              subtitle: 'View and manage schedule',
              color: AppColors.info,
              isDarkMode: isDarkMode,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TeacherScheduleScreen(),
                ),
              ),
            ),
            
            _buildActionCard(
              context: context,
              icon: Icons.people,
              title: 'Students',
              subtitle: 'View enrolled students',
              color: AppColors.indigo,
              isDarkMode: isDarkMode,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CourseStudentsScreen(course: course),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseHeader(bool isDarkMode, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode 
              ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
              : [color.withOpacity(0.8), color.withOpacity(0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: isDarkMode ? Border.all(color: AppColors.darkBorder) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(isDarkMode ? 0.1 : 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  course.type == CourseType.theory ? Icons.book : Icons.science,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.code,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      course.title,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Tags row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTag(course.semesterName, Icons.calendar_today),
              _buildTag(course.creditsString, Icons.star),
              _buildTag(
                course.type == CourseType.theory ? 'Theory' : 'Sessional',
                course.type == CourseType.theory ? Icons.menu_book : Icons.biotech,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(bool isDarkMode, Color color) {
    final attendanceCount = course.type == CourseType.theory
        ? getAttendanceCount(course.code, course.sections.first)
        : getAttendanceCount(course.code, course.groups.first);
    
    final studentCount = course.type == CourseType.theory
        ? course.sections.length * 60
        : course.groups.length * 30;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Classes',
            '$attendanceCount/${course.expectedClasses}',
            Icons.class_,
            AppColors.success,
            isDarkMode,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            'Students',
            studentCount.toString(),
            Icons.people,
            AppColors.info,
            isDarkMode,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            course.type == CourseType.theory ? 'Sections' : 'Groups',
            course.type == CourseType.theory 
                ? course.sections.length.toString()
                : course.groups.length.toString(),
            Icons.groups,
            AppColors.warning,
            isDarkMode,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface(isDarkMode),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(isDarkMode)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDarkMode),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary(isDarkMode),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface(isDarkMode),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border(isDarkMode)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(isDarkMode),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary(isDarkMode),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

/// Course-specific Attendance Screen
class CourseAttendanceScreen extends StatelessWidget {
  final TeacherCourse course;

  const CourseAttendanceScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    // Pass course to the attendance screen
    return TeacherAttendanceScreen(preSelectedCourse: course);
  }
}

/// Course-specific Grading Screen
class CourseGradingScreen extends StatelessWidget {
  final TeacherCourse course;

  const CourseGradingScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return TeacherGradingScreen(preSelectedCourse: course);
  }
}

/// Course-specific Announcements Screen
class CourseAnnouncementsScreen extends StatelessWidget {
  final TeacherCourse course;

  const CourseAnnouncementsScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return AnnouncementsScreen(course: course);
  }
}

/// Course-specific Students Screen
class CourseStudentsScreen extends StatelessWidget {
  final TeacherCourse course;

  const CourseStudentsScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return StudentsListScreen(course: course);
  }
}
