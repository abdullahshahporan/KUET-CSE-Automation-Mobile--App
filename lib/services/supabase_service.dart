import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized Supabase service for the KUET CSE Automation app
///
/// Usage:
/// ```dart
/// final supabase = SupabaseService.client;
/// ```
class SupabaseService {
  static SupabaseClient? _client;
  static bool _isInitialized = false;

  /// Initialize Supabase with your project credentials
  ///
  /// Call this ONCE in main.dart before runApp()
  static Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    if (_isInitialized) return; // Prevent double initialization
    
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
    _isInitialized = true;
  }

  /// Get the Supabase client instance
  static SupabaseClient get client {
    // Always try to get from Supabase.instance if our client is null
    if (_client == null) {
      try {
        _client = Supabase.instance.client;
        _isInitialized = true;
      } catch (e) {
        throw Exception(
          'SupabaseService not initialized. Call SupabaseService.initialize() first.',
        );
      }
    }
    return _client!;
  }

  /// Shorthand for accessing auth
  static GoTrueClient get auth => client.auth;

  /// Shorthand for accessing database
  static SupabaseQueryBuilder from(String table) => client.from(table);

  // =========================================
  // PROFILE METHODS
  // =========================================

  /// Get current user's ID
  static String? get currentUserId => auth.currentUser?.id;

  /// Get current user's email
  static String? get currentUserEmail => auth.currentUser?.email;

  /// Get student profile from database
  static Future<Map<String, dynamic>?> getStudentProfile() async {
    final userId = currentUserId;
    if (userId == null) return null;

    try {
      // First get user data
      final userData = await client
          .from('users')
          .select('id, email, full_name, phone, address, role, status')
          .eq('id', userId)
          .maybeSingle();

      if (userData == null) return null;

      // Then get student specific data
      final studentData = await client
          .from('students')
          .select('roll_no, department, batch, section, admission_year, current_year, current_semester, session')
          .eq('user_id', userId)
          .maybeSingle();

      if (studentData == null) return userData;

      // Merge data
      return {
        ...userData,
        ...studentData,
        'year_display': _getYearDisplay(studentData['current_year']),
        'semester_display': _getSemesterDisplay(studentData['current_semester']),
      };
    } catch (e) {
      print('Error fetching student profile: $e');
      return null;
    }
  }

  /// Get teacher profile from database
  static Future<Map<String, dynamic>?> getTeacherProfile() async {
    final userId = currentUserId;
    if (userId == null) return null;

    try {
      // First get user data
      final userData = await client
          .from('users')
          .select('id, email, full_name, phone, address, role, status')
          .eq('id', userId)
          .maybeSingle();

      if (userData == null) return null;

      // Then get teacher specific data
      final teacherData = await client
          .from('teachers')
          .select('employee_id, department, designation, experience_years, office_room')
          .eq('user_id', userId)
          .maybeSingle();

      if (teacherData == null) return userData;

      // Merge data
      return {
        ...userData,
        ...teacherData,
        'designation_display': _getDesignationDisplay(teacherData['designation']),
      };
    } catch (e) {
      print('Error fetching teacher profile: $e');
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
      print('Error updating contact info: $e');
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

/// Extension methods for common auth operations
extension SupabaseAuthExtension on GoTrueClient {
  /// Get current user's ID (uuid)
  String? get userId => currentUser?.id;

  /// Check if user is signed in
  bool get isSignedIn => currentUser != null;
}
