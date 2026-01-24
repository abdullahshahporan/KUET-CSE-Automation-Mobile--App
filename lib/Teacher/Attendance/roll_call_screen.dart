import 'package:flutter/material.dart';
import '../data/teacher_static_data.dart';
import '../../Student Folder/models/user_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/animated_components.dart';

/// Roll Call screen with 3D animated status buttons
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
    with TickerProviderStateMixin {
  late List<StudentUser> _students;
  final Map<String, AttendanceStatus> _attendance = {};
  bool _isSaving = false;
  late AnimationController _fadeController;
  late AnimationController _saveController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _saveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  void _loadStudents() {
    _students = getStudentsForCourse(widget.course, widget.sectionOrGroup);
    for (var student in _students) {
      _attendance[student.roll] = AttendanceStatus.absent;
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _saveController.dispose();
    super.dispose();
  }

  int get presentCount =>
      _attendance.values.where((s) => s == AttendanceStatus.present).length;
  int get lateCount =>
      _attendance.values.where((s) => s == AttendanceStatus.late).length;
  int get absentCount =>
      _attendance.values.where((s) => s == AttendanceStatus.absent).length;
  double get presentPercentage => _students.isNotEmpty
      ? (presentCount + lateCount) / _students.length * 100
      : 0;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.course.code} - ${widget.sectionOrGroup}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              _formatDate(widget.date),
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary(isDarkMode),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surface(isDarkMode),
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _markAllPresent,
            icon: Icon(Icons.check_circle, color: AppColors.success, size: 20),
            label: Text(
              'All Present',
              style: TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Stats Header
            _buildStatsHeader(isDarkMode),
            // Progress Bar
            _buildProgressBar(isDarkMode),
            // Student List
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: _students.length,
                itemBuilder: (context, index) {
                  final student = _students[index];
                  final status = _attendance[student.roll]!;
                  return _buildStudentCard(student, status, index, isDarkMode);
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(isDarkMode),
    );
  }

  Widget _buildStatsHeader(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface(isDarkMode),
        border: Border(bottom: BorderSide(color: AppColors.border(isDarkMode))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Present',
            presentCount,
            AppColors.present,
            isDarkMode,
          ),
          _buildStatDivider(isDarkMode),
          _buildStatItem('Late', lateCount, AppColors.late, isDarkMode),
          _buildStatDivider(isDarkMode),
          _buildStatItem('Absent', absentCount, AppColors.absent, isDarkMode),
          _buildStatDivider(isDarkMode),
          _buildStatItem(
            'Total',
            _students.length,
            AppColors.primary,
            isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color, bool isDarkMode) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Center(
            child: Text(
              value.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary(isDarkMode),
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider(bool isDarkMode) {
    return Container(width: 1, height: 40, color: AppColors.border(isDarkMode));
  }

  Widget _buildProgressBar(bool isDarkMode) {
    final progressColor = presentPercentage >= 80
        ? AppColors.success
        : presentPercentage >= 60
        ? AppColors.warning
        : AppColors.danger;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface(isDarkMode)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Attendance Rate',
                style: TextStyle(
                  color: AppColors.textSecondary(isDarkMode),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  Text(
                    '${presentPercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: progressColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    presentPercentage >= 80
                        ? Icons.trending_up
                        : presentPercentage >= 60
                        ? Icons.trending_flat
                        : Icons.trending_down,
                    color: progressColor,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.border(isDarkMode),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 8,
                width:
                    MediaQuery.of(context).size.width *
                    (presentPercentage / 100) *
                    0.9,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [progressColor.withOpacity(0.8), progressColor],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: progressColor.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(
    StudentUser student,
    AttendanceStatus status,
    int index,
    bool isDarkMode,
  ) {
    final statusColor = status == AttendanceStatus.present
        ? AppColors.present
        : status == AttendanceStatus.late
        ? AppColors.late
        : AppColors.absent;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 30).clamp(0, 300)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated(isDarkMode),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Roll Number Badge
            Container(
              width: 72,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Text(
                student.roll.substring(student.roll.length - 3),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: statusColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.textPrimary(isDarkMode),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Roll: ${student.roll}',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            // Status Buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedStatusButton(
                  label: 'P',
                  color: AppColors.present,
                  isSelected: status == AttendanceStatus.present,
                  onTap: () =>
                      _setStatus(student.roll, AttendanceStatus.present),
                ),
                const SizedBox(width: 8),
                AnimatedStatusButton(
                  label: 'L',
                  color: AppColors.late,
                  isSelected: status == AttendanceStatus.late,
                  onTap: () => _setStatus(student.roll, AttendanceStatus.late),
                ),
                const SizedBox(width: 8),
                AnimatedStatusButton(
                  label: 'A',
                  color: AppColors.absent,
                  isSelected: status == AttendanceStatus.absent,
                  onTap: () =>
                      _setStatus(student.roll, AttendanceStatus.absent),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(isDarkMode),
        border: Border(top: BorderSide(color: AppColors.border(isDarkMode))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
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
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else ...[
                const Icon(Icons.save, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                const Text(
                  'Save Attendance',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _setStatus(String roll, AttendanceStatus status) {
    setState(() {
      _attendance[roll] = status;
    });
  }

  void _markAllPresent() {
    setState(() {
      for (var student in _students) {
        _attendance[student.roll] = AttendanceStatus.present;
      }
    });
  }

  Future<void> _saveAttendance() async {
    setState(() => _isSaving = true);

    // Simulate saving
    await Future.delayed(const Duration(milliseconds: 1200));

    if (mounted) {
      setState(() => _isSaving = false);

      // Show success animation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Attendance Saved!',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Present: $presentCount | Late: $lateCount | Absent: $absentCount',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.pop(context);
    }
  }
}
