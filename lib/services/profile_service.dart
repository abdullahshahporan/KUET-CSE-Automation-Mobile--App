import 'package:flutter/foundation.dart';
import '../utils/display_utils.dart';
import 'session_service.dart';
import 'supabase_core.dart';

/// Handles student and teacher profile CRUD operations.
///
/// Separated from auth and course logic (SRP).
class ProfileService {
  ProfileService._();

  // ── Student Profile ─────────────────────────────────────────────────

  /// Get student profile (profiles + students tables).
  static Future<Map<String, dynamic>?> getStudentProfile() async {
    final userId = SessionService.currentUserId;
    if (userId == null) return null;

    try {
      final profileData = await SupabaseCore.from('profiles')
          .select('user_id, email, role, is_active, last_login, created_at')
          .eq('user_id', userId)
          .maybeSingle();

      if (profileData == null) return null;

      final studentData = await SupabaseCore.from('students')
          .select(
              'roll_no, full_name, phone, term, session, batch, section, cgpa')
          .eq('user_id', userId)
          .maybeSingle();

      if (studentData == null) return profileData;

      final termStr = (studentData['term'] ?? '1-1') as String;
      final parts = termStr.split('-');
      final year = int.tryParse(parts[0]) ?? 1;
      final semester = int.tryParse(parts.length > 1 ? parts[1] : '1') ?? 1;

      return {
        ...profileData,
        ...studentData,
        'current_year': year,
        'current_semester': semester,
        'year_display': DisplayUtils.yearDisplay(year),
        'semester_display': DisplayUtils.semesterDisplay(semester),
      };
    } catch (e) {
      debugPrint('Error fetching student profile: $e');
      return null;
    }
  }

  /// Update student phone number.
  static Future<bool> updateStudentPhone(String phone) async {
    final userId = SessionService.currentUserId;
    if (userId == null) return false;

    try {
      await SupabaseCore.from('students')
          .update({'phone': phone})
          .eq('user_id', userId);
      return true;
    } catch (e) {
      debugPrint('Error updating student phone: $e');
      return false;
    }
  }

  /// Update student term (one-way upgrade).
  static Future<bool> updateStudentTerm(String newTerm) async {
    final userId = SessionService.currentUserId;
    if (userId == null) return false;

    try {
      await SupabaseCore.from('students')
          .update({'term': newTerm})
          .eq('user_id', userId);
      return true;
    } catch (e) {
      debugPrint('Error updating student term: $e');
      return false;
    }
  }

  // ── Teacher Profile ─────────────────────────────────────────────────

  /// Get teacher profile (profiles + teachers tables).
  static Future<Map<String, dynamic>?> getTeacherProfile() async {
    await SupabaseCore.ensurePrefs();
    final userId = SessionService.currentUserId;
    if (userId == null) return null;

    try {
      final profileData = await SupabaseCore.from('profiles')
          .select('user_id, email, role, is_active, last_login, created_at')
          .eq('user_id', userId)
          .maybeSingle();

      if (profileData == null) return null;

      final teacherData = await SupabaseCore.from('teachers')
          .select(
              'teacher_uid, full_name, phone, designation, department, office_room, room_no, date_of_join, created_at')
          .eq('user_id', userId)
          .maybeSingle();

      if (teacherData == null) return profileData;

      return {
        ...profileData,
        ...teacherData,
        'designation_display':
            DisplayUtils.designationDisplay(teacherData['designation']),
      };
    } catch (e) {
      debugPrint('Error fetching teacher profile: $e');
      return null;
    }
  }

  /// Update teacher phone number.
  static Future<bool> updateTeacherPhone(String phone) async {
    final userId = SessionService.currentUserId;
    if (userId == null) return false;

    try {
      await SupabaseCore.from('teachers')
          .update({'phone': phone})
          .eq('user_id', userId);
      return true;
    } catch (e) {
      debugPrint('Error updating teacher phone: $e');
      return false;
    }
  }

  /// Update teacher profile fields (any combination).
  static Future<bool> updateTeacherProfile(
      Map<String, dynamic> fields) async {
    final userId = SessionService.currentUserId;
    if (userId == null || fields.isEmpty) return false;

    try {
      await SupabaseCore.from('teachers')
          .update(fields)
          .eq('user_id', userId);
      return true;
    } catch (e) {
      debugPrint('Error updating teacher profile: $e');
      return false;
    }
  }

  // ── Term Upgrade Requests ───────────────────────────────────────────

  /// Get the latest term upgrade request for the current student.
  static Future<Map<String, dynamic>?> getLatestTermUpgradeRequest() async {
    final userId = SessionService.currentUserId;
    if (userId == null) return null;

    try {
      return await SupabaseCore.from('term_upgrade_requests')
          .select()
          .eq('student_user_id', userId)
          .order('requested_at', ascending: false)
          .limit(1)
          .maybeSingle();
    } catch (e) {
      debugPrint('Error fetching term upgrade request: $e');
      return null;
    }
  }

  /// Submit a term upgrade request.
  static Future<bool> submitTermUpgradeRequest({
    required String currentTerm,
    required String requestedTerm,
    String? reason,
  }) async {
    final userId = SessionService.currentUserId;
    if (userId == null) return false;

    try {
      await SupabaseCore.from('term_upgrade_requests').insert({
        'student_user_id': userId,
        'current_term': currentTerm,
        'requested_term': requestedTerm,
        'reason': reason,
        'status': 'pending',
      });
      return true;
    } catch (e) {
      debugPrint('Error submitting term upgrade request: $e');
      return false;
    }
  }
}
