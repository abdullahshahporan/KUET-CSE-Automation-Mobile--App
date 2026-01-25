import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized Supabase service for the KUET CSE Automation app
///
/// Usage:
/// ```dart
/// final supabase = SupabaseService.client;
/// ```
class SupabaseService {
  static SupabaseClient? _client;

  /// Initialize Supabase with your project credentials
  ///
  /// Call this ONCE in main.dart before runApp()
  static Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      // Deep link configuration for email verification
      debug: true,
    );
    _client = Supabase.instance.client;
  }

  /// Get the Supabase client instance
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception(
        'SupabaseService not initialized. Call SupabaseService.initialize() first.',
      );
    }
    return _client!;
  }

  /// Shorthand for accessing auth
  static GoTrueClient get auth => client.auth;

  /// Shorthand for accessing database
  static SupabaseQueryBuilder from(String table) => client.from(table);
}

/// Extension methods for common auth operations
extension SupabaseAuthExtension on GoTrueClient {
  /// Get current user's ID (uuid)
  String? get userId => currentUser?.id;

  /// Check if user is signed in
  bool get isSignedIn => currentUser != null;
}
