/// Teacher user model for KUET CSE Automation App

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

/// Teacher user with additional properties
class TeacherUser extends AppUser {
  final String designation;
  final String? officeRoom;
  final List<String> assignedCourses;
  final String? phone;
  final String? employeeId;
  final int experience;

  const TeacherUser({
    required super.id,
    required super.name,
    required super.email,
    required this.designation,
    this.officeRoom,
    this.assignedCourses = const [],
    this.phone,
    this.employeeId,
    this.experience = 0,
    super.department,
    super.photoUrl,
  }) : super(role: UserRole.teacher);
}
