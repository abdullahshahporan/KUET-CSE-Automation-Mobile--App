class EnrolledStudent {
  final String enrollmentId;
  final String userId;
  final String rollNo;
  final String fullName;
  final String phone;
  final String term;
  final String session;
  final String? batch;
  final String? section;
  final double cgpa;
  final String enrollmentStatus;
  final DateTime enrolledAt;

  EnrolledStudent({
    required this.enrollmentId,
    required this.userId,
    required this.rollNo,
    required this.fullName,
    required this.phone,
    required this.term,
    required this.session,
    this.batch,
    this.section,
    required this.cgpa,
    required this.enrollmentStatus,
    required this.enrolledAt,
  });

  factory EnrolledStudent.fromJson(Map<String, dynamic> json) {
    final student = json['students'] as Map<String, dynamic>;
    
    return EnrolledStudent(
      enrollmentId: json['id'] as String,
      userId: student['user_id'] as String,
      rollNo: student['roll_no'] as String,
      fullName: student['full_name'] as String,
      phone: student['phone'] as String,
      term: student['term'] as String,
      session: student['session'] as String,
      batch: student['batch'] as String?,
      section: student['section'] as String?,
      cgpa: (student['cgpa'] as num?)?.toDouble() ?? 0.0,
      enrollmentStatus: json['enrollment_status'] as String,
      enrolledAt: DateTime.parse(json['enrolled_at'] as String),
    );
  }

  /// Create from a direct students table row (no enrollment wrapper)
  factory EnrolledStudent.fromStudentRow(Map<String, dynamic> row) {
    return EnrolledStudent(
      enrollmentId: '', // no enrollment record
      userId: row['user_id'] as String,
      rollNo: row['roll_no'] as String,
      fullName: row['full_name'] as String,
      phone: row['phone'] as String? ?? '',
      term: row['term'] as String,
      session: row['session'] as String,
      batch: row['batch'] as String?,
      section: row['section'] as String?,
      cgpa: (row['cgpa'] as num?)?.toDouble() ?? 0.0,
      enrollmentStatus: 'ENROLLED',
      enrolledAt: row['created_at'] != null
          ? DateTime.tryParse(row['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String get initial => fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';

  /// Derive section from roll number: last 3 digits 001-060 = A, 061-120 = B
  String get derivedSection {
    if (rollNo.length < 3) return section ?? 'A';
    try {
      final lastDigits = int.parse(rollNo.substring(rollNo.length - 3));
      return lastDigits <= 60 ? 'A' : 'B';
    } catch (_) {
      return section ?? 'A';
    }
  }

  String get termDisplay {
    final parts = term.split('-');
    if (parts.length != 2) return term;
    return '${parts[0]}-${parts[1]}';
  }
}
