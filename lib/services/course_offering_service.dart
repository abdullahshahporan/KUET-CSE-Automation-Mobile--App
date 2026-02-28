import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'session_service.dart';
import 'supabase_core.dart';

/// Handles teacher-specific course offerings and real-time subscriptions.
///
/// Separated from profile, auth, and student logic (SRP).
class CourseOfferingService {
  CourseOfferingService._();

  /// Fetch courses assigned to the currently logged-in teacher.
  static Future<List<Map<String, dynamic>>> getTeacherAssignedCourses() async {
    await SupabaseCore.ensurePrefs();
    final userId = SessionService.currentUserId;
    if (userId == null) return [];

    try {
      final response = await SupabaseCore.from('course_offerings')
          .select('''
            id,
            course_id,
            term,
            session,
            batch,
            is_active,
            courses (
              id,
              code,
              title,
              credit,
              course_type,
              description
            )
          ''')
          .eq('teacher_user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('[CourseOfferingService] ERROR: $e');
      return [];
    }
  }

  /// Subscribe to real-time changes on course_offerings for this teacher.
  static dynamic subscribeToTeacherCourses({
    required Function() onChanged,
  }) {
    final userId = SessionService.currentUserId;
    if (userId == null) return null;

    return SupabaseCore.client
        .channel('teacher-courses-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'course_offerings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'teacher_user_id',
            value: userId,
          ),
          callback: (payload) {
            debugPrint(
                '[Realtime] Teacher courses changed: ${payload.eventType}');
            onChanged();
          },
        )
        .subscribe();
  }

  /// Remove a real-time channel subscription.
  static Future<void> removeChannel(dynamic channel) async {
    if (channel != null) {
      await SupabaseCore.client.removeChannel(channel as RealtimeChannel);
    }
  }
}
