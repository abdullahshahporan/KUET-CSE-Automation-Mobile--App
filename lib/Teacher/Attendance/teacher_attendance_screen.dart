import 'package:flutter/material.dart';
import '../../utils/time_utils.dart';
import '../models/teacher_course.dart';
import '../models/enrolled_student.dart';
import '../../Student Folder/models/course_model.dart';
import '../../theme/app_colors.dart';
import '../services/teacher_course_service.dart';
import 'roll_call_screen.dart';

/// Teacher Attendance screen - Course-specific with date picker
class TeacherAttendanceScreen extends StatefulWidget {
  final TeacherCourse? preSelectedCourse;

  const TeacherAttendanceScreen({super.key, this.preSelectedCourse});

  @override
  State<TeacherAttendanceScreen> createState() =>
      _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  int _classesHeld = 0;
  List<EnrolledStudent> _allStudents = [];
  List<Map<String, dynamic>> _recentSessions = [];
  bool _isLoading = true;

  TeacherCourse get course => widget.preSelectedCourse!;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final offeringId = course.offeringId;
    if (offeringId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final results = await Future.wait([
        TeacherCourseService.getAttendanceCount(offeringId: offeringId),
        TeacherCourseService.getEnrolledStudents(courseCode: course.code),
        TeacherCourseService.getClassSessions(offeringId: offeringId, limit: 5),
      ]);

      if (mounted) {
        setState(() {
          _classesHeld = results[0] as int;
          _allStudents = results[1] as List<EnrolledStudent>;
          _recentSessions = results[2] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final color = course.type == CourseType.theory
        ? AppColors.primary
        : AppColors.accent;

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
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
                      course.type == CourseType.theory
                          ? 'Select Section'
                          : 'Select Group',
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
            child: Icon(
              Icons.calendar_today,
              color: AppColors.success,
              size: 22,
            ),
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
    final progress = course.expectedClasses > 0
        ? _classesHeld / course.expectedClasses
        : 0.0;

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
                '$_classesHeld of ${course.expectedClasses}',
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
            padding: EdgeInsets.only(
              right: section == course.sections.last ? 0 : 10,
            ),
            child: _buildSelectorCard(
              title: 'Section $section',
              subtitle: section == 'A' ? 'Roll 001-060' : 'Roll 061-120',
              count: '${_allStudents.where((s) => s.derivedSection == section).length} enrolled',
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
          subtitle: 'Roll ${rollRanges[group] ?? ''}',
          count: '${_countForGroup(group)} enrolled',
          color: colors[group] ?? AppColors.primary,
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
              style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
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
    if (_recentSessions.isEmpty) {
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
      children: _recentSessions.map((session) {
        final startsAt = DateTime.tryParse(session['starts_at'] as String? ?? '');
        final topic = session['topic'] as String? ?? '';
        final room = session['room_number'] as String? ?? '';

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
                child: Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.isNotEmpty ? topic : 'Class Session',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary(isDarkMode),
                      ),
                    ),
                    Text(
                      '${startsAt != null ? _formatDate(startsAt) : "Unknown"}${room.isNotEmpty ? " • $room" : ""}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary(isDarkMode),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatDate(DateTime date) => TimeUtils.formatDateTimeWithWeekday(date);

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

  /// Count students for a sessional group (A1=001-030, A2=031-060, B1=061-090, B2=091-120)
  int _countForGroup(String group) {
    return _allStudents.where((s) {
      final roll = int.tryParse(s.rollNo.length >= 3 ? s.rollNo.substring(s.rollNo.length - 3) : s.rollNo) ?? 0;
      switch (group) {
        case 'A1': return roll >= 1 && roll <= 30;
        case 'A2': return roll >= 31 && roll <= 60;
        case 'B1': return roll >= 61 && roll <= 90;
        case 'B2': return roll >= 91 && roll <= 120;
        default: return false;
      }
    }).length;
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
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface(isDarkMode),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            final offeringId = course.offeringId;
            if (offeringId == null) {
              return Center(
                child: Text('No offering ID', style: TextStyle(color: AppColors.textSecondary(isDarkMode))),
              );
            }
            return FutureBuilder<List<Map<String, dynamic>>>(
              future: TeacherCourseService.getClassSessions(offeringId: offeringId, limit: 50),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final sessions = snapshot.data ?? [];
                return SingleChildScrollView(
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
                      if (sessions.isEmpty)
                        Center(
                          child: Text(
                            'No records yet',
                            style: TextStyle(color: AppColors.textSecondary(isDarkMode)),
                          ),
                        )
                      else
                        ...sessions.map((session) {
                          final startsAt = DateTime.tryParse(session['starts_at'] as String? ?? '');
                          final topic = session['topic'] as String? ?? 'Class Session';
                          final room = session['room_number'] as String? ?? '';
                          final sessionId = session['id'] as String;

                          return FutureBuilder<Map<String, int>>(
                            future: TeacherCourseService.getSessionAttendanceStats(sessionId: sessionId),
                            builder: (context, statsSnap) {
                              final stats = statsSnap.data ?? {'present': 0, 'late': 0, 'absent': 0, 'total': 0};
                              final total = stats['total'] ?? 0;
                              final present = stats['present'] ?? 0;
                              final late = stats['late'] ?? 0;
                              final absent = stats['absent'] ?? 0;
                              final rate = total > 0 ? ((present + late) / total * 100) : 0.0;

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
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${topic.isNotEmpty ? topic : "Class Session"}${room.isNotEmpty ? " • $room" : ""}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.textPrimary(isDarkMode),
                                            ),
                                          ),
                                          Text(
                                            '${startsAt != null ? _formatDate(startsAt) : ""} · P: $present | L: $late | A: $absent',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary(isDarkMode),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: (rate >= 80
                                                ? AppColors.success
                                                : rate >= 60
                                                    ? AppColors.warning
                                                    : AppColors.danger)
                                            .withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${rate.toStringAsFixed(0)}%',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: rate >= 80
                                              ? AppColors.success
                                              : rate >= 60
                                                  ? AppColors.warning
                                                  : AppColors.danger,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        }),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
