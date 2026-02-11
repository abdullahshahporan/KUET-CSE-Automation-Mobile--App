import 'room_model.dart';

/// Occupancy state of a period in a room's schedule.
enum PeriodState { free, occupied, booked }

/// Combines a period with its occupancy info for display.
class PeriodStatus {
  final Period period;
  final PeriodState state;
  final String? courseCode;
  final String? teacherName;
  final String? bookingStatus; // 'pending' or 'approved' when state == booked

  PeriodStatus({
    required this.period,
    required this.state,
    this.courseCode,
    this.teacherName,
    this.bookingStatus,
  });
}

/// A room booking request from a teacher.
class RoomBookingRequest {
  final String id;
  final String teacherUserId;
  final String? offeringId;
  final String roomNumber;
  final int dayOfWeek;
  final String startPeriod;
  final String endPeriod;
  final String startTime;
  final String endTime;
  final String? section;
  final String? purpose;
  final String status;
  final String? courseCode;
  final String? courseTitle;
  final String? teacherName;
  final DateTime? requestedAt;

  RoomBookingRequest({
    required this.id,
    required this.teacherUserId,
    this.offeringId,
    required this.roomNumber,
    required this.dayOfWeek,
    required this.startPeriod,
    required this.endPeriod,
    required this.startTime,
    required this.endTime,
    this.section,
    this.purpose,
    required this.status,
    this.courseCode,
    this.courseTitle,
    this.teacherName,
    this.requestedAt,
  });

  factory RoomBookingRequest.fromMap(Map<String, dynamic> m) {
    final offering = m['course_offerings'] as Map<String, dynamic>?;
    final course = offering?['courses'] as Map<String, dynamic>? ?? {};
    final teacher = m['teachers'] as Map<String, dynamic>? ?? {};

    return RoomBookingRequest(
      id: m['id'] as String,
      teacherUserId: m['teacher_user_id'] as String,
      offeringId: m['offering_id'] as String?,
      roomNumber: m['room_number'] as String,
      dayOfWeek: m['day_of_week'] as int,
      startPeriod: m['start_period'] as String,
      endPeriod: m['end_period'] as String,
      startTime: m['start_time'] as String? ?? '',
      endTime: m['end_time'] as String? ?? '',
      section: m['section'] as String?,
      purpose: m['purpose'] as String?,
      status: m['status'] as String,
      courseCode: course['code'] as String?,
      courseTitle: course['title'] as String?,
      teacherName: teacher['full_name'] as String?,
      requestedAt: m['requested_at'] != null
          ? DateTime.tryParse(m['requested_at'] as String)
          : null,
    );
  }

  String get dayName => RoomSlot.dayNames[dayOfWeek];

  /// Whether this is a custom break-period booking.
  bool get isCustom => startPeriod == 'Custom';

  /// Check if this booking covers a specific period.
  bool coversPeriod(Period p) {
    final startIdx = Period.all.indexWhere((x) => x.label == startPeriod);
    final endIdx = Period.all.indexWhere((x) => x.label == endPeriod);
    final pIdx = Period.all.indexWhere((x) => x.label == p.label);
    return pIdx >= startIdx && pIdx <= endIdx;
  }
}
