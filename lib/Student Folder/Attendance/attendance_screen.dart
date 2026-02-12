import 'package:flutter/material.dart';
import '../services/student_attendance_service.dart';
import '../models/student_attendance_data.dart';
import 'widgets/course_attendance_card.dart';
import 'widgets/overall_attendance_summary.dart';
import '../../theme/app_colors.dart';

/// Main Attendance Tracker screen — fetches real data from Supabase.
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<CourseAttendanceSummary> _courses = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final data = await StudentAttendanceService.getAttendanceSummaries();
      if (mounted) {
        setState(() {
          _courses = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading attendance: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      appBar: AppBar(
        title: Text(
          'Attendance Tracker',
          style: TextStyle(color: AppColors.textPrimary(isDarkMode)),
        ),
        backgroundColor: AppColors.surface(isDarkMode),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary(isDarkMode),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError(isDarkMode)
              : _courses.isEmpty
                  ? _buildEmpty(isDarkMode)
                  : RefreshIndicator(
                      onRefresh: _loadAttendance,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Overall summary card
                            OverallAttendanceSummary(courses: _courses),

                            // Course-wise header
                            Row(
                              children: [
                                Text(
                                  'Course-wise Attendance',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary(isDarkMode),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${_courses.length} Courses',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.primary),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Course attendance cards
                            ..._courses.map(
                              (summary) =>
                                  CourseAttendanceCard(summary: summary),
                            ),

                            // Legend
                            const SizedBox(height: 16),
                            _buildLegend(isDarkMode),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildError(bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(
              'Failed to load attendance',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(isDarkMode),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              style: TextStyle(
                  fontSize: 13, color: AppColors.textSecondary(isDarkMode)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadAttendance,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_busy_rounded,
              size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            'No attendance data yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(isDarkMode),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Attendance will appear here once classes start',
            style: TextStyle(color: AppColors.textSecondary(isDarkMode)),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(isDarkMode),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(isDarkMode)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attendance Guide',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDarkMode),
            ),
          ),
          const SizedBox(height: 12),
          _legendItem(AppColors.success, '≥ 80%', 'Safe', isDarkMode),
          _legendItem(AppColors.warning, '70-80%', 'Acceptable', isDarkMode),
          _legendItem(
              const Color(0xFFF97316), '60-70%', 'Edging', isDarkMode),
          _legendItem(AppColors.danger, '< 60%',
              'Cannot sit in Term Final', isDarkMode),
        ],
      ),
    );
  }

  Widget _legendItem(
      Color color, String range, String label, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            range,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(isDarkMode),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '- $label',
            style:
                TextStyle(color: AppColors.textSecondary(isDarkMode)),
          ),
        ],
      ),
    );
  }
}
