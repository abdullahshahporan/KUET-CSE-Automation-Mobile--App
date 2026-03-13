import 'package:flutter/foundation.dart';

import '../../services/supabase_service.dart';
import '../../utils/time_utils.dart';
import '../Room_info/room_model.dart';
import '../Room_info/room_service.dart';
import 'teacher_schedule_model.dart';

enum RoomConflictSource { routine, teacherBooking, crBooking }

class RoomConflictRecord {
  final String roomNumber;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final String label;
  final RoomConflictSource source;

  const RoomConflictRecord({
    required this.roomNumber,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.label,
    required this.source,
  });

  bool overlaps(String otherStart, String otherEnd) {
    final start = TimeUtils.trimToHHmm(startTime);
    final end = TimeUtils.trimToHHmm(endTime);
    final targetStart = TimeUtils.trimToHHmm(otherStart);
    final targetEnd = TimeUtils.trimToHHmm(otherEnd);
    return start.compareTo(targetEnd) < 0 && end.compareTo(targetStart) > 0;
  }
}

class RoomAvailabilityOption {
  final Room room;
  final bool isAvailable;
  final String? conflictLabel;
  final RoomConflictSource? conflictSource;

  const RoomAvailabilityOption({
    required this.room,
    required this.isAvailable,
    this.conflictLabel,
    this.conflictSource,
  });
}

class TeacherRoomAllocationService {
  static Future<List<RoomAvailabilityOption>> fetchRoomAvailabilityForSlot({
    required TeacherSlot slot,
    required DateTime date,
  }) async {
    try {
      final dateKey = _dateKey(date);
      final results = await Future.wait([
        RoomService.fetchAllRooms(),
        _fetchRoutineConflicts(date),
        _fetchTeacherBookingConflicts(dateKey),
        _fetchCrBookingConflicts(dateKey),
      ]);

      final rooms = results[0] as List<Room>;
      final routineConflicts = results[1] as List<RoomConflictRecord>;
      final teacherBookingConflicts = results[2] as List<RoomConflictRecord>;
      final crBookingConflicts = results[3] as List<RoomConflictRecord>;

      return buildRoomAvailabilityOptions(
        rooms: rooms,
        slot: slot,
        routineConflicts: routineConflicts,
        teacherBookingConflicts: teacherBookingConflicts,
        crBookingConflicts: crBookingConflicts,
      );
    } catch (e) {
      debugPrint('Error fetching room availability: $e');
      return [];
    }
  }

  static Future<String?> findRoomConflictForSlot({
    required TeacherSlot slot,
    required DateTime date,
    required String roomNumber,
  }) async {
    final dateKey = _dateKey(date);

    try {
      final results = await Future.wait([
        _fetchRoutineConflicts(date),
        _fetchTeacherBookingConflicts(dateKey),
        _fetchCrBookingConflicts(dateKey),
      ]);

      return conflictLabelForRoom(
        roomNumber: roomNumber,
        slot: slot,
        routineConflicts: results[0],
        teacherBookingConflicts: results[1],
        crBookingConflicts: results[2],
      );
    } catch (e) {
      debugPrint('Error checking room conflict: $e');
      return 'Failed to verify room availability. Please try again.';
    }
  }

  static List<RoomAvailabilityOption> buildRoomAvailabilityOptions({
    required List<Room> rooms,
    required TeacherSlot slot,
    required List<RoomConflictRecord> routineConflicts,
    required List<RoomConflictRecord> teacherBookingConflicts,
    required List<RoomConflictRecord> crBookingConflicts,
  }) {
    final options = rooms.map((room) {
      final conflictLabel = conflictLabelForRoom(
        roomNumber: room.roomNumber,
        slot: slot,
        routineConflicts: routineConflicts,
        teacherBookingConflicts: teacherBookingConflicts,
        crBookingConflicts: crBookingConflicts,
      );
      final source = _conflictSourceForRoom(
        roomNumber: room.roomNumber,
        slot: slot,
        routineConflicts: routineConflicts,
        teacherBookingConflicts: teacherBookingConflicts,
        crBookingConflicts: crBookingConflicts,
      );

      return RoomAvailabilityOption(
        room: room,
        isAvailable: conflictLabel == null,
        conflictLabel: conflictLabel,
        conflictSource: source,
      );
    }).toList();

    options.sort((a, b) {
      if (a.isAvailable != b.isAvailable) {
        return a.isAvailable ? -1 : 1;
      }
      return a.room.roomNumber.compareTo(b.room.roomNumber);
    });
    return options;
  }

  static String? conflictLabelForRoom({
    required String roomNumber,
    required TeacherSlot slot,
    required List<RoomConflictRecord> routineConflicts,
    required List<RoomConflictRecord> teacherBookingConflicts,
    required List<RoomConflictRecord> crBookingConflicts,
  }) {
    final targetStart = slot.startTime;
    final targetEnd = slot.endTime;

    RoomConflictRecord? pickConflict(List<RoomConflictRecord> records) {
      for (final record in records) {
        if (record.roomNumber != roomNumber) continue;
        if (record.dayOfWeek != slot.dayOfWeek) continue;
        if (record.overlaps(targetStart, targetEnd)) {
          return record;
        }
      }
      return null;
    }

    final routineConflict = pickConflict(routineConflicts);
    if (routineConflict != null) return routineConflict.label;

    final teacherBookingConflict = pickConflict(teacherBookingConflicts);
    if (teacherBookingConflict != null) return teacherBookingConflict.label;

    final crBookingConflict = pickConflict(crBookingConflicts);
    if (crBookingConflict != null) return crBookingConflict.label;

    return null;
  }

  static RoomConflictSource? _conflictSourceForRoom({
    required String roomNumber,
    required TeacherSlot slot,
    required List<RoomConflictRecord> routineConflicts,
    required List<RoomConflictRecord> teacherBookingConflicts,
    required List<RoomConflictRecord> crBookingConflicts,
  }) {
    for (final record in [
      ...routineConflicts,
      ...teacherBookingConflicts,
      ...crBookingConflicts,
    ]) {
      if (record.roomNumber == roomNumber &&
          record.dayOfWeek == slot.dayOfWeek &&
          record.overlaps(slot.startTime, slot.endTime)) {
        return record.source;
      }
    }
    return null;
  }

  static Future<List<RoomConflictRecord>> _fetchRoutineConflicts(
    DateTime date,
  ) async {
    final day = date.weekday == DateTime.sunday ? 0 : date.weekday;
    final data = await SupabaseService.client
        .from('routine_slots')
        .select('''
          id, offering_id, room_number, day_of_week, start_time, end_time, section,
          valid_from, valid_until,
          course_offerings!inner (
            is_active,
            courses ( code, title, course_type )
          )
        ''')
        .eq('day_of_week', day)
        .eq('course_offerings.is_active', true)
        .order('start_time', ascending: true);

    final slots = (data as List)
        .map((row) => TeacherSlot.fromMap(row as Map<String, dynamic>))
        .toList();
    final effective = TeacherSlot.resolveEffectiveSlotsForDate(slots, date);

    return effective
        .where((slot) => slot.isAssigned)
        .map(
          (slot) => RoomConflictRecord(
            roomNumber: slot.roomNumber,
            dayOfWeek: slot.dayOfWeek,
            startTime: slot.startTime,
            endTime: slot.endTime,
            label: 'Scheduled: ${slot.courseCode}',
            source: RoomConflictSource.routine,
          ),
        )
        .toList();
  }

  static Future<List<RoomConflictRecord>> _fetchTeacherBookingConflicts(
    String dateKey,
  ) async {
    final data = await SupabaseService.client
        .from('room_booking_requests')
        .select('''
          room_number, day_of_week, start_time, end_time,
          course_offerings ( courses ( code ) )
        ''')
        .eq('booking_date', dateKey)
        .eq('status', 'approved');

    return (data as List)
        .map((row) => row as Map<String, dynamic>)
        .where(
          (row) => (row['room_number'] as String?)?.trim().isNotEmpty ?? false,
        )
        .map((row) {
          final offering =
              row['course_offerings'] as Map<String, dynamic>? ?? {};
          final course = offering['courses'] as Map<String, dynamic>? ?? {};
          return RoomConflictRecord(
            roomNumber: row['room_number'] as String? ?? '',
            dayOfWeek: row['day_of_week'] as int? ?? 0,
            startTime: row['start_time'] as String? ?? '',
            endTime: row['end_time'] as String? ?? '',
            label: 'Booked: ${course['code'] ?? 'Teacher slot'}',
            source: RoomConflictSource.teacherBooking,
          );
        })
        .toList();
  }

  static Future<List<RoomConflictRecord>> _fetchCrBookingConflicts(
    String dateKey,
  ) async {
    final data = await SupabaseService.client
        .from('cr_room_requests')
        .select('room_number, day_of_week, start_time, end_time, course_code')
        .eq('request_date', dateKey)
        .eq('status', 'approved');

    return (data as List)
        .map((row) => row as Map<String, dynamic>)
        .where(
          (row) => (row['room_number'] as String?)?.trim().isNotEmpty ?? false,
        )
        .map(
          (row) => RoomConflictRecord(
            roomNumber: row['room_number'] as String? ?? '',
            dayOfWeek: row['day_of_week'] as int? ?? 0,
            startTime: row['start_time'] as String? ?? '',
            endTime: row['end_time'] as String? ?? '',
            label: 'CR booking: ${row['course_code'] ?? 'Booked slot'}',
            source: RoomConflictSource.crBooking,
          ),
        )
        .toList();
  }

  static String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
