import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kuet_cse_automation/Student%20Folder/models/app_models.dart';
import 'package:kuet_cse_automation/services/session_service.dart';
import 'package:kuet_cse_automation/services/supabase_core.dart';

/// Notices Provider — reads exam schedules directly from the [exams] table
/// for the student's enrolled courses. No dependency on the notifications table.
final noticesProvider = FutureProvider<List<Notice>>((ref) async {
  return _fetchNotices();
});

Future<List<Notice>> _fetchNotices() async {
  try {
    final userId = SessionService.currentUserId;
    if (userId == null) return [];

    // Determine if user is a teacher or student
    final role = SessionService.currentRole ?? '';
    final isTeacher = role.toLowerCase() == 'teacher';

    late final List<dynamic> offerings;

    if (isTeacher) {
      // Teachers: fetch course offerings they are assigned to
      offerings = await SupabaseCore.from('course_offerings')
          .select('id, courses(code, title), teachers(full_name)')
          .eq('teacher_user_id', userId)
          .eq('is_active', true);
    } else {
      // Students: get term first, then fetch offerings for that term
      final student = await SupabaseCore.from('students')
          .select('term')
          .eq('user_id', userId)
          .maybeSingle();
      final term = student?['term'] as String?;
      if (term == null) return [];

      offerings = await SupabaseCore.from('course_offerings')
          .select('id, courses(code, title), teachers(full_name)')
          .eq('term', term)
          .eq('is_active', true);
    }

    final offeringList = (offerings as List).cast<Map<String, dynamic>>();
    if (offeringList.isEmpty) return [];

    final offeringIds =
        offeringList.map((o) => o['id']?.toString()).whereType<String>().toList();

    // Build a lookup: offeringId → {courseCode, courseTitle, teacherName}
    final offeringMeta = <String, Map<String, String>>{};
    for (final o in offeringList) {
      final id = o['id']?.toString();
      if (id == null) continue;
      final course = o['courses'] as Map<String, dynamic>? ?? {};
      final teacher = o['teachers'] as Map<String, dynamic>? ?? {};
      offeringMeta[id] = {
        'code': course['code'] as String? ?? '',
        'title': course['title'] as String? ?? '',
        'teacher': teacher['full_name'] as String? ?? '',
      };
    }

    // Fetch exams for those offerings, most recent first
    final examsData = await SupabaseCore.from('exams')
        .select()
        .inFilter('offering_id', offeringIds)
        .order('created_at', ascending: false)
        .limit(60);

    final notices = <Notice>[];

    for (final row in (examsData as List)) {
      final e = Map<String, dynamic>.from(row as Map);
      final offeringId = e['offering_id']?.toString() ?? '';
      final meta = offeringMeta[offeringId];
      if (meta == null) continue;

      final rawType = (e['exam_type'] as String? ?? 'CT').toUpperCase();
      final typeLabel = switch (rawType) {
        'CT' || 'CLASS_TEST' => 'Class Test (CT)',
        'TERM_FINAL' || 'FINAL' => 'Term Final',
        'QUIZ_VIVA' || 'QUIZ' || 'VIVA' => 'Quiz / Viva',
        _ => rawType,
      };
      final courseCode = meta['code']!;
      final courseTitle = meta['title']!;
      final teacherName = meta['teacher']!;
      final examDate = e['exam_date'] as String?;
      final maxMarks = e['max_marks'];
      final syllabus = e['syllabus'] as String?;

      final createdAt = DateTime.tryParse(e['created_at'] as String? ?? '');
      final dateStr = createdAt != null
          ? DateFormat('MMMM d, yyyy').format(createdAt)
          : '';

      final descParts = <String>[
        if (examDate != null && examDate.isNotEmpty) 'Date: $examDate',
        if (maxMarks != null) 'Max Marks: $maxMarks',
        if (teacherName.isNotEmpty) 'Teacher: $teacherName',
        if (syllabus != null && syllabus.isNotEmpty) 'Syllabus: $syllabus',
      ];

      notices.add(Notice(
        id: e['id']?.toString() ?? '',
        title: '📅 $typeLabel — $courseCode',
        description: descParts.isNotEmpty
            ? descParts.join(' | ')
            : '$typeLabel for $courseTitle',
        date: dateStr,
        category: 'Exam',
        isImportant: true,
      ));
    }

    // Fetch approved CR room bookings for the user's courses (fails gracefully)
    try {
      List<dynamic> roomRows;
      if (isTeacher) {
        roomRows = await SupabaseCore.from('cr_room_requests')
            .select()
            .eq('teacher_user_id', userId)
            .eq('status', 'approved')
            .order('created_at', ascending: false)
            .limit(30);
      } else {
        final enrolledCodes = offeringMeta.values
            .map((m) => m['code']!)
            .where((c) => c.isNotEmpty)
            .toList();
        if (enrolledCodes.isNotEmpty) {
          roomRows = await SupabaseCore.from('cr_room_requests')
              .select()
              .inFilter('course_code', enrolledCodes)
              .eq('status', 'approved')
              .order('created_at', ascending: false)
              .limit(30);
        } else {
          roomRows = [];
        }
      }

      const roomDayNames = [
        'Sunday', 'Monday', 'Tuesday', 'Wednesday',
        'Thursday', 'Friday', 'Saturday',
      ];
      for (final row in (roomRows as List)) {
        final r = Map<String, dynamic>.from(row as Map);
        final courseCode = r['course_code'] as String? ?? '';
        final roomNumber = r['room_number'] as String? ?? '';
        final dayOfWeek = r['day_of_week'] as int? ?? 0;
        final startTime = r['start_time'] as String? ?? '';
        final endTime = r['end_time'] as String? ?? '';
        final requestDate = r['request_date'] as String? ?? '';
        final createdAt = DateTime.tryParse(r['created_at'] as String? ?? '');
        final dayLabel = roomDayNames.elementAtOrNull(dayOfWeek) ?? 'Day $dayOfWeek';
        final dateStr = createdAt != null
            ? DateFormat('MMMM d, yyyy').format(createdAt)
            : '';

        final descParts = <String>[
          if (roomNumber.isNotEmpty) 'Room: $roomNumber',
          'Day: $dayLabel',
          if (requestDate.isNotEmpty) 'Date: $requestDate',
          if (startTime.isNotEmpty) 'Time: $startTime–$endTime',
        ];

        notices.add(Notice(
          id: 'room_${r['id'] ?? ''}',
          title: '🏫 Room Booked — $courseCode',
          description: descParts.join(' | '),
          date: dateStr,
          category: 'Event',
          isImportant: false,
        ));
      }
    } catch (_) {}

    // Also fetch announcements from notifications table (fails gracefully)
    try {
      final now = DateTime.now().toIso8601String();
      final ann = await SupabaseCore.from('notifications')
          .select()
          .inFilter('type', ['announcement', 'exam_notice'])
          .or('expires_at.is.null,expires_at.gt.$now')
          .order('created_at', ascending: false)
          .limit(20);

      for (final row in (ann as List)) {
        final m = Map<String, dynamic>.from(row as Map);
        final createdAt =
            DateTime.tryParse(m['created_at'] as String? ?? '');
        notices.add(Notice(
          id: m['id']?.toString() ?? '',
          title: m['title'] as String? ?? '',
          description: m['body'] as String? ?? '',
          date: createdAt != null
              ? DateFormat('MMMM d, yyyy').format(createdAt)
              : '',
          category: 'Academic',
          isImportant: false,
        ));
      }
    } catch (_) {}

    return notices;
  } catch (e) {
    debugPrint('[noticesProvider] error: $e');
    return [];
  }
}
