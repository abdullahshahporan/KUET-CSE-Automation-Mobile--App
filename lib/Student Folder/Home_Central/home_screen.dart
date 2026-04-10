import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kuet_cse_automation/Student%20Folder/Home/Features/ExamManage/cr_exam_screen.dart';
import 'package:kuet_cse_automation/Student%20Folder/Home/Features/Notice/Notice_Screen.dart';
import 'package:kuet_cse_automation/Student%20Folder/Home/Features/RoomRequest/cr_room_request_screen.dart';
import 'package:kuet_cse_automation/Student%20Folder/Home/Features/Schedule/unified_schedule_screen.dart';
import 'package:kuet_cse_automation/shared/widgets/dot_grid_painter.dart';
import 'package:kuet_cse_automation/theme/app_colors.dart';

import '../../services/supabase_service.dart';
import '../Attendance/attendance_screen.dart';
import '../Attendance/student_geo_attendance_screen.dart';
import '../Curriculum/curriculum_screen.dart';
import '../services/cr_room_request_service.dart';
import '../services/student_attendance_service.dart';
import 'widgets/upcoming_schedule_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  String _firstName = 'Student';
  bool _isCR = false;
  double? _avgAttendance;
  int? _todayClassCount;

  final GlobalKey<UpcomingScheduleSectionState> _upcomingScheduleKey =
      GlobalKey<UpcomingScheduleSectionState>();

  // Stagger animation
  late final AnimationController _staggerCtrl;
  static const int _tileCount = 9; // max tiles incl. CR

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadUserData(), _loadQuickStats()]);
    if (mounted) _staggerCtrl.forward();
  }

  Future<void> _loadUserData() async {
    final profile = await SupabaseService.getStudentProfile();
    if (mounted && profile != null) {
      setState(() {
        _firstName = SupabaseService.getFirstName(profile['full_name']);
      });
    }
    final isCR = await CRRoomRequestService.checkIsCR();
    if (mounted) setState(() => _isCR = isCR);
  }

  Future<void> _loadQuickStats() async {
    try {
      final summaries = await StudentAttendanceService.getAttendanceSummaries();
      if (summaries.isNotEmpty && mounted) {
        final avg = summaries
                .map((s) => s.percentage)
                .reduce((a, b) => a + b) /
            summaries.length;
        setState(() => _avgAttendance = avg);
      }
    } catch (_) {}
  }

  Future<void> _refreshHome() async {
    _staggerCtrl.reset();
    setState(() {
      _avgAttendance = null;
      _todayClassCount = null;
    });
    await Future.wait([
      _loadAll(),
      _upcomingScheduleKey.currentState?.refresh() ?? Future.value(),
    ]);
  }

  // Returns staggered SlideTransition + FadeTransition for a tile at [index]
  Widget _staggeredTile(int index, Widget child) {
    const intervalStep = 0.07;
    final start = (index * intervalStep).clamp(0.0, 0.9);
    final end = (start + 0.35).clamp(0.0, 1.0);

    final curvedAnim = CurvedAnimation(
      parent: _staggerCtrl,
      curve: Interval(start, end, curve: Curves.easeOutBack),
    );
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _staggerCtrl,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(curvedAnim),
        child: child,
      ),
    );
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dotColor = (isDark ? Colors.white : Colors.black)
        .withValues(alpha: isDark ? 0.06 : 0.04);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Stack(
        children: [
          // Dot-grid background
          Positioned.fill(
            child: CustomPaint(
              painter: DotGridPainter(dotColor: dotColor),
            ),
          ),
          RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _refreshHome,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                // ── Welcome + Stats header ──────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWelcomeSection(isDark),
                        const SizedBox(height: 16),
                        _buildQuickStatsRow(isDark),
                        const SizedBox(height: 20),
                        // Section label
                        Row(
                          children: [
                            Text(
                              'Quick Access',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary(isDark),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),

                // ── Bento Grid ─────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.1,
                    ),
                    delegate: SliverChildListDelegate(
                      _buildBentoTiles(isDark),
                    ),
                  ),
                ),

                // ── Upcoming Schedule ───────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
                    child:
                        UpcomingScheduleSection(key: _upcomingScheduleKey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Welcome Section ─────────────────────────────────────────────────
  Widget _buildWelcomeSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _firstName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'CSE Department · KUET',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.school_outlined,
              size: 24,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick Stats Row ──────────────────────────────────────────────────
  Widget _buildQuickStatsRow(bool isDark) {
    final surface =
        isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Row(
      children: [
        Expanded(
          child: _StatChip(
            label: 'Avg Attendance',
            value: _avgAttendance != null
                ? '${_avgAttendance!.toStringAsFixed(1)}%'
                : '—',
            icon: Icons.bar_chart_rounded,
            color: _avgAttendance != null
                ? (_avgAttendance! >= 75
                    ? AppColors.success
                    : _avgAttendance! >= 60
                        ? AppColors.warning
                        : AppColors.danger)
                : AppColors.primary,
            surface: surface,
            border: border,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChip(
            label: 'Today\'s Classes',
            value: _todayClassCount != null
                ? '$_todayClassCount'
                : '—',
            icon: Icons.today_rounded,
            color: AppColors.primary,
            surface: surface,
            border: border,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  // ── Bento Tiles list ────────────────────────────────────────────────
  List<Widget> _buildBentoTiles(bool isDark) {
    int idx = 0;

    Widget tile(
      IconData icon,
      String title,
      String sub,
      VoidCallback onTap,
    ) {
      final w = _buildFeatureTile(
        isDark: isDark,
        icon: icon,
        title: title,
        subtitle: sub,
        onTap: onTap,
      );
      return _staggeredTile(idx++, w);
    }

    return [
      tile(Icons.fact_check_rounded, 'Attendance', 'Track presence', () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AttendanceScreen()));
      }),
      tile(Icons.menu_book_rounded, 'Course Info', 'Syllabus & credits', () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CourseInfoScreen()));
      }),
      tile(Icons.calendar_month_rounded, 'Schedule', 'Class timetable', () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const UnifiedScheduleScreen()));
      }),
      tile(Icons.campaign_rounded, 'Notices', 'Dept. updates', () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const NoticeScreen()));
      }),
      tile(Icons.location_on_rounded, 'Geo-Attend', 'Location check-in', () {
        Navigator.push(context,
            MaterialPageRoute(
                builder: (_) => const StudentGeoAttendanceScreen()));
      }),
      if (_isCR)
        tile(Icons.meeting_room_rounded, 'Room Request', 'CR booking', () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const CRRoomRequestScreen()));
        }),
      if (_isCR)
        tile(Icons.edit_calendar_rounded, 'Manage Exams', 'CT & exams', () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const CRExamScreen()));
        }),
    ];
  }

  // ── Feature tile ────────────────────────────────────────────────────
  Widget _buildFeatureTile({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final surface =
        isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon box — monochromatic teal
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 26, color: Colors.white),
              ),
              // Labels
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary(isDark),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════
// Stat chip widget
// ════════════════════════════════════════════════════════
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color surface;
  final Color border;
  final bool isDark;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.surface,
    required this.border,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary(isDark),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
