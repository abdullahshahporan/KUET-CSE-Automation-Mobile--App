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

  /// Ensure SharedPreferences is initialized (safety net)
  static Future<SharedPreferences> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
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

      // Ensure SharedPreferences is initialized before writing
      final prefs = await _ensurePrefs();
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyUserId, userId);
      await prefs.setString(_keyEmail, userEmail);
      await prefs.setString(_keyRole, role);

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
    final prefs = await _ensurePrefs();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyRole);
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

  /// Get student profile from database (profiles + students tables)
  static Future<Map<String, dynamic>?> getStudentProfile() async {
    final userId = currentUserId;
    if (userId == null) return null;

    try {
      final profileData = await client
          .from('profiles')
          .select('user_id, email, role, is_active, last_login, created_at')
          .eq('user_id', userId)
          .maybeSingle();

      if (profileData == null) return null;

      final studentData = await client
          .from('students')
          .select('roll_no, full_name, phone, term, session, batch, section, cgpa')
          .eq('user_id', userId)
          .maybeSingle();

      if (studentData == null) return profileData;

      // Parse term '1-2' → year=1, semester=2
      final term = (studentData['term'] ?? '1-1') as String;
      final termParts = term.split('-');
      final year = int.tryParse(termParts[0]) ?? 1;
      final semester = int.tryParse(termParts.length > 1 ? termParts[1] : '1') ?? 1;

      return {
        ...profileData,
        ...studentData,
        'current_year': year,
        'current_semester': semester,
        'year_display': _getYearDisplay(year),
        'semester_display': _getSemesterDisplay(semester),
      };
    } catch (e) {
      debugPrint('Error fetching student profile: $e');
      return null;
    }
  }

  /// Get teacher profile from database (profiles + teachers tables)
  static Future<Map<String, dynamic>?> getTeacherProfile() async {
    await _ensurePrefs();
    final userId = currentUserId;
    if (userId == null) return null;

    try {
      final profileData = await client
          .from('profiles')
          .select('user_id, email, role, is_active, last_login, created_at')
          .eq('user_id', userId)
          .maybeSingle();

      if (profileData == null) return null;

      final teacherData = await client
          .from('teachers')
          .select('teacher_uid, full_name, phone, designation, department, office_room, room_no, date_of_join, created_at')
          .eq('user_id', userId)
          .maybeSingle();

      if (teacherData == null) return profileData;

      return {
        ...profileData,
        ...teacherData,
        'designation_display': _getDesignationDisplay(teacherData['designation']),
      };
    } catch (e) {
      debugPrint('Error fetching teacher profile: $e');
      return null;
    }
  }

  /// Update student term (one-way upgrade only).
  /// Returns true on success.
  static Future<bool> updateStudentTerm(String newTerm) async {
    final userId = currentUserId;
    if (userId == null) return false;

    try {
      await client
          .from('students')
          .update({'term': newTerm})
          .eq('user_id', userId);
      return true;
    } catch (e) {
      debugPrint('Error updating student term: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Term Upgrade Requests
  // ---------------------------------------------------------------------------

  /// Get the latest term upgrade request for the current student.
  /// Returns null if no request exists.
  static Future<Map<String, dynamic>?> getLatestTermUpgradeRequest() async {
    final userId = currentUserId;
    if (userId == null) return null;

    try {
      final response = await client
          .from('term_upgrade_requests')
          .select()
          .eq('student_user_id', userId)
          .order('requested_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('Error fetching term upgrade request: $e');
      return null;
    }
  }

  /// Submit a term upgrade request.
  /// Returns `true` on success.
  static Future<bool> submitTermUpgradeRequest({
    required String currentTerm,
    required String requestedTerm,
    String? reason,
  }) async {
    final userId = currentUserId;
    if (userId == null) return false;

    try {
      await client.from('term_upgrade_requests').insert({
        'student_user_id': userId,
        'current_term': currentTerm,
        'requested_term': requestedTerm,
        'reason': reason,
        'status': 'pending',
      });
      return true;
    } catch (e) {
      debugPrint('Error submitting term upgrade request: $e');
      return false;
    }
  }

  /// Update student phone number
  static Future<bool> updateStudentPhone(String phone) async {
    final userId = currentUserId;
    if (userId == null) return false;

    try {
      await client
          .from('students')
          .update({'phone': phone})
          .eq('user_id', userId);
      return true;
    } catch (e) {
      debugPrint('Error updating student phone: $e');
      return false;
    }
  }

  /// Update teacher phone number
  static Future<bool> updateTeacherPhone(String phone) async {
    final userId = currentUserId;
    if (userId == null) return false;

    try {
      await client
          .from('teachers')
          .update({'phone': phone})
          .eq('user_id', userId);
      return true;
    } catch (e) {
      debugPrint('Error updating teacher phone: $e');
      return false;
    }
  }

  /// Update teacher profile fields (any combination).
  /// Pass only the fields you want to update.
  static Future<bool> updateTeacherProfile(Map<String, dynamic> fields) async {
    final userId = currentUserId;
    if (userId == null || fields.isEmpty) return false;

    try {
      await client
          .from('teachers')
          .update(fields)
          .eq('user_id', userId);
      return true;
    } catch (e) {
      debugPrint('Error updating teacher profile: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Teacher Assigned Courses (from course_offerings)
  // ---------------------------------------------------------------------------

  /// Fetch courses assigned to the currently logged-in teacher
  /// Joins course_offerings → courses to get full course info
  static Future<List<Map<String, dynamic>>> getTeacherAssignedCourses() async {
    await _ensurePrefs();
    final userId = currentUserId;
    if (userId == null) return [];

    try {
      final response = await client
          .from('course_offerings')
          .select('''
            id,
            course_id,
            term,
            session,
            batch,
            is_active,
            courses (
              id,
              code,
              title,
              credit,
              course_type,
              description
            )
          ''')
          .eq('teacher_user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('[TeacherCourses] ERROR: $e');
      return [];
    }
  }

  /// Subscribe to real-time changes on course_offerings for this teacher
  static dynamic subscribeToTeacherCourses({
    required Function() onChanged,
  }) {
    final userId = currentUserId;
    if (userId == null) return null;

    return client
        .channel('teacher-courses-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'course_offerings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'teacher_user_id',
            value: userId,
          ),
          callback: (payload) {
            debugPrint('[Realtime] Teacher courses changed: ${payload.eventType}');
            onChanged();
          },
        )
        .subscribe();
  }

  /// Remove a real-time channel subscription
  static Future<void> removeChannel(dynamic channel) async {
    if (channel != null) {
      await client.removeChannel(channel as RealtimeChannel);
    }
  }

  // ---------------------------------------------------------------------------
  // Password change
  // ---------------------------------------------------------------------------

  /// Change password: verify current password then update hash
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      return {'success': false, 'message': 'Not logged in'};
    }

    try {
      // Fetch current hash
      final profile = await client
          .from('profiles')
          .select('password_hash')
          .eq('user_id', userId)
          .maybeSingle();

      if (profile == null) {
        return {'success': false, 'message': 'Profile not found'};
      }

      final storedHash = profile['password_hash'] as String? ?? '';

      // Verify current password
      if (!BCrypt.checkpw(currentPassword, storedHash)) {
        return {'success': false, 'message': 'Current password is incorrect'};
      }

      // Hash new password and update
      final newHash = BCrypt.hashpw(newPassword, BCrypt.gensalt());
      await client
          .from('profiles')
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
