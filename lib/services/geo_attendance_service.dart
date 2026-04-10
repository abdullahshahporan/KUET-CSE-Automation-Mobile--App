import 'dart:math' show pi, sin, cos, sqrt, atan2;
import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

/// Service for geo-attendance room management and attendance submission.
///
/// Distance check uses each room's stored GPS coordinates (30 m radius).
/// Falls back to the KUET CSE building centre (100 m) when a room has no coordinates.
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
      // Auto-close expired rooms first
      await SupabaseService.from('geo_attendance_rooms')
          .update({'is_active': false})
          .eq('is_active', true)
          .lt('end_time', DateTime.now().toUtc().toIso8601String());

      // Check course type to determine max rooms
      final offering = await SupabaseService.from('course_offerings')
          .select('courses(course_type)')
          .eq('id', offeringId)
          .single();
      final courseType = (offering['courses']?['course_type'] as String?)?.toLowerCase() ?? 'theory';
      final maxRooms = courseType == 'lab' ? maxLabRooms : maxTheoryRooms;

      // Count current active rooms for this teacher
      final activeData = await SupabaseService.from('geo_attendance_rooms')
          .select('id')
          .eq('teacher_user_id', teacherUserId)
          .eq('is_active', true);
      final activeCount = (activeData as List).length;

      if (activeCount >= maxRooms) {
        throw Exception(
          'Room limit reached: You already have $activeCount active room(s). '
          'Max $maxRooms for ${courseType == "lab" ? "lab" : "theory"} courses. '
          'Close an existing room first.'
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

      final sessionData = await SupabaseService.from('class_sessions')
          .insert(sessionInsert)
          .select('id')
          .single();
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
      if (roomNumber != null && roomNumber.isNotEmpty) {
        roomInsert['room_number'] = roomNumber;
      }
      if (section != null && section.isNotEmpty) {
        roomInsert['section'] = section;
      }

      final data = await SupabaseService.from('geo_attendance_rooms')
          .insert(roomInsert)
          .select('*')
          .single();

      return data;
    } catch (e) {
      debugPrint('Error opening geo room: $e');
      rethrow;
    }
  }

  // ── Teacher: Close a geo-attendance room ─────────────────

  static Future<void> closeRoom(String roomId) async {
    await SupabaseService.from('geo_attendance_rooms')
        .update({'is_active': false})
        .eq('id', roomId);
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
      String roomId) async {
    try {
      final data = await SupabaseService.from('geo_attendance_logs')
          .select('''
            *,
            students!geo_attendance_logs_student_fkey ( roll_no, full_name )
          ''')
          .eq('geo_room_id', roomId)
          .order('submitted_at', ascending: true);

      return List<Map<String, dynamic>>.from(data as List);
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
      final studentData = await SupabaseService.from('students')
          .select('term, section, roll_no')
          .eq('user_id', studentUserId)
          .single();
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

      debugPrint('GeoService: ${roomList.length} rooms after term=$term filter');

      // Filter by student's section if the room has a section specified
      roomList.removeWhere((room) {
        final roomSection = room['section'] as String?;
        if (roomSection == null || roomSection.isEmpty) return false;

        // Extract roll number suffix for matching
        final rollNum = int.tryParse(
            rollNo.length >= 3 ? rollNo.substring(rollNo.length - 3) : rollNo) ?? 0;

        // Normalize section label - support both short codes (A, B, A1...) and
        // long labels (Section A (01–60), Group A1 (01–30)...)
        final sectionUpper = roomSection.toUpperCase().trim();

        bool matchesSection(String code) {
          return sectionUpper == code ||
              sectionUpper.startsWith('SECTION $code') ||
              sectionUpper.startsWith('GROUP $code');
        }

        // Theory sections
        if (matchesSection('A') && !matchesSection('A1') && !matchesSection('A2')) {
          return rollNum < 1 || rollNum > 60;
        }
        if (matchesSection('B') && !matchesSection('B1') && !matchesSection('B2')) {
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
      await SupabaseService.from('geo_attendance_rooms')
          .update({'is_active': false})
          .eq('id', geoRoomId);
      throw Exception('This attendance room has expired');
    }

    // 2. Calculate distance – prefer room-specific coordinates, fallback to building
    double targetLat = buildingLat;
    double targetLng = buildingLng;
    double maxDist = buildingMaxDistanceMeters;

    final roomNumber = roomData['room_number'] as String?;
    if (roomNumber != null && roomNumber.isNotEmpty) {
      final roomRow = await SupabaseService.from('rooms')
          .select('latitude, longitude')
          .eq('room_number', roomNumber)
          .maybeSingle();
      final roomLat = (roomRow?['latitude'] as num?)?.toDouble();
      final roomLng = (roomRow?['longitude'] as num?)?.toDouble();
      if (roomLat != null && roomLng != null) {
        targetLat = roomLat;
        targetLng = roomLng;
        maxDist = roomMaxDistanceMeters;
      }
    }

    final distance = _haversineDistance(latitude, longitude, targetLat, targetLng);

    if (distance > maxDist) {
      final label = maxDist == roomMaxDistanceMeters ? 'room' : 'building';
      throw GeoDistanceException(
        'You are ${distance.round()}m from the $label. Must be within ${maxDist.round()}m.',
        distance,
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
    String? enrollmentId;
    final enrollmentData = await SupabaseService.from('enrollments')
        .select('id')
        .eq('offering_id', roomData['offering_id'])
        .eq('student_user_id', studentUserId)
        .maybeSingle();

    if (enrollmentData != null) {
      enrollmentId = enrollmentData['id'] as String;
    } else {
      // Auto-create enrollment
      final newEnrollment = await SupabaseService.from('enrollments')
          .insert({
            'offering_id': roomData['offering_id'],
            'student_user_id': studentUserId,
            'enrollment_status': 'ENROLLED',
          })
          .select('id')
          .single();
      enrollmentId = newEnrollment['id'] as String;
    }

    // 5. Save geo-attendance log
    await SupabaseService.from('geo_attendance_logs').insert({
      'geo_room_id': geoRoomId,
      'student_user_id': studentUserId,
      'latitude': latitude,
      'longitude': longitude,
      'distance_meters': distance.round(),
      'status': 'PRESENT',
    });

    // 6. Save to main attendance_records
    try {
      await SupabaseService.from('attendance_records').upsert({
        'session_id': roomData['session_id'],
        'enrollment_id': enrollmentId,
        'status': 'PRESENT',
        'marked_by_teacher_user_id': roomData['teacher_user_id'],
        'remarks': 'Geo-attendance: ${distance.round()}m',
      });
    } catch (e) {
      debugPrint('Warning: Could not save attendance_record: $e');
    }

    // 7. Save to flat `attendance` table (same as manual/CSV attendance)
    try {
      final offering = roomData['course_offerings'] as Map<String, dynamic>?;
      final courseCode =
          (offering?['courses'] as Map<String, dynamic>?)?['code'] as String?;

      final studentRow = await SupabaseService.from('students')
          .select('roll_no')
          .eq('user_id', studentUserId)
          .single();
      final studentRoll = studentRow['roll_no'] as String?;

      final attendanceDate =
          roomData['date'] as String? ??
          DateTime.now().toIso8601String().split('T')[0];

      if (courseCode != null && studentRoll != null) {
        await SupabaseService.from('attendance').upsert({
          'course_code': courseCode,
          'student_roll': studentRoll,
          'date': attendanceDate,
          'status': 'present',
          'section_or_group': roomData['section'],
        });
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

  // ── Haversine formula ────────────────────────────────────

  /// Calculate distance from given coordinates to the KUET CSE Building.
  static double calculateDistance(double latitude, double longitude) {
    return _haversineDistance(latitude, longitude, buildingLat, buildingLng);
  }

  static double _haversineDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    const r = 6371000.0; // Earth radius in meters
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }
}

/// Custom exception for distance violations
class GeoDistanceException implements Exception {
  final String message;
  final double distance;
  GeoDistanceException(this.message, this.distance);

  @override
  String toString() => message;
}
