import 'package:flutter/foundation.dart';
import '../../../services/supabase_service.dart';
import '../../Home/Features/Schedule/class_schedule/class_schedule_models.dart';
import '../../Home/Features/Schedule/class_schedule/class_schedule_providers.dart';

/// Lightweight model for an upcoming class item displayed on the home screen.
class UpcomingClass {
  final String courseCode;
  final String courseTitle;
  final String teacher;
  final String room;
  final String time; // formatted "10:00 AM - 11:00 AM"
  final String startTime; // raw "10:00:00"
  final int dayOfWeek;
  final String? section;
  final bool isOngoing;

  const UpcomingClass({
    required this.courseCode,
    required this.courseTitle,
    required this.teacher,
    required this.room,
    required this.time,
    required this.startTime,
    required this.dayOfWeek,
    this.section,
    this.isOngoing = false,
  });

  /// Build from the existing [ClassSchedule] model.
  factory UpcomingClass.fromClassSchedule(ClassSchedule s,
      {bool isOngoing = false}) {
    return UpcomingClass(
      courseCode: s.courseCode,
      courseTitle: s.courseName,
      teacher: s.teacher,
      room: s.room,
      time: s.time,
      startTime: s.startTime,
      dayOfWeek: s.dayOfWeek,
      section: s.section,
      isOngoing: isOngoing,
    );
  }
}

/// Service that reuses [ScheduleService.fetchClassSchedule] and filters
/// to today's remaining + next-day classes for the home "Upcoming" section.
class UpcomingScheduleService {
  /// Returns a map with:
  ///   `'today'`    → `List<UpcomingClass>` (remaining today, sorted by time)
  ///   `'tomorrow'` → `List<UpcomingClass>` (full next-class-day schedule)
  ///   `'dayLabel'` → `String` label for tomorrow section (e.g. "Tomorrow" or "Saturday")
  static Future<Map<String, dynamic>> getUpcoming() async {
    try {
      final result = await ScheduleService.fetchClassSchedule();
      final schedules = result['schedules'] as List<ClassSchedule>? ?? [];

      if (schedules.isEmpty) {
        debugPrint('[Upcoming] No schedules at all');
        return _empty();
      }

      final now = DateTime.now();
      // Sunday=0 .. Saturday=6 in our DB convention (matching ClassSchedule)
      final todayDow = now.weekday % 7; // DateTime: Mon=1..Sun=7 → Sun=0..Sat=6

      final nowMinutes = now.hour * 60 + now.minute;

      // --- Today's classes ---
      final todaySlots = schedules.where((s) => s.dayOfWeek == todayDow).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

      final todayUpcoming = <UpcomingClass>[];
      for (final s in todaySlots) {
        final startMin = _parseMinutes(s.startTime);
        final endMin = _parseMinutes(s.endTime);

        if (endMin <= nowMinutes) continue; // already finished

        final ongoing = startMin <= nowMinutes && nowMinutes < endMin;
        todayUpcoming.add(UpcomingClass.fromClassSchedule(s, isOngoing: ongoing));
      }

      // --- Next class day ---
      // Find the next DOW that has classes (skip empty days & Friday)
      String dayLabel = 'Tomorrow';
      List<UpcomingClass> nextDayClasses = [];

      for (int offset = 1; offset <= 7; offset++) {
        final nextDow = (todayDow + offset) % 7;
        final slots = schedules.where((s) => s.dayOfWeek == nextDow).toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

        if (slots.isNotEmpty) {
          nextDayClasses =
              slots.map((s) => UpcomingClass.fromClassSchedule(s)).toList();
          dayLabel = offset == 1
              ? 'Tomorrow'
              : _dayName(nextDow);
          break;
        }
      }

      debugPrint(
          '[Upcoming] today=${todayUpcoming.length}, next=$dayLabel(${nextDayClasses.length})');

      return {
        'today': todayUpcoming,
        'tomorrow': nextDayClasses,
        'dayLabel': dayLabel,
      };
    } catch (e) {
      debugPrint('[Upcoming] ERROR: $e');
      return _empty();
    }
  }

  static Map<String, dynamic> _empty() => {
        'today': <UpcomingClass>[],
        'tomorrow': <UpcomingClass>[],
        'dayLabel': 'Tomorrow',
      };

  /// Parse "HH:MM:SS" → total minutes since midnight.
  static int _parseMinutes(String time) {
    try {
      final parts = time.split(':');
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    } catch (_) {
      return 0;
    }
  }

  static String _dayName(int dow) {
    const days = [
      'Sunday', 'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday',
    ];
    return (dow >= 0 && dow < 7) ? days[dow] : 'Unknown';
  }
}
