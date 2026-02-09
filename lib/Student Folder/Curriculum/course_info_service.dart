import '../../services/supabase_service.dart';
import '../models/course_model.dart';

/// Service for fetching course/curriculum data from Supabase
class CourseInfoService {
  /// Fetch courses for a given year-term from the curriculum table,
  /// joining courses and course_offerings (with assigned teachers).
  ///
  /// The query:
  ///   curriculum -> courses (code, title, credit, course_type, description)
  ///              -> course_offerings -> teachers (full_name)
  static Future<List<Course>> fetchCourses({
    required int year,
    required int term,
  }) async {
    try {
      final termStr = '$year-$term';

      // Query curriculum with nested joins:
      // curriculum -> courses -> course_offerings -> teachers
      final response = await SupabaseService.from('curriculum')
          .select('''
            id,
            term,
            is_elective,
            syllabus_year,
            course_id,
            courses (
              id,
              code,
              title,
              credit,
              course_type,
              description
            )
          ''')
          .eq('term', termStr)
          .order('created_at', ascending: true);

      final List<dynamic> data = response as List<dynamic>;

      if (data.isEmpty) return [];

      // Collect all course_ids to fetch offerings in one query
      final courseIds = data
          .map((item) => (item as Map<String, dynamic>)['course_id'] as String)
          .toSet()
          .toList();

      // Fetch all offerings for these courses with teacher info
      final offeringsResponse = await SupabaseService.from('course_offerings')
          .select('''
            id,
            course_id,
            teacher_user_id,
            term,
            session,
            batch,
            is_active,
            teachers (
              full_name,
              designation,
              department
            )
          ''')
          .inFilter('course_id', courseIds)
          .eq('term', termStr)
          .eq('is_active', true);

      final List<dynamic> offerings = offeringsResponse as List<dynamic>;

      // Group offerings by course_id
      final Map<String, List<Map<String, dynamic>>> offeringsByCourse = {};
      for (final offering in offerings) {
        final map = offering as Map<String, dynamic>;
        final courseId = map['course_id'] as String;
        offeringsByCourse.putIfAbsent(courseId, () => []).add(map);
      }

      // Build Course objects
      final courses = <Course>[];
      for (final item in data) {
        final map = item as Map<String, dynamic>;
        final courseId = map['course_id'] as String;

        // Attach offerings to the curriculum item for parsing
        final enrichedMap = Map<String, dynamic>.from(map);
        enrichedMap['course_offerings'] = offeringsByCourse[courseId] ?? [];

        courses.add(Course.fromSupabase(enrichedMap));
      }

      // Sort: theory first, then lab; within each group sort by code
      courses.sort((a, b) {
        if (a.type != b.type) {
          return a.type == CourseType.theory ? -1 : 1;
        }
        return a.code.compareTo(b.code);
      });

      return courses;
    } catch (e) {
      throw CourseInfoException('Failed to fetch courses: $e');
    }
  }

  /// Fetch all available terms from the curriculum table
  static Future<List<String>> fetchAvailableTerms() async {
    try {
      final response = await SupabaseService.from('curriculum')
          .select('term')
          .order('term', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      final terms = data
          .map((item) => (item as Map<String, dynamic>)['term'] as String)
          .toSet()
          .toList();
      terms.sort();
      return terms;
    } catch (e) {
      throw CourseInfoException('Failed to fetch available terms: $e');
    }
  }
}

class CourseInfoException implements Exception {
  final String message;
  const CourseInfoException(this.message);

  @override
  String toString() => 'CourseInfoException: $message';
}
