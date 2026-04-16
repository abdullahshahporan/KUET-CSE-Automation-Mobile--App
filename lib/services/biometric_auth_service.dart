import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import 'auth_service.dart';
import 'session_service.dart';

/// Handles device biometric availability plus securely stored login credentials.
class BiometricAuthService {
  BiometricAuthService._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static final LocalAuthentication _localAuth = LocalAuthentication();

  static const _keyEnabled = 'biometric_login_enabled';
  static const _keyEmail = 'biometric_login_email';
  static const _keyPassword = 'biometric_login_password';
  static const _keyRole = 'biometric_login_role';

  static Future<bool> isSupported() async {
    try {
      final deviceSupported = await _localAuth.isDeviceSupported();
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      if (!deviceSupported || !canCheckBiometrics) {
        return false;
      }

      final biometrics = await _localAuth.getAvailableBiometrics();
      return biometrics.any(_supportsBiometricType);
    } catch (e, st) {
      debugPrint('Biometric support check failed: $e\n$st');
      return false;
    }
  }

  static Future<bool> isEnabled() async =>
      (await _storage.read(key: _keyEnabled)) == 'true';

  static Future<bool> hasStoredCredentials() async {
    final email = await _storage.read(key: _keyEmail);
    final password = await _storage.read(key: _keyPassword);
    return (email?.isNotEmpty ?? false) && (password?.isNotEmpty ?? false);
  }

  static Future<bool> isReadyForBiometricLogin() async {
    if (!await isSupported()) {
      return false;
    }
    return await isEnabled() && await hasStoredCredentials();
  }

  static Future<Map<String, dynamic>> enableForCurrentUser({
    required String currentPassword,
  }) async {
    final email = SessionService.currentEmail;
    final role = SessionService.currentRole;

    if (email == null || role == null) {
      return {
        'success': false,
        'message': 'Log in again before enabling biometric login.',
      };
    }

    final supported = await isSupported();
    if (!supported) {
      return {
        'success': false,
        'message': 'Biometric authentication is not available on this device.',
      };
    }

    final verification = await AuthService.verifyCurrentPassword(
      currentPassword: currentPassword,
    );
    if (verification['success'] != true) {
      return verification;
    }

    final authenticated = await _authenticate(
      reason:
          'Confirm your identity to enable fingerprint login on this device.',
    );
    if (!authenticated) {
      return {
        'success': false,
        'message': 'Biometric verification was cancelled.',
      };
    }

    await _storage.write(key: _keyEnabled, value: 'true');
    await _storage.write(key: _keyEmail, value: email.trim().toLowerCase());
    await _storage.write(key: _keyPassword, value: currentPassword);
    await _storage.write(key: _keyRole, value: role);

    return {
      'success': true,
      'message': 'Fingerprint login enabled for this device.',
    };
  }

  static Future<void> disable() async {
    await _storage.delete(key: _keyEnabled);
    await _storage.delete(key: _keyEmail);
    await _storage.delete(key: _keyPassword);
    await _storage.delete(key: _keyRole);
  }

  static Future<Map<String, dynamic>> signInWithBiometrics() async {
    if (!await isReadyForBiometricLogin()) {
      return {
        'success': false,
        'message': 'Enable fingerprint login first from Settings.',
      };
    }

    final authenticated = await _authenticate(
      reason: 'Authenticate to sign in with fingerprint.',
    );
    if (!authenticated) {
      return {
        'success': false,
        'message': 'Biometric authentication was cancelled.',
      };
    }

    final email = await _storage.read(key: _keyEmail);
    final password = await _storage.read(key: _keyPassword);
    if (email == null || password == null) {
      await disable();
      return {
        'success': false,
        'message': 'Saved fingerprint credentials are incomplete.',
      };
    }

    final result = await AuthService.signIn(email: email, password: password);
    final message = (result['message'] ?? '').toString();
    if (result['success'] != true && message == 'Invalid email or password') {
      await disable();
      return {
        'success': false,
        'message':
            'Saved fingerprint credentials are outdated. Sign in with your password and enable fingerprint login again.',
      };
    }

    return result;
  }

  static Future<void> syncStoredPasswordIfEnabled({
    required String email,
    required String newPassword,
    String? role,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      return;
    }

    if (!await isEnabled()) {
      return;
    }

    final storedEmail = (await _storage.read(
      key: _keyEmail,
    ))?.trim().toLowerCase();
    if (storedEmail != normalizedEmail) {
      return;
    }

    await _storage.write(key: _keyPassword, value: newPassword);
    if (role != null && role.isNotEmpty) {
      await _storage.write(key: _keyRole, value: role);
    }
  }

  static Future<bool> _authenticate({required String reason}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } on PlatformException catch (e, st) {
      debugPrint('Biometric authentication failed: $e\n$st');
      return false;
    } catch (e, st) {
      debugPrint('Unexpected biometric error: $e\n$st');
      return false;
    }
  }

  static bool _supportsBiometricType(BiometricType type) {
    return type == BiometricType.fingerprint ||
        type == BiometricType.strong ||
        type == BiometricType.weak ||
        type == BiometricType.face;
  }
}
