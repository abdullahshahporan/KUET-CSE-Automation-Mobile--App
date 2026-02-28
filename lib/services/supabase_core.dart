import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Core Supabase client accessor and initialization.
///
/// This is the single place that holds the Supabase client and
/// SharedPreferences instances. Other services depend on this.
class SupabaseCore {
  SupabaseCore._();

  static SupabaseClient? _client;
  static SharedPreferences? _prefs;

  /// Initialize Supabase + SharedPreferences. Call once in `main()`.
  static Future<void> initialize({
    String? supabaseUrl,
    String? supabaseAnonKey,
  }) async {
    await Supabase.initialize(
      url: supabaseUrl ?? SupabaseConfig.supabaseUrl,
      anonKey: supabaseAnonKey ?? SupabaseConfig.supabaseAnonKey,
      debug: kDebugMode,
    );
    _client = Supabase.instance.client;
    _prefs = await SharedPreferences.getInstance();
  }

  /// Ensure SharedPreferences is ready (safety net).
  static Future<SharedPreferences> ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Get the Supabase client singleton.
  static SupabaseClient get client {
    if (_client == null) {
      try {
        _client = Supabase.instance.client;
      } catch (e) {
        throw Exception(
          'Supabase not initialized. Call SupabaseCore.initialize() first.',
        );
      }
    }
    return _client!;
  }

  /// Shorthand for `client.from(table)`.
  static SupabaseQueryBuilder from(String table) => client.from(table);

  /// Access to SharedPreferences (can be null if not yet initialized).
  static SharedPreferences? get prefs => _prefs;
}
