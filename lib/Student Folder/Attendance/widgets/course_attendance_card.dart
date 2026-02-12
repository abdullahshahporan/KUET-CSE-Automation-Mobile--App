import 'package:flutter/material.dart';
import '../../models/student_attendance_data.dart';
import '../../../theme/app_colors.dart';
import 'session_history_list.dart';

/// Card widget displaying attendance for a single course.
///
/// Uses [CourseAttendanceSummary] from Supabase instead of static data.
/// Tap to expand and see class history + analysis.
class CourseAttendanceCard extends StatefulWidget {
  final CourseAttendanceSummary summary;

  const CourseAttendanceCard({super.key, required this.summary});

  @override
  State<CourseAttendanceCard> createState() => _CourseAttendanceCardState();
}

class _CourseAttendanceCardState extends State<CourseAttendanceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  bool _isExpanded = false;

  CourseAttendanceSummary get _s => widget.summary;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0,
      end: _s.percentage / 100,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Color> get _colors {
    switch (_s.level) {
      case AttendanceLevel.safe:
        return [AppColors.success, const Color(0xFF14B8A6)];
      case AttendanceLevel.acceptable:
        return [AppColors.warning, const Color(0xFFF97316)];
      case AttendanceLevel.edging:
        return [const Color(0xFFF97316), const Color(0xFFEA580C)];
      case AttendanceLevel.alarming:
        return [AppColors.danger, const Color(0xFFDC2626)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isLow = _s.percentage < 75;

    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.surface(isDarkMode),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isLow
                ? _colors[0].withOpacity(0.4)
                : AppColors.border(isDarkMode),
            width: isLow ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _colors[0].withOpacity(isDarkMode ? 0.15 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              _buildMainContent(isDarkMode),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: _isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox.shrink(),
                secondChild: _buildExpandedContent(isDarkMode),
              ),
              if (isLow && !_isExpanded) _buildWarningBanner(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCourseIcon(),
              const SizedBox(width: 14),
              Expanded(child: _buildCourseInfo(isDarkMode)),
              _buildPercentageCircle(isDarkMode),
            ],
          ),
          const SizedBox(height: 20),
          _buildProgressBar(isDarkMode),
          const SizedBox(height: 16),
          _buildStatsRow(isDarkMode),
        ],
      ),
    );
  }

  Widget _buildCourseIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _colors[0].withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        _s.courseType.toLowerCase() == 'lab'
            ? Icons.science_rounded
            : Icons.menu_book_rounded,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildCourseInfo(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _s.courseCode,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _colors[0],
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _s.courseTitle,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(isDarkMode),
            height: 1.3,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPercentageCircle(bool isDarkMode) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _colors[0].withOpacity(0.1),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) => SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                value: _progressAnimation.value,
                strokeWidth: 4,
                backgroundColor: AppColors.border(isDarkMode),
                valueColor: AlwaysStoppedAnimation<Color>(_colors[0]),
                strokeCap: StrokeCap.round,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _s.percentage.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _colors[0],
                  height: 1,
                ),
              ),
              Text(
                '%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: _colors[0].withOpacity(0.7),
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(bool isDarkMode) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Attendance Progress',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary(isDarkMode))),
            Text('${_s.attendedCount}/${_s.totalSessions}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(isDarkMode))),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: AppColors.border(isDarkMode),
          ),
          child: AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) => FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _progressAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: LinearGradient(colors: _colors),
                  boxShadow: [
                    BoxShadow(
                      color: _colors[0].withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(bool isDarkMode) {
    return Row(
      children: [
        _statChip(Icons.check_circle_rounded, '${_s.presentCount}',
            AppColors.success, isDarkMode),
        const SizedBox(width: 8),
        _statChip(Icons.access_time_rounded, '${_s.lateCount}',
            AppColors.warning, isDarkMode),
        const SizedBox(width: 8),
        _statChip(Icons.cancel_rounded, '${_s.absentCount}',
            AppColors.danger, isDarkMode),
        const SizedBox(width: 8),
        _statChip(Icons.calendar_today_rounded, '${_s.totalSessions}',
            AppColors.primary, isDarkMode),
        const Spacer(),
        AnimatedRotation(
          turns: _isExpanded ? 0.5 : 0,
          duration: const Duration(milliseconds: 300),
          child: Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary(isDarkMode)),
        ),
      ],
    );
  }

  Widget _statChip(IconData icon, String value, Color color, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(bool isDarkMode) {
    final classesFor75 = _s.classesNeededFor(75);
    final classesFor80 = _s.classesNeededFor(80);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: AppColors.border(isDarkMode)),
          const SizedBox(height: 12),
          Text('Attendance Analysis',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(isDarkMode))),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _analysisCard(
                  'For 75%',
                  classesFor75 <= 0 ? 'Achieved' : '+$classesFor75 classes',
                  classesFor75 <= 0 ? AppColors.success : AppColors.warning,
                  isDarkMode,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _analysisCard(
                  'For 80%',
                  classesFor80 <= 0 ? 'Achieved' : '+$classesFor80 classes',
                  classesFor80 <= 0 ? AppColors.success : AppColors.primary,
                  isDarkMode,
                ),
              ),
            ],
          ),
          if (_s.percentage < 60) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.danger.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.danger, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Risk: You may not be eligible for Term Final!',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.danger),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_s.sessions.isNotEmpty) ...[
            const SizedBox(height: 16),
            SessionHistoryList(sessions: _s.sessions),
          ],
        ],
      ),
    );
  }

  Widget _analysisCard(
      String title, String value, Color color, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary(isDarkMode))),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _colors[0].withOpacity(0.15),
            _colors[1].withOpacity(0.1),
          ],
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 18, color: _colors[0]),
          const SizedBox(width: 8),
          Text(
            'Attendance below 75% - Attend more classes!',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500, color: _colors[0]),
          ),
        ],
      ),
    );
  }
}
