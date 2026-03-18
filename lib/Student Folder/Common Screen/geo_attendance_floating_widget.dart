import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/push_config.dart';
import '../../services/geo_attendance_service.dart';
import '../../services/local_notification_service.dart';
import '../../services/notification_provider.dart';
import '../../services/notification_service.dart';
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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  List<Map<String, dynamic>> _openRooms = [];
  Timer? _refreshTimer;
  Timer? _countdownTimer;
  RealtimeChannel? _realtimeChannel;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  final Set<String> _alertedRoomIds = <String>{};
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 1.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fetchRooms();
    _subscribeRealtime();
    _requestLocationPermission();
    // Re-fetch every minute as a fallback for expiry handling.
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _fetchRooms(),
    );
    // Tick countdown every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _openRooms.isNotEmpty) setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    final channel = _realtimeChannel;
    if (channel != null) {
      unawaited(SupabaseService.removeChannel(channel));
    }
    _slideController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;

    unawaited(_fetchRooms());
    if (mounted) {
      unawaited(context.read<NotificationProvider>().refresh());
    }
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
      final pending = rooms
          .where((r) => r['already_submitted'] != true)
          .toList();
      debugPrint(
        'GeoFloatingWidget: ${pending.length} pending (not submitted)',
      );
      await _syncPendingRoomHistory(pending);
      _updateVisibleRooms(pending);
    } catch (e) {
      debugPrint('GeoFloatingWidget: Error fetching rooms: $e');
    }
  }

  void _subscribeRealtime() {
    final userId = SupabaseService.currentUserId;
    if (userId == null || userId.isEmpty) return;

    _realtimeChannel = SupabaseService.client
        .channel('student-geo-attendance-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'geo_attendance_rooms',
          callback: (payload) {
            unawaited(_handleRealtimeRoomChange(payload));
          },
        )
        .subscribe();
  }

  Future<void> _handleRealtimeRoomChange(PostgresChangePayload payload) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null || userId.isEmpty) return;

    final roomId = (payload.newRecord['id'] ?? payload.oldRecord['id'])
        ?.toString();

    try {
      final rooms = await GeoAttendanceService.getOpenRoomsForStudent(
        studentUserId: userId,
      );
      final pending = rooms
          .where((r) => r['already_submitted'] != true)
          .toList();
      _updateVisibleRooms(pending);

      if (payload.eventType != PostgresChangeEvent.insert || roomId == null) {
        return;
      }

      Map<String, dynamic>? openedRoom;
      for (final room in pending) {
        if (room['id']?.toString() == roomId) {
          openedRoom = room;
          break;
        }
      }

      if (openedRoom == null || !_alertedRoomIds.add(roomId)) {
        return;
      }

      await _showRealtimeRoomAlert(openedRoom);
    } catch (e) {
      debugPrint('GeoFloatingWidget: realtime change error: $e');
    }
  }

  void _updateVisibleRooms(List<Map<String, dynamic>> pending) {
    if (!mounted) return;

    final wasVisible = _visible;
    _visible = pending.isNotEmpty;
    setState(() => _openRooms = pending);

    if (_visible && !wasVisible) {
      _slideController.forward();
    } else if (!_visible && wasVisible) {
      _slideController.reverse();
    }
  }

  Future<void> _showRealtimeRoomAlert(Map<String, dynamic> room) async {
    final payload = _buildRoomNotificationPayload(room);

    await NotificationService.saveLocalInboxNotification(
      type: 'geo_attendance_open',
      title: payload.title,
      body: payload.body,
      metadata: payload.metadata,
      createdAt: DateTime.now(),
    );

    if (!PushConfig.hasRemotePushCredentials) {
      await LocalNotificationService.show(
        title: payload.title,
        body: payload.body,
        payload: 'geo_room|${room['id']}',
      );
    }

    if (mounted) {
      await context.read<NotificationProvider>().refresh();
    }
  }

  Future<void> _syncPendingRoomHistory(
    List<Map<String, dynamic>> pending,
  ) async {
    if (pending.isEmpty) return;

    for (final room in pending) {
      final payload = _buildRoomNotificationPayload(room);
      await NotificationService.saveLocalInboxNotification(
        type: 'geo_attendance_open',
        title: payload.title,
        body: payload.body,
        metadata: payload.metadata,
        createdAt: DateTime.now(),
      );
    }

    if (mounted) {
      await context.read<NotificationProvider>().refresh();
    }
  }

  _RoomNotificationPayload _buildRoomNotificationPayload(
    Map<String, dynamic> room,
  ) {
    final offering = room['course_offerings'] as Map<String, dynamic>?;
    final course = offering?['courses'] as Map<String, dynamic>?;
    final courseCode = course?['code'] as String? ?? 'Course';
    final rawSection = (room['section'] as String?)?.trim();
    final sectionLabel = (rawSection == null || rawSection.isEmpty)
        ? ''
        : ' ($rawSection)';
    final endTime = DateTime.tryParse(room['end_time'] as String? ?? '');
    final endLabel = endTime == null
        ? 'the room closes soon'
        : 'submit before ${_formatTime(endTime.toLocal())}';

    return _RoomNotificationPayload(
      title: 'Attendance Open — $courseCode$sectionLabel',
      body: 'Your attendance for $courseCode is ready. Please $endLabel.',
      metadata: {
        'course_code': courseCode,
        if (room['id'] != null) 'geo_room_id': room['id'].toString(),
        if (rawSection != null && rawSection.isNotEmpty)
          'geo_room_section': rawSection,
        if (room['room_number'] != null &&
            room['room_number'].toString().trim().isNotEmpty)
          'room_number': room['room_number'].toString().trim(),
        if (endTime != null) 'end_time_label': _formatTime(endTime.toLocal()),
      },
    );
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

  String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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
    final teacher =
        (offering?['teachers'] as Map<String, dynamic>?)?['full_name']
            as String? ??
        '';
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
                                  horizontal: 6,
                                  vertical: 2,
                                ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
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
                    color: const Color(
                      0xFF4ADE80,
                    ).withOpacity(0.4 + _controller.value * 0.3),
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

class _RoomNotificationPayload {
  final String title;
  final String body;
  final Map<String, dynamic> metadata;

  const _RoomNotificationPayload({
    required this.title,
    required this.body,
    required this.metadata,
  });
}
