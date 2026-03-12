import 'package:flutter/foundation.dart';

import 'supabase_service.dart';

/// Service for fetching optional (elective) course assignments for the
/// currently logged-in student.
///
/// The admin assigns elective courses to individual students via the
/// `optional_course_assignments` table. This service checks which offering IDs
/// the current student is assigned to, so that course display, schedule, and
/// attendance can be filtered accordingly.
class OptionalCourseService {
  OptionalCourseService._();

  /// Cache to avoid re-fetching every time.
  static Set<String>? _cachedOfferingIds;
  static String? _cachedForUserId;

  /// Returns the set of `course_offerings.id` values that the current
  /// student has been assigned (i.e. elective courses they should see).
  ///
  /// Returns an empty set if the student has no assignments or if
  /// the query fails.
  static Future<Set<String>> getMyAssignedOfferingIds({bool forceRefresh = false}) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return {};

    // Return cached if still valid
    if (!forceRefresh && _cachedOfferingIds != null && _cachedForUserId == userId) {
      return _cachedOfferingIds!;
    }

    try {
      final data = await SupabaseService.from('optional_course_assignments')
          .select('offering_id')
          .eq('student_user_id', userId);

      final list = data as List;
      final ids = list.map((row) => row['offering_id'] as String).toSet();
      debugPrint('[OptionalCourse] Student $userId has ${ids.length} elective assignment(s)');

      _cachedOfferingIds = ids;
      _cachedForUserId = userId;
      return ids;
    } catch (e) {
      debugPrint('[OptionalCourse] ERROR fetching assignments: $e');
      return {};
    }
  }

  /// Returns the set of `courses.id` values for elective courses in a given term.
  ///
  /// Queries the `curriculum` table for rows where `is_elective = true` and the
  /// related course code matches the given year-term.
  static Future<Set<String>> getElectiveCourseIds({
    required String term,
  }) async {
    try {
      final data = await SupabaseService.from('curriculum')
          .select('course_id')
          .eq('term', term)
          .eq('is_elective', true);

      final list = data as List;
      final ids = list.map((row) => row['course_id'] as String).toSet();
      debugPrint('[OptionalCourse] Term $term has ${ids.length} elective course(s) in curriculum');
      return ids;
    } catch (e) {
      debugPrint('[OptionalCourse] ERROR fetching elective course IDs: $e');
      return {};
    }
  }

  /// Clears the cache (e.g., on logout or term change).
  static void clearCache() {
    _cachedOfferingIds = null;
    _cachedForUserId = null;
  }
}
