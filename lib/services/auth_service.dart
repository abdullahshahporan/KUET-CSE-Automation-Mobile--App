import 'dart:async';

import 'package:bcrypt/bcrypt.dart';

import '../config/push_config.dart';
import 'background_notification_service.dart';
import 'push_notification_service.dart';
import 'session_service.dart';
import 'supabase_core.dart';

/// Handles authentication: sign-in, sign-out, and password changes.
///
/// Separated from profile and course logic (SRP).
class AuthService {
  AuthService._();

  static const _recoveryFailureMessage =
      'We could not verify those account details.';

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
          .maybeSingle()
          .timeout(const Duration(seconds: 15));

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
      ).timeout(const Duration(seconds: 5));
      PushConfig.loginUser(userId);
      // Keep login responsive even if OneSignal is slow/unavailable.
      unawaited(
        PushNotificationService.syncUserIdentity()
            .timeout(const Duration(seconds: 5))
            .catchError((_) {}),
      );

      // Update last_login (non-critical)
      try {
        await SupabaseCore.from('profiles')
            .update({'last_login': DateTime.now().toUtc().toIso8601String()})
            .eq('user_id', userId)
            .timeout(const Duration(seconds: 5));
      } catch (_) {}

      return {
        'success': true,
        'user_id': userId,
        'role': role,
        'email': userEmail,
      };
    } on TimeoutException {
      return {
        'success': false,
        'message':
            'Sign in timed out. Please check your connection and try again.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  /// Sign out – clears saved session.
  static Future<void> signOut() async {
    await BackgroundNotificationService.stop();
    PushConfig.logoutUser();
    await PushNotificationService.clearUserIdentity();
    await SessionService.clearSession();
  }

  /// Change password: verify current password, then update hash.
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final verification = await verifyCurrentPassword(
        currentPassword: currentPassword,
      );
      if (verification['success'] != true) {
        return verification;
      }

      final userId = SessionService.currentUserId;
      if (userId == null) {
        return {'success': false, 'message': 'Not logged in'};
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

  /// Verifies the current user's password without mutating the session.
  static Future<Map<String, dynamic>> verifyCurrentPassword({
    required String currentPassword,
  }) async {
    final userId = SessionService.currentUserId;
    if (userId == null) {
      return {'success': false, 'message': 'Not logged in'};
    }

    try {
      final profile = await SupabaseCore.from(
        'profiles',
      ).select('password_hash').eq('user_id', userId).maybeSingle();

      if (profile == null) {
        return {'success': false, 'message': 'Profile not found'};
      }

      final storedHash = profile['password_hash'] as String? ?? '';
      if (!BCrypt.checkpw(currentPassword, storedHash)) {
        return {'success': false, 'message': 'Current password is incorrect'};
      }

      return {'success': true, 'message': 'Password verified'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Recovers a forgotten password using email plus institutional identity.
  static Future<Map<String, dynamic>> resetForgottenPassword({
    required String email,
    required String verificationValue,
    required String newPassword,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedVerification = verificationValue.trim().toUpperCase();

    if (normalizedEmail.isEmpty ||
        normalizedVerification.isEmpty ||
        newPassword.length < 6) {
      return {'success': false, 'message': _recoveryFailureMessage};
    }

    try {
      final profile = await SupabaseCore.from('profiles')
          .select('user_id, role, is_active')
          .eq('email', normalizedEmail)
          .maybeSingle()
          .timeout(const Duration(seconds: 15));

      if (profile == null) {
        return {'success': false, 'message': _recoveryFailureMessage};
      }

      final isActive = profile['is_active'] as bool? ?? false;
      if (!isActive) {
        return {
          'success': false,
          'message': 'Account is deactivated. Contact admin.',
        };
      }

      final userId = (profile['user_id'] ?? '').toString();
      final role = (profile['role'] ?? '').toString().toUpperCase();

      late final String table;
      late final String column;
      switch (role) {
        case 'STUDENT':
          table = 'students';
          column = 'roll_no';
          break;
        case 'TEACHER':
          table = 'teachers';
          column = 'teacher_uid';
          break;
        default:
          return {
            'success': false,
            'message': 'Password recovery is not available for this account.',
          };
      }

      final identityRow = await SupabaseCore.from(
        table,
      ).select(column).eq('user_id', userId).maybeSingle();

      if (identityRow == null) {
        return {'success': false, 'message': _recoveryFailureMessage};
      }

      final storedValue = (identityRow[column] ?? '')
          .toString()
          .trim()
          .toUpperCase();
      if (storedValue != normalizedVerification) {
        return {'success': false, 'message': _recoveryFailureMessage};
      }

      final newHash = BCrypt.hashpw(newPassword, BCrypt.gensalt());
      await SupabaseCore.from('profiles')
          .update({
            'password_hash': newHash,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('user_id', userId);

      return {'success': true, 'message': 'Password reset successfully'};
    } on TimeoutException {
      return {
        'success': false,
        'message':
            'Password reset timed out. Please check your connection and try again.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
}
