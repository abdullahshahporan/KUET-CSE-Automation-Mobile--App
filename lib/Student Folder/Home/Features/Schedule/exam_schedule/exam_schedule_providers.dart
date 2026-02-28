import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:kuet_cse_automation/services/supabase_service.dart';
import 'package:kuet_cse_automation/utils/course_utils.dart';
import 'exam_schedule_models.dart';

// Exam Category Provider (CT, Term Final, Quiz/Viva)
final selectedExamCategoryProvider = StateProvider<String>((ref) => 'CT');

/// Async provider that fetches exam schedule from Supabase.
///
/// Uses the course code convention: code "32xx" → year 3, term 2.
/// Fetches all active offerings with exams, then filters
/// client-side by matching the course code prefix to the student's term.
final examScheduleProvider =
    FutureProvider<List<ExamSchedule>>((ref) async {
  return ExamScheduleService.fetchExamSchedule();
});

class ExamScheduleService {
  /// Fetch exam schedule for the current student from Supabase.
  static Future<List<ExamSchedule>> fetchExamSchedule() async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) {
        debugPrint('[ExamSchedule] No logged-in user');
        return [];
      }

      final studentData = await SupabaseService.client
          .from('students')
          .select('term')
          .eq('user_id', userId)
          .maybeSingle();

      if (studentData == null) {
        debugPrint('[ExamSchedule] No student profile found');
        return [];
      }

      final studentTerm = studentData['term'] as String? ?? '1-1';

      // Parse year & term from "3-2"
      final (:year, :term) = CourseUtils.parseTerm(studentTerm);
      final termPrefix = '$year$term';
      debugPrint('[ExamSchedule] Student term=$studentTerm, prefix=$termPrefix');

      // Fetch ALL active course_offerings with exams and courses
      final response = await SupabaseService.client
          .from('course_offerings')
          .select('''
            id,
            term,
            is_active,
            courses (
              id,
              code,
              title,
              course_type
            ),
            exams (
              id,
              name,
              exam_type,
              max_marks,
              exam_date,
              exam_time,
              duration_minutes,
              room_numbers,
              created_at
            )
          ''')
          .eq('is_active', true);

      final List<dynamic> data = response as List<dynamic>;
      debugPrint('[ExamSchedule] Got ${data.length} active offerings total');

      // Flatten & filter by course code prefix
      final exams = <ExamSchedule>[];
      for (final offering in data) {
        final offeringMap = offering as Map<String, dynamic>;
        final courseData = offeringMap['courses'] as Map<String, dynamic>?;
        final courseCode = courseData?['code'] as String?;

        // Skip if course code doesn't match this term
        if (!CourseUtils.codeMatchesTerm(courseCode, year, term)) continue;

        final examList = offeringMap['exams'] as List<dynamic>? ?? [];
        for (final exam in examList) {
          final examMap = exam as Map<String, dynamic>;

          final flatMap = Map<String, dynamic>.from(examMap);
          flatMap['course_offerings'] = {
            'id': offeringMap['id'],
            'term': offeringMap['term'],
            'courses': offeringMap['courses'],
          };

          exams.add(ExamSchedule.fromSupabase(flatMap));
        }
      }

      // Sort by date
      exams.sort((a, b) => a.date.compareTo(b.date));

      debugPrint('[ExamSchedule] Returning ${exams.length} exams');
      return exams;
    } catch (e) {
      debugPrint('[ExamSchedule] ERROR: $e');
      return [];
    }
  }

}
