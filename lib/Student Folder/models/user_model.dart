/// User and role models for KUET CSE Automation App

/// User roles in the system
enum UserRole { student, teacher, admin }

/// Extension to get role from email domain
extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.student:
        return 'Student';
      case UserRole.teacher:
        return 'Teacher';
      case UserRole.admin:
        return 'Admin';
    }
  }
}

/// Detect user role from email domain
UserRole? getUserRoleFromEmail(String email) {
  email = email.toLowerCase().trim();
  if (email.endsWith('@stud.kuet.ac.bd')) {
    return UserRole.student;
  } else if (email.endsWith('@cse.kuet.ac.bd')) {
    return UserRole.teacher;
  } else if (email.endsWith('@kuet.ac.bd')) {
    return UserRole.admin;
  }
  return null; // Unknown domain
}

/// Base user class
class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? department;
  final String? photoUrl;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.department = 'Computer Science & Engineering',
    this.photoUrl,
  });
}

/// Student user with additional properties
class StudentUser extends AppUser {
  final String roll;
  final String batch;
  final int currentYear;
  final int currentTerm;
  final String section; // A or B

  const StudentUser({
    required super.id,
    required super.name,
    required super.email,
    required this.roll,
    required this.batch,
    required this.currentYear,
    required this.currentTerm,
    required this.section,
    super.department,
    super.photoUrl,
  }) : super(role: UserRole.student);

  /// Get sessional group based on roll
  String get sessionalGroup {
    final rollNum = int.tryParse(roll.substring(roll.length - 3)) ?? 0;
    if (rollNum <= 30) return 'A1';
    if (rollNum <= 60) return 'A2';
    if (rollNum <= 90) return 'B1';
    return 'B2';
  }

  /// Get formatted batch (e.g., "2021")
  String get formattedBatch => '20$batch';

  /// Get semester name (e.g., "3rd Year 2nd Term")
  String get semesterName {
    final yearSuffix = currentYear == 1
        ? 'st'
        : currentYear == 2
        ? 'nd'
        : currentYear == 3
        ? 'rd'
        : 'th';
    final termSuffix = currentTerm == 1 ? 'st' : 'nd';
    return '$currentYear$yearSuffix Year $currentTerm$termSuffix Term';
  }
}
