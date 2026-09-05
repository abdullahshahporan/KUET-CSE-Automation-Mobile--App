import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'session_token_store.dart';
import 'authenticated_api.dart';

import '../config/push_config.dart';
import '../config/supabase_config.dart';
import 'background_notification_service.dart';
import 'profile_service.dart';
import 'push_notification_service.dart';
import 'session_service.dart';
import 'supabase_core.dart';

/// Handles authentication: sign-in, sign-out, and password changes.
///
/// Separated from profile and course logic (SRP).
class AuthService {
  AuthService._();

  /// Sign in by making an HTTP POST request to /api/auth/login.
  ///
  /// Returns a Map with keys: `success`, `user_id`, `role`, `email`, `message`.
  static Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    final client = HttpClient();
    final normalizedEmail = email.trim().toLowerCase();
    try {
      final uri = Uri.parse('${SupabaseConfig.backendUrl}/api/auth/login');
      final request = await client
          .postUrl(uri)
          .timeout(const Duration(seconds: 15));
      request.headers.contentType = ContentType.json;
      request.headers.set('x-client-type', 'mobile');
      request.write(
        jsonEncode({'email': normalizedEmail, 'password': password}),
      );

      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        try {
          final errJson = jsonDecode(responseBody);
          return {
            'success': false,
            'message':
                errJson['error'] ?? 'Login failed (${response.statusCode})',
          };
        } catch (_) {
          return {
            'success': false,
            'message': 'Login failed with status code ${response.statusCode}',
          };
        }
      }

      final resJson = jsonDecode(responseBody);
      if (resJson['success'] != true || resJson['data'] == null) {
        return {
          'success': false,
          'message': resJson['error'] ?? 'Invalid email or password',
        };
      }

      final data = resJson['data'] as Map<String, dynamic>;
      final userId = (data['id'] ?? '').toString();
      final role = (data['role'] ?? '').toString().toUpperCase();
      final userEmail = (data['email'] ?? normalizedEmail).toString();
      final token = (data['token'] ?? '').toString();
      if (token.isEmpty || userId.isEmpty || role.isEmpty) {
        return {
          'success': false,
          'message': 'The sign-in service returned an incomplete session.',
        };
      }

      await _saveSuccessfulSignIn(
        userId: userId,
        email: userEmail,
        role: role,
        token: token.isEmpty ? null : token,
      );

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
            'The secure sign-in service is unavailable. Please try again later.',
      };
    } on SocketException {
      return {
        'success': false,
        'message':
            'The secure sign-in service is unavailable. Please try again later.',
      };
    } on HttpException {
      return {
        'success': false,
        'message':
            'The secure sign-in service is unavailable. Please try again later.',
      };
    } on HandshakeException {
      return {
        'success': false,
        'message':
            'The secure sign-in service is unavailable. Please try again later.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    } finally {
      client.close();
    }
  }

  static Future<void> _saveSuccessfulSignIn({
    required String userId,
    required String email,
    required String role,
    String? token,
  }) async {
    await SessionService.saveSession(
      userId: userId,
      email: email,
      role: role,
    ).timeout(const Duration(seconds: 5));

    if (token == null || token.isEmpty)
      throw StateError('A signed session is required');
    await SessionTokenStore.write(token);
    await (await SupabaseCore.ensurePrefs()).remove('user_token');

    PushConfig.loginUser(userId);
    // Keep login responsive even if FCM token registration is slow.
    unawaited(
      PushNotificationService.syncUserIdentity()
          .timeout(const Duration(seconds: 5))
          .catchError((_) {}),
    );
  }

  /// Sign out – clears saved session.
  static Future<void> signOut() async {
    try {
      await AuthenticatedApi.post('/api/auth/logout', {});
    } catch (_) {}
    await SessionTokenStore.clear();
    await BackgroundNotificationService.stop();
    PushConfig.logoutUser();
    await PushNotificationService.clearUserIdentity();
    ProfileService.clearCache();
    await SessionService.clearSession();
  }

  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final result = await AuthenticatedApi.post('/api/auth/password', {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
    if (result['success'] == true) await signOut();
    return result;
  }

  static Future<Map<String, dynamic>> verifyCurrentPassword({
    required String currentPassword,
  }) => AuthenticatedApi.post('/api/auth/password', {
    'current_password': currentPassword,
  });

  static Future<Map<String, dynamic>> resumeSession() async {
    final result = await AuthenticatedApi.post('/api/auth/session', {});
    if (result['success'] != true) return result;
    final data = result['data'] as Map<String, dynamic>;
    await SessionService.saveSession(
      userId: data['id'] as String,
      email: data['email'] as String,
      role: (data['role'] as String).toUpperCase(),
    );
    return {
      'success': true,
      'user_id': data['id'],
      'email': data['email'],
      'role': (data['role'] as String).toUpperCase(),
    };
  }

  /// Recovery requires an administrator-issued, expiring one-use token.
  static Future<Map<String, dynamic>> resetForgottenPassword({
    required String email,
    required String verificationValue,
    required String newPassword,
  }) => AuthenticatedApi.post('/api/auth/recovery', {
    'email': email.trim().toLowerCase(),
    'recovery_token': verificationValue,
    'new_password': newPassword,
  });
}
