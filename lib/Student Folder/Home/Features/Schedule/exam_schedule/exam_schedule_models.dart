import 'package:intl/intl.dart';

/// Model for exam schedule fetched from Supabase exams table
class ExamSchedule {
  final String id;
  final String courseName;
  final String courseCode;
  final String examType;
  final String category; // CT, Term Final, Quiz/Viva
  final String date;
  final String time;
  final String room;
  final String syllabus;
  final double maxMarks;
  final int? durationMinutes;

  ExamSchedule({
    this.id = '',
    required this.courseName,
    required this.courseCode,
    required this.examType,
    required this.category,
    required this.date,
    required this.time,
    required this.room,
    required this.syllabus,
    this.maxMarks = 0,
    this.durationMinutes,
  });

  /// Create from Supabase exams joined data
  factory ExamSchedule.fromSupabase(Map<String, dynamic> json) {
    final offering = json['course_offerings'] as Map<String, dynamic>? ?? {};
    final course = offering['courses'] as Map<String, dynamic>? ?? {};

    final examType = json['exam_type'] as String? ?? 'CT';
    final examName = json['name'] as String? ?? '';
    final examDate = json['exam_date'] as String?;
    final examTime = json['exam_time'] as String?;
    final maxMarks = (json['max_marks'] as num?)?.toDouble() ?? 0;
    final durationMinutes = json['duration_minutes'] as int?;
    final roomNumbers = json['room_numbers'] as List<dynamic>?;

    // Map exam_type enum to display category
    String category;
    switch (examType.toUpperCase()) {
      case 'CT':
      case 'CLASS_TEST':
        category = 'CT';
        break;
      case 'MID':
      case 'MIDTERM':
      case 'FINAL':
      case 'TERM_FINAL':
        category = 'Term Final';
        break;
      case 'QUIZ':
      case 'VIVA':
      case 'QUIZ_VIVA':
        category = 'Quiz/Viva';
        break;
      default:
        category = 'CT';
    }

    // Format date
    String formattedDate = 'TBA';
    if (examDate != null) {
      try {
        final parsed = DateTime.parse(examDate);
        formattedDate = DateFormat('MMMM d, yyyy').format(parsed);
      } catch (_) {
        formattedDate = examDate;
      }
    }

    // Format time
    String formattedTime = 'TBA';
    if (examTime != null) {
      formattedTime = _formatTime(examTime);
      if (durationMinutes != null) {
        try {
          final parts = examTime.split(':');
          final startHour = int.parse(parts[0]);
          final startMin = int.parse(parts[1]);
          final endMinutes = startHour * 60 + startMin + durationMinutes;
          final endHour = endMinutes ~/ 60;
          final endMin = endMinutes % 60;
          final endTimeStr =
              '${endHour.toString().padLeft(2, '0')}:${endMin.toString().padLeft(2, '0')}';
          formattedTime = '${_formatTime(examTime)} - ${_formatTime(endTimeStr)}';
        } catch (_) {}
      }
    }

    // Format rooms
    String roomStr = 'TBA';
    if (roomNumbers != null && roomNumbers.isNotEmpty) {
      roomStr = roomNumbers.join(', ');
    }

    return ExamSchedule(
      id: (json['id'] ?? '').toString(),
      courseName: course['title'] as String? ?? 'Unknown Course',
      courseCode: course['code'] as String? ?? '',
      examType: examName.isNotEmpty ? examName : examType,
      category: category,
      date: formattedDate,
      time: formattedTime,
      room: roomStr,
      syllabus: examName,
      maxMarks: maxMarks,
      durationMinutes: durationMinutes,
    );
  }

  static String _formatTime(String time24) {
    try {
      final parts = time24.split(':');
      int hour = int.parse(parts[0]);
      final min = parts.length > 1 ? parts[1] : '00';
      final amPm = hour >= 12 ? 'PM' : 'AM';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      return '$hour:$min $amPm';
    } catch (_) {
      return time24;
    }
  }
}
