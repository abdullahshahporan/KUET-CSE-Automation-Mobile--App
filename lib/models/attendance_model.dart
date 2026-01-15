/// Attendance model for KUET CSE Automation App
class AttendanceRecord {
  final String courseCode;
  final String courseName;
  final int totalClasses;
  final int attendedClasses;

  const AttendanceRecord({
    required this.courseCode,
    required this.courseName,
    required this.totalClasses,
    required this.attendedClasses,
  });

  /// Calculate attendance percentage
  double get percentage => totalClasses > 0 ? (attendedClasses / totalClasses) * 100 : 0;

  /// Get attendance status based on percentage
  AttendanceStatus get status {
    if (percentage >= 80) return AttendanceStatus.safe;
    if (percentage >= 70) return AttendanceStatus.acceptable;
    if (percentage >= 60) return AttendanceStatus.edging;
    return AttendanceStatus.alarming;
  }

  /// Get status message
  String get statusMessage {
    switch (status) {
      case AttendanceStatus.safe:
        return 'Safe';
      case AttendanceStatus.acceptable:
        return 'Acceptable';
      case AttendanceStatus.edging:
        return 'Edging';
      case AttendanceStatus.alarming:
        return 'Cannot sit in Term Final!';
    }
  }
}

enum AttendanceStatus {
  safe,       // >= 80%
  acceptable, // 70-80%
  edging,     // 60-70%
  alarming,   // < 60%
}
