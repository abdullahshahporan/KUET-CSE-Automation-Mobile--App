// Notice, Assignment models
// Schedule models are in Home/Features/Schedule folder
// AttendanceRecord is in attendance_model.dart — re-exported here for convenience
export 'attendance_model.dart' show AttendanceRecord;

class Notice {
  final String id;
  final String title;
  final String description;
  final String date;
  final String category;
  final bool isImportant;

  Notice({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.category,
    required this.isImportant,
  });
}

class Assignment {
  final String id;
  final String title;
  final String courseName;
  final String description;
  final String deadline;
  final String status; // pending, submitted, overdue
  final int marks;

  Assignment({
    required this.id,
    required this.title,
    required this.courseName,
    required this.description,
    required this.deadline,
    required this.status,
    required this.marks,
  });
}
