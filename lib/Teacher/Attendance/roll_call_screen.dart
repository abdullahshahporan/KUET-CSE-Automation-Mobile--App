import 'package:flutter/material.dart';
import '../../shared/ui_helpers.dart';
import '../../utils/time_utils.dart';
import '../models/teacher_course.dart';
import '../models/enrolled_student.dart';
import '../services/teacher_course_service.dart';
import '../../Student Folder/models/course_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/animated_components.dart';
import 'widgets/attendance_stats_header.dart';
import 'widgets/attendance_progress_bar.dart';
import 'widgets/student_attendance_card.dart';

/// Roll Call screen — mark attendance per student, then save to Supabase.
class RollCallScreen extends StatefulWidget {
  final TeacherCourse course;
  final String sectionOrGroup;
  final DateTime date;

  const RollCallScreen({
    super.key,
    required this.course,
    required this.sectionOrGroup,
    required this.date,
  });

  @override
  State<RollCallScreen> createState() => _RollCallScreenState();
}

class _RollCallScreenState extends State<RollCallScreen>
    with SingleTickerProviderStateMixin {
  List<EnrolledStudent> _students = [];
  /// Keyed by **userId** so the map can be sent directly to the service.
  final Map<String, AttendanceStatus> _attendance = {};
  bool _isSaving = false;
  bool _isLoading = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // ── Lifecycle ──────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController, curve: Curves.easeOut);
    _loadStudents();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // ── Data ───────────────────────────────────────────────────

  Future<void> _loadStudents() async {
    if (widget.course.offeringId == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final all = await TeacherCourseService.getEnrolledStudents(
        courseCode: widget.course.code,
        offeringId: widget.course.offeringId,
      );

      final filtered = all.where((s) {
        if (widget.course.type == CourseType.theory) {
          return s.derivedSection == widget.sectionOrGroup;
        }
        return _sessionalGroup(s) == widget.sectionOrGroup;
      }).toList()
        ..sort((a, b) => a.rollNo.compareTo(b.rollNo));

      setState(() {
        _students = filtered;
        for (final s in filtered) {
          _attendance[s.userId] = AttendanceStatus.absent;
        }
        _isLoading = false;
      });
      _fadeController.forward();
    } catch (e) {
      debugPrint('Error loading students: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  static String _sessionalGroup(EnrolledStudent s) {
    final n = int.tryParse(
            s.rollNo.length >= 3
                ? s.rollNo.substring(s.rollNo.length - 3)
                : s.rollNo) ??
        0;
    if (n <= 30) return 'A1';
    if (n <= 60) return 'A2';
    if (n <= 90) return 'B1';
    return 'B2';
  }

  // ── Computed stats ─────────────────────────────────────────

  int get _presentCount =>
      _attendance.values.where((s) => s == AttendanceStatus.present).length;
  int get _lateCount =>
      _attendance.values.where((s) => s == AttendanceStatus.late).length;
  int get _absentCount =>
      _attendance.values.where((s) => s == AttendanceStatus.absent).length;
  double get _percentage =>
      _students.isNotEmpty ? (_presentCount + _lateCount) / _students.length * 100 : 0;

  // ── UI ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      appBar: _buildAppBar(isDarkMode),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? _buildEmpty(isDarkMode)
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      AttendanceStatsHeader(
                        presentCount: _presentCount,
                        lateCount: _lateCount,
                        absentCount: _absentCount,
                        totalCount: _students.length,
                      ),
                      AttendanceProgressBar(percentage: _percentage),
                      Expanded(
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: _students.length,
                          itemBuilder: (_, i) {
                            final student = _students[i];
                            return StudentAttendanceCard(
                              student: student,
                              status: _attendance[student.userId]!,
                              index: i,
                              onStatusChanged: (s) =>
                                  setState(() => _attendance[student.userId] = s),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: _buildSaveBar(isDarkMode),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDarkMode) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${widget.course.code} - ${widget.sectionOrGroup}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(_formatDate(widget.date),
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary(isDarkMode))),
        ],
      ),
      backgroundColor: AppColors.surface(isDarkMode),
      elevation: 0,
      actions: [
        TextButton.icon(
          onPressed: _markAllPresent,
          icon: Icon(Icons.check_circle, color: AppColors.success, size: 20),
          label: Text('All Present',
              style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildEmpty(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 8),
          Text('No students found',
              style: TextStyle(color: AppColors.textSecondary(isDarkMode))),
        ],
      ),
    );
  }

  Widget _buildSaveBar(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(isDarkMode),
        border: Border(top: BorderSide(color: AppColors.border(isDarkMode))),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1),
              blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: SafeArea(
        child: AnimatedPressButton(
          onTap: _isSaving ? null : _saveAttendance,
          backgroundColor: AppColors.success,
          shadowColor: AppColors.success,
          borderRadius: BorderRadius.circular(14),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isSaving)
                const SizedBox(
                  height: 22, width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                )
              else ...[
                const Icon(Icons.save, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                const Text('Save Attendance',
                    style: TextStyle(color: Colors.white, fontSize: 16,
                        fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────

  void _markAllPresent() {
    setState(() {
      for (final s in _students) {
        _attendance[s.userId] = AttendanceStatus.present;
      }
    });
  }

  Future<void> _saveAttendance() async {
    setState(() => _isSaving = true);
    try {
      final offeringId = widget.course.offeringId;
      if (offeringId == null) throw Exception('No offering ID');

      // Build map: studentUserId → status string
      final map = <String, String>{};
      for (final s in _students) {
        map[s.userId] = _attendance[s.userId]!.apiValue;
      }

      await TeacherCourseService.saveAttendance(
        offeringId: offeringId,
        date: widget.date,
        roomNumber: null,
        attendance: map,
      );

      if (!mounted) return;
      setState(() => _isSaving = false);

      showAppSnackBar(context, message: 'Attendance Saved! Present: $_presentCount | Late: $_lateCount | Absent: $_absentCount');
        Navigator.pop(context, true); // return true so caller can refresh
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        showAppSnackBar(context, message: 'Failed to save: $e', isSuccess: false);
      }
    }
  }

  // ── Helpers ────────────────────────────────────────────────

  static String _formatDate(DateTime d) => TimeUtils.formatDateTimeUS(d);
}
