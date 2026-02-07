import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized Supabase service for the KUET CSE Automation app
///
/// Authentication queries the `profiles` table directly and verifies
/// the bcrypt-hashed password on the client side using the `bcrypt` package.
class SupabaseService {
  static SupabaseClient? _client;
  static SharedPreferences? _prefs;

  // SharedPreferences keys
  static const _keyUserId = 'user_id';
  static const _keyEmail = 'user_email';
  static const _keyRole = 'user_role';
  static const _keyIsLoggedIn = 'is_logged_in';

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
      debug: kDebugMode,
    );
    _client = Supabase.instance.client;
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get the Supabase client instance
  static SupabaseClient get client {
    if (_client == null) {
      try {
        _client = Supabase.instance.client;
      } catch (e) {
        throw Exception(
          'SupabaseService not initialized. Call SupabaseService.initialize() first.',
        );
      }
    }
    return _client!;
  }

  /// Shorthand for accessing database
  static SupabaseQueryBuilder from(String table) => client.from(table);

  // ---------------------------------------------------------------------------
  // Authentication (direct Supabase query + client-side bcrypt verification)
  // ---------------------------------------------------------------------------

  /// Sign in by querying the `profiles` table and verifying the bcrypt hash.
  ///
  /// Returns a Map with keys: `success`, `user_id`, `role`, `email`, `message`
  static Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Query the profiles table for the user
      final response = await client
          .from('profiles')
          .select('user_id, email, password_hash, role, is_active')
          .eq('email', email.trim().toLowerCase())
          .maybeSingle();

      if (response == null) {
        return {
          'success': false,
          'message': 'Invalid email or password',
        };
      }

      // Check if account is active
      final isActive = response['is_active'] as bool? ?? false;
      if (!isActive) {
        return {
          'success': false,
          'message': 'Account is deactivated. Contact admin.',
        };
      }

      // Verify password using bcrypt
      final storedHash = response['password_hash'] as String? ?? '';
      final passwordMatches = BCrypt.checkpw(password, storedHash);

      if (!passwordMatches) {
        return {
          'success': false,
          'message': 'Invalid email or password',
        };
      }

      // Password verified – save session locally
      final userId = (response['user_id'] ?? '').toString();
      final role = (response['role'] ?? '').toString();
      final userEmail = (response['email'] ?? email).toString();

      await _prefs?.setBool(_keyIsLoggedIn, true);
      await _prefs?.setString(_keyUserId, userId);
      await _prefs?.setString(_keyEmail, userEmail);
      await _prefs?.setString(_keyRole, role);

      // Update last_login timestamp (non-critical)
      try {
        await client
            .from('profiles')
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
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  /// Sign out – clears saved session
  static Future<void> signOut() async {
    await _prefs?.remove(_keyIsLoggedIn);
    await _prefs?.remove(_keyUserId);
    await _prefs?.remove(_keyEmail);
    await _prefs?.remove(_keyRole);
  }

  // ---------------------------------------------------------------------------
  // Session helpers
  // ---------------------------------------------------------------------------

  /// Whether a user session is saved locally
  static bool get isLoggedIn => _prefs?.getBool(_keyIsLoggedIn) ?? false;

  /// Current user's ID (from local session)
  static String? get currentUserId => _prefs?.getString(_keyUserId);

  /// Current user's email (from local session)
  static String? get currentEmail => _prefs?.getString(_keyEmail);

  /// Current user's role (from local session) – e.g. STUDENT, TEACHER, ADMIN
  static String? get currentRole => _prefs?.getString(_keyRole);

  // ---------------------------------------------------------------------------
  // Profile methods
  // ---------------------------------------------------------------------------

  /// Get student profile from database
  static Future<Map<String, dynamic>?> getStudentProfile() async {
    final userId = currentUserId;
    if (userId == null) return null;

    try {
      final userData = await client
          .from('users')
          .select('id, email, full_name, phone, address, role, status')
          .eq('id', userId)
          .maybeSingle();

      if (userData == null) return null;

      final studentData = await client
          .from('students')
          .select('roll_no, department, batch, section, admission_year, current_year, current_semester, session')
          .eq('user_id', userId)
          .maybeSingle();

      if (studentData == null) return userData;

      return {
        ...userData,
        ...studentData,
        'year_display': _getYearDisplay(studentData['current_year']),
        'semester_display': _getSemesterDisplay(studentData['current_semester']),
      };
    } catch (e) {
      debugPrint('Error fetching student profile: $e');
      return null;
    }
  }

  /// Get teacher profile from database
  static Future<Map<String, dynamic>?> getTeacherProfile() async {
    final userId = currentUserId;
    if (userId == null) return null;

    try {
      final userData = await client
          .from('users')
          .select('id, email, full_name, phone, address, role, status')
          .eq('id', userId)
          .maybeSingle();

      if (userData == null) return null;

      final teacherData = await client
          .from('teachers')
          .select('employee_id, department, designation, experience_years, office_room')
          .eq('user_id', userId)
          .maybeSingle();

      if (teacherData == null) return userData;

      return {
        ...userData,
        ...teacherData,
        'designation_display': _getDesignationDisplay(teacherData['designation']),
      };
    } catch (e) {
      debugPrint('Error fetching teacher profile: $e');
      return null;
    }
  }

  /// Update user contact info (phone and address)
  static Future<bool> updateContactInfo({
    String? phone,
    String? address,
  }) async {
    final userId = currentUserId;
    if (userId == null) return false;

    try {
      await client
          .from('users')
          .update({
            if (phone != null) 'phone': phone,
            if (address != null) 'address': address,
          })
          .eq('id', userId);
      return true;
    } catch (e) {
      debugPrint('Error updating contact info: $e');
      return false;
    }
  }

  /// Get first name from full name
  static String getFirstName(String? fullName) {
    if (fullName == null || fullName.isEmpty) return 'User';
    return fullName.split(' ').first;
  }

  // Helper methods
  static String _getYearDisplay(int? year) {
    switch (year) {
      case 1: return '1st';
      case 2: return '2nd';
      case 3: return '3rd';
      case 4: return '4th';
      default: return '${year ?? 1}th';
    }
  }

  static String _getSemesterDisplay(int? semester) {
    switch (semester) {
      case 1: return '1st';
      case 2: return '2nd';
      default: return '${semester ?? 1}th';
    }
  }

  static String _getDesignationDisplay(String? designation) {
    switch (designation) {
      case 'LECTURER': return 'Lecturer';
      case 'ASSISTANT_PROFESSOR': return 'Assistant Professor';
      case 'ASSOCIATE_PROFESSOR': return 'Associate Professor';
      case 'PROFESSOR': return 'Professor';
      default: return designation ?? 'Faculty';
    }
  }
}
