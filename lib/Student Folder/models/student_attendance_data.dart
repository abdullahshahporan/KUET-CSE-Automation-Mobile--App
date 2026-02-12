/// Models for student attendance data fetched from Supabase.

/// Attendance summary for a single course (from the student's perspective).
class CourseAttendanceSummary {
  final String courseCode;
  final String courseTitle;
  final String courseType; // 'Theory' or 'Lab'
  final double credit;
  final String offeringId;
  final int totalSessions;
  final int presentCount;
  final int lateCount;
  final int absentCount;
  final List<SessionAttendanceEntry> sessions;

  const CourseAttendanceSummary({
    required this.courseCode,
    required this.courseTitle,
    required this.courseType,
    required this.credit,
    required this.offeringId,
    required this.totalSessions,
    required this.presentCount,
    required this.lateCount,
    required this.absentCount,
    required this.sessions,
  });

  /// Attended = present + late
  int get attendedCount => presentCount + lateCount;

  /// Percentage of classes attended (present + late)
  double get percentage =>
      totalSessions > 0 ? (attendedCount / totalSessions) * 100 : 0;

  /// Status category based on percentage thresholds
  AttendanceLevel get level {
    final p = percentage;
    if (p >= 80) return AttendanceLevel.safe;
    if (p >= 70) return AttendanceLevel.acceptable;
    if (p >= 60) return AttendanceLevel.edging;
    return AttendanceLevel.alarming;
  }

  /// Human-readable status label
  String get statusLabel {
    switch (level) {
      case AttendanceLevel.safe:
        return 'Safe';
      case AttendanceLevel.acceptable:
        return 'Acceptable';
      case AttendanceLevel.edging:
        return 'Edging';
      case AttendanceLevel.alarming:
        return 'Cannot sit in Term Final!';
    }
  }

  /// Calculate consecutive classes needed to reach [target]%
  int classesNeededFor(double target) {
    if (percentage >= target) return 0;
    int attended = attendedCount;
    int total = totalSessions;
    int needed = 0;
    while ((attended / total * 100) < target && needed < 200) {
      attended++;
      total++;
      needed++;
    }
    return needed;
  }
}

/// A single class-session attendance entry for detail/history views.
class SessionAttendanceEntry {
  final String sessionId;
  final DateTime date;
  final String status; // PRESENT, LATE, ABSENT
  final String? topic;
  final String? roomNumber;

  const SessionAttendanceEntry({
    required this.sessionId,
    required this.date,
    required this.status,
    this.topic,
    this.roomNumber,
  });

  bool get isPresent => status == 'PRESENT';
  bool get isLate => status == 'LATE';
  bool get isAbsent => status == 'ABSENT';

  String get displayStatus {
    switch (status) {
      case 'PRESENT':
        return 'Present';
      case 'LATE':
        return 'Late';
      default:
        return 'Absent';
    }
  }
}

/// Attendance health levels
enum AttendanceLevel { safe, acceptable, edging, alarming }
