import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_core.dart';

/// Manages local session state (SharedPreferences).
///
/// Separated from auth logic (SRP): this class only reads/writes
/// local session keys.
class SessionService {
  SessionService._();

  static const _keyUserId = 'user_id';
  static const _keyEmail = 'user_email';
  static const _keyRole = 'user_role';
  static const _keyIsLoggedIn = 'is_logged_in';

  static SharedPreferences? get _prefs => SupabaseCore.prefs;

  // ── Read ────────────────────────────────────────────────────────────

  static bool get isLoggedIn => _prefs?.getBool(_keyIsLoggedIn) ?? false;
  static String? get currentUserId => _prefs?.getString(_keyUserId);
  static String? get currentEmail => _prefs?.getString(_keyEmail);
  static String? get currentRole => _prefs?.getString(_keyRole);

  // ── Write ───────────────────────────────────────────────────────────

  /// Save session after successful login.
  static Future<void> saveSession({
    required String userId,
    required String email,
    required String role,
  }) async {
    final prefs = await SupabaseCore.ensurePrefs();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyRole, role);
  }

  /// Clear the local session (logout).
  static Future<void> clearSession() async {
    final prefs = await SupabaseCore.ensurePrefs();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyRole);
  }
}
