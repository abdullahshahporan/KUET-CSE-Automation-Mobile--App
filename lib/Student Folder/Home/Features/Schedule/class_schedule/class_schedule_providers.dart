import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:kuet_cse_automation/services/supabase_service.dart';
import 'package:kuet_cse_automation/utils/course_utils.dart';
import 'class_schedule_models.dart';

/// Provider for selected section filter (A / B)
/// Default is empty string — means use auto-detected section from roll.
final selectedSectionProvider =
    StateProvider<String>((ref) => '');

/// Async provider that fetches class schedule from Supabase.
final classScheduleProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final sectionOverride = ref.watch(selectedSectionProvider);
  return ScheduleService.fetchClassSchedule(sectionOverride: sectionOverride);
});

class ScheduleService {
  /// Derive section from roll number — delegates to [CourseUtils].
  static String sectionFromRoll(String? rollNo) =>
      CourseUtils.sectionFromRoll(rollNo);

  /// Fetch class schedule for the current student from Supabase.
  static Future<Map<String, dynamic>> fetchClassSchedule({
    String sectionOverride = '',
  }) async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) {
        debugPrint('[ClassSchedule] No logged-in user');
        return {'schedules': <ClassSchedule>[], 'section': 'A', 'rollNo': ''};
      }

      final studentData = await SupabaseService.client
          .from('students')
          .select('term, section, roll_no')
          .eq('user_id', userId)
          .maybeSingle();

      if (studentData == null) {
        debugPrint('[ClassSchedule] No student profile found');
        return {'schedules': <ClassSchedule>[], 'section': 'A', 'rollNo': ''};
      }

      final studentTerm = studentData['term'] as String? ?? '1-1';
      final rollNo = studentData['roll_no'] as String? ?? '';

      final autoSection = CourseUtils.sectionFromRoll(rollNo);
      final activeSection = sectionOverride.isEmpty ? autoSection : sectionOverride;

      final parsed = CourseUtils.parseTerm(studentTerm);
      final year = parsed.year;
      final term = parsed.term;
      debugPrint('[ClassSchedule] roll=$rollNo, activeSection=$activeSection, prefix=$year$term');

      final response = await SupabaseService.client
          .from('routine_slots')
          .select('''
            id,
            day_of_week,
            start_time,
            end_time,
            room_number,
            section,
            course_offerings (
              id,
              term,
              session,
              batch,
              is_active,
              courses (
                id,
                code,
                title,
                credit,
                course_type
              ),
              teachers (
                full_name,
                designation
              )
            )
          ''');

      final List<dynamic> data = response as List<dynamic>;
      debugPrint('[ClassSchedule] Got ${data.length} total routine_slots');

      final schedules = <ClassSchedule>[];
      for (final item in data) {
        final map = item as Map<String, dynamic>;
        final offering = map['course_offerings'] as Map<String, dynamic>?;
        if (offering == null) continue;
        if (offering['is_active'] != true) continue;

        final courseData = offering['courses'] as Map<String, dynamic>?;
        final courseCode = courseData?['code'] as String?;
        if (!CourseUtils.codeMatchesTerm(courseCode, year, term)) continue;

        final slotSection = map['section'] as String?;
        if (slotSection != null && slotSection.isNotEmpty) {
          if (slotSection.toUpperCase() != activeSection.toUpperCase()) {
            continue;
          }
        }

        schedules.add(ClassSchedule.fromSupabase(map));
      }

      schedules.sort((a, b) {
        if (a.dayOfWeek != b.dayOfWeek) return a.dayOfWeek.compareTo(b.dayOfWeek);
        return a.startTime.compareTo(b.startTime);
      });

      debugPrint('[ClassSchedule] Returning ${schedules.length} slots for section $activeSection');
      return {
        'schedules': schedules,
        'section': activeSection,
        'autoSection': autoSection,
        'rollNo': rollNo,
      };
    } catch (e) {
      debugPrint('[ClassSchedule] ERROR: $e');
      return {'schedules': <ClassSchedule>[], 'section': 'A', 'rollNo': ''};
    }
  }
}
