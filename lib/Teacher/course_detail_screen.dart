import 'package:flutter/material.dart';
import 'data/teacher_static_data.dart';
import '../Student Folder/models/course_model.dart';
import '../theme/app_colors.dart';
import 'Attendance/teacher_attendance_screen.dart';
import 'Grading/teacher_grading_screen.dart';
import 'Schedule/teacher_schedule_screen.dart';
import 'Announcements/announcements_screen.dart';
import 'Students/students_list_screen.dart';
import 'services/teacher_course_service.dart';
import 'widgets/course_header_card.dart';
import 'widgets/course_stat_card.dart';
import 'widgets/course_action_card.dart';

/// Course Detail Screen - All actions for a specific course
class CourseDetailScreen extends StatefulWidget {
  final TeacherCourse course;

  const CourseDetailScreen({super.key, required this.course});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  int _studentCount = 0;
  int _attendanceCount = 0;
  int _expectedClasses = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourseData();
  }

  Future<void> _loadCourseData() async {
    setState(() => _isLoading = true);

    final offeringId = widget.course.offeringId;
    if (offeringId == null || offeringId.isEmpty) {
      // No offering ID — use static fallback
      if (mounted) {
        setState(() {
          _expectedClasses = widget.course.expectedClasses;
          _isLoading = false;
        });
      }
      return;
    }

    try {
      // Fetch data in parallel
      final results = await Future.wait([
        TeacherCourseService.getStudentCount(courseCode: widget.course.code),
        TeacherCourseService.getAttendanceCount(offeringId: offeringId),
        TeacherCourseService.getExpectedClasses(courseCode: widget.course.code),
      ]);

      if (mounted) {
        setState(() {
          _studentCount = results[0];
          _attendanceCount = results[1];
          _expectedClasses = results[2];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _expectedClasses = widget.course.expectedClasses;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final color = widget.course.type == CourseType.theory
        ? AppColors.primary
        : AppColors.accent;

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      appBar: AppBar(
        backgroundColor: AppColors.surface(isDarkMode),
        elevation: 0,
        title: Text(
          widget.course.code,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary(isDarkMode),
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary(isDarkMode),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.textPrimary(isDarkMode)),
            onPressed: _loadCourseData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCourseData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Course Header Card
                    CourseHeaderCard(
                      code: widget.course.code,
                      title: widget.course.title,
                      semesterName: widget.course.semesterName,
                      creditsString: widget.course.creditsString,
                      type: widget.course.type,
                      isDarkMode: isDarkMode,
                      color: color,
                    ),
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

                    CourseActionCard(
                      icon: Icons.fact_check,
                      title: 'Take Attendance',
                      subtitle: 'Mark present, late, or absent',
                      color: AppColors.success,
                      isDarkMode: isDarkMode,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CourseAttendanceScreen(course: widget.course),
                        ),
                      ),
                    ),

                    CourseActionCard(
                      icon: Icons.grading,
                      title: 'Enter Marks',
                      subtitle: 'CT, Assignment, Quiz, Lab marks',
                      color: AppColors.primary,
                      isDarkMode: isDarkMode,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CourseGradingScreen(course: widget.course),
                        ),
                      ),
                    ),

                    CourseActionCard(
                      icon: Icons.campaign,
                      title: 'Announcements',
                      subtitle: 'Notify students in this course',
                      color: AppColors.warning,
                      isDarkMode: isDarkMode,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CourseAnnouncementsScreen(course: widget.course),
                        ),
                      ),
                    ),

                    CourseActionCard(
                      icon: Icons.schedule,
                      title: 'Class Schedule',
                      subtitle: 'View and manage schedule',
                      color: AppColors.info,
                      isDarkMode: isDarkMode,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TeacherScheduleScreen(
                            courseCode: widget.course.code,
                          ),
                        ),
                      ),
                    ),

                    CourseActionCard(
                      icon: Icons.people,
                      title: 'Students',
                      subtitle: 'View enrolled students',
                      color: AppColors.indigo,
                      isDarkMode: isDarkMode,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CourseStudentsScreen(course: widget.course),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildQuickStats(bool isDarkMode, Color color) {
    final groupCount = widget.course.type == CourseType.theory
        ? widget.course.sections.length
        : widget.course.groups.length;

    return Row(
      children: [
        Expanded(
          child: CourseStatCard(
            label: 'Classes',
            value: '$_attendanceCount/${_expectedClasses > 0 ? _expectedClasses : widget.course.expectedClasses}',
            icon: Icons.class_,
            color: AppColors.success,
            isDarkMode: isDarkMode,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: CourseStatCard(
            label: 'Students',
            value: _studentCount.toString(),
            icon: Icons.people,
            color: AppColors.info,
            isDarkMode: isDarkMode,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: CourseStatCard(
            label: widget.course.type == CourseType.theory ? 'Sections' : 'Groups',
            value: groupCount.toString(),
            icon: Icons.groups,
            color: AppColors.warning,
            isDarkMode: isDarkMode,
          ),
        ),
      ],
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
