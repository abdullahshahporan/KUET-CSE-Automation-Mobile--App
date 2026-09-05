import '../../services/authenticated_api.dart';
import 'package:flutter/foundation.dart';
import '../../services/session_service.dart';
import '../../services/supabase_core.dart';
import '../../utils/course_utils.dart';
import '../../Teacher/Room_info/room_booking_model.dart';
import '../../Teacher/Room_info/room_model.dart';
import '../../Teacher/Room_info/room_service.dart';
import '../models/cr_room_request_model.dart';

/// Service for CR (Class Representative) room request operations.
class CRRoomRequestService {
  CRRoomRequestService._();

  // ── Check if current student is a CR ──────────────────────

  static Future<bool> checkIsCR() async {
    final userId = SessionService.currentUserId;
    if (userId == null) return false;

    try {
      final data = await SupabaseCore.from(
        'students',
      ).select('is_cr').eq('user_id', userId).maybeSingle();
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

    final result = await AuthenticatedApi.post('/api/cr-room-requests', {
      'course_code': courseCode,
      'teacher_user_id': teacherUserId,
      'room_number': roomNumber,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'request_date': requestDate,
      'reason': reason,
    });
    return (
      success: result['success'] == true,
      message: (result['message'] ?? 'Room request submitted').toString(),
    );
  }

  static Future<List<Map<String, dynamic>>> getCoursesForTerm() async {
    final userId = SessionService.currentUserId;
    if (userId == null) return [];

    try {
      // 1. Get student's current term (e.g. "3-2") and section
      final student = await SupabaseCore.from(
        'students',
      ).select('term, session, section').eq('user_id', userId).maybeSingle();

      if (student == null) return [];

      final termStr = student['term'] as String;
      final studentSession = student['session'] as String?;
      final studentSection = student['section'] as String?;
      final parsed = CourseUtils.parseTerm(termStr);
      final year = parsed.year;
      final term = parsed.term;

      // 2. Fetch all courses and filter by code prefix (same as CourseInfoService)
      final coursesData = await SupabaseCore.from(
        'courses',
      ).select('id, code, title, course_type');

      final allCourses = (coursesData as List)
          .map((c) => c as Map<String, dynamic>)
          .where(
            (c) =>
                CourseUtils.codeMatchesTerm(c['code'] as String?, year, term),
          )
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
      final data = await SupabaseCore.from(
        'rooms',
      ).select('room_number').order('room_number');

      return (data as List).map((e) => e['room_number'] as String).toList();
    } catch (e) {
      debugPrint('Error fetching rooms: $e');
      return [];
    }
  }

  // ── Delete a request and clean up synced routine_slot ───

  static Future<bool> deleteRequest(String requestId) async {
    final response = await AuthenticatedApi.send(
      'DELETE',
      '/api/cr-room-requests?id=${Uri.encodeQueryComponent(requestId)}',
      {},
    );
    return response['success'] == true;
  }

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
    String courseCode,
  ) async {
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
      final roomVariants = RoomService.roomNumberVariants(roomNumber);

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
          .inFilter('room_number', roomVariants)
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
          .inFilter('room_number', roomVariants)
          .eq('booking_date', requestDate)
          .eq('status', 'approved');

      final bookings = (bookingData as List)
          .map((e) => RoomBookingRequest.fromMap(e as Map<String, dynamic>))
          .toList();

      // 3. Also check cr_room_requests on this date
      final crData = await SupabaseCore.from('cr_room_requests')
          .select('id, start_time, end_time, course_code')
          .inFilter('room_number', roomVariants)
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

  static String _fmt(String t) => t.length >= 5 ? t.substring(0, 5) : t;
}
