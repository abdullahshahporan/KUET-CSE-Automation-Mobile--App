import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:kuet_cse_automation/services/supabase_service.dart';
import 'class_schedule_models.dart';

/// Provider for selected section filter (A / B)
/// Default is empty string — means use auto-detected section from roll.
final selectedSectionProvider =
    StateProvider<String>((ref) => '');

/// Async provider that fetches class schedule from Supabase.
///
/// Queries routine_slots directly with forward join to
/// course_offerings → courses + teachers.
/// Filters client-side by course code prefix matching the student's term,
/// and by section derived from the student's roll number.
final classScheduleProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final sectionOverride = ref.watch(selectedSectionProvider);
  return ScheduleService.fetchClassSchedule(sectionOverride: sectionOverride);
});

class ScheduleService {
  /// Derive section from roll number.
  /// Last 3 digits: 001-060 → A, 061+ → B
  static String sectionFromRoll(String? rollNo) {
    if (rollNo == null || rollNo.isEmpty) return 'A';
    // Extract last 3 digits (or fewer if roll is short)
    final digits = rollNo.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 'A';
    final last3 = digits.length >= 3
        ? digits.substring(digits.length - 3)
        : digits;
    final num = int.tryParse(last3) ?? 1;
    return num <= 60 ? 'A' : 'B';
  }

  /// Fetch class schedule for the current student from Supabase.
  ///
  /// 1. Gets the student's roll_no and term.
  /// 2. Derives section from roll number (or uses override).
  /// 3. Queries routine_slots directly (forward join to course_offerings → courses + teachers).
  /// 4. Filters by course code prefix and section.
  ///
  /// Returns a Map with 'schedules', 'section', and 'rollNo'.
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

      // Derive section from roll number
      final autoSection = sectionFromRoll(rollNo);
      final activeSection = sectionOverride.isEmpty ? autoSection : sectionOverride;

      // Parse year & term from "3-2" → year=3, term=2
      final parts = studentTerm.split('-');
      final year = int.tryParse(parts[0]) ?? 1;
      final term = int.tryParse(parts.length > 1 ? parts[1] : '1') ?? 1;
      final termPrefix = '$year$term';
      debugPrint('[ClassSchedule] roll=$rollNo, autoSection=$autoSection, activeSection=$activeSection, prefix=$termPrefix');

      // Query FROM routine_slots with forward join to course_offerings → courses + teachers
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

      // Filter client-side
      final schedules = <ClassSchedule>[];
      for (final item in data) {
        final map = item as Map<String, dynamic>;
        final offering = map['course_offerings'] as Map<String, dynamic>?;
        if (offering == null) continue;

        // Must be active
        if (offering['is_active'] != true) continue;

        // Course code must match term prefix
        final courseData = offering['courses'] as Map<String, dynamic>?;
        final courseCode = courseData?['code'] as String?;
        if (!_codeMatchesTerm(courseCode, year, term)) continue;

        // Section filter: if the slot has a section, must match
        final slotSection = map['section'] as String?;
        if (slotSection != null && slotSection.isNotEmpty) {
          if (slotSection.toUpperCase() != activeSection.toUpperCase()) {
            continue;
          }
        }

        schedules.add(ClassSchedule.fromSupabase(map));
      }

      // Sort by day then by start_time
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

  /// Check if course code matches year-term.
  /// "CSE 3201" → digits "3201" → starts with "32" → matches year=3, term=2.
  static bool _codeMatchesTerm(String? code, int year, int term) {
    if (code == null || code.isEmpty) return false;
    final prefix = '$year$term';
    final digits = code.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.startsWith(prefix);
  }
}
