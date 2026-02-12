import 'package:flutter/foundation.dart';
import '../../services/supabase_service.dart';
import '../models/enrolled_student.dart';

class TeacherCourseService {
  /// Derive term string from a course code.
  /// CSE 3209 → digits "3209" → year=3, term=2 → "3-2"
  /// CSE 2201 → digits "2201" → year=2, term=2 → "2-2"
  static String _termFromCourseCode(String courseCode) {
    // Extract the numeric part (e.g. "3209" from "CSE 3209")
    final digits = courseCode.replaceAll(RegExp(r'[^0-9]'), '');
    final year = digits[0]; // first digit = year
    final term = digits[1]; // second digit = term
    return '$year-$term';
  }

  /// Fetch students for a course by deriving the term from courseCode
  /// and querying the students table directly.
  static Future<List<EnrolledStudent>> getEnrolledStudents({
    required String courseCode,
    String? offeringId, // kept for future use but not required
    String? section,
  }) async {
    try {
      final term = _termFromCourseCode(courseCode);
      debugPrint('Fetching students for courseCode=$courseCode → term=$term');

      final studentData = await SupabaseService.from('students')
          .select('''
            user_id, roll_no, full_name, phone,
            term, session, batch, section, cgpa, created_at
          ''')
          .eq('term', term);

      var students = (studentData as List)
          .map((row) =>
              EnrolledStudent.fromStudentRow(row as Map<String, dynamic>))
          .toList();

      // Filter by section in Dart if provided
      if (section != null && section.isNotEmpty && section != 'All') {
        students =
            students.where((s) => s.derivedSection == section).toList();
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
      final term = _termFromCourseCode(courseCode);
      final data = await SupabaseService.from('students')
          .select('user_id')
          .eq('term', term);
      return (data as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Get attendance count (number of class sessions held)
  static Future<int> getAttendanceCount({
    required String offeringId,
  }) async {
    try {
      final data = await SupabaseService.from('class_sessions')
          .select('id')
          .eq('offering_id', offeringId);

      return (data as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Get total expected classes from course credit
  static Future<int> getExpectedClasses({
    required String courseCode,
  }) async {
    try {
      final data = await SupabaseService.from('courses')
          .select('credit, course_type')
          .eq('code', courseCode)
          .single();

      final credits = (data['credit'] as num).toDouble();
      final type = (data['course_type'] as String? ?? 'Theory').toLowerCase();

      // Theory (3 credits) ≈ 18 classes, Lab (1.5 credits) ≈ 10 sessions
      if (type == 'lab') {
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
      final data = await SupabaseService.from('attendance_records')
          .select('status')
          .eq('session_id', sessionId);

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
  /// Auto-creates enrollment records when they don't exist.
  /// Throws on failure so the caller can show the real error.
  static Future<void> saveAttendance({
    required String offeringId,
    required DateTime date,
    required String? roomNumber,
    required Map<String, String> attendance, // studentUserId -> status
  }) async {
      final teacherId = SupabaseService.currentUserId;
      if (teacherId == null) throw Exception('Not logged in');

      // 1. Create class session
      final sessionInsert = <String, dynamic>{
        'offering_id': offeringId,
        'starts_at': date.toIso8601String(),
        'ends_at': date.add(const Duration(hours: 1)).toIso8601String(),
      };
      // Only set room_number if valid (FK constraint)
      if (roomNumber != null && roomNumber.isNotEmpty) {
        sessionInsert['room_number'] = roomNumber;
      }

      final sessionData = await SupabaseService.from('class_sessions')
          .insert(sessionInsert)
          .select('id')
          .single();
      final sessionId = sessionData['id'] as String;

      // 2. Ensure enrollment records exist (upsert)
      final studentIds = attendance.keys.toList();
      final existingEnrollments = await SupabaseService.from('enrollments')
          .select('id, student_user_id')
          .eq('offering_id', offeringId)
          .inFilter('student_user_id', studentIds);

      final enrollmentMap = <String, String>{}; // studentUserId -> enrollmentId
      for (final e in (existingEnrollments as List)) {
        enrollmentMap[e['student_user_id'] as String] = e['id'] as String;
      }

      // Create missing enrollments
      final missing = studentIds.where((id) => !enrollmentMap.containsKey(id)).toList();
      if (missing.isNotEmpty) {
        final toInsert = missing
            .map((sid) => {
                  'offering_id': offeringId,
                  'student_user_id': sid,
                  'enrollment_status': 'ENROLLED',
                })
            .toList();

        final inserted = await SupabaseService.from('enrollments')
            .insert(toInsert)
            .select('id, student_user_id');

        for (final e in (inserted as List)) {
          enrollmentMap[e['student_user_id'] as String] = e['id'] as String;
        }
      }

      // 3. Insert attendance records
      final records = attendance.entries
          .where((e) => enrollmentMap.containsKey(e.key))
          .map((e) => {
                'session_id': sessionId,
                'enrollment_id': enrollmentMap[e.key],
                'status': e.value,
                'marked_by_teacher_user_id': teacherId,
              })
          .toList();

      await SupabaseService.from('attendance_records').insert(records);
  }

  /// Save announcement to Supabase notices table
  static Future<bool> saveAnnouncement({
    required String title,
    required String body,
    required String? targetTerm,
    required String? targetSession,
    String? priority,
  }) async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) return false;

      await SupabaseService.from('notices').insert({
        'title': title,
        'body': body,
        'author_user_id': userId,
        'target_term': targetTerm,
        'target_session': targetSession,
        'priority': priority ?? 'NORMAL',
        'is_published': true,
        'published_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('Error saving announcement: $e');
      return false;
    }
  }
}
