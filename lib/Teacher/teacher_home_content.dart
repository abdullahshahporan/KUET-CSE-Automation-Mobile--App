import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;

import '../Student Folder/models/course_model.dart';
import '../app_theme.dart';
import '../services/supabase_service.dart';
import '../theme/app_colors.dart';
import 'course_detail_screen.dart';
import 'data/teacher_static_data.dart';

/// Teacher Home Content - Shows courses and upcoming schedule
class TeacherHomeContent extends StatefulWidget {
  const TeacherHomeContent({super.key});

  @override
  State<TeacherHomeContent> createState() => _TeacherHomeContentState();
}

class _TeacherHomeContentState extends State<TeacherHomeContent> {
  bool _showAllCourses = false;
  String _teacherName = 'Teacher';

  @override
  void initState() {
    super.initState();
    _loadTeacherName();
  }

  Future<void> _loadTeacherName() async {
    final profile = await SupabaseService.getTeacherProfile();
    if (mounted && profile != null) {
      setState(() {
        _teacherName = profile['full_name'] ?? 'Teacher';
      });
    }
  }

  // Get today's schedule
  List<Map<String, String>> _getTodaySchedule() {
    final weekday = DateTime.now().weekday;
    final dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final today = dayNames[weekday - 1];

    final schedule = [
      {
        'day': 'Sunday',
        'classes': [
          {
            'time': '09:00 - 10:00',
            'course': 'CSE 3201',
            'room': 'Room 301',
            'section': 'A',
          },
          {
            'time': '11:00 - 12:00',
            'course': 'CSE 3201',
            'room': 'Room 301',
            'section': 'B',
          },
        ],
      },
      {
        'day': 'Monday',
        'classes': [
          {
            'time': '10:00 - 01:00',
            'course': 'CSE 3202',
            'room': 'Lab 201',
            'section': 'A1',
          },
        ],
      },
      {
        'day': 'Tuesday',
        'classes': [
          {
            'time': '09:00 - 10:00',
            'course': 'CSE 3201',
            'room': 'Room 301',
            'section': 'A',
          },
          {
            'time': '10:00 - 11:00',
            'course': 'CSE 3201',
            'room': 'Room 301',
            'section': 'B',
          },
        ],
      },
      {
        'day': 'Wednesday',
        'classes': [
          {
            'time': '10:00 - 01:00',
            'course': 'CSE 3202',
            'room': 'Lab 201',
            'section': 'A2',
          },
        ],
      },
      {
        'day': 'Thursday',
        'classes': [
          {
            'time': '02:00 - 03:00',
            'course': 'CSE 2101',
            'room': 'Room 401',
            'section': 'A',
          },
          {
            'time': '03:00 - 04:00',
            'course': 'CSE 2101',
            'room': 'Room 401',
            'section': 'B',
          },
        ],
      },
      {'day': 'Friday', 'classes': []},
      {'day': 'Saturday', 'classes': []},
    ];

    final todaySchedule = schedule.firstWhere(
      (s) => s['day'] == today,
      orElse: () => {'day': today, 'classes': []},
    );

    return (todaySchedule['classes'] as List)
        .cast<Map<String, dynamic>>()
        .map((e) => Map<String, String>.from(e))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = provider.Provider.of<ThemeProvider>(context);
    final todayClasses = _getTodaySchedule();

    // Determine courses to display
    final displayedCourses = _showAllCourses
        ? teacherCourses
        : teacherCourses.take(3).toList();
    final hasMoreCourses = teacherCourses.length > 3;

    return SafeArea(
      child: Column(
        children: [
          // Header with profile and theme toggle
          _buildHeader(context, isDarkMode, themeProvider),

          // Content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // My Courses Section
                  _buildSectionHeader(
                    'My Courses',
                    '${teacherCourses.length} courses',
                    isDarkMode,
                  ),
                  const SizedBox(height: 12),

                  // Course Cards
                  ...displayedCourses.map(
                    (course) => _buildCourseCard(course, isDarkMode),
                  ),

                  // See More Button
                  if (hasMoreCourses && !_showAllCourses)
                    _buildSeeMoreButton(isDarkMode),

                  // See Less Button when expanded
                  if (hasMoreCourses && _showAllCourses)
                    _buildSeeLessButton(isDarkMode),

                  const SizedBox(height: 24),

                  // Upcoming Schedule Section
                  _buildSectionHeader(
                    'Today\'s Schedule',
                    '${todayClasses.length} classes',
                    isDarkMode,
                  ),
                  const SizedBox(height: 12),

                  if (todayClasses.isEmpty)
                    _buildNoClassesCard(isDarkMode)
                  else
                    ...todayClasses.map(
                      (classInfo) => _buildScheduleCard(classInfo, isDarkMode),
                    ),

                  const SizedBox(height: 80), // Space for FAB
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    bool isDarkMode,
    ThemeProvider themeProvider,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface(isDarkMode),
        border: Border(bottom: BorderSide(color: AppColors.border(isDarkMode))),
      ),
      child: Row(
        children: [
          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary(isDarkMode),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _teacherName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(isDarkMode),
                  ),
                ),
              ],
            ),
          ),

          // Theme Toggle Button
          GestureDetector(
            onTap: () => themeProvider.toggleTheme(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.amber.withOpacity(0.15)
                    : Colors.indigo.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDarkMode
                      ? Colors.amber.withOpacity(0.3)
                      : Colors.indigo.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Center(
                child: Icon(
                  isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: isDarkMode ? Colors.amber : Colors.indigo,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(isDarkMode),
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary(isDarkMode),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSeeMoreButton(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: InkWell(
        onTap: () => setState(() => _showAllCourses = true),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.expand_more, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'See ${teacherCourses.length - 3} More Courses',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeeLessButton(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: InkWell(
        onTap: () => setState(() => _showAllCourses = false),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated(isDarkMode),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border(isDarkMode)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.expand_less,
                color: AppColors.textSecondary(isDarkMode),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Show Less',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary(isDarkMode),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoClassesCard(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface(isDarkMode),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(isDarkMode)),
      ),
      child: Column(
        children: [
          Icon(Icons.celebration, size: 48, color: AppColors.success),
          const SizedBox(height: 12),
          Text(
            'No Classes Today!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDarkMode),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Enjoy your day off',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary(isDarkMode),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(Map<String, String> classInfo, bool isDarkMode) {
    final course = teacherCourses.firstWhere(
      (c) => c.code == classInfo['course'],
      orElse: () => teacherCourses.first,
    );
    final color = course.type == CourseType.theory
        ? AppColors.primary
        : AppColors.accent;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface(isDarkMode),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(isDarkMode)),
      ),
      child: Row(
        children: [
          // Time indicator
          Container(
            width: 4,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),

          // Class info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      classInfo['course'] ?? '',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(isDarkMode),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Section ${classInfo['section']}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: AppColors.textSecondary(isDarkMode),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      classInfo['time'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary(isDarkMode),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.room,
                      size: 14,
                      color: AppColors.textSecondary(isDarkMode),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      classInfo['room'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary(isDarkMode),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Course type icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              course.type == CourseType.theory ? Icons.book : Icons.science,
              color: color,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(TeacherCourse course, bool isDarkMode) {
    final color = course.type == CourseType.theory
        ? AppColors.primary
        : AppColors.accent;
    final attendanceCount = course.type == CourseType.theory
        ? getAttendanceCount(course.code, course.sections.first)
        : getAttendanceCount(course.code, course.groups.first);
    final progress = attendanceCount / course.expectedClasses;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourseDetailScreen(course: course),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface(isDarkMode),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border(isDarkMode)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Header
            Row(
              children: [
                // Course Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    course.type == CourseType.theory
                        ? Icons.book
                        : Icons.science,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),

                // Course Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            course.code,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary(isDarkMode),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              course.shortSemester,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        course.title,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary(isDarkMode),
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Progress Bar
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Classes Taken',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary(isDarkMode),
                            ),
                          ),
                          Text(
                            '$attendanceCount / ${course.expectedClasses}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: AppColors.border(isDarkMode),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Quick Info Row
            Row(
              children: [
                _buildInfoChip(
                  course.type == CourseType.theory
                      ? '${course.sections.length} Sections'
                      : '${course.groups.length} Groups',
                  Icons.people,
                  isDarkMode,
                ),
                const SizedBox(width: 10),
                _buildInfoChip(course.creditsString, Icons.star, isDarkMode),
                const SizedBox(width: 10),
                _buildInfoChip(
                  course.type == CourseType.theory ? 'Theory' : 'Lab',
                  course.type == CourseType.theory
                      ? Icons.menu_book
                      : Icons.biotech,
                  isDarkMode,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated(isDarkMode),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border(isDarkMode)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary(isDarkMode)),
          const SizedBox(width: 4),
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
}
