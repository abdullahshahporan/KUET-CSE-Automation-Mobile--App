import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'geo_attendance_service.dart';
import 'local_notification_service.dart';
import 'notification_service.dart';

class GeoAttendancePresenceMonitorService {
  GeoAttendancePresenceMonitorService._();

  static final GeoAttendancePresenceMonitorService instance =
      GeoAttendancePresenceMonitorService._();

  static const Duration _pollInterval = Duration(minutes: 1);

  final Map<String, DateTime> _outsideSinceByRoomId = <String, DateTime>{};
  final Set<String> _markedAbsentRoomIds = <String>{};

  Timer? _timer;
  String? _studentUserId;
  bool _monitoringEnabled = true;
  bool _tickInProgress = false;
  List<Map<String, dynamic>> _submittedRooms = const [];

  void updateRooms({
    required String studentUserId,
    required List<Map<String, dynamic>> rooms,
  }) {
    _studentUserId = studentUserId;
    _submittedRooms = rooms
        .where((room) => room['already_submitted'] == true)
        .map((room) => Map<String, dynamic>.from(room))
        .toList(growable: false);

    final activeRoomIds = _submittedRooms
        .map((room) => room['id']?.toString())
        .whereType<String>()
        .toSet();

    _outsideSinceByRoomId.removeWhere(
      (roomId, _) => !activeRoomIds.contains(roomId),
    );
    _markedAbsentRoomIds.removeWhere(
      (roomId) => !activeRoomIds.contains(roomId),
    );

    if (_submittedRooms.isEmpty) {
      _timer?.cancel();
      _timer = null;
      return;
    }

    _timer ??= Timer.periodic(_pollInterval, (_) {
      unawaited(_tick());
    });
    unawaited(_tick());
  }

  void setMonitoringEnabled(bool value) {
    _monitoringEnabled = value;
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _studentUserId = null;
    _submittedRooms = const [];
    _outsideSinceByRoomId.clear();
    _markedAbsentRoomIds.clear();
    _tickInProgress = false;
  }

  Future<void> _tick() async {
    if (!_monitoringEnabled ||
        _tickInProgress ||
        _studentUserId == null ||
        _studentUserId!.isEmpty ||
        _submittedRooms.isEmpty) {
      return;
    }

    _tickInProgress = true;
    try {
      final locationEnabled = await Geolocator.isLocationServiceEnabled();
      if (!locationEnabled) return;

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      final now = DateTime.now();
      for (final room in _submittedRooms) {
        final roomId = room['id']?.toString();
        if (roomId == null ||
            roomId.isEmpty ||
            _markedAbsentRoomIds.contains(roomId)) {
          continue;
        }

        final graceMinutes =
            ((room['absence_grace_minutes'] as num?)?.round() ??
                    GeoAttendanceService.defaultAbsenceGraceMinutes)
                .clamp(1, 600);

        final locationCheck =
            await GeoAttendanceService.checkAttendanceLocation(
              geoRoomId: roomId,
              latitude: position.latitude,
              longitude: position.longitude,
            );

        if (locationCheck.isWithinRange) {
          _outsideSinceByRoomId.remove(roomId);
          continue;
        }

        final outsideSince = _outsideSinceByRoomId.putIfAbsent(
          roomId,
          () => now,
        );
        if (now.difference(outsideSince) < Duration(minutes: graceMinutes)) {
          continue;
        }

        await GeoAttendanceService.updateRoomAttendanceStatus(
          roomId: roomId,
          studentUserId: _studentUserId!,
          status: 'ABSENT',
        );
        _markedAbsentRoomIds.add(roomId);
        _outsideSinceByRoomId.remove(roomId);
        await _notifyAbsent(room, graceMinutes);
      }
    } catch (e) {
      debugPrint('GeoPresenceMonitor: $e');
    } finally {
      _tickInProgress = false;
    }
  }

  Future<void> _notifyAbsent(
    Map<String, dynamic> room,
    int graceMinutes,
  ) async {
    final offering = room['course_offerings'] as Map<String, dynamic>?;
    final course = offering?['courses'] as Map<String, dynamic>?;
    final courseCode = course?['code'] as String? ?? 'your class';
    final roomId = room['id']?.toString();

    final title = 'Attendance marked absent';
    final body =
        'You stayed outside the geo-attendance area for $graceMinutes min in '
        '$courseCode.';

    await NotificationService.saveLocalInboxNotification(
      type: 'attendance_absent',
      title: title,
      body: body,
      metadata: {
        if (roomId != null && roomId.isNotEmpty) 'geo_room_id': roomId,
        'course_code': courseCode,
        'absent_after_minutes': graceMinutes,
      },
      createdAt: DateTime.now(),
    );

    await LocalNotificationService.show(
      title: title,
      body: body,
      payload: roomId == null ? 'attendance_absent' : 'geo_room|$roomId',
    );
  }
}
