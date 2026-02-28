import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;

import '../Student Folder/models/course_model.dart';
import '../app_theme.dart';
import '../services/supabase_service.dart';
import '../theme/app_colors.dart';
import '../utils/course_utils.dart';
import 'course_detail_screen.dart';
import 'models/teacher_course.dart';
import 'Schedule/teacher_schedule_service.dart';
import 'Schedule/teacher_schedule_model.dart';

/// Teacher Home Content - Shows courses and upcoming schedule
class TeacherHomeContent extends StatefulWidget {
  const TeacherHomeContent({super.key});

  @override
  State<TeacherHomeContent> createState() => _TeacherHomeContentState();
}

class _TeacherHomeContentState extends State<TeacherHomeContent> {
  bool _showAllCourses = false;
  String _teacherName = 'Teacher';
  List<TeacherCourse> _assignedCourses = [];
  bool _loadingCourses = true;
  dynamic _realtimeChannel;
  List<TeacherSlot> _todaySlots = [];
  bool _loadingSchedule = true;

  @override
  void initState() {
    super.initState();
    _loadTeacherName();
    _loadAssignedCourses();
    _loadTodaySchedule();
    _subscribeToChanges();
  }

  @override
  void dispose() {
    // Clean up real-time subscription
    if (_realtimeChannel != null) {
      SupabaseService.removeChannel(_realtimeChannel);
    }
    super.dispose();
  }

  Future<void> _loadTeacherName() async {
    final profile = await SupabaseService.getTeacherProfile();
    if (mounted && profile != null) {
      setState(() {
        _teacherName = profile['full_name'] ?? 'Teacher';
      });
    }
  }

  Future<void> _loadAssignedCourses() async {
    try {
      final offerings = await SupabaseService.getTeacherAssignedCourses();
      if (!mounted) return;

      final courses = offerings.map((offering) {
        final course = offering['courses'] as Map<String, dynamic>? ?? {};
        final courseCode = course['code'] as String? ?? '';

        // Derive year & term from course code using shared utility
        final year = CourseUtils.yearFromCode(courseCode);
        final termNum = CourseUtils.termFromCode(courseCode);

        final typeStr = (course['course_type'] as String? ?? 'Theory').toLowerCase();
        final courseType = typeStr == 'lab' ? CourseType.lab : CourseType.theory;
        final credit = (course['credit'] as num?)?.toDouble() ?? 3.0;

        return TeacherCourse(
          code: course['code'] as String? ?? '',
          title: course['title'] as String? ?? '',
          credits: credit,
          type: courseType,
          year: year,
          term: termNum,
          expectedClasses: courseType == CourseType.lab
              ? (credit * 6.67).round() // ~10 for 1.5 credit lab
              : (credit * 6).round(),   // ~18 for 3 credit theory
          sections: courseType == CourseType.theory ? ['A', 'B'] : [],
          groups: courseType == CourseType.lab ? ['A1', 'A2', 'B1', 'B2'] : [],
          teachers: [_teacherName],
          offeringId: offering['id'] as String?,
          session: offering['session'] as String?,
        );
      }).toList();

      setState(() {
        _assignedCourses = courses;
        _loadingCourses = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loadingCourses = false);
      }
    }
  }

  void _subscribeToChanges() {
    _realtimeChannel = SupabaseService.subscribeToTeacherCourses(
      onChanged: () {
        // Refetch courses when real-time event received
        _loadAssignedCourses();
      },
    );
  }

  // Load today's schedule from Supabase
  Future<void> _loadTodaySchedule() async {
    try {
      final schedule = await TeacherScheduleService.fetchSchedule();
      // DateTime.now().weekday: 1=Mon..7=Sun
      // TeacherSlot.dayOfWeek: 0=Sun..6=Sat
      final dartWeekday = DateTime.now().weekday; // 1=Mon..7=Sun
      final dbDay = dartWeekday == 7 ? 0 : dartWeekday; // Convert to 0=Sun..6=Sat

      if (mounted) {
        setState(() {
          _todaySlots = schedule[dbDay] ?? [];
          _loadingSchedule = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingSchedule = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = provider.Provider.of<ThemeProvider>(context);
    final todayClasses = _todaySlots;

    // Determine courses to display
    final displayedCourses = _showAllCourses
        ? _assignedCourses
        : _assignedCourses.take(3).toList();
    final hasMoreCourses = _assignedCourses.length > 3;

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
                    _loadingCourses
                        ? 'Loading...'
                        : '${_assignedCourses.length} courses',
                    isDarkMode,
                  ),
                  const SizedBox(height: 12),

                  // Course Cards
                  if (_loadingCourses)
                    _buildLoadingCoursesCard(isDarkMode)
                  else if (_assignedCourses.isEmpty)
                    _buildNoCoursesCard(isDarkMode)
                  else
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
                    _loadingSchedule
                        ? 'Loading...'
                        : '${todayClasses.length} classes',
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
                'See ${_assignedCourses.length - 3} More Courses',
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

  Widget _buildScheduleCard(TeacherSlot slot, bool isDarkMode) {
    final isTheory = slot.courseType.toLowerCase() == 'theory';
    final color = isTheory ? AppColors.primary : AppColors.accent;

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
                      slot.courseCode,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(isDarkMode),
                      ),
                    ),
                    if (slot.section != null && slot.section!.isNotEmpty) ...[
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
                          'Section ${slot.section}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                    ],
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
                      slot.timeRange,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary(isDarkMode),
                      ),
                    ),
                    if (slot.roomNumber.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      Icon(
                        Icons.room,
                        size: 14,
                        color: AppColors.textSecondary(isDarkMode),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        slot.roomNumber,
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

          // Course type icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isTheory ? Icons.book : Icons.science,
              color: color,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCoursesCard(bool isDarkMode) {
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
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Loading your courses...',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary(isDarkMode),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoCoursesCard(bool isDarkMode) {
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
          Icon(Icons.school_outlined, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            'No Courses Assigned',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDarkMode),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Courses will appear here once assigned by admin',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary(isDarkMode),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(TeacherCourse course, bool isDarkMode) {
    final color = course.type == CourseType.theory
        ? AppColors.primary
        : AppColors.accent;

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
