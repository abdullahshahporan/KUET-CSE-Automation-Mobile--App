import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:kuet_cse_automation/Student%20Folder/Home/Features/Schedule/exam_schedule/exam_schedule_models.dart';
import 'package:kuet_cse_automation/Student%20Folder/Home/Features/Schedule/exam_schedule/exam_schedule_providers.dart';
import 'package:kuet_cse_automation/services/local_notification_service.dart';
import 'package:kuet_cse_automation/services/session_service.dart';
import 'package:kuet_cse_automation/services/supabase_core.dart';

class ExamReminderService {
  ExamReminderService._();

  static const _leadMinutesKey = 'exam_reminder_lead_minutes';
  static const int defaultLeadMinutes = 180;

  static Future<int> getLeadMinutes() async {
    final prefs = await SupabaseCore.ensurePrefs();
    return prefs.getInt(_leadMinutesKey) ?? defaultLeadMinutes;
  }

  static Future<void> setLeadMinutes(int minutes) async {
    final prefs = await SupabaseCore.ensurePrefs();
    final safe = minutes.clamp(15, 24 * 60);
    await prefs.setInt(_leadMinutesKey, safe);
  }

  static Future<void> syncUpcomingReminders() async {
    final userId = SessionService.currentUserId;
    final role = SessionService.currentRole;
    if (userId == null) return;

    final leadMinutes = await getLeadMinutes();
    await LocalNotificationService.cancelExamReminders();

    try {
      final List<ExamSchedule> exams;
      if (role == 'TEACHER') {
        exams = await _fetchTeacherExams(userId);
      } else {
        exams = await ExamScheduleService.fetchExamSchedule();
      }

      final now = DateTime.now();

      for (final exam in exams) {
        final examStartsAt = _parseExamDateTime(exam);
        if (examStartsAt == null || !examStartsAt.isAfter(now)) continue;

        final reminderKey = '${exam.id}|${_dateKey(examStartsAt)}';
        await LocalNotificationService.scheduleExamReminder(
          reminderKey: reminderKey,
          examStartsAt: examStartsAt,
          leadMinutes: leadMinutes,
          courseCode: exam.courseCode,
          examLabel: '${exam.examType} exam',
          room: exam.room,
        );
      }
    } catch (e) {
      debugPrint('[ExamReminderService] syncUpcomingReminders error: $e');
    }
  }

  /// Fetch upcoming exams for a teacher based on their active course offerings.
  static Future<List<ExamSchedule>> _fetchTeacherExams(
    String teacherUserId,
  ) async {
    try {
      final response = await SupabaseCore.from('course_offerings').select('''
          id, term,
          courses ( id, code, title, course_type ),
          exams (
            id, name, exam_type, max_marks, exam_date,
            exam_time, duration_minutes, room_numbers, created_at
          )
        ''').eq('teacher_user_id', teacherUserId).eq('is_active', true);

      final exams = <ExamSchedule>[];
      for (final offering in response as List) {
        final offeringMap = offering as Map<String, dynamic>;
        final examList = offeringMap['exams'] as List<dynamic>? ?? [];
        for (final exam in examList) {
          final flatMap = Map<String, dynamic>.from(
            exam as Map<String, dynamic>,
          );
          flatMap['course_offerings'] = {
            'id': offeringMap['id'],
            'term': offeringMap['term'],
            'courses': offeringMap['courses'],
          };
          exams.add(ExamSchedule.fromSupabase(flatMap));
        }
      }
      return exams;
    } catch (e) {
      debugPrint('[ExamReminderService] _fetchTeacherExams error: $e');
      return [];
    }
  }

  static DateTime? _parseExamDateTime(ExamSchedule exam) {
    try {
      final parsedDate = DateFormat('MMMM d, yyyy').parse(exam.date);
      final timeRange = exam.time.split('-').first.trim();
      final parsedTime = DateFormat('h:mm a').parse(timeRange);
      return DateTime(
        parsedDate.year,
        parsedDate.month,
        parsedDate.day,
        parsedTime.hour,
        parsedTime.minute,
      );
    } catch (_) {
      return null;
    }
  }

  static String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}