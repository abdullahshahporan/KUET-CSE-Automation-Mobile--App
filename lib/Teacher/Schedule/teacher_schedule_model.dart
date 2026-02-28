import '../../utils/time_utils.dart';

/// Data model for a single teacher routine slot.
class TeacherSlot {
  final String id;
  final String offeringId;
  final String courseCode;
  final String courseTitle;
  final String roomNumber;
  final int dayOfWeek; // 0=Sun … 6=Sat
  final String startTime; // HH:mm:ss
  final String endTime;
  final String? section;
  final String courseType; // Theory / Lab

  TeacherSlot({
    required this.id,
    required this.offeringId,
    required this.courseCode,
    required this.courseTitle,
    required this.roomNumber,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.section,
    this.courseType = 'Theory',
  });

  factory TeacherSlot.fromMap(Map<String, dynamic> m) {
    final offering = m['course_offerings'] as Map<String, dynamic>? ?? {};
    final course = offering['courses'] as Map<String, dynamic>? ?? {};

    return TeacherSlot(
      id: m['id'] as String,
      offeringId: m['offering_id'] as String,
      courseCode: course['code'] as String? ?? '',
      courseTitle: course['title'] as String? ?? '',
      roomNumber: m['room_number'] as String? ?? '',
      dayOfWeek: m['day_of_week'] as int? ?? 0,
      startTime: m['start_time'] as String? ?? '',
      endTime: m['end_time'] as String? ?? '',
      section: m['section'] as String?,
      courseType: course['course_type'] as String? ?? 'Theory',
    );
  }

  /// e.g. "09:00 - 10:00"
  String get timeRange => TimeUtils.timeRange(startTime, endTime);

  String get dayName => TimeUtils.dayName(dayOfWeek);

  /// Backward-compatible static accessor for day names list.
  static List<String> get dayNames => TimeUtils.dayNames;
}
