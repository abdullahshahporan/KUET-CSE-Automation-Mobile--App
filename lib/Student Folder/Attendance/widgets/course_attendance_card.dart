import 'package:flutter/material.dart';
import '../../models/attendance_model.dart';
import '../../../theme/app_colors.dart';

/// Card widget displaying attendance for a single course
class CourseAttendanceCard extends StatefulWidget {
  final AttendanceRecord record;

  const CourseAttendanceCard({super.key, required this.record});

  @override
  State<CourseAttendanceCard> createState() => _CourseAttendanceCardState();
}

class _CourseAttendanceCardState extends State<CourseAttendanceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0,
      end: widget.record.percentage / 100,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colors = _getStatusColors();
    final isLow = widget.record.percentage < 75;
    final missedClasses =
        widget.record.totalClasses - widget.record.attendedClasses;

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
                ? colors[0].withOpacity(0.4)
                : AppColors.border(isDarkMode),
            width: isLow ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colors[0].withOpacity(isDarkMode ? 0.15 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              // Main Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Course Icon
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: colors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: colors[0].withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.menu_book_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Course Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.record.courseCode,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: colors[0],
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.record.courseName,
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
                          ),
                        ),
                        // Percentage Circle
                        _buildPercentageCircle(colors, isDarkMode),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Animated Progress Bar
                    _buildProgressBar(colors, isDarkMode),
                    const SizedBox(height: 16),

                    // Stats Row
                    Row(
                      children: [
                        _buildStatChip(
                          icon: Icons.check_circle_rounded,
                          label: 'Present',
                          value: '${widget.record.attendedClasses}',
                          color: AppColors.success,
                          isDarkMode: isDarkMode,
                        ),
                        const SizedBox(width: 10),
                        _buildStatChip(
                          icon: Icons.cancel_rounded,
                          label: 'Absent',
                          value: '$missedClasses',
                          color: AppColors.danger,
                          isDarkMode: isDarkMode,
                        ),
                        const SizedBox(width: 10),
                        _buildStatChip(
                          icon: Icons.calendar_today_rounded,
                          label: 'Total',
                          value: '${widget.record.totalClasses}',
                          color: AppColors.primary,
                          isDarkMode: isDarkMode,
                        ),
                        const Spacer(),
                        // Expand indicator
                        AnimatedRotation(
                          turns: _isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textSecondary(isDarkMode),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Expanded Content
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: _isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox.shrink(),
                secondChild: _buildExpandedContent(
                  colors,
                  isDarkMode,
                  missedClasses,
                ),
              ),

              // Warning Banner (if low attendance)
              if (isLow && !_isExpanded)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colors[0].withOpacity(0.15),
                        colors[1].withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: colors[0],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Attendance below 75% - Attend more classes!',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colors[0],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPercentageCircle(List<Color> colors, bool isDarkMode) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors[0].withOpacity(0.1),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  value: _progressAnimation.value,
                  strokeWidth: 4,
                  backgroundColor: AppColors.border(isDarkMode),
                  valueColor: AlwaysStoppedAnimation<Color>(colors[0]),
                  strokeCap: StrokeCap.round,
                ),
              );
            },
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${widget.record.percentage.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors[0],
                  height: 1,
                ),
              ),
              Text(
                '%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: colors[0].withOpacity(0.7),
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(List<Color> colors, bool isDarkMode) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Attendance Progress',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary(isDarkMode),
              ),
            ),
            Text(
              '${widget.record.attendedClasses}/${widget.record.totalClasses}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(isDarkMode),
              ),
            ),
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
            builder: (context, child) {
              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _progressAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      colors: colors,
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors[0].withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDarkMode,
  }) {
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
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(
    List<Color> colors,
    bool isDarkMode,
    int missedClasses,
  ) {
    // Calculate classes needed to reach 75% and 80%
    int classesFor75 = _calculateClassesNeeded(75);
    int classesFor80 = _calculateClassesNeeded(80);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: AppColors.border(isDarkMode)),
          const SizedBox(height: 12),
          Text(
            'Attendance Analysis',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(isDarkMode),
            ),
          ),
          const SizedBox(height: 12),
          // Analysis Cards
          Row(
            children: [
              Expanded(
                child: _buildAnalysisCard(
                  title: 'For 75%',
                  value: classesFor75 <= 0
                      ? 'Achieved ✓'
                      : '+$classesFor75 classes',
                  color: classesFor75 <= 0
                      ? AppColors.success
                      : AppColors.warning,
                  isDarkMode: isDarkMode,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildAnalysisCard(
                  title: 'For 80%',
                  value: classesFor80 <= 0
                      ? 'Achieved ✓'
                      : '+$classesFor80 classes',
                  color: classesFor80 <= 0
                      ? AppColors.success
                      : AppColors.primary,
                  isDarkMode: isDarkMode,
                ),
              ),
            ],
          ),
          if (widget.record.percentage < 60) ...[
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
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.danger,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Risk: You may not be eligible for Term Final!',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalysisCard({
    required String title,
    required String value,
    required Color color,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary(isDarkMode),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  int _calculateClassesNeeded(double targetPercentage) {
    if (widget.record.percentage >= targetPercentage) return 0;
    int attended = widget.record.attendedClasses;
    int total = widget.record.totalClasses;
    int needed = 0;

    while ((attended / total * 100) < targetPercentage && needed < 100) {
      attended++;
      total++;
      needed++;
    }
    return needed;
  }

  List<Color> _getStatusColors() {
    switch (widget.record.status) {
      case AttendanceStatus.safe:
        return [AppColors.success, const Color(0xFF14B8A6)];
      case AttendanceStatus.acceptable:
        return [AppColors.warning, const Color(0xFFF97316)];
      case AttendanceStatus.edging:
        return [const Color(0xFFF97316), const Color(0xFFEA580C)];
      case AttendanceStatus.alarming:
        return [AppColors.danger, const Color(0xFFDC2626)];
    }
  }
}
