import 'package:flutter/foundation.dart';
import '../../services/supabase_service.dart';
import '../models/student_attendance_data.dart';

/// Service to fetch attendance data for the currently logged-in student.
///
/// Query strategy:
///   1. Get student's `user_id` from SharedPrefs.
///   2. Find all enrollments for this student.
///   3. For each enrollment → get the offering → get the course.
///   4. For each enrollment → get attendance_records joined with class_sessions.
///   5. Aggregate into [CourseAttendanceSummary] list.
///
/// If the student has NO enrollment rows, fall back to:
///   - Derive term from the students table.
///   - List all course_offerings for that term.
///   - Count class_sessions per offering (totalSessions).
///   - Since there are no attendance_records, all show 0 attended.
class StudentAttendanceService {
  /// Fetch attendance summaries for every enrolled course.
  static Future<List<CourseAttendanceSummary>> getAttendanceSummaries() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) throw Exception('Not logged in');

    // ── Step 1: Try enrollments-based fetch ──────────────────
    final enrollments = await SupabaseService.from('enrollments')
        .select('''
          id,
          offering_id,
          course_offerings!inner (
            id,
            term,
            courses!inner ( code, title, credit, course_type )
          )
        ''')
        .eq('student_user_id', userId);

    final enrollmentList = enrollments as List;

    if (enrollmentList.isNotEmpty) {
      return _buildFromEnrollments(userId, enrollmentList);
    }

    // ── Step 2: Fallback — derive from student's term ────────
    debugPrint('No enrollments found, falling back to term-based lookup');
    return _buildFromTerm(userId);
  }

  // ─────────────────────────────────────────────────────────────
  // PATH A: Student has enrollment records
  // ─────────────────────────────────────────────────────────────

  static Future<List<CourseAttendanceSummary>> _buildFromEnrollments(
    String userId,
    List<dynamic> enrollmentList,
  ) async {
    final summaries = <CourseAttendanceSummary>[];

    for (final enr in enrollmentList) {
      final enrollmentId = enr['id'] as String;
      final offering = enr['course_offerings'] as Map<String, dynamic>;
      final course = offering['courses'] as Map<String, dynamic>;
      final offeringId = offering['id'] as String;

      final courseCode = course['code'] as String;
      final courseTitle = course['title'] as String;
      final credit = (course['credit'] as num).toDouble();
      final courseType = course['course_type'] as String? ?? 'Theory';

      // Get all class_sessions for this offering
      final sessionsData = await SupabaseService.from('class_sessions')
          .select('id, starts_at, topic, room_number')
          .eq('offering_id', offeringId)
          .order('starts_at', ascending: true);
      final sessionList = sessionsData as List;

      // Get this student's attendance_records for each session
      final attendanceData = await SupabaseService.from('attendance_records')
          .select('session_id, status')
          .eq('enrollment_id', enrollmentId);
      final attendanceList = attendanceData as List;

      // Build a lookup: sessionId → status
      final statusBySession = <String, String>{};
      for (final a in attendanceList) {
        statusBySession[a['session_id'] as String] =
            (a['status'] as String).toUpperCase();
      }

      // Build per-session entries
      int present = 0, late = 0, absent = 0;
      final sessions = <SessionAttendanceEntry>[];

      for (final sess in sessionList) {
        final sid = sess['id'] as String;
        final status = statusBySession[sid] ?? 'ABSENT';

        sessions.add(SessionAttendanceEntry(
          sessionId: sid,
          date: DateTime.parse(sess['starts_at'] as String),
          status: status,
          topic: sess['topic'] as String?,
          roomNumber: sess['room_number'] as String?,
        ));

        if (status == 'PRESENT') {
          present++;
        } else if (status == 'LATE') {
          late++;
        } else {
          absent++;
        }
      }

      summaries.add(CourseAttendanceSummary(
        courseCode: courseCode,
        courseTitle: courseTitle,
        courseType: courseType,
        credit: credit,
        offeringId: offeringId,
        totalSessions: sessionList.length,
        presentCount: present,
        lateCount: late,
        absentCount: absent,
        sessions: sessions,
      ));
    }

    // Sort by course code
    summaries.sort((a, b) => a.courseCode.compareTo(b.courseCode));
    return summaries;
  }

  // ─────────────────────────────────────────────────────────────
  // PATH B: No enrollments — derive from student's term
  // ─────────────────────────────────────────────────────────────

  static Future<List<CourseAttendanceSummary>> _buildFromTerm(
    String userId,
  ) async {
    // Get student's current term
    final studentData = await SupabaseService.from('students')
        .select('term')
        .eq('user_id', userId)
        .single();
    final term = studentData['term'] as String; // e.g. "3-2"

    // Get all course_offerings for this term
    final offeringsData = await SupabaseService.from('course_offerings')
        .select('''
          id,
          courses!inner ( code, title, credit, course_type )
        ''')
        .eq('term', term)
        .eq('is_active', true);

    final offeringsList = offeringsData as List;
    final summaries = <CourseAttendanceSummary>[];

    for (final off in offeringsList) {
      final course = off['courses'] as Map<String, dynamic>;
      final offeringId = off['id'] as String;
      final courseCode = course['code'] as String;
      final courseTitle = course['title'] as String;
      final credit = (course['credit'] as num).toDouble();
      final courseType = course['course_type'] as String? ?? 'Theory';

      // Count class_sessions held so far
      final sessionsData = await SupabaseService.from('class_sessions')
          .select('id, starts_at, topic, room_number')
          .eq('offering_id', offeringId)
          .order('starts_at', ascending: true);
      final sessionList = sessionsData as List;

      // Check if this student has any enrollment for this offering
      final enrData = await SupabaseService.from('enrollments')
          .select('id')
          .eq('offering_id', offeringId)
          .eq('student_user_id', userId);
      final enrollmentRows = enrData as List;
      final enrollmentId =
          enrollmentRows.isNotEmpty ? enrollmentRows.first['id'] as String : null;

      // If enrollment exists, fetch attendance
      final statusBySession = <String, String>{};
      if (enrollmentId != null) {
        final attData = await SupabaseService.from('attendance_records')
            .select('session_id, status')
            .eq('enrollment_id', enrollmentId);
        for (final a in (attData as List)) {
          statusBySession[a['session_id'] as String] =
              (a['status'] as String).toUpperCase();
        }
      }

      int present = 0, late = 0, absent = 0;
      final sessions = <SessionAttendanceEntry>[];

      for (final sess in sessionList) {
        final sid = sess['id'] as String;
        final status = statusBySession[sid] ?? 'ABSENT';

        sessions.add(SessionAttendanceEntry(
          sessionId: sid,
          date: DateTime.parse(sess['starts_at'] as String),
          status: status,
          topic: sess['topic'] as String?,
          roomNumber: sess['room_number'] as String?,
        ));

        if (status == 'PRESENT') {
          present++;
        } else if (status == 'LATE') {
          late++;
        } else {
          absent++;
        }
      }

      summaries.add(CourseAttendanceSummary(
        courseCode: courseCode,
        courseTitle: courseTitle,
        courseType: courseType,
        credit: credit,
        offeringId: offeringId,
        totalSessions: sessionList.length,
        presentCount: present,
        lateCount: late,
        absentCount: absent,
        sessions: sessions,
      ));
    }

    summaries.sort((a, b) => a.courseCode.compareTo(b.courseCode));
    return summaries;
  }
}
