import 'authenticated_api.dart';
import 'dart:math' show pi, sin, cos, sqrt, atan2;
import 'package:flutter/foundation.dart';
import '../utils/course_utils.dart';
import 'biometric_auth_service.dart';
import 'geo_attendance_code_service.dart';
import 'supabase_service.dart';

/// Service for geo-attendance room management and attendance submission.
///
/// Geo-attendance now requires a mapped room with GPS coordinates so each room
/// can enforce its configured radius consistently.
class GeoAttendanceService {
  static const double buildingLat = 22.8993;
  static const double buildingLng = 89.5023;

  static const double defaultRoomMaxDistanceMeters = 30;
  static const int defaultDurationMinutes = 50;
  static const int defaultAbsenceGraceMinutes = 5;
  static const int maxTheoryRooms = 2;
  static const int maxLabRooms = 4;

  // ── Shared target resolution for teacher + student flows ──────────────

  static String? _cleanText(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static String? _deriveTermFromCourseCode(String? courseCode) {
    if (courseCode == null) return null;
    final match = RegExp(r'\d\d').firstMatch(courseCode);
    if (match != null) {
      final digits = match.group(0)!;
      return '${digits[0]}-${digits[1]}';
    }
    return null;
  }

  static String? _normalizeTerm(String? value) {
    final cleaned = _cleanText(value);
    if (cleaned == null) return null;

    final direct = RegExp(r'^([1-4])\s*[-/]\s*([1-2])$').firstMatch(cleaned);
    if (direct != null) {
      return '${direct.group(1)}-${direct.group(2)}';
    }

    final named = RegExp(
      r'(?:year|level|term|semester)?\s*([1-4])\D+(?:term|semester)?\s*([1-2])',
      caseSensitive: false,
    ).firstMatch(cleaned);
    if (named != null) {
      return '${named.group(1)}-${named.group(2)}';
    }

    return cleaned;
  }

  static bool _termsMatch(String? left, String? right) {
    final leftTerm = _normalizeTerm(left);
    final rightTerm = _normalizeTerm(right);
    return leftTerm != null && rightTerm != null && leftTerm == rightTerm;
  }

  static String? _normalizeSection(String? section) {
    final cleaned = _cleanText(section);
    if (cleaned == null) return null;

    final normalized = cleaned.toUpperCase();
    if (RegExp(r'^[A-Z]\d?$').hasMatch(normalized)) {
      return normalized;
    }

    final named = RegExp(
      r'\b(section|group)\s+([A-Za-z]\d?)\b',
      caseSensitive: false,
    ).firstMatch(cleaned);
    if (named != null) {
      return named.group(2)?.toUpperCase();
    }

    return normalized;
  }

  static ({int min, int max})? _getRollRange(String? section) {
    switch (_normalizeSection(section)) {
      case 'A':
        return (min: 1, max: 60);
      case 'B':
        return (min: 61, max: 121);
      case 'A1':
        return (min: 1, max: 30);
      case 'A2':
        return (min: 31, max: 60);
      case 'B1':
        return (min: 61, max: 90);
      case 'B2':
        return (min: 91, max: 121);
      default:
        return null;
    }
  }

  static int? _extractRollSuffix(String? rollNo) {
    final digits = (rollNo ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(
      digits.substring(digits.length >= 3 ? digits.length - 3 : 0),
    );
  }

  static bool _isTargetStudentForSection(
    Map<String, dynamic> student,
    String? section,
  ) {
    final normalizedSection = _normalizeSection(section);
    if (normalizedSection == null) return true;

    final studentSection = _cleanText(
      student['section'] as String?,
    )?.toUpperCase();
    if (studentSection == normalizedSection) {
      return true;
    }

    final rollRange = _getRollRange(section);
    final rollSuffix = _extractRollSuffix(student['roll_no'] as String?);
    if (rollRange == null || rollSuffix == null) {
      return false;
    }

    return rollSuffix >= rollRange.min && rollSuffix <= rollRange.max;
  }

  static String? _roomCourseCode(Map<String, dynamic> room) {
    final offering = room['course_offerings'] as Map<String, dynamic>?;
    final course = offering?['courses'] as Map<String, dynamic>?;
    return _cleanText(course?['code']?.toString()) ??
        _cleanText(room['course_code']?.toString());
  }

  static String? _roomTargetTerm(Map<String, dynamic> room) {
    final offering = room['course_offerings'] as Map<String, dynamic>?;
    final courseCode = _roomCourseCode(room);
    return _normalizeTerm(room['target_term']?.toString()) ??
        _normalizeTerm(offering?['term']?.toString()) ??
        _deriveTermFromCourseCode(courseCode);
  }

  static bool _isRoomCurrentlyOpen(Map<String, dynamic> room) {
    if (room['is_active'] != true) return false;
    final endTime = DateTime.tryParse(room['end_time']?.toString() ?? '');
    if (endTime == null) return true;
    return endTime.toLocal().isAfter(DateTime.now());
  }

  static void _applyRoomCourseFallback(
    Map<String, dynamic> room, {
    String? courseCode,
    String? term,
    String? section,
  }) {
    final cleanedSection = _cleanText(section);
    if (cleanedSection != null &&
        _cleanText(room['section']?.toString()) == null) {
      room['section'] = cleanedSection;
    }

    final existingOffering = room['course_offerings'] as Map<String, dynamic>?;
    final existingCourse =
        existingOffering?['courses'] as Map<String, dynamic>?;
    final resolvedCode =
        _cleanText(existingCourse?['code']?.toString()) ??
        _cleanText(room['course_code']?.toString()) ??
        _cleanText(courseCode);
    final resolvedTerm =
        _normalizeTerm(existingOffering?['term']?.toString()) ??
        _normalizeTerm(room['target_term']?.toString()) ??
        _normalizeTerm(term) ??
        _deriveTermFromCourseCode(resolvedCode);

    if (existingOffering == null &&
        (resolvedCode != null || resolvedTerm != null)) {
      room['course_offerings'] = {
        'id': _cleanText(room['offering_id']?.toString()),
        'term': resolvedTerm,
        'courses': {
          'code': resolvedCode ?? 'Course',
          'title': resolvedCode ?? 'Course',
          'course_type': null,
        },
        'teachers': null,
      };
      return;
    }

    if (existingOffering == null) return;

    if (_cleanText(existingOffering['term']?.toString()) == null &&
        resolvedTerm != null) {
      existingOffering['term'] = resolvedTerm;
    }

    if (existingCourse == null && resolvedCode != null) {
      existingOffering['courses'] = {
        'code': resolvedCode,
        'title': resolvedCode,
        'course_type': null,
      };
    }
  }

  static bool _roomMatchesStudentSection(
    Map<String, dynamic> room,
    String rollNo,
  ) {
    final roomSection = _cleanText(room['section']?.toString());
    if (roomSection == null) return true;

    final rollRange = _getRollRange(roomSection);
    if (rollRange == null) return true;

    final rollSuffix = _extractRollSuffix(rollNo);
    if (rollSuffix == null) return false;
    return rollSuffix >= rollRange.min && rollSuffix <= rollRange.max;
  }

  static bool _roomMatchesStudentAudience(
    Map<String, dynamic> room,
    _StudentGeoContext context,
  ) {
    _applyRoomCourseFallback(room);
    if (!_isRoomCurrentlyOpen(room)) return false;

    final offering = room['course_offerings'] as Map<String, dynamic>?;
    final offeringId =
        _cleanText(offering?['id']?.toString()) ??
        _cleanText(room['offering_id']?.toString());
    final targetTerm = _roomTargetTerm(room);

    final matchesOffering =
        offeringId != null && context.enrolledOfferingIds.contains(offeringId);
    final courseCode = _roomCourseCode(room)?.toUpperCase();
    final matchesCourse =
        courseCode != null && context.enrolledCourseCodes.contains(courseCode);
    final matchesTerm = _termsMatch(targetTerm, context.term);

    if (!matchesOffering && !matchesCourse && !matchesTerm) return false;
    return _roomMatchesStudentSection(room, context.rollNo);
  }

  static Future<_StudentGeoContext?> _getStudentGeoContext(
    String studentUserId,
  ) async {
    final studentData = await SupabaseService.from(
      'students',
    ).select('term, section, roll_no').eq('user_id', studentUserId).single();

    final enrollmentData = await SupabaseService.from(
      'enrollments',
    ).select('offering_id').eq('student_user_id', studentUserId);

    final enrolledOfferingIds = (enrollmentData as List)
        .map(
          (row) => _cleanText(
            (row as Map<String, dynamic>)['offering_id']?.toString(),
          ),
        )
        .whereType<String>()
        .toSet();
    final enrolledCourseCodes = await _getEnrolledCourseCodes(
      enrolledOfferingIds,
    );

    return _StudentGeoContext(
      term: _normalizeTerm(studentData['term'] as String?),
      section: _cleanText(studentData['section'] as String?),
      rollNo: studentData['roll_no'] as String? ?? '',
      enrolledOfferingIds: enrolledOfferingIds,
      enrolledCourseCodes: enrolledCourseCodes,
    );
  }

  static Future<Set<String>> _getEnrolledCourseCodes(
    Set<String> offeringIds,
  ) async {
    if (offeringIds.isEmpty) return <String>{};

    try {
      final offeringRows = await SupabaseService.from(
        'course_offerings',
      ).select('id, course_id').inFilter('id', offeringIds.toList());
      final courseIds = (offeringRows as List)
          .map(
            (row) => _cleanText(
              (row as Map<String, dynamic>)['course_id']?.toString(),
            ),
          )
          .whereType<String>()
          .toSet()
          .toList();
      if (courseIds.isEmpty) return <String>{};

      final courseRows = await SupabaseService.from(
        'courses',
      ).select('id, code').inFilter('id', courseIds);
      return (courseRows as List)
          .map(
            (row) => _cleanText(
              (row as Map<String, dynamic>)['code']?.toString(),
            )?.toUpperCase(),
          )
          .whereType<String>()
          .toSet();
    } catch (e) {
      debugPrint('GeoService: enrolled course-code lookup failed: $e');
      return <String>{};
    }
  }

  static Future<void> _markAlreadySubmitted(
    List<Map<String, dynamic>> rooms, {
    required String studentUserId,
  }) async {
    if (rooms.isEmpty) return;

    final roomIds = rooms
        .map((room) => _cleanText(room['id']?.toString()))
        .whereType<String>()
        .toList();
    if (roomIds.isEmpty) return;

    final logs = await SupabaseService.from('geo_attendance_logs')
        .select('geo_room_id')
        .eq('student_user_id', studentUserId)
        .inFilter('geo_room_id', roomIds);

    final submittedIds = (logs as List)
        .map((log) => (log as Map<String, dynamic>)['geo_room_id'] as String?)
        .whereType<String>()
        .toSet();

    for (final room in rooms) {
      room['already_submitted'] = submittedIds.contains(room['id']);
    }
  }

  static Future<Map<String, dynamic>> _insertGeoAttendanceRoom(
    Map<String, dynamic> roomInsert,
  ) async {
    try {
      return await SupabaseService.from(
        'geo_attendance_rooms',
      ).insert(roomInsert).select('*').single();
    } catch (e) {
      final hasOptionalTargetColumns =
          roomInsert.containsKey('course_code') ||
          roomInsert.containsKey('target_term');
      final message = e.toString().toLowerCase();
      final missingOptionalColumn =
          message.contains('course_code') ||
          message.contains('target_term') ||
          (message.contains('schema cache') &&
              message.contains('geo_attendance_rooms'));

      if (!hasOptionalTargetColumns || !missingOptionalColumn) {
        rethrow;
      }

      final fallbackInsert = Map<String, dynamic>.from(roomInsert)
        ..remove('course_code')
        ..remove('target_term');
      final data = await SupabaseService.from(
        'geo_attendance_rooms',
      ).insert(fallbackInsert).select('*').single();
      data['course_code'] = roomInsert['course_code'];
      data['target_term'] = roomInsert['target_term'];
      return data;
    }
  }

  static Future<List<Map<String, dynamic>>>
  _resolveGeoAttendanceTargetStudents({
    required String offeringId,
    required String? term,
    String? section,
  }) async {
    final enrollmentRows = await SupabaseService.from(
      'enrollments',
    ).select('student_user_id').eq('offering_id', offeringId);

    final enrolledUserIds = (enrollmentRows as List)
        .map(
          (row) => _cleanText(
            (row as Map<String, dynamic>)['student_user_id'] as String?,
          ),
        )
        .whereType<String>()
        .toSet()
        .toList();

    if (enrolledUserIds.isNotEmpty) {
      final studentRows = await SupabaseService.from('students')
          .select('user_id, roll_no, section')
          .inFilter('user_id', enrolledUserIds);

      return List<Map<String, dynamic>>.from(studentRows as List)
          .where(
            (row) =>
                _cleanText(row['user_id'] as String?) != null &&
                _cleanText(row['roll_no'] as String?) != null,
          )
          .where((row) => _isTargetStudentForSection(row, section))
          .toList();
    }

    final normalizedTerm = _normalizeTerm(term);
    if (normalizedTerm == null) {
      return [];
    }

    var fallbackRows = await SupabaseService.from(
      'students',
    ).select('user_id, roll_no, section, term').eq('term', normalizedTerm);
    var fallbackList = List<Map<String, dynamic>>.from(fallbackRows as List);

    if (fallbackList.isEmpty) {
      fallbackRows = await SupabaseService.from(
        'students',
      ).select('user_id, roll_no, section, term');
      fallbackList = List<Map<String, dynamic>>.from(fallbackRows as List)
          .where((row) => _termsMatch(row['term'] as String?, normalizedTerm))
          .toList();
    }

    return fallbackList
        .where(
          (row) =>
              _cleanText(row['user_id'] as String?) != null &&
              _cleanText(row['roll_no'] as String?) != null,
        )
        .where((row) => _isTargetStudentForSection(row, section))
        .toList();
  }

  static Future<void> _seedDefaultGeoAttendanceAbsences({
    required String offeringId,
    required String sessionId,
    required String teacherUserId,
    required String? courseCode,
    required String? term,
    required String attendanceDate,
    String? section,
  }) async {
    final derivedTerm = _deriveTermFromCourseCode(courseCode);
    final resolvedTerm = derivedTerm ?? term;

    final targetStudents = await _resolveGeoAttendanceTargetStudents(
      offeringId: offeringId,
      term: resolvedTerm,
      section: section,
    );

    if (targetStudents.isEmpty) return;

    final studentUserIds = targetStudents
        .map((student) => _cleanText(student['user_id'] as String?))
        .whereType<String>()
        .toList();

    final existingEnrollments = await SupabaseService.from('enrollments')
        .select('id, student_user_id')
        .eq('offering_id', offeringId)
        .inFilter('student_user_id', studentUserIds);

    final enrollmentByStudentId = <String, String>{};
    for (final row in existingEnrollments as List) {
      final map = row as Map<String, dynamic>;
      final studentUserId = _cleanText(map['student_user_id'] as String?);
      final enrollmentId = _cleanText(map['id'] as String?);
      if (studentUserId != null && enrollmentId != null) {
        enrollmentByStudentId[studentUserId] = enrollmentId;
      }
    }

    // Only pre-existing active enrolments may receive attendance records.

    final attendanceRows = targetStudents
        .map((student) {
          final studentUserId = _cleanText(student['user_id'] as String?);
          final enrollmentId = studentUserId == null
              ? null
              : enrollmentByStudentId[studentUserId];
          if (enrollmentId == null) return null;
          return {
            'session_id': sessionId,
            'enrollment_id': enrollmentId,
            'status': 'ABSENT',
            'marked_by_teacher_user_id': teacherUserId,
            'remarks': 'No geo-attendance response received.',
          };
        })
        .whereType<Map<String, dynamic>>()
        .toList();

    if (attendanceRows.isNotEmpty) {
      await SupabaseService.from(
        'attendance_records',
      ).upsert(attendanceRows, onConflict: 'session_id,enrollment_id');
    }

    if (courseCode != null && courseCode.isNotEmpty) {
      final flatAttendanceRows = targetStudents
          .map((student) {
            final studentRoll = _cleanText(student['roll_no'] as String?);
            if (studentRoll == null) return null;
            return {
              'course_code': courseCode,
              'student_roll': studentRoll,
              'date': attendanceDate,
              'status': 'absent',
              'section_or_group': section,
            };
          })
          .whereType<Map<String, dynamic>>()
          .toList();

      if (flatAttendanceRows.isNotEmpty) {
        await SupabaseService.from('attendance').upsert(
          flatAttendanceRows,
          onConflict: 'course_code,student_roll,date',
        );
      }
    }
  }

  // ── Teacher: Open a geo-attendance room ──────────────────

  static Future<Map<String, dynamic>> openRoom({
    required String offeringId,
    required String teacherUserId,
    required DateTime startTime,
    required DateTime endTime,
    required int rangeMeters,
    required int durationMinutes,
    required int absenceGraceMinutes,
    String? roomNumber,
    String? section,
  }) async {
    try {
      final cleanedRoomNumber = roomNumber?.trim();
      if (cleanedRoomNumber == null || cleanedRoomNumber.isEmpty) {
        throw Exception('Please select a mapped room for geo-attendance.');
      }

      await _resolveRoomTarget(cleanedRoomNumber);

      final safeRangeMeters = rangeMeters.clamp(1, 500);
      final safeDurationMinutes = durationMinutes.clamp(1, 600);
      final safeAbsenceGraceMinutes = absenceGraceMinutes.clamp(
        1,
        safeDurationMinutes,
      );

      // Auto-close expired rooms first
      await _closeExpiredRooms();

      final offeringMeta = await SupabaseService.from('course_offerings')
          .select('term, course_id, courses(code, course_type)')
          .eq('id', offeringId)
          .single();
      final offeringTerm = offeringMeta['term'] as String?;

      final offeringCourse = offeringMeta['courses'] as Map<String, dynamic>?;
      String? courseCode = offeringCourse?['code'] as String?;
      String? fallbackCourseType;
      final courseId = offeringMeta['course_id'] as String?;
      if ((courseCode == null || courseCode.isEmpty) &&
          courseId != null &&
          courseId.isNotEmpty) {
        final courseData = await SupabaseService.from(
          'courses',
        ).select('code, course_type').eq('id', courseId).single();
        courseCode = courseData['code'] as String?;
        fallbackCourseType = courseData['course_type'] as String?;
      }
      final typeText =
          (offeringCourse?['course_type'] as String?)?.toLowerCase() ??
          fallbackCourseType?.toLowerCase() ??
          'theory';
      final isLabByCode = CourseUtils.isLabCourseCode(courseCode);
      final isLabCourse =
          isLabByCode == true || (isLabByCode == null && typeText == 'lab');
      final courseType = isLabCourse ? 'lab' : 'theory';
      final maxRooms = isLabCourse ? maxLabRooms : maxTheoryRooms;

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

      final targetTerm =
          _deriveTermFromCourseCode(courseCode) ?? _normalizeTerm(offeringTerm);

      String? sessionId;
      String? roomId;

      try {
        final attendanceDate = startTime.toUtc().toIso8601String().split(
          'T',
        )[0];

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
        final createdSessionId = sessionData['id'] as String;
        sessionId = createdSessionId;

        // Create the geo-attendance room
        final roomInsert = <String, dynamic>{
          'offering_id': offeringId,
          'session_id': createdSessionId,
          'teacher_user_id': teacherUserId,
          'date': attendanceDate,
          'start_time': startTime.toUtc().toIso8601String(),
          'end_time': endTime.toUtc().toIso8601String(),
          'is_active': true,
        };
        roomInsert['room_number'] = cleanedRoomNumber;
        if (section != null && section.isNotEmpty) {
          roomInsert['section'] = section;
        }
        if (_cleanText(courseCode) != null) {
          roomInsert['course_code'] = courseCode!.trim().toUpperCase();
        }
        if (targetTerm != null) {
          roomInsert['target_term'] = targetTerm;
        }
        roomInsert['range_meters'] = safeRangeMeters;
        roomInsert['duration_minutes'] = safeDurationMinutes;
        roomInsert['absence_grace_minutes'] = safeAbsenceGraceMinutes;

        final data = await _insertGeoAttendanceRoom(roomInsert);
        _applyRoomCourseFallback(
          data,
          courseCode: courseCode,
          term: targetTerm,
        );

        roomId = data['id'] as String?;

        if (roomId != null) {
          final code = await GeoAttendanceCodeService.generateCode(roomId);
          data['verification_code'] = code;
        }

        await _seedDefaultGeoAttendanceAbsences(
          offeringId: offeringId,
          sessionId: createdSessionId,
          teacherUserId: teacherUserId,
          courseCode: courseCode,
          term: offeringTerm,
          attendanceDate: attendanceDate,
          section: section,
        );

        return data;
      } catch (e) {
        if (roomId != null && roomId.isNotEmpty) {
          await SupabaseService.from(
            'geo_attendance_rooms',
          ).delete().eq('id', roomId);
        }
        if (sessionId != null && sessionId.isNotEmpty) {
          await SupabaseService.from(
            'class_sessions',
          ).delete().eq('id', sessionId);
        }
        rethrow;
      }
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
    await GeoAttendanceCodeService.deleteCode(roomId);
  }

  // ── Teacher: Get active rooms ────────────────────────────

  static Future<List<Map<String, dynamic>>> getActiveRooms({
    required String teacherUserId,
  }) async {
    try {
      // Close expired rooms first (use UTC for correct comparison)
      await _closeExpiredRooms();

      final data = await SupabaseService.from('geo_attendance_rooms')
          .select('*')
          .eq('teacher_user_id', teacherUserId)
          .eq('is_active', true)
          .order('start_time', ascending: false);

      final rooms = List<Map<String, dynamic>>.from(data as List);
      await _attachGeoRoomDetails(rooms, includeCodes: true);
      return rooms;
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
          .select('*')
          .eq('teacher_user_id', teacherUserId)
          .eq('is_active', false)
          .order('created_at', ascending: false)
          .limit(limit);

      final rooms = List<Map<String, dynamic>>.from(data as List);
      await _attachGeoRoomDetails(rooms);
      return rooms;
    } catch (e) {
      debugPrint('Error fetching recent rooms: $e');
      return [];
    }
  }

  static Future<void> _attachGeoRoomDetails(
    List<Map<String, dynamic>> rooms, {
    bool includeCodes = false,
  }) async {
    if (rooms.isEmpty) return;

    if (includeCodes) {
      final roomIds = rooms
          .map((room) => _cleanText(room['id']?.toString()))
          .whereType<String>()
          .toList();
      if (roomIds.isNotEmpty) {
        try {
          final codeRows = await SupabaseService.from(
            'geo_attendance_codes',
          ).select('room_id, code').inFilter('room_id', roomIds);
          final codeByRoomId = <String, Map<String, dynamic>>{};
          for (final row in codeRows as List) {
            final map = Map<String, dynamic>.from(row as Map);
            final roomId = _cleanText(map['room_id']?.toString());
            if (roomId != null) {
              codeByRoomId[roomId] = {'code': map['code']};
            }
          }
          for (final room in rooms) {
            final roomId = _cleanText(room['id']?.toString());
            room['geo_attendance_codes'] = roomId == null
                ? null
                : codeByRoomId[roomId];
          }
        } catch (e) {
          debugPrint('GeoService: code hydration failed: $e');
        }
      }
    }

    final offeringIds = rooms
        .map((room) => _cleanText(room['offering_id']?.toString()))
        .whereType<String>()
        .toSet()
        .toList();
    if (offeringIds.isEmpty) {
      for (final room in rooms) {
        _applyRoomCourseFallback(room);
      }
      return;
    }

    List<Map<String, dynamic>> offerings;
    try {
      final offeringRows = await SupabaseService.from('course_offerings')
          .select('id, term, course_id, teacher_user_id')
          .inFilter('id', offeringIds);
      offerings = List<Map<String, dynamic>>.from(offeringRows as List);
    } catch (e) {
      debugPrint('GeoService: offering hydration failed: $e');
      for (final room in rooms) {
        _applyRoomCourseFallback(room);
      }
      return;
    }

    final courseIds = offerings
        .map((offering) => _cleanText(offering['course_id']?.toString()))
        .whereType<String>()
        .toSet()
        .toList();
    final teacherIds = offerings
        .map((offering) => _cleanText(offering['teacher_user_id']?.toString()))
        .whereType<String>()
        .toSet()
        .toList();

    final coursesById = <String, Map<String, dynamic>>{};
    if (courseIds.isNotEmpty) {
      try {
        final courseRows = await SupabaseService.from(
          'courses',
        ).select('id, code, title, course_type').inFilter('id', courseIds);
        for (final row in courseRows as List) {
          final course = Map<String, dynamic>.from(row as Map);
          final id = _cleanText(course['id']?.toString());
          if (id != null) {
            coursesById[id] = course;
          }
        }
      } catch (e) {
        debugPrint('GeoService: course hydration failed: $e');
      }
    }

    final teachersById = <String, Map<String, dynamic>>{};
    if (teacherIds.isNotEmpty) {
      try {
        final teacherRows = await SupabaseService.from(
          'teachers',
        ).select('user_id, full_name').inFilter('user_id', teacherIds);
        for (final row in teacherRows as List) {
          final teacher = Map<String, dynamic>.from(row as Map);
          final id = _cleanText(teacher['user_id']?.toString());
          if (id != null) {
            teachersById[id] = {'full_name': teacher['full_name']};
          }
        }
      } catch (e) {
        debugPrint('GeoService: teacher hydration failed: $e');
      }
    }

    final offeringsById = <String, Map<String, dynamic>>{};
    for (final offering in offerings) {
      final id = _cleanText(offering['id']?.toString());
      if (id == null) continue;

      final courseId = _cleanText(offering['course_id']?.toString());
      final teacherId = _cleanText(offering['teacher_user_id']?.toString());
      offeringsById[id] = {
        'id': id,
        'term': offering['term'],
        'courses': courseId == null ? null : coursesById[courseId],
        'teachers': teacherId == null ? null : teachersById[teacherId],
      };
    }

    for (final room in rooms) {
      final offeringId = _cleanText(room['offering_id']?.toString());
      room['course_offerings'] = offeringId == null
          ? null
          : offeringsById[offeringId];
      _applyRoomCourseFallback(room);
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
      final sessionId = roomData['session_id'] as String?;

      final data = await SupabaseService.from('geo_attendance_logs')
          .select('''
            *,
            students!geo_attendance_logs_student_fkey ( roll_no, full_name )
          ''')
          .eq('geo_room_id', roomId)
          .order('submitted_at', ascending: true);

      final logs = List<Map<String, dynamic>>.from(data as List);

      final attendanceRows = <Map<String, dynamic>>[];
      if (sessionId != null && sessionId.isNotEmpty) {
        final attendanceData = await SupabaseService.from('attendance_records')
            .select('id, enrollment_id, status, remarks, marked_at')
            .eq('session_id', sessionId);
        attendanceRows.addAll(
          List<Map<String, dynamic>>.from(attendanceData as List),
        );
      }

      final enrollmentData = await SupabaseService.from('enrollments')
          .select('id, student_user_id')
          .eq('offering_id', roomData['offering_id'] as String);

      final enrollmentByStudentId = <String, String>{};
      final studentIdByEnrollmentId = <String, String>{};
      for (final row in enrollmentData as List) {
        final map = row as Map<String, dynamic>;
        final studentId = map['student_user_id'] as String?;
        final enrollmentId = map['id'] as String?;
        if (studentId != null && enrollmentId != null) {
          enrollmentByStudentId[studentId] = enrollmentId;
          studentIdByEnrollmentId[enrollmentId] = studentId;
        }
      }

      final attendanceByEnrollmentId = <String, Map<String, dynamic>>{};
      for (final row in attendanceRows) {
        final enrollmentId = row['enrollment_id'] as String?;
        if (enrollmentId != null) {
          attendanceByEnrollmentId[enrollmentId] = row;
        }
      }

      final studentIds = <String>{
        ...logs
            .map((log) => log['student_user_id'] as String? ?? '')
            .where((id) => id.isNotEmpty),
        ...attendanceRows
            .map((row) => row['enrollment_id'] as String?)
            .whereType<String>()
            .map((enrollmentId) => studentIdByEnrollmentId[enrollmentId])
            .whereType<String>(),
      }.toList();

      final studentsById = <String, Map<String, dynamic>>{};
      if (studentIds.isNotEmpty) {
        final studentRows = await SupabaseService.from(
          'students',
        ).select('user_id, roll_no, full_name').inFilter('user_id', studentIds);

        for (final row in studentRows as List) {
          final map = row as Map<String, dynamic>;
          final studentId = map['user_id'] as String?;
          if (studentId != null) {
            studentsById[studentId] = {
              'roll_no': map['roll_no'],
              'full_name': map['full_name'],
            };
          }
        }
      }

      final loggedStudentIds = <String>{};
      for (final log in logs) {
        final studentId = log['student_user_id'] as String?;
        if (studentId != null) {
          loggedStudentIds.add(studentId);
          log['students'] ??= studentsById[studentId];
        }
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

      for (final attendanceRow in attendanceRows) {
        final enrollmentId = attendanceRow['enrollment_id'] as String?;
        final studentId = enrollmentId == null
            ? null
            : studentIdByEnrollmentId[enrollmentId];
        if (studentId == null || loggedStudentIds.contains(studentId)) {
          continue;
        }

        logs.add({
          'id': 'attendance_${attendanceRow['id']}',
          'geo_room_id': roomId,
          'student_user_id': studentId,
          'distance_meters': null,
          'status': attendanceRow['status'] ?? 'ABSENT',
          'attendance_status': attendanceRow['status'] ?? 'ABSENT',
          'attendance_record_id': attendanceRow['id'],
          'submitted_at': attendanceRow['marked_at'],
          'remarks': attendanceRow['remarks'],
          'students': studentsById[studentId],
          'is_attendance_record_only': true,
        });
      }

      logs.sort((a, b) {
        final aStudent = a['students'] as Map<String, dynamic>?;
        final bStudent = b['students'] as Map<String, dynamic>?;
        final aRoll = aStudent?['roll_no']?.toString() ?? '';
        final bRoll = bStudent?['roll_no']?.toString() ?? '';
        return aRoll.compareTo(bRoll);
      });

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
      final context = await _getStudentGeoContext(studentUserId);
      if (context == null) return [];

      // Close expired rooms (use UTC for correct comparison)
      await _closeExpiredRooms();

      // Get active rooms first, then hydrate offering/course details in
      // separate queries. This keeps CSE 32xx -> 3-2 matching working even
      // when a nested PostgREST relation fails or RLS hides the join.
      final rooms = await SupabaseService.from(
        'geo_attendance_rooms',
      ).select('*').eq('is_active', true).order('start_time', ascending: true);

      debugPrint('GeoService: fetched ${(rooms as List).length} active rooms');

      final roomList = List<Map<String, dynamic>>.from(rooms);
      await _attachGeoRoomDetails(roomList);

      // Filter rooms whose offering matches the student's enrolled courses,
      // offering term, or derived term from the course code.
      roomList.removeWhere(
        (room) => !_roomMatchesStudentAudience(room, context),
      );

      debugPrint(
        'GeoService: ${roomList.length} rooms after enrollment/term filtering',
      );

      await _markAlreadySubmitted(roomList, studentUserId: studentUserId);

      return roomList;
    } catch (e) {
      debugPrint('Error fetching open rooms: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getOpenRoomForStudentById({
    required String studentUserId,
    required String roomId,
    String? fallbackCourseCode,
    String? fallbackSection,
    String? fallbackTerm,
  }) async {
    try {
      final context = await _getStudentGeoContext(studentUserId);
      if (context == null) return null;

      await _closeExpiredRooms();

      final data = await SupabaseService.from(
        'geo_attendance_rooms',
      ).select('*').eq('id', roomId).maybeSingle();
      if (data == null) return null;

      final room = Map<String, dynamic>.from(data);
      await _attachGeoRoomDetails([room]);
      _applyRoomCourseFallback(
        room,
        courseCode: fallbackCourseCode,
        term: fallbackTerm,
        section: fallbackSection,
      );

      if (!_roomMatchesStudentAudience(room, context)) return null;
      await _markAlreadySubmitted([room], studentUserId: studentUserId);
      return room;
    } catch (e) {
      debugPrint('Error fetching focused geo room: $e');
      return null;
    }
  }

  // ── Student: Submit geo-attendance ───────────────────────

  static Future<Map<String, dynamic>> submitAttendance({
    required String geoRoomId,
    required String studentUserId,
    required double latitude,
    required double longitude,
    String? verificationCode,
  }) async {
    await BiometricAuthService.requireBiometricForAttendance();
    final result = await AuthenticatedApi.post('/api/student/geo-attendance', {
      'geo_room_id': geoRoomId,
      'latitude': latitude,
      'longitude': longitude,
      'verification_code': verificationCode,
    });
    if (result['success'] != true)
      throw Exception(result['message'] ?? 'Attendance submission failed');
    return result;
  }

  static Future<GeoAttendanceLocationCheck> checkAttendanceLocation({
    required String geoRoomId,
    required double latitude,
    required double longitude,
  }) async {
    final roomData = await SupabaseService.from(
      'geo_attendance_rooms',
    ).select('room_number, range_meters').eq('id', geoRoomId).single();

    return _buildLocationCheck(
      roomNumber: roomData['room_number'] as String?,
      rangeMeters: (roomData['range_meters'] as num?)?.toDouble(),
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
    required double? rangeMeters,
    required double latitude,
    required double longitude,
  }) async {
    final target = await _resolveRoomTarget(
      roomNumber,
      maxDistanceMeters: rangeMeters,
    );
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
    String? roomNumber, {
    double? maxDistanceMeters,
  }) async {
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
          maxDistance: _normalizeRangeMeters(maxDistanceMeters),
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
    final row = await SupabaseService.from('enrollments')
        .select('id')
        .eq('offering_id', offeringId)
        .eq('student_user_id', studentUserId)
        .eq('enrollment_status', 'ENROLLED')
        .maybeSingle();
    if (row == null) throw StateError('Active enrolment required');
    return row['id'] as String;
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

  static double _normalizeRangeMeters(double? value) {
    if (value == null || !value.isFinite || value <= 0) {
      return defaultRoomMaxDistanceMeters;
    }
    return value;
  }

  static Future<void> _closeExpiredRooms() async {
    try {
      final expiredData = await SupabaseService.from('geo_attendance_rooms')
          .select('id')
          .eq('is_active', true)
          .lt('end_time', DateTime.now().toUtc().toIso8601String());
      final expiredList = List<Map<String, dynamic>>.from(expiredData as List);
      if (expiredList.isNotEmpty) {
        final expiredIds = expiredList.map((r) => r['id'] as String).toList();
        await SupabaseService.from(
          'geo_attendance_rooms',
        ).update({'is_active': false}).inFilter('id', expiredIds);
        await GeoAttendanceCodeService.deleteCodes(expiredIds);
      }
    } catch (e) {
      debugPrint('Error auto-closing expired rooms: $e');
    }
  }
}

class _StudentGeoContext {
  final String? term;
  final String? section;
  final String rollNo;
  final Set<String> enrolledOfferingIds;
  final Set<String> enrolledCourseCodes;

  const _StudentGeoContext({
    required this.term,
    required this.section,
    required this.rollNo,
    required this.enrolledOfferingIds,
    required this.enrolledCourseCodes,
  });
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
    this.maxDistance = GeoAttendanceService.defaultRoomMaxDistanceMeters,
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
