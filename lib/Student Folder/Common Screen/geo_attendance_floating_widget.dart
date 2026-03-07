import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/geo_attendance_service.dart';
import '../../services/supabase_service.dart';
//import '../../theme/app_colors.dart';
import '../Attendance/student_geo_attendance_screen.dart';

/// A Foodpanda-style floating overlay that appears when geo-attendance
/// rooms are open. Shows mini course details + live countdown timer.
class GeoAttendanceFloatingWidget extends StatefulWidget {
  const GeoAttendanceFloatingWidget({super.key});

  @override
  State<GeoAttendanceFloatingWidget> createState() =>
      _GeoAttendanceFloatingWidgetState();
}

class _GeoAttendanceFloatingWidgetState
    extends State<GeoAttendanceFloatingWidget>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _openRooms = [];
  Timer? _refreshTimer;
  Timer? _countdownTimer;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fetchRooms();
    _requestLocationPermission();
    // Re-fetch every 30 seconds
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _fetchRooms(),
    );
    // Tick countdown every second
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted && _openRooms.isNotEmpty) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _fetchRooms() async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) {
        debugPrint('GeoFloatingWidget: no userId, skipping fetch');
        return;
      }
      debugPrint('GeoFloatingWidget: fetching rooms for $userId');
      final rooms = await GeoAttendanceService.getOpenRoomsForStudent(
        studentUserId: userId,
      );
      debugPrint('GeoFloatingWidget: got ${rooms.length} rooms');
      final pending =
          rooms.where((r) => r['already_submitted'] != true).toList();
      debugPrint('GeoFloatingWidget: ${pending.length} pending (not submitted)');

      if (mounted) {
        final wasVisible = _visible;
        _visible = pending.isNotEmpty;
        setState(() => _openRooms = pending);

        if (_visible && !wasVisible) {
          _slideController.forward();
        } else if (!_visible && wasVisible) {
          _slideController.reverse();
        }
      }
    } catch (e) {
      debugPrint('GeoFloatingWidget: Error fetching rooms: $e');
    }
  }

  /// Request location permission proactively so the dialog appears
  /// before the student tries to submit attendance.
  Future<void> _requestLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('GeoFloatingWidget: Location services disabled');
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        debugPrint('GeoFloatingWidget: Permission result: $permission');
      }
    } catch (e) {
      debugPrint('GeoFloatingWidget: location permission error: $e');
    }
  }

  String _timeRemaining(String endTimeStr) {
    final end = DateTime.tryParse(endTimeStr);
    if (end == null) return '';
    final diff = end.toLocal().difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    final m = diff.inMinutes;
    final s = diff.inSeconds % 60;
    if (m >= 60) return '${diff.inHours}h ${m % 60}m';
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  double _timeProgress(String startStr, String endStr) {
    final start = DateTime.tryParse(startStr)?.toLocal();
    final end = DateTime.tryParse(endStr)?.toLocal();
    if (start == null || end == null) return 0;
    final total = end.difference(start).inSeconds;
    if (total <= 0) return 0;
    final elapsed = DateTime.now().difference(start).inSeconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible && !_slideController.isAnimating) {
      return const SizedBox.shrink();
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Take the first room for the mini display
    final room = _openRooms.isNotEmpty ? _openRooms.first : null;
    final offering = room?['course_offerings'] as Map<String, dynamic>?;
    final course = offering?['courses'] as Map<String, dynamic>?;
    final code = course?['code'] ?? '';
    final title = course?['title'] ?? '';
    final section = room?['section'] as String? ?? '';
    final endTime = room?['end_time'] as String? ?? '';
    final startTime = room?['start_time'] as String? ?? '';
    final teacher = (offering?['teachers'] as Map<String, dynamic>?)?['full_name'] as String? ?? '';
    final remaining = _timeRemaining(endTime);
    final progress = _timeProgress(startTime, endTime);
    final roomCount = _openRooms.length;

    return SlideTransition(
      position: _slideAnimation,
      child: GestureDetector(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const StudentGeoAttendanceScreen(),
            ),
          );
          _fetchRooms();
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode
                  ? [const Color(0xFF134E4A), const Color(0xFF0F3D3A)]
                  : [const Color(0xFF0D9488), const Color(0xFF0F766E)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D9488).withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top row: icon + course info + countdown badge
              Row(
                children: [
                  // Pulsing location icon
                  _PulsingDot(),
                  const SizedBox(width: 10),
                  // Course details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '$code${section.isNotEmpty ? ' ($section)' : ''}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (roomCount > 1) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '+${roomCount - 1} more',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          title.toString().length > 30
                              ? '${title.toString().substring(0, 30)}…'
                              : title.toString(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Countdown badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          remaining,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 3,
                  backgroundColor: Colors.white.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.7),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // Bottom row: teacher name + tap hint
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (teacher.isNotEmpty)
                    Text(
                      teacher,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 11,
                      ),
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Tap to submit',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white.withOpacity(0.6),
                        size: 10,
                      ),
                    ],
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

/// Pulsing green dot that indicates a live session
class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15 + _controller.value * 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFF4ADE80),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4ADE80)
                        .withOpacity(0.4 + _controller.value * 0.3),
                    blurRadius: 6 + _controller.value * 4,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
