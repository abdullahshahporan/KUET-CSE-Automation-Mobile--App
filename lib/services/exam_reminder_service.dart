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
    if (userId == null || role != 'STUDENT') return;

    final leadMinutes = await getLeadMinutes();
    await LocalNotificationService.cancelExamReminders();

    try {
      final exams = await ExamScheduleService.fetchExamSchedule();
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