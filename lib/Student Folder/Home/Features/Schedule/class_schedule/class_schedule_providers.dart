import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';
import 'package:kuet_cse_automation/services/optional_course_service.dart';
import 'package:kuet_cse_automation/services/supabase_service.dart';
import 'package:kuet_cse_automation/utils/course_utils.dart';
import 'package:kuet_cse_automation/utils/time_utils.dart';

import 'class_schedule_models.dart';

/// Provider for selected section filter (A / B)
/// Default is empty string — means use auto-detected section from roll.
final selectedSectionProvider = StateProvider<String>((ref) => '');

/// Async provider that fetches class schedule from Supabase.
final classScheduleProvider = FutureProvider<Map<String, dynamic>>((ref) async {
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
      final activeSection = sectionOverride.isEmpty
          ? autoSection
          : sectionOverride;

      final parsed = CourseUtils.parseTerm(studentTerm);
      final year = parsed.year;
      final term = parsed.term;
      debugPrint(
        '[ClassSchedule] roll=$rollNo, activeSection=$activeSection, prefix=$year$term',
      );

      final response = await SupabaseService.client
          .from('routine_slots')
          .select('''
            id,
            day_of_week,
            start_time,
            end_time,
            room_number,
            section,
            valid_from,
            valid_until,
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

      // For 4th year, pre-fetch elective info for filtering
      Set<String> electiveCourseIds = {};
      Set<String> assignedOfferingIds = {};
      if (year == 4) {
        electiveCourseIds = await OptionalCourseService.getElectiveCourseIds(
          term: '$year-$term',
        );
        assignedOfferingIds = await OptionalCourseService.getMyAssignedOfferingIds();
      }

      final schedules = <ClassSchedule>[];
      for (final item in data) {
        final map = item as Map<String, dynamic>;
        final offering = map['course_offerings'] as Map<String, dynamic>?;
        if (offering == null) continue;
        if (offering['is_active'] != true) continue;
        if (_isSingleDayOverride(map)) continue;

        final courseData = offering['courses'] as Map<String, dynamic>?;
        final courseCode = courseData?['code'] as String?;
        if (!CourseUtils.codeMatchesTerm(courseCode, year, term)) continue;

        // For 4th year: skip elective course slots student is not assigned to
        if (year == 4) {
          final courseId = courseData?['id']?.toString();
          final offeringId = offering['id']?.toString();
          if (courseId != null && electiveCourseIds.contains(courseId)) {
            if (offeringId == null || !assignedOfferingIds.contains(offeringId)) {
              continue;
            }
          }
        }

        final slotSection = map['section'] as String?;
        if (slotSection != null && slotSection.isNotEmpty) {
          if (slotSection.toUpperCase() != activeSection.toUpperCase()) {
            continue;
          }
        }

        schedules.add(ClassSchedule.fromSupabase(map));
      }

      // Merge upcoming exams (next 14 days) into the schedule
      final examItems = await _fetchUpcomingExamsAsScheduleItems(
        year, term, activeSection,
      );
      schedules.addAll(examItems);

      schedules.sort((a, b) {
        if (a.dayOfWeek != b.dayOfWeek)
          return a.dayOfWeek.compareTo(b.dayOfWeek);
        return a.startTime.compareTo(b.startTime);
      });

      debugPrint(
        '[ClassSchedule] Returning ${schedules.length} items (incl. ${examItems.length} exams) for section $activeSection',
      );
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

  static bool _isSingleDayOverride(Map<String, dynamic> map) {
    final validFrom = map['valid_from'] as String?;
    final validUntil = map['valid_until'] as String?;
    return validFrom != null && validUntil != null && validFrom == validUntil;
  }

  /// Fetch exams within the next 14 days and convert them to [ClassSchedule]
  /// items so they appear inline in the weekly schedule view.
  static Future<List<ClassSchedule>> _fetchUpcomingExamsAsScheduleItems(
    int year,
    int term,
    String activeSection,
  ) async {
    try {
      final today = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(today);
      final endStr = DateFormat('yyyy-MM-dd')
          .format(today.add(const Duration(days: 14)));

      final response = await SupabaseService.client
          .from('course_offerings')
          .select('''
            id,
            is_active,
            courses (
              id,
              code,
              title
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
              section,
              syllabus
            )
          ''')
          .eq('is_active', true);

      final List<dynamic> data = response as List<dynamic>;
      final items = <ClassSchedule>[];

      for (final offering in data) {
        final offeringMap = offering as Map<String, dynamic>;
        final courseData = offeringMap['courses'] as Map<String, dynamic>?;
        final courseCode = courseData?['code'] as String?;

        if (!CourseUtils.codeMatchesTerm(courseCode, year, term)) continue;

        final examList = offeringMap['exams'] as List<dynamic>? ?? [];
        for (final exam in examList) {
          final examMap = exam as Map<String, dynamic>;
          final examDateRaw = examMap['exam_date'] as String?;
          if (examDateRaw == null) continue;

          // Only include exams within the 14-day window
          if (examDateRaw.compareTo(todayStr) < 0 ||
              examDateRaw.compareTo(endStr) > 0) continue;

          // Section filter
          final examSection = examMap['section'] as String?;
          if (examSection != null && examSection.isNotEmpty) {
            if (examSection.toUpperCase() != activeSection.toUpperCase()) {
              continue;
            }
          }

          final parsedDate = DateTime.tryParse(examDateRaw);
          if (parsedDate == null) continue;

          // Dart weekday: 1=Mon...6=Sat,7=Sun → KUET day_of_week: 0=Sun,1=Mon...
          final kuetDay = parsedDate.weekday == 7 ? 0 : parsedDate.weekday;
          final dayName = TimeUtils.dayName(kuetDay);

          // Build time string
          final examTime = examMap['exam_time'] as String?;
          final durationMin = examMap['duration_minutes'] as int?;
          String startStr = examTime ?? '08:00:00';
          String endStr2 = startStr;
          if (examTime != null && durationMin != null) {
            try {
              final parts = examTime.split(':');
              final sh = int.parse(parts[0]);
              final sm = int.parse(parts[1]);
              final em = sh * 60 + sm + durationMin;
              endStr2 =
                  '${(em ~/ 60).toString().padLeft(2, '0')}:${(em % 60).toString().padLeft(2, '0')}:00';
            } catch (_) {}
          }
          final timeDisplay = examTime != null
              ? TimeUtils.timeRange12h(startStr, endStr2)
              : 'TBA';

          // Exam type label
          final examType = examMap['exam_type'] as String? ?? 'CT';
          String typeLabel;
          switch (examType.toUpperCase()) {
            case 'CT':
            case 'CLASS_TEST':
              typeLabel = 'CT';
              break;
            case 'MID':
            case 'MIDTERM':
            case 'FINAL':
            case 'TERM_FINAL':
              typeLabel = 'Term Final';
              break;
            case 'QUIZ':
            case 'VIVA':
            case 'QUIZ_VIVA':
              typeLabel = 'Quiz/Viva';
              break;
            default:
              typeLabel = examType;
          }

          final roomNumbers = examMap['room_numbers'] as List<dynamic>?;
          final roomStr = (roomNumbers != null && roomNumbers.isNotEmpty)
              ? roomNumbers.join(', ')
              : 'TBA';

          final maxMarks = (examMap['max_marks'] as num?)?.toDouble() ?? 0;
          final syllabusText =
              (examMap['syllabus'] as String?)?.isNotEmpty == true
                  ? examMap['syllabus'] as String
                  : (examMap['name'] as String? ?? '');
          final dateFormatted =
              DateFormat('EEE, MMM d').format(parsedDate);

          items.add(ClassSchedule(
            id: (examMap['id'] ?? '').toString(),
            courseName: courseData?['title'] as String? ?? 'Unknown Course',
            courseCode: courseCode ?? '',
            teacher: '',
            room: roomStr,
            startTime: startStr,
            endTime: endStr2,
            time: timeDisplay,
            day: dayName,
            dayOfWeek: kuetDay,
            isExam: true,
            examTypeLabel: typeLabel,
            examMaxMarks: maxMarks > 0 ? maxMarks : null,
            examSyllabus: syllabusText.isNotEmpty ? syllabusText : null,
            examDateFormatted: dateFormatted,
          ));
        }
      }

      debugPrint('[ClassSchedule] Found ${items.length} upcoming exams');
      return items;
    } catch (e) {
      debugPrint('[ClassSchedule] _fetchUpcomingExams error: $e');
      return [];
    }
  }
}
