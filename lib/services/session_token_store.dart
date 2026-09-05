import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionTokenStore {
  SessionTokenStore._();
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _key = 'deptflow_access_token';
  static Future<void> write(String token) =>
      _storage.write(key: _key, value: token);
  static Future<String?> read() => _storage.read(key: _key);
  static Future<void> clear() => _storage.delete(key: _key);
}
