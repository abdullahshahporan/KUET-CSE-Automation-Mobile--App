import '../../Student Folder/models/course_model.dart';

/// Extended course model for teacher with semester info.
///
/// Constructed from Supabase data in [teacher_home_content.dart].
class TeacherCourse {
  final String code;
  final String title;
  final double credits;
  final CourseType type;
  final int year;
  final int term;
  final int expectedClasses;
  final List<String> sections; // For theory: ['A', 'B']
  final List<String> groups; // For sessional: ['A1', 'A2', 'B1', 'B2']
  final List<String> teachers;
  final String? offeringId; // Supabase course_offerings.id
  final String? session; // Supabase course_offerings.session

  const TeacherCourse({
    required this.code,
    required this.title,
    required this.credits,
    required this.type,
    required this.year,
    required this.term,
    required this.expectedClasses,
    this.sections = const [],
    this.groups = const [],
    this.teachers = const [],
    this.offeringId,
    this.session,
  });

  String get semesterName {
    final yearSuffix = year == 1
        ? 'st'
        : year == 2
            ? 'nd'
            : year == 3
                ? 'rd'
                : 'th';
    final termSuffix = term == 1 ? 'st' : 'nd';
    return '$year-$term ($year$yearSuffix Year $term$termSuffix Term)';
  }

  String get shortSemester => '$year-$term';

  String get creditsString =>
      '${credits.toStringAsFixed(credits == credits.roundToDouble() ? 0 : 1)} Credits';

  /// Get batch roll prefix based on year (assuming current year is 2026)
  String get batchRollPrefix {
    final batchYear = 25 - year;
    return '2${batchYear.toString().padLeft(2, '0')}7';
  }
}
