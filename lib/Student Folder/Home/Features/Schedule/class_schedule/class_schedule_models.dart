import '../../../../../utils/time_utils.dart';

/// Model for a class schedule slot fetched from Supabase routine_slots
class ClassSchedule {
  final String id;
  final String courseName;
  final String courseCode;
  final String teacher;
  final String room;
  final String time;
  final String day;
  final String startTime;
  final String endTime;
  final int dayOfWeek;
  final String? section;

  ClassSchedule({
    this.id = '',
    required this.courseName,
    required this.courseCode,
    required this.teacher,
    required this.room,
    required this.time,
    required this.day,
    this.startTime = '',
    this.endTime = '',
    this.dayOfWeek = 0,
    this.section,
  });

  /// Create from Supabase routine_slots joined data
  factory ClassSchedule.fromSupabase(Map<String, dynamic> json) {
    final offering = json['course_offerings'] as Map<String, dynamic>? ?? {};
    final course = offering['courses'] as Map<String, dynamic>? ?? {};
    final teacher = offering['teachers'] as Map<String, dynamic>? ?? {};

    final startTime = json['start_time'] as String? ?? '00:00:00';
    final endTime = json['end_time'] as String? ?? '00:00:00';
    final dayOfWeek = json['day_of_week'] as int? ?? 0;
    final roomNumber = json['room_number'] as String? ?? 'TBA';

    return ClassSchedule(
      id: (json['id'] ?? '').toString(),
      courseName: course['title'] as String? ?? 'Unknown Course',
      courseCode: course['code'] as String? ?? '',
      teacher: teacher['full_name'] as String? ?? 'TBA',
      room: roomNumber,
      startTime: startTime,
      endTime: endTime,
      time: TimeUtils.timeRange12h(startTime, endTime),
      day: TimeUtils.dayName(dayOfWeek),
      dayOfWeek: dayOfWeek,
      section: json['section'] as String?,
    );
  }
}
