/// Course model for KUET CSE Automation App
class Course {
  final String code;
  final String title;
  final double credits;
  final CourseType type;
  final List<String> teachers;
  final int year;
  final int term;

  const Course({
    required this.code,
    required this.title,
    required this.credits,
    required this.type,
    required this.teachers,
    required this.year,
    required this.term,
  });

  /// Returns formatted credits string like "3.0 Credits"
  String get creditsString =>
      '${credits.toStringAsFixed(credits.truncateToDouble() == credits ? 0 : 1)} Credit${credits > 1 ? 's' : ''}';

  /// Returns type badge text
  String get typeBadge => type == CourseType.theory ? 'Theory' : 'Lab';
}

enum CourseType { theory, lab }
