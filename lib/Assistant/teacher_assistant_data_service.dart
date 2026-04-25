import '../Teacher/Schedule/teacher_schedule_model.dart';
import '../Teacher/Schedule/teacher_schedule_service.dart';
import '../services/supabase_service.dart';

enum TeacherAssistantIntent {
  assignedCourses,
  todaySchedule,
  tomorrowSchedule,
  nextClass,
  nextWeekSchedule,
  weeklySchedule,
}

class TeacherAssistantDataService {
  TeacherAssistantDataService._();

  static TeacherAssistantIntent? detectIntent(String message) {
    final text = message.toLowerCase();

    if (RegExp(
      r'\b(next|upcoming|nearest)\s+(class|lecture|period)\b',
    ).hasMatch(text)) {
      return TeacherAssistantIntent.nextClass;
    }
    if (text.contains('tomorrow') && _hasScheduleWord(text)) {
      return TeacherAssistantIntent.tomorrowSchedule;
    }
    if (RegExp(r'\bnext\s+week\b|\bupcoming\s+week\b').hasMatch(text) &&
        _hasScheduleWord(text)) {
      return TeacherAssistantIntent.nextWeekSchedule;
    }
    if (RegExp(
          r'\b(full|all|complete|weekly|week)\s+(class\s+)?(schedule|routine|timetable)\b',
        ).hasMatch(text) ||
        RegExp(
          r'\b(schedule|routine|timetable)\s+(for\s+)?(this\s+)?(full\s+)?week\b',
        ).hasMatch(text)) {
      return TeacherAssistantIntent.weeklySchedule;
    }
    if (RegExp(r"\btoday'?s?\b").hasMatch(text) && _hasScheduleWord(text)) {
      return TeacherAssistantIntent.todaySchedule;
    }
    if (_hasAssignedCourseIntent(text)) {
      return TeacherAssistantIntent.assignedCourses;
    }
    if (RegExp(r'\bmy\s+(schedule|routine|timetable)\b').hasMatch(text)) {
      return TeacherAssistantIntent.weeklySchedule;
    }

    return null;
  }

  static Future<String> answer(TeacherAssistantIntent intent) async {
    switch (intent) {
      case TeacherAssistantIntent.assignedCourses:
        return _assignedCoursesAnswer();
      case TeacherAssistantIntent.todaySchedule:
        return _scheduleForDateAnswer(DateTime.now(), 'today');
      case TeacherAssistantIntent.tomorrowSchedule:
        return _scheduleForDateAnswer(
          DateTime.now().add(const Duration(days: 1)),
          'tomorrow',
        );
      case TeacherAssistantIntent.nextClass:
        return _nextClassAnswer();
      case TeacherAssistantIntent.nextWeekSchedule:
        return _nextWeekScheduleAnswer();
      case TeacherAssistantIntent.weeklySchedule:
        return _weeklyScheduleAnswer();
    }
  }

  static bool _hasScheduleWord(String text) {
    return RegExp(
      r'\b(schedule|routine|timetable|class|classes|room|period|lecture)\b',
    ).hasMatch(text);
  }

  static bool _hasAssignedCourseIntent(String text) {
    return RegExp(
          r'\b(my\s+)?assigned\s+courses?\b|\bcourses?\s+assigned\b|\bwhich\s+courses?\b|\bwhat\s+courses?\b|\bmy\s+courses?\b',
        ).hasMatch(text) ||
        RegExp(
          r'\bassigned\s+subjects?\b|\bsubjects?\s+assigned\b|\bcurrent\s+courses?\b',
        ).hasMatch(text) ||
        RegExp(
          r'\bcourses?\s+(am\s+i\s+)?(teaching|taking|assigned)\b',
        ).hasMatch(text);
  }

  static Future<String> _assignedCoursesAnswer() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return 'Please sign in to view assigned courses.';

    final data = await SupabaseService.client
        .from('course_offerings')
        .select('''
          id, term, session, batch,
          courses ( code, title, credit, course_type )
        ''')
        .eq('teacher_user_id', userId)
        .eq('is_active', true)
        .order('term');

    final offerings = (data as List).cast<Map<String, dynamic>>();
    if (offerings.isEmpty) {
      return 'No active course assignments were found for you right now.';
    }

    final lines = <String>['Your active assigned courses:'];
    for (var i = 0; i < offerings.length; i += 1) {
      final offering = offerings[i];
      final course = offering['courses'] as Map<String, dynamic>? ?? {};
      final code = (course['code'] ?? 'Course').toString();
      final title = (course['title'] ?? '').toString().trim();
      final credit = course['credit'] != null
          ? ', ${course['credit']} credit'
          : '';
      final type = (course['course_type'] ?? '').toString().trim();
      final term = (offering['term'] ?? 'N/A').toString();
      final session = (offering['session'] ?? '').toString().trim();

      lines.add(
        '${i + 1}. $code${title.isNotEmpty ? ' - $title' : ''} '
        '(Term: $term'
        '${session.isNotEmpty ? ', Session: $session' : ''}'
        '$credit'
        '${type.isNotEmpty ? ', $type' : ''})',
      );
    }

    return lines.join('\n');
  }

  static Future<String> _scheduleForDateAnswer(
    DateTime date,
    String label,
  ) async {
    final slots = await TeacherScheduleService.fetchEffectiveScheduleForDate(
      date,
    );
    final dateText = _dateKey(date);
    final dayName = TeacherSlot.dayNames[_dayIndex(date)];

    if (slots.isEmpty) {
      return 'You have no scheduled classes for $label ($dayName, $dateText).';
    }

    return [
      'Your schedule for $label ($dayName, $dateText):',
      ...slots.map(_formatSlot),
    ].join('\n');
  }

  static Future<String> _weeklyScheduleAnswer() async {
    final grouped = await TeacherScheduleService.fetchSchedule();
    if (grouped.isEmpty) return 'No weekly schedule slots were found for you.';

    final lines = <String>['Your weekly schedule:'];
    for (
      var dayIndex = 0;
      dayIndex < TeacherSlot.dayNames.length;
      dayIndex += 1
    ) {
      final slots = grouped[dayIndex] ?? [];
      if (slots.isEmpty) continue;

      lines.add('${TeacherSlot.dayNames[dayIndex]}:');
      lines.addAll(slots.map((slot) => '- ${_formatSlot(slot)}'));
    }

    return lines.join('\n');
  }

  static Future<String> _nextWeekScheduleAnswer() async {
    final today = DateTime.now();
    final todayDayIndex = _dayIndex(today);
    final daysUntilNextSunday = todayDayIndex == 0 ? 7 : 7 - todayDayIndex;
    final start = DateTime(
      today.year,
      today.month,
      today.day,
    ).add(Duration(days: daysUntilNextSunday));
    final end = start.add(const Duration(days: 6));
    final lines = <String>[
      'Your next week schedule (${_dateKey(start)} to ${_dateKey(end)}):',
    ];

    for (var offset = 0; offset < 7; offset += 1) {
      final date = start.add(Duration(days: offset));
      final slots = await TeacherScheduleService.fetchEffectiveScheduleForDate(
        date,
      );
      if (slots.isEmpty) continue;

      lines.add('${TeacherSlot.dayNames[_dayIndex(date)]}, ${_dateKey(date)}:');
      lines.addAll(slots.map((slot) => '- ${_formatSlot(slot)}'));
    }

    if (lines.length == 1) {
      return 'No scheduled classes were found for next week (${_dateKey(start)} to ${_dateKey(end)}).';
    }

    return lines.join('\n');
  }

  static Future<String> _nextClassAnswer() async {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    for (var offset = 0; offset < 14; offset += 1) {
      final date = now.add(Duration(days: offset));
      final slots = await TeacherScheduleService.fetchEffectiveScheduleForDate(
        date,
      );
      final upcoming = slots.where((slot) {
        if (offset > 0) return true;
        return _timeToMinutes(slot.startTime) >= currentMinutes;
      }).toList();

      if (upcoming.isNotEmpty) {
        return 'Your next class is on ${TeacherSlot.dayNames[_dayIndex(date)]}, ${_dateKey(date)}:\n${_formatSlot(upcoming.first)}';
      }
    }

    return 'No upcoming class was found in the next 14 days.';
  }

  static String _formatSlot(TeacherSlot slot) {
    final room = slot.roomNumber.trim().isEmpty
        ? 'Not assigned'
        : slot.roomNumber.trim();
    final section = slot.section?.trim().isNotEmpty == true
        ? ', Section ${slot.section!.trim()}'
        : '';
    final title = slot.courseTitle.trim().isNotEmpty
        ? ' (${slot.courseTitle.trim()})'
        : '';
    return '${slot.timeRange} : ${slot.courseCode}$title room No.: $room$section';
  }

  static int _dayIndex(DateTime date) {
    return date.weekday == DateTime.sunday ? 0 : date.weekday;
  }

  static int _timeToMinutes(String value) {
    final parts = value.split(':');
    final hour = int.tryParse(parts.isNotEmpty ? parts[0] : '0') ?? 0;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    return hour * 60 + minute;
  }

  static String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
