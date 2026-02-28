import 'package:flutter/foundation.dart';
import '../../services/supabase_service.dart';
import '../../utils/course_utils.dart';
import '../models/course_model.dart';

/// Service for fetching course/curriculum data from Supabase.
///
/// Uses the course code convention: code "32xx" → year 3, term 2 (i.e. 3-2).
/// The first digit of the course number = year, second digit = term.
class CourseInfoService {
  /// Fetch courses for a given year-term.
  ///
  /// 1. Fetches ALL courses from the `courses` table.
  /// 2. Filters client-side by code prefix (e.g. "32" for year=3, term=2).
  /// 3. Fetches active offerings + teachers for matched courses.
  static Future<List<Course>> fetchCourses({
    required int year,
    required int term,
  }) async {
    try {
      final termPrefix = '$year$term'; // e.g. "32" for 3-2
      debugPrint('[CourseInfo] Fetching courses with code prefix: $termPrefix');

      // Step 1: Fetch all courses
      final coursesResponse = await SupabaseService.from('courses')
          .select('id, code, title, credit, course_type, description');

      final List<dynamic> allCourses = coursesResponse as List<dynamic>;
      debugPrint('[CourseInfo] Total courses in DB: ${allCourses.length}');

      // Step 2: Filter by code prefix  (e.g. "CSE 3201" → digits "3201" starts with "32")
      final matchedCourses = allCourses
          .map((c) => c as Map<String, dynamic>)
          .where((c) => CourseUtils.codeMatchesTerm(c['code'] as String?, year, term))
          .toList();

      debugPrint('[CourseInfo] Matched ${matchedCourses.length} courses for prefix $termPrefix');

      if (matchedCourses.isEmpty) return [];

      // Step 3: Fetch active offerings with teachers for these courses
      final courseIds = matchedCourses.map((c) => c['id'].toString()).toList();

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
          .eq('is_active', true);

      final List<dynamic> offerings = offeringsResponse as List<dynamic>;
      debugPrint('[CourseInfo] Got ${offerings.length} active offerings');

      // Group offerings by course_id
      final Map<String, List<Map<String, dynamic>>> offeringsByCourse = {};
      for (final o in offerings) {
        final map = o as Map<String, dynamic>;
        final cid = map['course_id'].toString();
        offeringsByCourse.putIfAbsent(cid, () => []).add(map);
      }

      // Step 4: Build Course objects
      final courses = <Course>[];
      for (final courseData in matchedCourses) {
        final cid = courseData['id'].toString();
        final enrichedMap = <String, dynamic>{
          'term': '$year-$term',
          'courses': courseData,
          'course_offerings': offeringsByCourse[cid] ?? [],
          'is_elective': false,
        };
        courses.add(Course.fromSupabase(enrichedMap));
      }

      // Sort: theory first, then lab; within each sort by code
      courses.sort((a, b) {
        if (a.type != b.type) {
          return a.type == CourseType.theory ? -1 : 1;
        }
        return a.code.compareTo(b.code);
      });

      debugPrint('[CourseInfo] Returning ${courses.length} courses');
      return courses;
    } catch (e) {
      debugPrint('[CourseInfo] ERROR: $e');
      throw CourseInfoException('Failed to fetch courses: $e');
    }
  }

  /// Fetch all available terms by scanning course codes
  static Future<List<String>> fetchAvailableTerms() async {
    try {
      final response = await SupabaseService.from('courses')
          .select('code');

      final List<dynamic> data = response as List<dynamic>;
      final terms = <String>{};
      for (final item in data) {
        final code = (item as Map<String, dynamic>)['code'] as String?;
        if (code == null) continue;
        final derived = CourseUtils.termFromCourseCode(code);
        if (derived != '1-1' || code.contains('1')) {
          terms.add(derived);
        }
      }
      final sorted = terms.toList()..sort();
      return sorted;
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
