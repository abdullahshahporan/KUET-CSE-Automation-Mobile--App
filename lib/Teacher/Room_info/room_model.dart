import '../../utils/time_utils.dart';

/// Data model for a room from the `rooms` table.
class Room {
  final String roomNumber;
  final String? buildingName;
  final int capacity;
  final String roomType;
  final List<String> facilities;
  final bool isActive;

  Room({
    required this.roomNumber,
    this.buildingName,
    required this.capacity,
    required this.roomType,
    this.facilities = const [],
    this.isActive = true,
  });

  factory Room.fromMap(Map<String, dynamic> m) => Room(
        roomNumber: m['room_number'] as String,
        buildingName: m['building_name'] as String?,
        capacity: m['capacity'] as int? ?? 0,
        roomType: m['room_type'] as String? ?? 'Classroom',
        facilities: List<String>.from(m['facilities'] ?? []),
        isActive: m['is_active'] as bool? ?? true,
      );

  bool get isLab =>
      roomType.toLowerCase().contains('lab') ||
      roomType.toLowerCase().contains('computer');

  IconLabel get typeLabel {
    final lower = roomType.toLowerCase();
    if (lower.contains('lab') || lower.contains('computer')) {
      return IconLabel.lab;
    } else if (lower.contains('seminar') || lower.contains('conference')) {
      return IconLabel.seminar;
    } else if (lower.contains('research')) {
      return IconLabel.research;
    }
    return IconLabel.classroom;
  }
}

enum IconLabel { classroom, lab, seminar, research }

/// A single booked slot in a room (from routine_slots + course_offerings + courses + teachers).
class RoomSlot {
  final String id;
  final String courseCode;
  final String courseTitle;
  final String courseType;
  final String teacherName;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final String? section;

  RoomSlot({
    required this.id,
    required this.courseCode,
    required this.courseTitle,
    required this.courseType,
    required this.teacherName,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.section,
  });

  factory RoomSlot.fromMap(Map<String, dynamic> m) {
    final offering = m['course_offerings'] as Map<String, dynamic>? ?? {};
    final course = offering['courses'] as Map<String, dynamic>? ?? {};
    final teacher = offering['teachers'] as Map<String, dynamic>? ?? {};

    return RoomSlot(
      id: m['id'] as String,
      courseCode: course['code'] as String? ?? '',
      courseTitle: course['title'] as String? ?? '',
      courseType: course['course_type'] as String? ?? 'Theory',
      teacherName: teacher['full_name'] as String? ?? 'Unknown',
      dayOfWeek: m['day_of_week'] as int? ?? 0,
      startTime: m['start_time'] as String? ?? '',
      endTime: m['end_time'] as String? ?? '',
      section: m['section'] as String?,
    );
  }

  /// e.g. "09:00 - 10:00"
  String get timeRange => TimeUtils.timeRange(startTime, endTime);

  String get dayName => TimeUtils.dayName(dayOfWeek);

  /// Backward-compatible static accessor for day names list.
  static List<String> get dayNames => TimeUtils.dayNames;
}
class Period {
  final String label; // e.g. "P1"
  final String start; // e.g. "08:00"
  final String end;   // e.g. "08:50"
  final bool isCustom; // true for custom break-time slots

  const Period(this.label, this.start, this.end, {this.isCustom = false});

  /// Full display: e.g. "P1  8:00-8:50"
  String get display => '$label  ${TimeUtils.formatTime12h(start)}-${TimeUtils.formatTime12h(end)}';

  /// Short form for dropdowns: e.g. "P1  8:00"
  String get shortDisplay => '$label  ${TimeUtils.formatTime12h(start)}';

  /// Backward-compatible static method for 12h time format.
  static String to12h(String time24) => TimeUtils.formatTime12h(time24);

  /// KUET standard 9-period timetable.
  static const all = [
    Period('P1', '08:00', '08:50'),
    Period('P2', '08:50', '09:40'),
    Period('P3', '09:40', '10:30'),
    Period('P4', '10:40', '11:30'),
    Period('P5', '11:30', '12:20'),
    Period('P6', '12:20', '13:10'),
    Period('P7', '14:30', '15:20'),
    Period('P8', '15:20', '16:10'),
    Period('P9', '16:10', '17:00'),
  ];
}
