import 'package:flutter/foundation.dart';
import '../../services/notification_service.dart';
import '../../services/session_service.dart';
import '../../services/supabase_core.dart';
import 'cr_room_request_service.dart';

/// Model for a CR-managed exam entry.
class CRExam {
  final String id;
  final String offeringId;
  final String courseName;
  final String courseCode;
  final String teacherName;
  final String teacherUserId;
  final String examType; // 'CT', 'TERM_FINAL', 'QUIZ_VIVA', 'MID'
  final String name;
  final double maxMarks;
  final String? examDate; // ISO yyyy-MM-dd
  final String? examTime; // HH:mm:ss
  final int? durationMinutes;
  final List<String> roomNumbers;
  final String? syllabus;
  final String? section;

  CRExam({
    required this.id,
    required this.offeringId,
    required this.courseName,
    required this.courseCode,
    required this.teacherName,
    required this.teacherUserId,
    required this.examType,
    required this.name,
    required this.maxMarks,
    this.examDate,
    this.examTime,
    this.durationMinutes,
    required this.roomNumbers,
    this.syllabus,
    this.section,
  });

  factory CRExam.fromMap(Map<String, dynamic> m) {
    final offering = m['course_offerings'] as Map<String, dynamic>? ?? {};
    final course = offering['courses'] as Map<String, dynamic>? ?? {};
    final teacher = offering['teachers'] as Map<String, dynamic>? ?? {};
    final rawRooms = m['room_numbers'] as List<dynamic>? ?? [];

    return CRExam(
      id: (m['id'] ?? '').toString(),
      offeringId: (m['offering_id'] ?? '').toString(),
      courseName: course['title'] as String? ?? 'Unknown Course',
      courseCode: course['code'] as String? ?? '',
      teacherName: teacher['full_name'] as String? ?? 'TBA',
      teacherUserId: offering['teacher_user_id'] as String? ?? '',
      examType: CRExamService._normalizeExamType(m['exam_type'] as String? ?? 'CT'),
      name: m['name'] as String? ?? '',
      maxMarks: (m['max_marks'] as num?)?.toDouble() ?? 0,
      examDate: m['exam_date'] as String?,
      examTime: m['exam_time'] as String?,
      durationMinutes: m['duration_minutes'] as int?,
      roomNumbers: rawRooms.map((r) => r.toString()).toList(),
      syllabus: m['syllabus'] as String?,
      section: m['section'] as String?,
    );
  }
}

/// Service for CR to manage (add / edit / delete) exam schedules.
class CRExamService {
  CRExamService._();

  // ── Fetch course offerings for the current student's term ──

  static Future<List<Map<String, dynamic>>> fetchMyOfferings() async {
    final userId = SessionService.currentUserId;
    if (userId == null) return [];

    try {
      final student = await SupabaseCore.from('students')
          .select('term, section')
          .eq('user_id', userId)
          .maybeSingle();

      if (student == null) return [];

      final term = student['term'] as String? ?? '';

      final data = await SupabaseCore.from('course_offerings')
          .select('''
            id,
            term,
            teacher_user_id,
            courses ( id, code, title ),
            teachers ( full_name )
          ''')
          .eq('term', term)
          .eq('is_active', true);

      return (data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('[CRExamService] fetchMyOfferings error: $e');
      return [];
    }
  }

  // ── Fetch exams created by this CR (or all for their term) ─

  static Future<List<CRExam>> fetchMyExams() async {
    final userId = SessionService.currentUserId;
    if (userId == null) return [];

    try {
      final student = await SupabaseCore.from('students')
          .select('term')
          .eq('user_id', userId)
          .maybeSingle();
      if (student == null) return [];

      final term = student['term'] as String? ?? '';

      // Fetch all exams for the current term's offerings
      final data = await SupabaseCore.from('exams')
          .select('''
            id,
            offering_id,
            name,
            exam_type,
            max_marks,
            exam_date,
            exam_time,
            duration_minutes,
            room_numbers,
            syllabus,
            section,
            created_by_student_user_id,
            created_at,
            course_offerings (
              id,
              term,
              teacher_user_id,
              courses ( code, title ),
              teachers ( full_name )
            )
          ''')
          .eq('course_offerings.term', term)
          .order('exam_date', ascending: true);

      return (data as List)
          .map((e) => CRExam.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[CRExamService] fetchMyExams error: $e');
      return [];
    }
  }

  // ── Create an exam entry and notify teacher + classmates ───

  static Future<({bool success, String message})> createExam({
    required String offeringId,
    required String teacherUserId,
    required String courseCode,
    required String courseName,
    required String teacherName,
    required String examType,
    required String name,
    required double maxMarks,
    String? examDate,
    String? examTime,
    int? durationMinutes,
    List<String> roomNumbers = const [],
    String? syllabus,
    String? section,
  }) async {
    final userId = SessionService.currentUserId;
    if (userId == null) return (success: false, message: 'Not logged in.');

    final isCR = await CRRoomRequestService.checkIsCR();
    if (!isCR) {
      return (
        success: false,
        message: 'You are not designated as a Class Representative.',
      );
    }

    try {
      final result = await SupabaseCore.from('exams').insert({
        'offering_id': offeringId,
        'name': name,
        'exam_type': examType,
        'max_marks': maxMarks,
        if (examDate != null && examDate.isNotEmpty) 'exam_date': examDate,
        if (examTime != null && examTime.isNotEmpty) 'exam_time': examTime,
        if (durationMinutes != null) 'duration_minutes': durationMinutes,
        'room_numbers': roomNumbers,
        if (syllabus != null && syllabus.isNotEmpty) 'syllabus': syllabus,
        if (section != null && section.isNotEmpty) 'section': section,
        'created_by_student_user_id': userId,
      }).select().single();

      // ── Send in-app + push notifications (fire-and-forget) ─
      try {
        final typeLabel = switch (examType.toUpperCase()) {
          'CT' || 'CLASS_TEST' => 'Class Test (CT)',
          'TERM_FINAL' || 'FINAL' => 'Term Final',
          'QUIZ_VIVA' || 'QUIZ' || 'VIVA' => 'Quiz / Viva',
          _ => examType,
        };
        final dateLabel = (examDate != null && examDate.isNotEmpty)
            ? examDate
            : 'TBA';
        final meta = {
          'exam_id': result['id']?.toString() ?? '',
          'exam_type': examType,
          'course_code': courseCode,
          'open_screen': 'exam_schedule',
        };

        // Notify teacher (USER target)
        if (teacherUserId.isNotEmpty) {
          await NotificationService.createNotification(
            type: 'exam_scheduled',
            title: '📋 $typeLabel Scheduled — $courseCode',
            body: '$courseName $typeLabel on $dateLabel.'
                '${maxMarks > 0 ? ' Max marks: ${maxMarks.toStringAsFixed(0)}.' : ''}',
            targetType: 'USER',
            targetValue: teacherUserId,
            metadata: meta,
          );
        }

        // Notify all classmates (COURSE target)
        await NotificationService.createNotification(
          type: 'exam_scheduled',
          title: '📅 $typeLabel — $courseCode',
          body: '$typeLabel for $courseName on $dateLabel.'
              '${teacherName.isNotEmpty ? ' Teacher: $teacherName.' : ''}',
          targetType: 'COURSE',
          targetValue: courseCode,
          metadata: meta,
        );
      } catch (e) {
        debugPrint('[CRExamService] notification send error (exam saved OK): $e');
      }

      return (success: true, message: 'Exam scheduled successfully!');
    } catch (e) {
      debugPrint('[CRExamService] createExam error: $e');
      return (success: false, message: 'Failed to create exam: $e');
    }
  }

  // ── Update an existing exam entry ─────────────────────────

  static Future<({bool success, String message})> updateExam({
    required String examId,
    required String originalCreatorId,
    String? name,
    String? examType,
    double? maxMarks,
    String? examDate,
    String? examTime,
    int? durationMinutes,
    List<String>? roomNumbers,
    String? syllabus,
    String? section,
  }) async {
    final userId = SessionService.currentUserId;
    if (userId == null) return (success: false, message: 'Not logged in.');

    if (userId != originalCreatorId) {
      return (
        success: false,
        message: 'You can only edit exams you have created.',
      );
    }

    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (examType != null) updates['exam_type'] = examType;
    if (maxMarks != null) updates['max_marks'] = maxMarks;
    if (examDate != null) updates['exam_date'] = examDate.isEmpty ? null : examDate;
    if (examTime != null) updates['exam_time'] = examTime.isEmpty ? null : examTime;
    if (durationMinutes != null) updates['duration_minutes'] = durationMinutes;
    if (roomNumbers != null) updates['room_numbers'] = roomNumbers;
    if (syllabus != null) updates['syllabus'] = syllabus.isEmpty ? null : syllabus;
    if (section != null) updates['section'] = section.isEmpty ? null : section;

    if (updates.isEmpty) return (success: true, message: 'No changes.');

    try {
      await SupabaseCore.from('exams')
          .update(updates)
          .eq('id', examId)
          .eq('created_by_student_user_id', userId);

      return (success: true, message: 'Exam updated successfully!');
    } catch (e) {
      debugPrint('[CRExamService] updateExam error: $e');
      return (success: false, message: 'Failed to update exam: $e');
    }
  }

  // ── Delete an exam entry ───────────────────────────────────

  static Future<({bool success, String message})> deleteExam({
    required String examId,
    required String originalCreatorId,
  }) async {
    final userId = SessionService.currentUserId;
    if (userId == null) return (success: false, message: 'Not logged in.');

    if (userId != originalCreatorId) {
      return (
        success: false,
        message: 'You can only delete exams you have created.',
      );
    }

    try {
      await SupabaseCore.from('exams')
          .delete()
          .eq('id', examId)
          .eq('created_by_student_user_id', userId);

      return (success: true, message: 'Exam deleted.');
    } catch (e) {
      debugPrint('[CRExamService] deleteExam error: $e');
      return (success: false, message: 'Failed to delete exam: $e');
    }
  }

  // ── Helpers ────────────────────────────────────────────────

  /// Normalises a DB enum value to the app's internal string.
  /// e.g. 'CLASS_TEST' → 'CT', 'MIDTERM' → 'CT' (fallback).
  static String _normalizeExamType(String raw) {
    switch (raw.toUpperCase()) {
      case 'CLASS_TEST':
      case 'CT':
        return 'CT';
      case 'TERM_FINAL':
      case 'FINAL':
        return 'TERM_FINAL';
      case 'QUIZ_VIVA':
      case 'QUIZ':
      case 'VIVA':
        return 'QUIZ_VIVA';
      default:
        return raw;
    }
  }

  static String _formatExamType(String type) {
    switch (type.toUpperCase()) {
      case 'CT':
      case 'CLASS_TEST':
        return 'Class Test (CT)';
      case 'MID':
      case 'MIDTERM':
        return 'Mid Term';
      case 'FINAL':
      case 'TERM_FINAL':
        return 'Term Final';
      case 'QUIZ':
      case 'VIVA':
      case 'QUIZ_VIVA':
        return 'Quiz/Viva';
      default:
        return type;
    }
  }
}
