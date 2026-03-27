import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kuet_cse_automation/Student%20Folder/models/app_models.dart';
import 'package:kuet_cse_automation/services/session_service.dart';
import 'package:kuet_cse_automation/services/supabase_core.dart';

/// Notices Provider — fetches exam-scheduled and announcement notifications
/// from Supabase and maps them to [Notice] objects.
final noticesProvider = FutureProvider<List<Notice>>((ref) async {
  return _fetchNotices();
});

Future<List<Notice>> _fetchNotices() async {
  try {
    final userId = SessionService.currentUserId;
    if (userId == null) return [];

    // Get student context for term/section/course filtering
    final student = await SupabaseCore.from('students')
        .select('term, section')
        .eq('user_id', userId)
        .maybeSingle();
    final term = student?['term'] as String?;
    final section =
        (student?['section'] as String?)?.trim().toUpperCase();

    // Enrolled course codes for COURSE-targeted notices
    List<String> enrolledCodes = [];
    if (term != null) {
      final offerings = await SupabaseCore.from('course_offerings')
          .select('courses!inner(code)')
          .eq('term', term);
      enrolledCodes = (offerings as List)
          .map((o) =>
              ((o['courses'] as Map<String, dynamic>?)?['code'] as String?)
                  ?.trim()
                  .toUpperCase())
          .whereType<String>()
          .toList();
    }

    // Fetch notifications intended for the notice board
    final now = DateTime.now().toIso8601String();
    final data = await SupabaseCore.from('notifications')
        .select()
        .inFilter('type', ['exam_scheduled', 'exam_notice', 'announcement'])
        .or('expires_at.is.null,expires_at.gt.$now')
        .order('created_at', ascending: false)
        .limit(100);

    final notices = <Notice>[];
    for (final row in (data as List<dynamic>)) {
      final m = Map<String, dynamic>.from(row as Map);
      final targetType =
          (m['target_type'] as String?)?.toUpperCase().trim() ?? '';
      final targetValue = (m['target_value'] as String?)?.trim();
      final targetYearTerm = (m['target_year_term'] as String?)?.trim();

      // Client-side visibility check
      final visible = switch (targetType) {
        'ALL' => true,
        'YEAR_TERM' => targetValue == term,
        'ROLE' => true,
        'USER' => targetValue == userId,
        'SECTION' =>
          targetValue?.toUpperCase() == section &&
              (targetYearTerm == null || targetYearTerm == term),
        'COURSE' =>
          targetValue?.toUpperCase() != null &&
              enrolledCodes.contains(targetValue!.toUpperCase()),
        _ => false,
      };
      if (!visible) continue;

      final type = (m['type'] as String?) ?? 'announcement';
      final createdAt = DateTime.tryParse(m['created_at'] as String? ?? '');
      final dateStr = createdAt != null
          ? DateFormat('MMMM d, yyyy').format(createdAt)
          : '';

      final (category, isImportant) = switch (type) {
        'exam_scheduled' || 'exam_notice' => ('Exam', true),
        _ => ('Academic', false),
      };

      notices.add(Notice(
        id: m['id']?.toString() ?? '',
        title: m['title'] as String? ?? '',
        description: m['body'] as String? ?? '',
        date: dateStr,
        category: category,
        isImportant: isImportant,
      ));
    }

    return notices;
  } catch (_) {
    return [];
  }
}
