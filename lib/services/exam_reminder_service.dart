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
  static const _signatureKeyPrefix = 'exam_reminder_signature_v2_';
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

    try {
      final List<ExamSchedule> exams;
      if (role == 'TEACHER') {
        exams = await _fetchTeacherExams(userId);
      } else {
        exams = await ExamScheduleService.fetchExamSchedule();
      }

      final now = DateTime.now();
      final plans = <_ExamReminderPlan>[];
      for (final exam in exams) {
        final examStartsAt = _parseExamDateTime(exam);
        if (examStartsAt == null || !examStartsAt.isAfter(now)) continue;
        if (!examStartsAt
            .subtract(Duration(minutes: leadMinutes))
            .isAfter(now)) {
          continue;
        }

        plans.add(
          _ExamReminderPlan(
            reminderKey: '${exam.id}|${_dateKey(examStartsAt)}',
            examStartsAt: examStartsAt,
            courseCode: exam.courseCode,
            examLabel: '${exam.examType} exam',
            room: exam.room,
          ),
        );
      }
      plans.sort((a, b) => a.examStartsAt.compareTo(b.examStartsAt));

      final signature = _buildSignature(
        userId: userId,
        role: role ?? '',
        leadMinutes: leadMinutes,
        plans: plans,
      );
      final prefs = await SupabaseCore.ensurePrefs();
      final signatureKey = _signatureKey(userId);
      final previousSignature = prefs.getString(signatureKey);
      if (previousSignature == signature) {
        return;
      }

      await LocalNotificationService.cancelExamReminders();
      for (final plan in plans) {
        await LocalNotificationService.scheduleExamReminder(
          reminderKey: plan.reminderKey,
          examStartsAt: plan.examStartsAt,
          leadMinutes: leadMinutes,
          courseCode: plan.courseCode,
          examLabel: plan.examLabel,
          room: plan.room,
        );
      }

      await prefs.setString(signatureKey, signature);
    } catch (e) {
      debugPrint('[ExamReminderService] syncUpcomingReminders error: $e');
    }
  }

  /// Fetch upcoming exams for a teacher based on their active course offerings.
  static Future<List<ExamSchedule>> _fetchTeacherExams(
    String teacherUserId,
  ) async {
    try {
      final response = await SupabaseCore.from('course_offerings')
          .select('''
          id, term,
          courses ( id, code, title, course_type ),
          exams (
            id, name, exam_type, max_marks, exam_date,
            exam_time, duration_minutes, room_numbers, created_at
          )
        ''')
          .eq('teacher_user_id', teacherUserId)
          .eq('is_active', true);

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

  static String _buildSignature({
    required String userId,
    required String role,
    required int leadMinutes,
    required List<_ExamReminderPlan> plans,
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
        ..write(plan.examStartsAt.toIso8601String())
        ..write('@')
        ..write(plan.courseCode)
        ..write('@')
        ..write(plan.room);
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
}

class _ExamReminderPlan {
  final String reminderKey;
  final DateTime examStartsAt;
  final String courseCode;
  final String examLabel;
  final String room;

  const _ExamReminderPlan({
    required this.reminderKey,
    required this.examStartsAt,
    required this.courseCode,
    required this.examLabel,
    required this.room,
  });
}
