import 'dart:math' show pi, sin, cos, sqrt, atan2;
import 'package:flutter/foundation.dart';
import 'biometric_auth_service.dart';
import 'supabase_service.dart';

/// Service for geo-attendance room management and attendance submission.
///
/// Geo-attendance now requires a mapped room with GPS coordinates so the
/// 30-meter radius can be enforced consistently.
class GeoAttendanceService {
  static const double buildingLat = 22.8993;
  static const double buildingLng = 89.5023;

  /// Radius when the room has its own stored coordinates.
  static const double roomMaxDistanceMeters = 30;

  /// Fallback radius when a room has no stored coordinates.
  static const double buildingMaxDistanceMeters = 100;
  static const int maxTheoryRooms = 2;
  static const int maxLabRooms = 4;

  // ── Teacher: Open a geo-attendance room ──────────────────

  static Future<Map<String, dynamic>> openRoom({
    required String offeringId,
    required String teacherUserId,
    required DateTime startTime,
    required DateTime endTime,
    String? roomNumber,
    String? section,
  }) async {
    try {
      final cleanedRoomNumber = roomNumber?.trim();
      if (cleanedRoomNumber == null || cleanedRoomNumber.isEmpty) {
        throw Exception('Please select a mapped room for geo-attendance.');
      }

      await _resolveRoomTarget(cleanedRoomNumber);

      // Auto-close expired rooms first
      await SupabaseService.from('geo_attendance_rooms')
          .update({'is_active': false})
          .eq('is_active', true)
          .lt('end_time', DateTime.now().toUtc().toIso8601String());

      // Check course type to determine max rooms
      final offering = await SupabaseService.from(
        'course_offerings',
      ).select('courses(course_type)').eq('id', offeringId).single();
      final courseType =
          (offering['courses']?['course_type'] as String?)?.toLowerCase() ??
          'theory';
      final maxRooms = courseType == 'lab' ? maxLabRooms : maxTheoryRooms;

      // Count current active rooms for this teacher
      final activeData = await SupabaseService.from(
        'geo_attendance_rooms',
      ).select('id').eq('teacher_user_id', teacherUserId).eq('is_active', true);
      final activeCount = (activeData as List).length;

      if (activeCount >= maxRooms) {
        throw Exception(
          'Room limit reached: You already have $activeCount active room(s). '
          'Max $maxRooms for ${courseType == "lab" ? "lab" : "theory"} courses. '
          'Close an existing room first.',
        );
      }

      // Create a class_session for this geo-attendance
      // NOTE: room_number is NOT inserted here because class_sessions has a FK
      // to the rooms table. The room_number is stored on geo_attendance_rooms instead.
      final sessionInsert = <String, dynamic>{
        'offering_id': offeringId,
        'starts_at': startTime.toUtc().toIso8601String(),
        'ends_at': endTime.toUtc().toIso8601String(),
        'topic': 'Geo-Attendance Session',
      };

      final sessionData = await SupabaseService.from(
        'class_sessions',
      ).insert(sessionInsert).select('id').single();
      final sessionId = sessionData['id'] as String;

      // Create the geo-attendance room
      final roomInsert = <String, dynamic>{
        'offering_id': offeringId,
        'session_id': sessionId,
        'teacher_user_id': teacherUserId,
        'date': DateTime.now().toIso8601String().split('T')[0],
        'start_time': startTime.toUtc().toIso8601String(),
        'end_time': endTime.toUtc().toIso8601String(),
        'is_active': true,
      };
      roomInsert['room_number'] = cleanedRoomNumber;
      if (section != null && section.isNotEmpty) {
        roomInsert['section'] = section;
      }

      final data = await SupabaseService.from(
        'geo_attendance_rooms',
      ).insert(roomInsert).select('*').single();

      return data;
    } catch (e) {
      debugPrint('Error opening geo room: $e');
      rethrow;
    }
  }

  // ── Teacher: Close a geo-attendance room ─────────────────

  static Future<void> closeRoom(String roomId) async {
    await SupabaseService.from(
      'geo_attendance_rooms',
    ).update({'is_active': false}).eq('id', roomId);
  }

  // ── Teacher: Get active rooms ────────────────────────────

  static Future<List<Map<String, dynamic>>> getActiveRooms({
    required String teacherUserId,
  }) async {
    try {
      // Close expired rooms first (use UTC for correct comparison)
      await SupabaseService.from('geo_attendance_rooms')
          .update({'is_active': false})
          .eq('is_active', true)
          .lt('end_time', DateTime.now().toUtc().toIso8601String());

      final data = await SupabaseService.from('geo_attendance_rooms')
          .select('''
            *,
            course_offerings (
              id, term,
              courses ( code, title, course_type )
            )
          ''')
          .eq('teacher_user_id', teacherUserId)
          .eq('is_active', true)
          .order('start_time', ascending: false);

      return List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      debugPrint('Error fetching active rooms: $e');
      return [];
    }
  }

  // ── Teacher: Get recent rooms (closed) ───────────────────

  static Future<List<Map<String, dynamic>>> getRecentRooms({
    required String teacherUserId,
    int limit = 10,
  }) async {
    try {
      final data = await SupabaseService.from('geo_attendance_rooms')
          .select('''
            *,
            course_offerings (
              id, term,
              courses ( code, title, course_type )
            )
          ''')
          .eq('teacher_user_id', teacherUserId)
          .eq('is_active', false)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      debugPrint('Error fetching recent rooms: $e');
      return [];
    }
  }

  // ── Teacher: Get attendance logs for a room ──────────────

  static Future<List<Map<String, dynamic>>> getRoomAttendanceLogs(
    String roomId,
  ) async {
    try {
      final roomData = await SupabaseService.from(
        'geo_attendance_rooms',
      ).select('session_id, offering_id').eq('id', roomId).single();

      final data = await SupabaseService.from('geo_attendance_logs')
          .select('''
            *,
            students!geo_attendance_logs_student_fkey ( roll_no, full_name )
          ''')
          .eq('geo_room_id', roomId)
          .order('submitted_at', ascending: true);

      final logs = List<Map<String, dynamic>>.from(data as List);
      if (logs.isEmpty) return logs;

      final studentIds = logs
          .map((log) => log['student_user_id'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      if (studentIds.isEmpty) {
        for (final log in logs) {
          log['attendance_status'] = log['status'];
        }
        return logs;
      }

      final enrollmentData = await SupabaseService.from('enrollments')
          .select('id, student_user_id')
          .eq('offering_id', roomData['offering_id'] as String)
          .inFilter('student_user_id', studentIds);

      final enrollmentByStudentId = <String, String>{};
      for (final row in enrollmentData as List) {
        final map = row as Map<String, dynamic>;
        final studentId = map['student_user_id'] as String?;
        final enrollmentId = map['id'] as String?;
        if (studentId != null && enrollmentId != null) {
          enrollmentByStudentId[studentId] = enrollmentId;
        }
      }

      final attendanceByEnrollmentId = <String, Map<String, dynamic>>{};
      final enrollmentIds = enrollmentByStudentId.values.toList();
      final sessionId = roomData['session_id'] as String?;

      if (sessionId != null && enrollmentIds.isNotEmpty) {
        final attendanceData = await SupabaseService.from('attendance_records')
            .select('id, enrollment_id, status')
            .eq('session_id', sessionId)
            .inFilter('enrollment_id', enrollmentIds);

        for (final row in attendanceData as List) {
          final map = row as Map<String, dynamic>;
          final enrollmentId = map['enrollment_id'] as String?;
          if (enrollmentId != null) {
            attendanceByEnrollmentId[enrollmentId] = map;
          }
        }
      }

      for (final log in logs) {
        final studentId = log['student_user_id'] as String?;
        final enrollmentId = studentId == null
            ? null
            : enrollmentByStudentId[studentId];
        final attendanceRecord = enrollmentId == null
            ? null
            : attendanceByEnrollmentId[enrollmentId];

        log['attendance_status'] =
            attendanceRecord?['status'] ?? log['status'] ?? 'PRESENT';
        if (attendanceRecord != null) {
          log['attendance_record_id'] = attendanceRecord['id'];
        }
      }

      return logs;
    } catch (e) {
      debugPrint('Error fetching attendance logs: $e');
      return [];
    }
  }

  // ── Student: Get open rooms for my courses ───────────────

  static Future<List<Map<String, dynamic>>> getOpenRoomsForStudent({
    required String studentUserId,
  }) async {
    try {
      // Get student's term and section
      final studentData = await SupabaseService.from(
        'students',
      ).select('term, section, roll_no').eq('user_id', studentUserId).single();
      final term = studentData['term'] as String;
      //final studentSection = studentData['section'] as String?;
      final rollNo = studentData['roll_no'] as String? ?? '';

      // Close expired rooms (use UTC for correct comparison)
      await SupabaseService.from('geo_attendance_rooms')
          .update({'is_active': false})
          .eq('is_active', true)
          .lt('end_time', DateTime.now().toUtc().toIso8601String());

      // Get active rooms — use regular joins (not !inner) and filter in Dart
      // to avoid PostgREST join failures that silently return empty results.
      final rooms = await SupabaseService.from('geo_attendance_rooms')
          .select('''
            *,
            course_offerings (
              id, term,
              courses ( code, title, course_type ),
              teachers ( full_name )
            )
          ''')
          .eq('is_active', true)
          .order('start_time', ascending: true);

      debugPrint('GeoService: fetched ${(rooms as List).length} active rooms');

      final roomList = List<Map<String, dynamic>>.from(rooms);

      // Filter rooms whose offering matches the student's term
      roomList.removeWhere((room) {
        final offering = room['course_offerings'] as Map<String, dynamic>?;
        if (offering == null) return true;
        return offering['term'] != term;
      });

      debugPrint(
        'GeoService: ${roomList.length} rooms after term=$term filter',
      );

      // Filter by student's section if the room has a section specified
      roomList.removeWhere((room) {
        final roomSection = room['section'] as String?;
        if (roomSection == null || roomSection.isEmpty) return false;

        // Extract roll number suffix for matching
        final rollNum =
            int.tryParse(
              rollNo.length >= 3 ? rollNo.substring(rollNo.length - 3) : rollNo,
            ) ??
            0;

        // Normalize section label - support both short codes (A, B, A1...) and
        // long labels (Section A (01–60), Group A1 (01–30)...)
        final sectionUpper = roomSection.toUpperCase().trim();

        bool matchesSection(String code) {
          return sectionUpper == code ||
              sectionUpper.startsWith('SECTION $code') ||
              sectionUpper.startsWith('GROUP $code');
        }

        // Theory sections
        if (matchesSection('A') &&
            !matchesSection('A1') &&
            !matchesSection('A2')) {
          return rollNum < 1 || rollNum > 60;
        }
        if (matchesSection('B') &&
            !matchesSection('B1') &&
            !matchesSection('B2')) {
          return rollNum < 61 || rollNum > 120;
        }
        // Lab groups
        if (matchesSection('A1')) return rollNum < 1 || rollNum > 30;
        if (matchesSection('A2')) return rollNum < 31 || rollNum > 60;
        if (matchesSection('B1')) return rollNum < 61 || rollNum > 90;
        if (matchesSection('B2')) return rollNum < 91 || rollNum > 120;

        return false;
      });

      // Check which rooms student already submitted to
      if (roomList.isNotEmpty) {
        final roomIds = roomList.map((r) => r['id'] as String).toList();
        final logs = await SupabaseService.from('geo_attendance_logs')
            .select('geo_room_id')
            .eq('student_user_id', studentUserId)
            .inFilter('geo_room_id', roomIds);

        final submittedIds = (logs as List)
            .map((l) => l['geo_room_id'] as String)
            .toSet();

        for (final room in roomList) {
          room['already_submitted'] = submittedIds.contains(room['id']);
        }
      }

      return roomList;
    } catch (e) {
      debugPrint('Error fetching open rooms: $e');
      return [];
    }
  }

  // ── Student: Submit geo-attendance ───────────────────────

  static Future<Map<String, dynamic>> submitAttendance({
    required String geoRoomId,
    required String studentUserId,
    required double latitude,
    required double longitude,
  }) async {
    // 1. Check room is active
    final roomData = await SupabaseService.from('geo_attendance_rooms')
        .select('*, course_offerings(id, term, courses(code))')
        .eq('id', geoRoomId)
        .single();

    if (roomData['is_active'] != true) {
      throw Exception('This attendance room is no longer active');
    }

    final endTime = DateTime.parse(roomData['end_time'] as String);
    if (endTime.isBefore(DateTime.now())) {
      await SupabaseService.from(
        'geo_attendance_rooms',
      ).update({'is_active': false}).eq('id', geoRoomId);
      throw Exception('This attendance room has expired');
    }

    // 2. Calculate distance – prefer room-specific coordinates, fallback to building
    final locationCheck = await _buildLocationCheck(
      roomNumber: roomData['room_number'] as String?,
      latitude: latitude,
      longitude: longitude,
    );
    final distance = locationCheck.distance;

    if (!locationCheck.isWithinRange) {
      throw GeoDistanceException(
        locationCheck.message,
        distance,
        maxDistance: locationCheck.maxDistance,
        targetLabel: locationCheck.targetLabel,
      );
    }

    // 3. Check for duplicate submission
    final existing = await SupabaseService.from('geo_attendance_logs')
        .select('id')
        .eq('geo_room_id', geoRoomId)
        .eq('student_user_id', studentUserId)
        .maybeSingle();

    if (existing != null) {
      throw Exception('You have already submitted attendance for this session');
    }

    // 4. Ensure enrollment exists
    final enrollmentId = await _ensureEnrollmentId(
      offeringId: roomData['offering_id'] as String,
      studentUserId: studentUserId,
    );

    // 5. Require biometric verification before writing attendance.
    await BiometricAuthService.requireBiometricForAttendance();

    // 6. Save geo-attendance log
    await SupabaseService.from('geo_attendance_logs').insert({
      'geo_room_id': geoRoomId,
      'student_user_id': studentUserId,
      'latitude': latitude,
      'longitude': longitude,
      'distance_meters': distance.round(),
      'status': 'PRESENT',
    });

    // 7. Save to main attendance_records
    try {
      await _syncAttendanceRecordStatus(
        sessionId: roomData['session_id'] as String,
        enrollmentId: enrollmentId,
        status: 'PRESENT',
        teacherUserId: roomData['teacher_user_id'] as String,
        remarks: 'Geo-attendance: ${distance.round()}m',
      );
    } catch (e) {
      debugPrint('Warning: Could not save attendance_record: $e');
    }

    // 8. Save to flat `attendance` table (same as manual/CSV attendance)
    try {
      final offering = roomData['course_offerings'] as Map<String, dynamic>?;
      final courseCode =
          (offering?['courses'] as Map<String, dynamic>?)?['code'] as String?;

      final attendanceDate =
          roomData['date'] as String? ??
          DateTime.now().toIso8601String().split('T')[0];

      if (courseCode != null) {
        await _syncFlatAttendanceStatus(
          courseCode: courseCode,
          studentUserId: studentUserId,
          attendanceDate: attendanceDate,
          status: 'present',
          sectionOrGroup: roomData['section'] as String?,
        );
      }
    } catch (e) {
      debugPrint('Warning: Could not save to flat attendance table: $e');
    }

    return {
      'success': true,
      'distance': distance.round(),
      'message': 'Attendance recorded successfully',
    };
  }

  static Future<GeoAttendanceLocationCheck> checkAttendanceLocation({
    required String geoRoomId,
    required double latitude,
    required double longitude,
  }) async {
    final roomData = await SupabaseService.from(
      'geo_attendance_rooms',
    ).select('room_number').eq('id', geoRoomId).single();

    return _buildLocationCheck(
      roomNumber: roomData['room_number'] as String?,
      latitude: latitude,
      longitude: longitude,
    );
  }

  static Future<void> updateRoomAttendanceStatus({
    required String roomId,
    required String studentUserId,
    required String status,
  }) async {
    final normalizedStatus = status.trim().toUpperCase();
    const allowedStatuses = {'PRESENT', 'LATE', 'ABSENT'};
    if (!allowedStatuses.contains(normalizedStatus)) {
      throw Exception('Unsupported attendance status: $status');
    }

    final roomData = await SupabaseService.from('geo_attendance_rooms')
        .select('''
          session_id,
          offering_id,
          teacher_user_id,
          date,
          section,
          course_offerings (
            courses ( code )
          )
        ''')
        .eq('id', roomId)
        .single();

    final sessionId = roomData['session_id'] as String?;
    if (sessionId == null || sessionId.isEmpty) {
      throw Exception('This geo-attendance room is missing a class session.');
    }

    final enrollmentId = await _ensureEnrollmentId(
      offeringId: roomData['offering_id'] as String,
      studentUserId: studentUserId,
    );

    await _syncAttendanceRecordStatus(
      sessionId: sessionId,
      enrollmentId: enrollmentId,
      status: normalizedStatus,
      teacherUserId: roomData['teacher_user_id'] as String,
      remarks: 'Teacher override in geo-attendance room',
    );

    final offering = roomData['course_offerings'] as Map<String, dynamic>?;
    final courseCode =
        (offering?['courses'] as Map<String, dynamic>?)?['code'] as String?;
    final attendanceDate =
        roomData['date'] as String? ??
        DateTime.now().toIso8601String().split('T')[0];

    if (courseCode != null && courseCode.isNotEmpty) {
      await _syncFlatAttendanceStatus(
        courseCode: courseCode,
        studentUserId: studentUserId,
        attendanceDate: attendanceDate,
        status: normalizedStatus.toLowerCase(),
        sectionOrGroup: roomData['section'] as String?,
      );
    }

    if (normalizedStatus != 'ABSENT') {
      await SupabaseService.from('geo_attendance_logs')
          .update({'status': normalizedStatus})
          .eq('geo_room_id', roomId)
          .eq('student_user_id', studentUserId);
    }
  }

  // ── Haversine formula ────────────────────────────────────

  /// Calculate distance from given coordinates to the KUET CSE Building.
  static double calculateDistance(double latitude, double longitude) {
    return _haversineDistance(latitude, longitude, buildingLat, buildingLng);
  }

  static Future<GeoAttendanceLocationCheck> _buildLocationCheck({
    required String? roomNumber,
    required double latitude,
    required double longitude,
  }) async {
    final target = await _resolveRoomTarget(roomNumber);
    final distance = _haversineDistance(
      latitude,
      longitude,
      target.latitude,
      target.longitude,
    );

    return GeoAttendanceLocationCheck(
      distance: distance,
      maxDistance: target.maxDistance,
      targetLabel: target.label,
      roomNumber: target.roomNumber,
    );
  }

  static Future<_GeoAttendanceTarget> _resolveRoomTarget(
    String? roomNumber,
  ) async {
    final cleanedRoomNumber = roomNumber?.trim();
    if (cleanedRoomNumber == null || cleanedRoomNumber.isEmpty) {
      throw Exception(
        'This attendance room has no mapped classroom. Please ask the teacher '
        'to reopen it after selecting a room.',
      );
    }

    final roomRows = await SupabaseService.from('rooms')
        .select('room_number, latitude, longitude')
        .inFilter('room_number', _roomNumberVariants(cleanedRoomNumber));

    final rooms = List<Map<String, dynamic>>.from(roomRows as List);
    for (final room in rooms) {
      final roomLat = (room['latitude'] as num?)?.toDouble();
      final roomLng = (room['longitude'] as num?)?.toDouble();
      if (roomLat != null && roomLng != null) {
        return _GeoAttendanceTarget(
          latitude: roomLat,
          longitude: roomLng,
          maxDistance: roomMaxDistanceMeters,
          roomNumber: room['room_number'] as String? ?? cleanedRoomNumber,
        );
      }
    }

    if (rooms.isNotEmpty) {
      final matchedRoom =
          rooms.first['room_number'] as String? ?? cleanedRoomNumber;
      throw Exception(
        'Room $matchedRoom does not have GPS coordinates yet. '
        'Please update the room location before opening geo-attendance.',
      );
    }

    throw Exception(
      'Room $cleanedRoomNumber was not found. '
      'Please select a valid room and try again.',
    );
  }

  static Future<String> _ensureEnrollmentId({
    required String offeringId,
    required String studentUserId,
  }) async {
    final enrollmentData = await SupabaseService.from('enrollments')
        .select('id')
        .eq('offering_id', offeringId)
        .eq('student_user_id', studentUserId)
        .maybeSingle();

    if (enrollmentData != null) {
      return enrollmentData['id'] as String;
    }

    final newEnrollment = await SupabaseService.from('enrollments')
        .insert({
          'offering_id': offeringId,
          'student_user_id': studentUserId,
          'enrollment_status': 'ENROLLED',
        })
        .select('id')
        .single();

    return newEnrollment['id'] as String;
  }

  static Future<void> _syncAttendanceRecordStatus({
    required String sessionId,
    required String enrollmentId,
    required String status,
    required String teacherUserId,
    String? remarks,
  }) async {
    final existing = await SupabaseService.from('attendance_records')
        .select('id')
        .eq('session_id', sessionId)
        .eq('enrollment_id', enrollmentId)
        .maybeSingle();

    final payload = <String, dynamic>{
      'status': status.trim().toUpperCase(),
      'marked_by_teacher_user_id': teacherUserId,
      'marked_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (remarks != null && remarks.isNotEmpty) {
      payload['remarks'] = remarks;
    }

    if (existing != null) {
      await SupabaseService.from(
        'attendance_records',
      ).update(payload).eq('id', existing['id'] as String);
      return;
    }

    await SupabaseService.from('attendance_records').insert({
      'session_id': sessionId,
      'enrollment_id': enrollmentId,
      ...payload,
    });
  }

  static Future<void> _syncFlatAttendanceStatus({
    required String courseCode,
    required String studentUserId,
    required String attendanceDate,
    required String status,
    String? sectionOrGroup,
  }) async {
    final studentRow = await SupabaseService.from(
      'students',
    ).select('roll_no').eq('user_id', studentUserId).single();
    final studentRoll = studentRow['roll_no'] as String?;
    if (studentRoll == null || studentRoll.isEmpty) return;

    final payload = <String, dynamic>{
      'course_code': courseCode,
      'student_roll': studentRoll,
      'date': attendanceDate,
      'status': status.toLowerCase(),
    };
    if (sectionOrGroup != null) {
      payload['section_or_group'] = sectionOrGroup;
    }

    final existing = await SupabaseService.from('attendance')
        .select('id')
        .eq('course_code', courseCode)
        .eq('student_roll', studentRoll)
        .eq('date', attendanceDate)
        .maybeSingle();

    if (existing != null) {
      await SupabaseService.from(
        'attendance',
      ).update(payload).eq('id', existing['id'] as String);
      return;
    }

    await SupabaseService.from('attendance').insert(payload);
  }

  static List<String> _roomNumberVariants(String roomNumber) {
    final variants = <String>{};

    void addVariant(String value) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return;
      variants.add(trimmed);
      variants.add(trimmed.toUpperCase());
    }

    addVariant(roomNumber);

    final compact = roomNumber.replaceAll(RegExp(r'\s+'), ' ').trim();
    addVariant(compact);

    final collapsed = roomNumber.replaceAll(RegExp(r'[\s_-]+'), '');
    addVariant(collapsed);

    for (final part in roomNumber.split(RegExp(r'[-_/\s]+'))) {
      addVariant(part);
    }

    final trailingToken = RegExp(
      r'([A-Za-z]*\d+[A-Za-z]*)$',
    ).firstMatch(compact);
    if (trailingToken != null) {
      addVariant(trailingToken.group(1)!);
    }

    return variants.toList();
  }

  static double _haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371000.0; // Earth radius in meters
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }
}

/// Custom exception for distance violations
class GeoDistanceException implements Exception {
  final String message;
  final double distance;
  final double maxDistance;
  final String targetLabel;

  GeoDistanceException(
    this.message,
    this.distance, {
    this.maxDistance = GeoAttendanceService.roomMaxDistanceMeters,
    this.targetLabel = 'room',
  });

  @override
  String toString() => message;
}

class GeoAttendanceLocationCheck {
  final double distance;
  final double maxDistance;
  final String targetLabel;
  final String roomNumber;

  const GeoAttendanceLocationCheck({
    required this.distance,
    required this.maxDistance,
    required this.targetLabel,
    required this.roomNumber,
  });

  bool get isWithinRange => distance <= maxDistance;

  String get message =>
      'You are ${distance.round()}m from the $targetLabel. '
      'You must be within ${maxDistance.round()}m.';
}

class _GeoAttendanceTarget {
  final double latitude;
  final double longitude;
  final double maxDistance;
  final String roomNumber;

  const _GeoAttendanceTarget({
    required this.latitude,
    required this.longitude,
    required this.maxDistance,
    required this.roomNumber,
  });

  String get label => 'room $roomNumber';
}
