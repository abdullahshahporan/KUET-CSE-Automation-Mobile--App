import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/display_utils.dart';
import 'auth_service.dart';
import 'course_offering_service.dart';
import 'profile_service.dart';
import 'session_service.dart';
import 'supabase_core.dart';

/// Backward-compatible facade that delegates to focused service classes.
///
/// New code should import the specific service directly:
///   - [AuthService] for sign-in / sign-out / password change
///   - [SessionService] for local session state
///   - [ProfileService] for profile CRUD + term upgrades
///   - [CourseOfferingService] for teacher course offerings + realtime
///   - [SupabaseCore] for raw Supabase client access
///
/// This facade exists so that existing call-sites don't break.
/// Gradually replace `SupabaseService.xxx` with the proper service.
class SupabaseService {
  // ── Initialization ──────────────────────────────────────────────────

  static Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) =>
      SupabaseCore.initialize(
        supabaseUrl: supabaseUrl,
        supabaseAnonKey: supabaseAnonKey,
      );

  // ── Client access ───────────────────────────────────────────────────

  static SupabaseClient get client => SupabaseCore.client;
  static SupabaseQueryBuilder from(String table) => SupabaseCore.from(table);

  // ── Auth ────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) =>
      AuthService.signIn(email: email, password: password);

  static Future<void> signOut() => AuthService.signOut();

  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      AuthService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

  // ── Session ─────────────────────────────────────────────────────────

  static bool get isLoggedIn => SessionService.isLoggedIn;
  static String? get currentUserId => SessionService.currentUserId;
  static String? get currentEmail => SessionService.currentEmail;
  static String? get currentRole => SessionService.currentRole;

  // ── Profiles ────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getStudentProfile() =>
      ProfileService.getStudentProfile();

  static Future<Map<String, dynamic>?> getTeacherProfile() =>
      ProfileService.getTeacherProfile();

  static Future<bool> updateStudentTerm(String newTerm) =>
      ProfileService.updateStudentTerm(newTerm);

  static Future<bool> updateStudentPhone(String phone) =>
      ProfileService.updateStudentPhone(phone);

  static Future<bool> updateTeacherPhone(String phone) =>
      ProfileService.updateTeacherPhone(phone);

  static Future<bool> updateTeacherProfile(Map<String, dynamic> fields) =>
      ProfileService.updateTeacherProfile(fields);

  // ── Term Upgrade ────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getLatestTermUpgradeRequest() =>
      ProfileService.getLatestTermUpgradeRequest();

  static Future<bool> submitTermUpgradeRequest({
    required String currentTerm,
    required String requestedTerm,
    String? reason,
  }) =>
      ProfileService.submitTermUpgradeRequest(
        currentTerm: currentTerm,
        requestedTerm: requestedTerm,
        reason: reason,
      );

  // ── Teacher Courses ─────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getTeacherAssignedCourses() =>
      CourseOfferingService.getTeacherAssignedCourses();

  static dynamic subscribeToTeacherCourses({required Function() onChanged}) =>
      CourseOfferingService.subscribeToTeacherCourses(onChanged: onChanged);

  static Future<void> removeChannel(dynamic channel) =>
      CourseOfferingService.removeChannel(channel);

  // ── Helpers ─────────────────────────────────────────────────────────

  static String getFirstName(String? fullName) =>
      DisplayUtils.firstName(fullName);
}
