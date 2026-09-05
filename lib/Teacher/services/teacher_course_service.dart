import '../../services/authenticated_api.dart';
import 'package:flutter/foundation.dart';
import '../../services/supabase_service.dart';
import '../../utils/course_utils.dart';
import '../models/enrolled_student.dart';

class TeacherCourseService {
  /// Fetch students for a course by deriving the term from courseCode
  /// and querying the students table directly.
  static Future<List<EnrolledStudent>> getEnrolledStudents({
    required String courseCode,
    String? offeringId, // kept for future use but not required
    String? section,
  }) async {
    try {
      final term = CourseUtils.termFromCourseCode(courseCode);
      debugPrint('Fetching students for courseCode=$courseCode → term=$term');

      final studentData = await SupabaseService.from('students')
          .select('''
            user_id, roll_no, full_name, phone,
            term, session, batch, section, cgpa, created_at
          ''')
          .eq('term', term);

      var students = (studentData as List)
          .map(
            (row) =>
                EnrolledStudent.fromStudentRow(row as Map<String, dynamic>),
          )
          .toList();

      // Filter by section in Dart if provided
      if (section != null && section.isNotEmpty && section != 'All') {
        students = students.where((s) => s.derivedSection == section).toList();
      }

      // Sort by roll number
      students.sort((a, b) => a.rollNo.compareTo(b.rollNo));

      return students;
    } catch (e) {
      debugPrint('Error fetching students: $e');
      throw Exception('Failed to fetch students: $e');
    }
  }

  /// Get student count by deriving term from courseCode.
  static Future<int> getStudentCount({
    required String courseCode,
    String? offeringId, // kept for compatibility
  }) async {
    try {
      final term = CourseUtils.termFromCourseCode(courseCode);
      final data = await SupabaseService.from(
        'students',
      ).select('user_id').eq('term', term);
      return (data as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Get attendance count (number of class sessions held)
  static Future<int> getAttendanceCount({required String offeringId}) async {
    try {
      final data = await SupabaseService.from(
        'class_sessions',
      ).select('id').eq('offering_id', offeringId);

      return (data as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Get total expected classes from course credit
  static Future<int> getExpectedClasses({required String courseCode}) async {
    try {
      final data = await SupabaseService.from(
        'courses',
      ).select('credit, course_type').eq('code', courseCode).single();

      final credits = (data['credit'] as num).toDouble();
      final type = (data['course_type'] as String? ?? 'Theory').toLowerCase();
      final isLabByCode = CourseUtils.isLabCourseCode(courseCode);

      // Theory (3 credits) ≈ 18 classes, Lab (1.5 credits) ≈ 10 sessions
      if (isLabByCode == true || (isLabByCode == null && type == 'lab')) {
        return (credits * 6.67).round();
      }
      return (credits * 6).round();
    } catch (e) {
      return 0;
    }
  }

  /// Fetch recent class sessions (attendance records) for a course offering
  static Future<List<Map<String, dynamic>>> getClassSessions({
    required String offeringId,
    int limit = 10,
  }) async {
    try {
      final data = await SupabaseService.from('class_sessions')
          .select('''
            id,
            starts_at,
            ends_at,
            topic,
            room_number
          ''')
          .eq('offering_id', offeringId)
          .order('starts_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      debugPrint('Error fetching class sessions: $e');
      return [];
    }
  }

  /// Get attendance stats for a specific class session
  static Future<Map<String, int>> getSessionAttendanceStats({
    required String sessionId,
  }) async {
    try {
      final data = await SupabaseService.from(
        'attendance_records',
      ).select('status').eq('session_id', sessionId);

      final records = data as List;
      int present = 0, absent = 0, late = 0;
      for (final r in records) {
        final status = (r['status'] as String).toLowerCase();
        if (status == 'present') {
          present++;
        } else if (status == 'late') {
          late++;
        } else {
          absent++;
        }
      }
      final total = present + absent + late;
      final rate = total > 0 ? ((present + late) / total * 100).round() : 0;

      return {
        'present': present,
        'absent': absent,
        'late': late,
        'total': total,
        'rate': rate,
      };
    } catch (e) {
      return {'present': 0, 'absent': 0, 'late': 0, 'total': 0, 'rate': 0};
    }
  }

  /// Save attendance for a class session.
  ///
  /// [attendance] maps **student_user_id** → status string.
  /// Requires existing active enrolments; all writes commit atomically.
  /// Throws on failure so the caller can show the real error.
  static Future<void> saveAttendance({
    required String offeringId,
    required DateTime date,
    required String? roomNumber,
    required Map<String, String> attendance, // studentUserId -> status
  }) async {
    final result =
        await AuthenticatedApi.post('/api/teacher-portal/attendance/session', {
          'offering_id': offeringId,
          'starts_at': date.toUtc().toIso8601String(),
          'room_number': roomNumber,
          'attendance': attendance,
        });
    if (result['success'] != true)
      throw Exception(result['message'] ?? 'Could not save attendance');
  }

  /// Save announcement to Supabase notices table
  static Future<bool> saveAnnouncement({
    required String title,
    required String body,
    required String courseCode,
    required String? targetTerm,
    required String? targetSession,
    String? priority,
  }) async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) return false;

      final result =
          await AuthenticatedApi.post('/api/teacher-portal/announcements', {
            'title': title,
            'content': body,
            'course_code': courseCode,
            'priority': priority ?? 'medium',
            'type': 'notice',
          });
      return result['success'] == true;
    } catch (e) {
      debugPrint('Error saving announcement: $e');
      return false;
    }
  }
}
