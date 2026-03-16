import 'package:flutter/foundation.dart';
import 'package:kuet_cse_automation/services/local_notification_service.dart';
import 'package:kuet_cse_automation/services/session_service.dart';
import 'package:kuet_cse_automation/services/supabase_core.dart';
import 'package:kuet_cse_automation/Student%20Folder/Home/Features/Schedule/class_schedule/class_schedule_models.dart';
import 'package:kuet_cse_automation/Student%20Folder/Home/Features/Schedule/class_schedule/class_schedule_providers.dart';
import 'package:kuet_cse_automation/Teacher/Schedule/teacher_schedule_service.dart';

class ClassReminderService {
  ClassReminderService._();

  static const _leadMinutesKey = 'class_reminder_lead_minutes';
  static const int defaultLeadMinutes = 10;

  static Future<int> getLeadMinutes() async {
    final prefs = await SupabaseCore.ensurePrefs();
    return prefs.getInt(_leadMinutesKey) ?? defaultLeadMinutes;
  }

  static Future<void> setLeadMinutes(int minutes) async {
    final prefs = await SupabaseCore.ensurePrefs();
    final safe = minutes.clamp(1, 120);
    await prefs.setInt(_leadMinutesKey, safe);
  }

  static Future<void> syncTodayReminders() async {
    final userId = SessionService.currentUserId;
    final role = SessionService.currentRole;
    if (userId == null || role == null) return;

    final leadMinutes = await getLeadMinutes();
    await LocalNotificationService.cancelClassReminders();

    if (role == 'TEACHER') {
      await _scheduleTeacherToday(leadMinutes);
      return;
    }

    if (role == 'STUDENT') {
      await _scheduleStudentToday(leadMinutes);
    }
  }

  static Future<void> _scheduleStudentToday(int leadMinutes) async {
    try {
      final now = DateTime.now();
      final todayDow = now.weekday % 7; // Sun=0..Sat=6

      final result = await ScheduleService.fetchClassSchedule();
      final schedules = result['schedules'] as List<ClassSchedule>? ?? [];

      for (final slot in schedules) {
        if (slot.dayOfWeek != todayDow) continue;

        final classStartAt = _dateWithTime(now, slot.startTime);
        if (!classStartAt.isAfter(now)) continue;

        final reminderKey = 'student|${slot.id}|${_dateKey(now)}';
        await LocalNotificationService.scheduleClassReminder(
          reminderKey: reminderKey,
          classStartAt: classStartAt,
          leadMinutes: leadMinutes,
          courseCode: slot.courseCode,
          courseTitle: slot.courseName,
          room: slot.room,
          isTeacher: false,
          section: slot.section,
        );
      }
    } catch (e) {
      debugPrint('[ClassReminderService] _scheduleStudentToday error: $e');
    }
  }

  static Future<void> _scheduleTeacherToday(int leadMinutes) async {
    try {
      final now = DateTime.now();
      final slots = await TeacherScheduleService.fetchEffectiveScheduleForDate(now);

      for (final slot in slots) {
        final classStartAt = _dateWithTime(now, slot.startTime);
        if (!classStartAt.isAfter(now)) continue;

        final reminderKey = 'teacher|${slot.id}|${_dateKey(now)}';
        await LocalNotificationService.scheduleClassReminder(
          reminderKey: reminderKey,
          classStartAt: classStartAt,
          leadMinutes: leadMinutes,
          courseCode: slot.courseCode,
          courseTitle: slot.courseTitle,
          room: slot.displayRoomNumber,
          isTeacher: true,
          section: slot.section,
        );
      }
    } catch (e) {
      debugPrint('[ClassReminderService] _scheduleTeacherToday error: $e');
    }
  }

  static DateTime _dateWithTime(DateTime date, String hhmmss) {
    final parts = hhmmss.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  static String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
