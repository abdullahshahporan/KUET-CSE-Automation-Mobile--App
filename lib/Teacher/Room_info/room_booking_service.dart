import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import '../../services/supabase_service.dart';
import 'room_booking_model.dart';
import 'room_model.dart';

/// Service for room booking requests (CRUD + period status computation).
class RoomBookingService {
  // ─── Fetch pending/approved bookings for a room ───────
  static Future<List<RoomBookingRequest>> fetchRoomBookings(
      String roomNumber) async {
    try {
      final data = await SupabaseService.client
          .from('room_booking_requests')
          .select('''
            id, teacher_user_id, offering_id, room_number,
            day_of_week, start_period, end_period,
            start_time, end_time, section, purpose, status, requested_at,
            course_offerings ( courses ( code, title ) ),
            teachers!rbr_teacher_fkey ( full_name )
          ''')
          .eq('room_number', roomNumber)
          .eq('status', 'approved')
          .order('day_of_week')
          .order('start_time');

      return (data as List)
          .map((e) => RoomBookingRequest.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching room bookings: $e');
      return [];
    }
  }

  // ─── Submit a new booking request (timestamp-priority) ─
  /// Inserts a booking with auto-approved status if no conflicting
  /// booking exists for the same room + day + overlapping periods.
  /// If a conflict is found, the earlier `requested_at` wins.
  static Future<BookingResult> submitBookingRequest({
    required String roomNumber,
    required String offeringId,
    required int dayOfWeek,
    required Period fromPeriod,
    required Period toPeriod,
    String? section,
    String? purpose,
  }) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) {
      return const BookingResult(success: false, message: 'Not logged in.');
    }

    try {
      // 1. Check for conflicting bookings (same room, same day, overlapping periods)
      final conflicts = await _checkConflicts(
        roomNumber: roomNumber,
        dayOfWeek: dayOfWeek,
        fromPeriod: fromPeriod,
        toPeriod: toPeriod,
      );

      if (conflicts.isNotEmpty) {
        final earliest = conflicts.first; // ordered by requested_at asc
        return BookingResult(
          success: false,
          message:
              'Slot already booked! ${earliest.courseCode ?? "A course"} was '
              'booked by ${earliest.teacherName ?? "another teacher"} '
              '(requested first). Only one booking per slot is allowed.',
        );
      }

      // 2. No conflicts — auto-approve the booking immediately
      await SupabaseService.client.from('room_booking_requests').insert({
        'teacher_user_id': userId,
        'offering_id': offeringId,
        'room_number': roomNumber,
        'day_of_week': dayOfWeek,
        'start_period': fromPeriod.label,
        'end_period': toPeriod.label,
        'start_time': '${fromPeriod.start}:00',
        'end_time': '${toPeriod.end}:00',
        'section': section,
        'purpose': purpose,
        'status': 'approved',
      });
      return const BookingResult(
          success: true, message: 'Slot booked successfully!');
    } catch (e) {
      debugPrint('Error submitting booking request: $e');
      String msg = e.toString();
      if (msg.contains('row-level security') || msg.contains('policy')) {
        msg = 'Permission denied. RLS INSERT policy missing on '
            'room_booking_requests table. Ask admin to add it.';
      } else if (msg.contains('violates foreign key')) {
        msg = 'Invalid reference. Check that the course offering and '
            'teacher records exist.';
      } else if (msg.length > 150) {
        msg = msg.substring(0, 150);
      }
      return BookingResult(
        success: false,
        message: msg,
      );
    }
  }

  // ─── Submit a custom-time booking (break period) ──────
  /// For booking during the 1:10 PM – 2:30 PM break with custom times.
  static Future<BookingResult> submitCustomBookingRequest({
    required String roomNumber,
    required String offeringId,
    required int dayOfWeek,
    required TimeOfDay customStart,
    required TimeOfDay customEnd,
    String? section,
    String? purpose,
  }) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) {
      return const BookingResult(success: false, message: 'Not logged in.');
    }

    // Validate the custom time is within break period (13:10 – 14:30)
    final startMin = customStart.hour * 60 + customStart.minute;
    final endMin = customEnd.hour * 60 + customEnd.minute;
    const breakStart = 13 * 60 + 10; // 1:10 PM
    const breakEnd = 14 * 60 + 30;   // 2:30 PM

    if (startMin < breakStart || endMin > breakEnd || startMin >= endMin) {
      return const BookingResult(
        success: false,
        message: 'Custom time must be within 1:10 PM – 2:30 PM '
            'and start must be before end.',
      );
    }

    final startStr =
        '${customStart.hour.toString().padLeft(2, '0')}:${customStart.minute.toString().padLeft(2, '0')}';
    final endStr =
        '${customEnd.hour.toString().padLeft(2, '0')}:${customEnd.minute.toString().padLeft(2, '0')}';

    try {
      // Check for time-based conflicts in the break window
      final data = await SupabaseService.client
          .from('room_booking_requests')
          .select('''
            id, teacher_user_id, offering_id, room_number,
            day_of_week, start_period, end_period,
            start_time, end_time, section, purpose, status, requested_at,
            course_offerings ( courses ( code, title ) ),
            teachers!rbr_teacher_fkey ( full_name )
          ''')
          .eq('room_number', roomNumber)
          .eq('day_of_week', dayOfWeek)
          .eq('status', 'approved')
          .order('requested_at', ascending: true);

      final bookings = (data as List)
          .map((e) => RoomBookingRequest.fromMap(e as Map<String, dynamic>))
          .toList();

      // Time-based overlap check
      for (final b in bookings) {
        final bStart = _fmt(b.startTime);
        final bEnd = _fmt(b.endTime);
        // Overlaps if NOT (bEnd <= startStr OR bStart >= endStr)
        if (!(bEnd.compareTo(startStr) <= 0 ||
            bStart.compareTo(endStr) >= 0)) {
          return BookingResult(
            success: false,
            message:
                'Time conflict! ${b.courseCode ?? "A booking"} '
                '($bStart-$bEnd) overlaps with your requested time.',
          );
        }
      }

      await SupabaseService.client.from('room_booking_requests').insert({
        'teacher_user_id': userId,
        'offering_id': offeringId,
        'room_number': roomNumber,
        'day_of_week': dayOfWeek,
        'start_period': 'Custom',
        'end_period': 'Custom',
        'start_time': '$startStr:00',
        'end_time': '$endStr:00',
        'section': section,
        'purpose': purpose,
        'status': 'approved',
      });
      return const BookingResult(
          success: true, message: 'Custom slot booked successfully!');
    } catch (e) {
      debugPrint('Error submitting custom booking: $e');
      String msg = e.toString();
      if (msg.length > 150) msg = msg.substring(0, 150);
      return BookingResult(success: false, message: msg);
    }
  }

  // ─── Check for conflicting bookings ───────────────────
  static Future<List<RoomBookingRequest>> _checkConflicts({
    required String roomNumber,
    required int dayOfWeek,
    required Period fromPeriod,
    required Period toPeriod,
  }) async {
    try {
      final data = await SupabaseService.client
          .from('room_booking_requests')
          .select('''
            id, teacher_user_id, offering_id, room_number,
            day_of_week, start_period, end_period,
            start_time, end_time, section, purpose, status, requested_at,
            course_offerings ( courses ( code, title ) ),
            teachers!rbr_teacher_fkey ( full_name )
          ''')
          .eq('room_number', roomNumber)
          .eq('day_of_week', dayOfWeek)
          .eq('status', 'approved')
          .order('requested_at', ascending: true);

      final bookings = (data as List)
          .map((e) => RoomBookingRequest.fromMap(e as Map<String, dynamic>))
          .toList();

      // Check which bookings overlap with the requested period range
      final fromIdx =
          Period.all.indexWhere((x) => x.label == fromPeriod.label);
      final toIdx = Period.all.indexWhere((x) => x.label == toPeriod.label);

      return bookings.where((b) {
        final bFromIdx =
            Period.all.indexWhere((x) => x.label == b.startPeriod);
        final bToIdx = Period.all.indexWhere((x) => x.label == b.endPeriod);
        return !(bToIdx < fromIdx || bFromIdx > toIdx);
      }).toList();
    } catch (e) {
      debugPrint('Error checking conflicts: $e');
      return [];
    }
  }

  // ─── Fetch current teacher's active course offerings ──
  static Future<List<Map<String, dynamic>>> fetchTeacherOfferings() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return [];

    try {
      final data = await SupabaseService.client
          .from('course_offerings')
          .select('id, term, session, batch, courses ( code, title )')
          .eq('teacher_user_id', userId)
          .eq('is_active', true);
      return (data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error fetching teacher offerings: $e');
      return [];
    }
  }

  // ─── Compute period statuses for a given day ──────────
  static List<PeriodStatus> computePeriodStatuses({
    required int day,
    required Map<int, List<RoomSlot>> routineSlots,
    required List<RoomBookingRequest> bookings,
  }) {
    final daySlots = routineSlots[day] ?? [];
    final dayBookings = bookings.where((b) => b.dayOfWeek == day).toList();

    return Period.all.map((period) {
      // 1. Check routine slots (permanent schedule)
      for (final slot in daySlots) {
        final sStart = _fmt(slot.startTime);
        final sEnd = _fmt(slot.endTime);
        if (sStart.compareTo(period.end) < 0 &&
            sEnd.compareTo(period.start) > 0) {
          return PeriodStatus(
            period: period,
            state: PeriodState.occupied,
            courseCode: slot.courseCode,
            teacherName: slot.teacherName,
          );
        }
      }

      // 2. Check booking requests (pending/approved)
      for (final booking in dayBookings) {
        if (booking.coversPeriod(period)) {
          return PeriodStatus(
            period: period,
            state: PeriodState.booked,
            courseCode: booking.courseCode,
            teacherName: booking.teacherName,
            bookingStatus: booking.status,
          );
        }
      }

      // 3. Otherwise free
      return PeriodStatus(period: period, state: PeriodState.free);
    }).toList();
  }

  static String _fmt(String t) => t.length >= 5 ? t.substring(0, 5) : t;
}

/// Result of a booking attempt.
class BookingResult {
  final bool success;
  final String message;
  const BookingResult({required this.success, required this.message});
}
