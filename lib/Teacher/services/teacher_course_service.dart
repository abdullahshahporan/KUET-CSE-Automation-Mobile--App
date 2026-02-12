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

  /// Save attendance for a class session (create session + records)
  static Future<bool> saveAttendance({
    required String offeringId,
    required DateTime date,
    required String? roomNumber,
    required Map<String, String> attendance, // enrollmentId -> status
  }) async {
    try {
      final teacherId = SupabaseService.currentUserId;
      if (teacherId == null) return false;

      // Create class session
      final sessionData = await SupabaseService.from('class_sessions')
          .insert({
            'offering_id': offeringId,
            'starts_at': date.toIso8601String(),
            'ends_at': date.add(const Duration(hours: 1)).toIso8601String(),
            'room_number': roomNumber,
          })
          .select('id')
          .single();

      final sessionId = sessionData['id'] as String;

      // Insert attendance records
      final records = attendance.entries.map((e) => {
        'session_id': sessionId,
        'enrollment_id': e.key,
        'status': e.value,
        'marked_by_teacher_user_id': teacherId,
      }).toList();

      await SupabaseService.from('attendance_records').insert(records);
      return true;
    } catch (e) {
      debugPrint('Error saving attendance: $e');
      return false;
    }
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
