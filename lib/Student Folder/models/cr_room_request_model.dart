/// Model for CR (Class Representative) room requests.
class CRRoomRequest {
  final String id;
  final String studentUserId;
  final String courseCode;
  final String teacherUserId;
  final String? roomNumber;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final String term;
  final String session;
  final String? section;
  final String? reason;
  final String status; // 'pending', 'approved', 'rejected'
  final String? adminRemarks;
  final DateTime? createdAt;
  final String? requestDate;
  // Joined fields
  final String? courseTitle;
  final String? teacherName;

  const CRRoomRequest({
    required this.id,
    required this.studentUserId,
    required this.courseCode,
    required this.teacherUserId,
    this.roomNumber,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.term,
    required this.session,
    this.section,
    this.reason,
    required this.status,
    this.adminRemarks,
    this.createdAt,
    this.requestDate,
    this.courseTitle,
    this.teacherName,
  });

  factory CRRoomRequest.fromMap(Map<String, dynamic> m) {
    final teacher = m['teachers'] as Map<String, dynamic>? ?? {};

    return CRRoomRequest(
      id: m['id'] as String,
      studentUserId: m['student_user_id'] as String,
      courseCode: m['course_code'] as String,
      teacherUserId: m['teacher_user_id'] as String,
      roomNumber: m['room_number'] as String?,
      dayOfWeek: m['day_of_week'] as int,
      startTime: m['start_time'] as String? ?? '',
      endTime: m['end_time'] as String? ?? '',
      term: m['term'] as String,
      session: m['session'] as String,
      section: m['section'] as String?,
      reason: m['reason'] as String?,
      status: m['status'] as String,
      adminRemarks: m['admin_remarks'] as String?,
      createdAt: m['created_at'] != null
          ? DateTime.tryParse(m['created_at'] as String)
          : null,
      requestDate: m['request_date'] as String?,
      courseTitle: m['course_title'] as String?,
      teacherName: teacher['full_name'] as String?,
    );
  }

  String get dayName => _dayNames[dayOfWeek];

  static const _dayNames = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];
}
