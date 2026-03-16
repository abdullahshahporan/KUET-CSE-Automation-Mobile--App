import 'package:flutter/foundation.dart';
import '../../services/session_service.dart';
import '../../services/supabase_core.dart';
import '../../services/notification_service.dart';
import '../../utils/course_utils.dart';
import '../../Teacher/Room_info/room_booking_model.dart';
import '../../Teacher/Room_info/room_model.dart';
import '../models/cr_room_request_model.dart';

/// Service for CR (Class Representative) room request operations.
class CRRoomRequestService {
  CRRoomRequestService._();

  // ── Check if current student is a CR ──────────────────────

  static Future<bool> checkIsCR() async {
    final userId = SessionService.currentUserId;
    if (userId == null) return false;

    try {
      final data = await SupabaseCore.from('students')
          .select('is_cr')
          .eq('user_id', userId)
          .maybeSingle();
      return (data?['is_cr'] as bool?) ?? false;
    } catch (e) {
      debugPrint('Error checking CR status: $e');
      return false;
    }
  }

  // ── Get current student's room requests ───────────────────

  static Future<List<CRRoomRequest>> getMyRequests() async {
    final userId = SessionService.currentUserId;
    if (userId == null) return [];

    try {
      final data = await SupabaseCore.from('cr_room_requests')
          .select('''
            id, student_user_id, course_code, teacher_user_id,
            room_number, day_of_week, start_time, end_time,
            term, session, section, reason, status,
            admin_remarks, created_at, request_date,
            teachers!cr_room_requests_teacher_user_id_fkey ( full_name )
          ''')
          .eq('student_user_id', userId)
          .order('created_at', ascending: false);

      return (data as List)
          .map((e) => CRRoomRequest.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching CR room requests: $e');
      return [];
    }
  }

  // ── Submit a new room request ─────────────────────────────

  static Future<({bool success, String message})> submitRequest({
    required String courseCode,
    required String teacherUserId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    required String term,
    required String session,
    String? section,
    String? reason,
    String? roomNumber,
    required String requestDate,
  }) async {
    final userId = SessionService.currentUserId;
    if (userId == null) {
      return (success: false, message: 'Not logged in.');
    }

    // Verify CR status
    final isCR = await checkIsCR();
    if (!isCR) {
      return (success: false, message: 'You are not designated as a CR.');
    }

    if (roomNumber == null) {
      return (success: false, message: 'Room is required.');
    }

    try {
      // ── FCFS conflict check (date-based) ──
      final conflict = await _checkSlotConflicts(
        roomNumber: roomNumber,
        dayOfWeek: dayOfWeek,
        startTime: startTime,
        endTime: endTime,
        requestDate: requestDate,
      );
      if (conflict != null) {
        return (success: false, message: conflict);
      }

      // No conflict — auto-approve (FCFS: first request wins)
      await SupabaseCore.from('cr_room_requests').insert({
        'student_user_id': userId,
        'course_code': courseCode,
        'teacher_user_id': teacherUserId,
        'day_of_week': dayOfWeek,
        'start_time': startTime,
        'end_time': endTime,
        'term': term,
        'session': session,
        'section': section,
        'reason': reason,
        'status': 'approved',
        'room_number': roomNumber,
        'request_date': requestDate,
      });

      // Sync to routine_slots so Schedule & TV Display show this CR booking
      await _syncToRoutineSlot(
        courseCode: courseCode,
        teacherUserId: teacherUserId,
        roomNumber: roomNumber,
        dayOfWeek: dayOfWeek,
        startTime: startTime,
        endTime: endTime,
        term: term,
        session: session,
        section: section,
        requestDate: requestDate,
      );

      // Fire notification to all students in the section
      const dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
      await NotificationService.createNotification(
        type: 'room_allocated',
        title: 'Room $roomNumber Booked — $courseCode',
        body: 'CR booked Room $roomNumber for $courseCode on '
            '${dayNames.elementAtOrNull(dayOfWeek) ?? 'Day $dayOfWeek'} '
            '($startTime–$endTime).',
        targetType: section != null ? 'SECTION' : 'YEAR_TERM',
        targetValue: section ?? term,
        targetYearTerm: section != null ? term : null,
        metadata: {
          'course_code': courseCode,
          'room_number': roomNumber,
          'start_time': startTime,
          'end_time': endTime,
          'request_date': requestDate,
        },
      );

      return (success: true, message: 'Room booked successfully! (Auto-approved)');
    } catch (e) {
      debugPrint('Error submitting CR room request: $e');
      String msg = e.toString();
      if (msg.contains('row-level security') || msg.contains('policy')) {
        msg = 'Permission denied. Contact admin.';
      } else if (msg.length > 120) {
        msg = msg.substring(0, 120);
      }
      return (success: false, message: msg);
    }
  }

  // ── Get courses for student's current term ────────────────

  static Future<List<Map<String, dynamic>>> getCoursesForTerm() async {
    final userId = SessionService.currentUserId;
    if (userId == null) return [];

    try {
      // 1. Get student's current term (e.g. "3-2") and section
      final student = await SupabaseCore.from('students')
          .select('term, session, section')
          .eq('user_id', userId)
          .maybeSingle();

      if (student == null) return [];

      final termStr = student['term'] as String;
      final studentSession = student['session'] as String?;
      final studentSection = student['section'] as String?;
      final parsed = CourseUtils.parseTerm(termStr);
      final year = parsed.year;
      final term = parsed.term;

      // 2. Fetch all courses and filter by code prefix (same as CourseInfoService)
      final coursesData = await SupabaseCore.from('courses')
          .select('id, code, title, course_type');

      final allCourses = (coursesData as List)
          .map((c) => c as Map<String, dynamic>)
          .where((c) =>
              CourseUtils.codeMatchesTerm(c['code'] as String?, year, term))
          .toList();

      if (allCourses.isEmpty) return [];

      // 3. Fetch active offerings for matched courses
      final courseIds = allCourses.map((c) => c['id'].toString()).toList();

      final offeringsData = await SupabaseCore.from('course_offerings')
          .select('''
            id, course_id, term, session, batch,
            teachers ( user_id, full_name )
          ''')
          .inFilter('course_id', courseIds)
          .eq('is_active', true);

      // 4. Build result with course info embedded
      final courseById = <String, Map<String, dynamic>>{};
      for (final c in allCourses) {
        courseById[c['id'].toString()] = c;
      }

      final results = <Map<String, dynamic>>[];
      for (final o in (offeringsData as List)) {
        final offering = o as Map<String, dynamic>;
        final courseId = offering['course_id'].toString();
        final course = courseById[courseId];
        if (course != null) {
          results.add({
            ...offering,
            'courses': course,
            'section': studentSection,
            if (offering['session'] == null && studentSession != null)
              'session': studentSession,
          });
        }
      }

      return results;
    } catch (e) {
      debugPrint('Error fetching courses: $e');
      return [];
    }
  }

  // ── Get available rooms ───────────────────────────────────

  static Future<List<String>> getAvailableRooms() async {
    try {
      final data = await SupabaseCore.from('rooms')
          .select('room_number')
          .order('room_number');

      return (data as List)
          .map((e) => e['room_number'] as String)
          .toList();
    } catch (e) {
      debugPrint('Error fetching rooms: $e');
      return [];
    }
  }

  // ── Delete a request and clean up synced routine_slot ───

  static Future<bool> deleteRequest(String requestId) async {
    try {
      // Fetch request details before deleting (to clean up routine_slot)
      final reqData = await SupabaseCore.from('cr_room_requests')
          .select('room_number, day_of_week, start_time, end_time, request_date, status')
          .eq('id', requestId)
          .maybeSingle();

      await SupabaseCore.from('cr_room_requests')
          .delete()
          .eq('id', requestId);

      // Clean up synced routine_slot if the request was approved
      if (reqData != null &&
          reqData['status'] == 'approved' &&
          reqData['request_date'] != null &&
          reqData['room_number'] != null) {
        try {
          await SupabaseCore.from('routine_slots')
              .delete()
              .eq('room_number', reqData['room_number'])
              .eq('day_of_week', reqData['day_of_week'])
              .eq('start_time', reqData['start_time'])
              .eq('end_time', reqData['end_time'])
              .eq('valid_from', reqData['request_date'])
              .eq('valid_until', reqData['request_date']);
        } catch (e) {
          debugPrint('CR delete: failed to clean up routine_slot: $e');
        }
      }
      return true;
    } catch (e) {
      debugPrint('Error deleting CR room request: $e');
      return false;
    }
  }

  // ── Sync CR booking to routine_slots for Schedule & TV Display ──

  static Future<void> _syncToRoutineSlot({
    required String courseCode,
    required String teacherUserId,
    required String roomNumber,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    required String term,
    required String session,
    String? section,
    required String requestDate,
  }) async {
    try {
      // Step 1: Find the course by code
      final courseRows = await SupabaseCore.from('courses')
          .select('id')
          .eq('code', courseCode)
          .limit(1);

      if ((courseRows as List).isEmpty) {
        debugPrint('CR sync: course not found for code: $courseCode');
        return;
      }
      final courseId = courseRows[0]['id'] as String;

      // Step 2: Find an active offering for this course + teacher
      final offerings = await SupabaseCore.from('course_offerings')
          .select('id')
          .eq('course_id', courseId)
          .eq('teacher_user_id', teacherUserId)
          .eq('term', term)
          .eq('session', session)
          .eq('is_active', true)
          .limit(1);

      String? offeringId;
      if ((offerings as List).isNotEmpty) {
        offeringId = offerings[0]['id'] as String;
      } else {
        // Create a new offering
        final newOffering = await SupabaseCore.from('course_offerings')
            .insert({
              'course_id': courseId,
              'teacher_user_id': teacherUserId,
              'term': term,
              'session': session,
              'section': section,
              'is_active': true,
            })
            .select('id')
            .single();
        offeringId = newOffering['id'] as String?;
      }

      if (offeringId == null) {
        debugPrint('CR sync: could not resolve offering_id');
        return;
      }

      // Step 3: Check if a routine_slot already exists for this exact slot
      final existing = await SupabaseCore.from('routine_slots')
          .select('id')
          .eq('offering_id', offeringId)
          .eq('day_of_week', dayOfWeek)
          .eq('start_time', startTime)
          .eq('end_time', endTime)
          .eq('valid_from', requestDate)
          .eq('valid_until', requestDate)
          .limit(1);

      if ((existing as List).isNotEmpty) {
        // Update room on existing slot
        await SupabaseCore.from('routine_slots')
            .update({'room_number': roomNumber, 'section': section})
            .eq('id', existing[0]['id']);
      } else {
        // Insert new date-scoped routine_slot
        await SupabaseCore.from('routine_slots').insert({
          'offering_id': offeringId,
          'room_number': roomNumber,
          'day_of_week': dayOfWeek,
          'start_time': startTime,
          'end_time': endTime,
          'section': section,
          'valid_from': requestDate,
          'valid_until': requestDate,
        });
      }
    } catch (e) {
      debugPrint('CR sync to routine_slots failed: $e');
      // Non-fatal: the CR booking itself succeeded
    }
  }

  // ── Get unique courses for student's term ─────────────────

  static Future<List<Map<String, dynamic>>> getUniqueCourses() async {
    final offerings = await getCoursesForTerm();
    final seen = <String>{};
    final unique = <Map<String, dynamic>>[];
    for (final o in offerings) {
      final course = o['courses'] as Map<String, dynamic>;
      final code = course['code'] as String? ?? '';
      if (seen.add(code)) {
        unique.add(course);
      }
    }
    return unique;
  }

  // ── Get teachers offering a specific course ───────────────

  static Future<List<Map<String, dynamic>>> getTeachersForCourse(
      String courseCode) async {
    final offerings = await getCoursesForTerm();
    final teachers = <Map<String, dynamic>>[];
    final seen = <String>{};
    for (final o in offerings) {
      final course = o['courses'] as Map<String, dynamic>;
      if (course['code'] == courseCode) {
        final teacher = o['teachers'] as Map<String, dynamic>;
        final uid = teacher['user_id'] as String? ?? '';
        if (seen.add(uid)) {
          teachers.add({
            ...teacher,
            'offering_id': o['id'],
            'section': o['section'],
          });
        }
      }
    }
    return teachers;
  }

  // ── Get available (free) period slots for a room on a specific date ─

  static Future<List<PeriodStatus>> getAvailableSlotsForRoom({
    required String roomNumber,
    required int dayOfWeek,
    required String requestDate,
  }) async {
    try {
      // 1. Fetch routine slots for the room on this day_of_week
      final routineData = await SupabaseCore.from('routine_slots')
          .select('''
            id, room_number, day_of_week, start_time, end_time, section,
            valid_from, valid_until,
            course_offerings!inner (
              id, is_active,
              courses ( code, title, course_type ),
              teachers ( full_name )
            )
          ''')
          .eq('room_number', roomNumber)
          .eq('day_of_week', dayOfWeek)
          .eq('course_offerings.is_active', true);

      // Filter routine slots by date validity
      final reqDate = DateTime.tryParse(requestDate);
      final validRoutineData = (routineData as List).where((e) {
        final vFrom = e['valid_from'] as String?;
        final vUntil = e['valid_until'] as String?;
        if (vFrom == null && vUntil == null) return true;
        if (reqDate == null) return true;
        final from = vFrom != null ? DateTime.tryParse(vFrom) : null;
        final until = vUntil != null ? DateTime.tryParse(vUntil) : null;
        return (from == null || !reqDate.isBefore(from)) &&
               (until == null || !reqDate.isAfter(until));
      }).toList();

      final routineSlots = validRoutineData
          .map((e) => RoomSlot.fromMap(e as Map<String, dynamic>))
          .toList();

      // 2. Fetch approved bookings for the room on this specific date
      final bookingData = await SupabaseCore.from('room_booking_requests')
          .select('''
            id, teacher_user_id, offering_id, room_number,
            day_of_week, start_period, end_period,
            start_time, end_time, section, purpose, status, requested_at,
            booking_date,
            course_offerings ( courses ( code, title ) ),
            teachers!rbr_teacher_fkey ( full_name )
          ''')
          .eq('room_number', roomNumber)
          .eq('booking_date', requestDate)
          .eq('status', 'approved');

      final bookings = (bookingData as List)
          .map((e) => RoomBookingRequest.fromMap(e as Map<String, dynamic>))
          .toList();

      // 3. Also check cr_room_requests on this date
      final crData = await SupabaseCore.from('cr_room_requests')
          .select('id, start_time, end_time, course_code')
          .eq('room_number', roomNumber)
          .eq('request_date', requestDate)
          .eq('status', 'approved');

      // 4. Compute period statuses
      final daySlots = routineSlots;

      return Period.all.map((period) {
        // Check routine (permanent schedule auto-synced)
        for (final slot in daySlots) {
          final sStart = _fmt(slot.startTime);
          final sEnd = _fmt(slot.endTime);
          if (sStart.compareTo(period.end) < 0 &&
              sEnd.compareTo(period.start) > 0) {
            return PeriodStatus(
              period: period,
              state: PeriodState.occupied,
              courseCode: slot.courseCode,
              teacherName: slot.teacherName,
            );
          }
        }
        // Check teacher bookings for this date
        for (final booking in bookings) {
          if (booking.coversPeriod(period)) {
            return PeriodStatus(
              period: period,
              state: PeriodState.booked,
              courseCode: booking.courseCode,
              teacherName: booking.teacherName,
              bookingStatus: booking.status,
            );
          }
        }
        // Check CR bookings for this date
        for (final row in (crData as List)) {
          final cStart = _fmt(row['start_time'] as String? ?? '');
          final cEnd = _fmt(row['end_time'] as String? ?? '');
          if (cStart.compareTo(period.end) < 0 &&
              cEnd.compareTo(period.start) > 0) {
            return PeriodStatus(
              period: period,
              state: PeriodState.booked,
              courseCode: row['course_code'] as String?,
            );
          }
        }
        return PeriodStatus(period: period, state: PeriodState.free);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching available slots: $e');
      return [];
    }
  }

  // ── FCFS: Check for conflicting bookings ──────────────────
  /// Returns an error message if a conflict exists, or null if free.
  /// Checks: routine_slots (valid on date), room_booking_requests (by date),
  /// and cr_room_requests (by date).
  static Future<String?> _checkSlotConflicts({
    required String roomNumber,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    required String requestDate,
  }) async {
    final reqStart = _fmt(startTime);
    final reqEnd = _fmt(endTime);

    try {
      // 1. Check routine_slots (permanent class schedule valid on this date)
      final routineData = await SupabaseCore.from('routine_slots')
          .select('''
            id, room_number, day_of_week, start_time, end_time,
            valid_from, valid_until,
            course_offerings!inner (
              is_active,
              courses ( code, title ),
              teachers ( full_name )
            )
          ''')
          .eq('room_number', roomNumber)
          .eq('day_of_week', dayOfWeek)
          .eq('course_offerings.is_active', true);

      final reqDate = DateTime.tryParse(requestDate);
      for (final row in (routineData as List)) {
        // Check date validity of the routine slot
        final vFrom = row['valid_from'] as String?;
        final vUntil = row['valid_until'] as String?;
        if (reqDate != null) {
          final from = vFrom != null ? DateTime.tryParse(vFrom) : null;
          final until = vUntil != null ? DateTime.tryParse(vUntil) : null;
          if (from != null && reqDate.isBefore(from)) continue;
          if (until != null && reqDate.isAfter(until)) continue;
        }
        final sStart = _fmt(row['start_time'] as String? ?? '');
        final sEnd = _fmt(row['end_time'] as String? ?? '');
        if (sStart.compareTo(reqEnd) < 0 && sEnd.compareTo(reqStart) > 0) {
          final offering = row['course_offerings'] as Map<String, dynamic>? ?? {};
          final course = offering['courses'] as Map<String, dynamic>? ?? {};
          final code = course['code'] ?? 'A class';
          return 'Slot conflict! $code is permanently scheduled in this room '
              'during that time.';
        }
      }

      // 2. Check room_booking_requests (teacher bookings on this date)
      final bookingData = await SupabaseCore.from('room_booking_requests')
          .select('''
            id, start_time, end_time, requested_at,
            course_offerings ( courses ( code, title ) ),
            teachers!rbr_teacher_fkey ( full_name )
          ''')
          .eq('room_number', roomNumber)
          .eq('booking_date', requestDate)
          .eq('status', 'approved')
          .order('requested_at', ascending: true);

      for (final row in (bookingData as List)) {
        final bStart = _fmt(row['start_time'] as String? ?? '');
        final bEnd = _fmt(row['end_time'] as String? ?? '');
        if (bStart.compareTo(reqEnd) < 0 && bEnd.compareTo(reqStart) > 0) {
          final offering = row['course_offerings'] as Map<String, dynamic>? ?? {};
          final course = offering['courses'] as Map<String, dynamic>? ?? {};
          final teacher = row['teachers'] as Map<String, dynamic>? ?? {};
          final code = course['code'] ?? 'A course';
          final name = teacher['full_name'] ?? 'a teacher';
          return 'Slot already booked! $code was booked by $name '
              '(requested first). FCFS — only one booking per slot.';
        }
      }

      // 3. Check cr_room_requests (other CR bookings on this date)
      final crData = await SupabaseCore.from('cr_room_requests')
          .select('''
            id, course_code, start_time, end_time, created_at,
            teachers!cr_room_requests_teacher_user_id_fkey ( full_name )
          ''')
          .eq('room_number', roomNumber)
          .eq('request_date', requestDate)
          .eq('status', 'approved')
          .order('created_at', ascending: true);

      for (final row in (crData as List)) {
        final cStart = _fmt(row['start_time'] as String? ?? '');
        final cEnd = _fmt(row['end_time'] as String? ?? '');
        if (cStart.compareTo(reqEnd) < 0 && cEnd.compareTo(reqStart) > 0) {
          final code = row['course_code'] ?? 'A course';
          return 'Slot already taken! $code was booked earlier (FCFS).';
        }
      }

      return null; // No conflicts
    } catch (e) {
      debugPrint('Error checking slot conflicts: $e');
      return 'Failed to verify slot availability. Please try again.';
    }
  }

  static String _fmt(String t) => t.length >= 5 ? t.substring(0, 5) : t;
}
