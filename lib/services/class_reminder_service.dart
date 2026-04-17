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
  static const _signatureKeyPrefix = 'class_reminder_signature_v2_';
  static const int defaultLeadMinutes = 10;

  // Schedule reminders for today + the next 6 days so they survive
  // without the app being opened daily.
  static const int _scheduleDays = 7;

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
    final plans = switch (role) {
      'TEACHER' => await _buildTeacherPlans(leadMinutes),
      'HEAD' => await _buildTeacherPlans(leadMinutes),
      'STUDENT' => await _buildStudentPlans(leadMinutes),
      _ => <_ClassReminderPlan>[],
    };

    final signature = _buildSignature(
      userId: userId,
      role: role,
      leadMinutes: leadMinutes,
      plans: plans,
    );
    final prefs = await SupabaseCore.ensurePrefs();
    final signatureKey = _signatureKey(userId);
    final previousSignature = prefs.getString(signatureKey);
    if (previousSignature == signature) {
      return;
    }

    await LocalNotificationService.cancelClassReminders();
    for (final plan in plans) {
      await LocalNotificationService.scheduleClassReminder(
        reminderKey: plan.reminderKey,
        classStartAt: plan.classStartAt,
        leadMinutes: leadMinutes,
        courseCode: plan.courseCode,
        courseTitle: plan.courseTitle,
        room: plan.room,
        isTeacher: plan.isTeacher,
        section: plan.section,
      );
    }
    await prefs.setString(signatureKey, signature);
  }

  static Future<List<_ClassReminderPlan>> _buildStudentPlans(
    int leadMinutes,
  ) async {
    try {
      final now = DateTime.now();
      final result = await ScheduleService.fetchClassSchedule();
      final schedules = result['schedules'] as List<ClassSchedule>? ?? [];
      final plans = <_ClassReminderPlan>[];

      for (int offset = 0; offset < _scheduleDays; offset++) {
        final date = now.add(Duration(days: offset));
        final dow = date.weekday % 7; // Sun=0..Sat=6

        for (final slot in schedules) {
          if (slot.isExam) continue; // handled by ExamReminderService
          if (slot.dayOfWeek != dow) continue;

          final classStartAt = _dateWithTime(date, slot.startTime);
          if (!classStartAt.isAfter(now)) continue;
          if (!classStartAt
              .subtract(Duration(minutes: leadMinutes))
              .isAfter(now)) {
            continue;
          }

          plans.add(
            _ClassReminderPlan(
              reminderKey: 'student|${slot.id}|${_dateKey(date)}',
              classStartAt: classStartAt,
              courseCode: slot.courseCode,
              courseTitle: slot.courseName,
              room: slot.room,
              isTeacher: false,
              section: slot.section,
            ),
          );
        }
      }

      plans.sort((a, b) => a.classStartAt.compareTo(b.classStartAt));
      return plans;
    } catch (e) {
      debugPrint('[ClassReminderService] _buildStudentPlans error: $e');
      return [];
    }
  }

  static Future<List<_ClassReminderPlan>> _buildTeacherPlans(
    int leadMinutes,
  ) async {
    try {
      final now = DateTime.now();
      final plans = <_ClassReminderPlan>[];

      for (int offset = 0; offset < _scheduleDays; offset++) {
        final date = now.add(Duration(days: offset));
        final slots =
            await TeacherScheduleService.fetchEffectiveScheduleForDate(date);

        for (final slot in slots) {
          final classStartAt = _dateWithTime(date, slot.startTime);
          if (!classStartAt.isAfter(now)) continue;
          if (!classStartAt
              .subtract(Duration(minutes: leadMinutes))
              .isAfter(now)) {
            continue;
          }

          plans.add(
            _ClassReminderPlan(
              reminderKey: 'teacher|${slot.id}|${_dateKey(date)}',
              classStartAt: classStartAt,
              courseCode: slot.courseCode,
              courseTitle: slot.courseTitle,
              room: slot.displayRoomNumber,
              isTeacher: true,
              section: slot.section,
            ),
          );
        }
      }

      plans.sort((a, b) => a.classStartAt.compareTo(b.classStartAt));
      return plans;
    } catch (e) {
      debugPrint('[ClassReminderService] _buildTeacherPlans error: $e');
      return [];
    }
  }

  static String _buildSignature({
    required String userId,
    required String role,
    required int leadMinutes,
    required List<_ClassReminderPlan> plans,
  }) {
    final buffer = StringBuffer()
      ..write(userId)
      ..write('|')
      ..write(role)
      ..write('|')
      ..write(leadMinutes)
      ..write('|')
      ..write(plans.length);

    for (final plan in plans) {
      buffer
        ..write('|')
        ..write(plan.reminderKey)
        ..write('@')
        ..write(plan.classStartAt.toIso8601String())
        ..write('@')
        ..write(plan.courseCode)
        ..write('@')
        ..write(plan.room)
        ..write('@')
        ..write(plan.section ?? '');
    }

    return 'v2:${_stableHash(buffer.toString())}';
  }

  static String _signatureKey(String userId) => '$_signatureKeyPrefix$userId';

  static String _stableHash(String input) {
    var hash = 0;
    for (final rune in input.runes) {
      hash = ((hash * 31) + rune) & 0x7fffffff;
    }
    return hash.toRadixString(16);
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

class _ClassReminderPlan {
  final String reminderKey;
  final DateTime classStartAt;
  final String courseCode;
  final String courseTitle;
  final String room;
  final bool isTeacher;
  final String? section;

  const _ClassReminderPlan({
    required this.reminderKey,
    required this.classStartAt,
    required this.courseCode,
    required this.courseTitle,
    required this.room,
    required this.isTeacher,
    required this.section,
  });
}
