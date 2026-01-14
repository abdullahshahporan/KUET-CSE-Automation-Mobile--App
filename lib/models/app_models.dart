// Notice, Assignment, and Attendance models
// Schedule models are in Home/Features/Schedule folder

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

class AttendanceRecord {
  final String courseCode;
  final String courseName;
  final int totalClasses;
  final int attendedClasses;
  final double percentage;

  AttendanceRecord({
    required this.courseCode,
    required this.courseName,
    required this.totalClasses,
    required this.attendedClasses,
    required this.percentage,
  });
}
