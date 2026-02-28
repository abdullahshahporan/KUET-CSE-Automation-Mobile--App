import 'package:bcrypt/bcrypt.dart';
import 'session_service.dart';
import 'supabase_core.dart';

/// Handles authentication: sign-in, sign-out, and password changes.
///
/// Separated from profile and course logic (SRP).
class AuthService {
  AuthService._();

  /// Sign in by querying the `profiles` table and verifying the bcrypt hash.
  ///
  /// Returns a Map with keys: `success`, `user_id`, `role`, `email`, `message`.
  static Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await SupabaseCore.from('profiles')
          .select('user_id, email, password_hash, role, is_active')
          .eq('email', email.trim().toLowerCase())
          .maybeSingle();

      if (response == null) {
        return {'success': false, 'message': 'Invalid email or password'};
      }

      final isActive = response['is_active'] as bool? ?? false;
      if (!isActive) {
        return {
          'success': false,
          'message': 'Account is deactivated. Contact admin.',
        };
      }

      final storedHash = response['password_hash'] as String? ?? '';
      if (!BCrypt.checkpw(password, storedHash)) {
        return {'success': false, 'message': 'Invalid email or password'};
      }

      final userId = (response['user_id'] ?? '').toString();
      final role = (response['role'] ?? '').toString();
      final userEmail = (response['email'] ?? email).toString();

      // Save session locally
      await SessionService.saveSession(
        userId: userId,
        email: userEmail,
        role: role,
      );

      // Update last_login (non-critical)
      try {
        await SupabaseCore.from('profiles')
            .update({'last_login': DateTime.now().toUtc().toIso8601String()})
            .eq('user_id', userId);
      } catch (_) {}

      return {
        'success': true,
        'user_id': userId,
        'role': role,
        'email': userEmail,
      };
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  /// Sign out – clears saved session.
  static Future<void> signOut() async => SessionService.clearSession();

  /// Change password: verify current password, then update hash.
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final userId = SessionService.currentUserId;
    if (userId == null) {
      return {'success': false, 'message': 'Not logged in'};
    }

    try {
      final profile = await SupabaseCore.from('profiles')
          .select('password_hash')
          .eq('user_id', userId)
          .maybeSingle();

      if (profile == null) {
        return {'success': false, 'message': 'Profile not found'};
      }

      final storedHash = profile['password_hash'] as String? ?? '';
      if (!BCrypt.checkpw(currentPassword, storedHash)) {
        return {'success': false, 'message': 'Current password is incorrect'};
      }

      final newHash = BCrypt.hashpw(newPassword, BCrypt.gensalt());
      await SupabaseCore.from('profiles')
          .update({
            'password_hash': newHash,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('user_id', userId);

      return {'success': true, 'message': 'Password changed successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
}
