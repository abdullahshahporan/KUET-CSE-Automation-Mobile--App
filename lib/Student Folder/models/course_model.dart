/// Course model for KUET CSE Automation App
/// Supports both static data and Supabase-fetched data
class Course {
  final String? id;
  final String code;
  final String title;
  final double credits;
  final CourseType type;
  final List<String> teachers;
  final int year;
  final int term;
  final String? description;
  final bool isElective;
  final String? session;
  final String? batch;

  const Course({
    this.id,
    required this.code,
    required this.title,
    required this.credits,
    required this.type,
    required this.teachers,
    required this.year,
    required this.term,
    this.description,
    this.isElective = false,
    this.session,
    this.batch,
  });

  /// Create a Course from Supabase curriculum + course + offering data
  factory Course.fromSupabase(Map<String, dynamic> json) {
    final courseData = json['courses'] as Map<String, dynamic>? ?? json;
    final term = json['term'] as String? ?? '1-1';
    final parts = term.split('-');
    final year = int.tryParse(parts[0]) ?? 1;
    final termNum = int.tryParse(parts.length > 1 ? parts[1] : '1') ?? 1;

    // Parse course type
    final courseTypeStr =
        (courseData['course_type'] as String? ?? 'Theory').toLowerCase();
    final courseType =
        courseTypeStr == 'lab' ? CourseType.lab : CourseType.theory;

    // Parse teachers from course_offerings
    final teachers = <String>[];
    final offerings = json['course_offerings'] as List<dynamic>?;
    if (offerings != null) {
      for (final offering in offerings) {
        final offeringMap = offering as Map<String, dynamic>;
        final teacher = offeringMap['teachers'] as Map<String, dynamic>?;
        if (teacher != null) {
          final name = teacher['full_name'] as String?;
          if (name != null && !teachers.contains(name)) {
            teachers.add(name);
          }
        }
      }
    }

    return Course(
      id: (courseData['id'] ?? '').toString(),
      code: courseData['code'] as String? ?? '',
      title: courseData['title'] as String? ?? '',
      credits: (courseData['credit'] as num?)?.toDouble() ?? 0.0,
      type: courseType,
      teachers: teachers,
      year: year,
      term: termNum,
      description: courseData['description'] as String?,
      isElective: json['is_elective'] as bool? ?? false,
      session: _extractSession(offerings),
      batch: _extractBatch(offerings),
    );
  }

  static String? _extractSession(List<dynamic>? offerings) {
    if (offerings == null || offerings.isEmpty) return null;
    final first = offerings.first as Map<String, dynamic>;
    return first['session'] as String?;
  }

  static String? _extractBatch(List<dynamic>? offerings) {
    if (offerings == null || offerings.isEmpty) return null;
    final first = offerings.first as Map<String, dynamic>;
    return first['batch'] as String?;
  }

  /// Returns formatted credits string like "3.0 Credits"
  String get creditsString =>
      '${credits.toStringAsFixed(credits.truncateToDouble() == credits ? 0 : 1)} Credit${credits > 1 ? 's' : ''}';

  /// Returns type badge text
  String get typeBadge => type == CourseType.theory ? 'Theory' : 'Lab';
}

enum CourseType { theory, lab }
