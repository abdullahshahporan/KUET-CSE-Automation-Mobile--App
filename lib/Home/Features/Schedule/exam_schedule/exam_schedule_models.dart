class ExamSchedule {
  final String courseName;
  final String courseCode;
  final String examType;
  final String category; // CT, Term Final, Quiz/Viva
  final String date;
  final String time;
  final String room;
  final String syllabus;

  ExamSchedule({
    required this.courseName,
    required this.courseCode,
    required this.examType,
    required this.category,
    required this.date,
    required this.time,
    required this.room,
    required this.syllabus,
  });
}
