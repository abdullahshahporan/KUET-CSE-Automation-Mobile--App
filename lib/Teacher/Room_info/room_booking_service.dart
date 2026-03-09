import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import '../../services/supabase_service.dart';
import 'room_booking_model.dart';
import 'room_model.dart';

/// Service for room booking requests (CRUD + period status computation).
class RoomBookingService {
  // ─── Fetch pending/approved bookings for a room on a specific date ───────
  static Future<List<RoomBookingRequest>> fetchRoomBookings(
      String roomNumber, {String? bookingDate}) async {
    try {
      var query = SupabaseService.client
          .from('room_booking_requests')
          .select('''
            id, teacher_user_id, offering_id, room_number,
            day_of_week, start_period, end_period,
            start_time, end_time, section, purpose, status, requested_at,
            booking_date,
            course_offerings ( courses ( code, title ) ),
            teachers!rbr_teacher_fkey ( full_name )
          ''')
          .eq('room_number', roomNumber)
          .eq('status', 'approved');

      if (bookingDate != null) {
        query = query.eq('booking_date', bookingDate);
      }

      final data = await query
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
    required String bookingDate,
    String? section,
    String? purpose,
  }) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) {
      return const BookingResult(success: false, message: 'Not logged in.');
    }

    try {
      // 1. Check for conflicting bookings (same room, same date, overlapping periods)
      final conflicts = await _checkConflicts(
        roomNumber: roomNumber,
        dayOfWeek: dayOfWeek,
        fromPeriod: fromPeriod,
        toPeriod: toPeriod,
        bookingDate: bookingDate,
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
        'booking_date': bookingDate,
        'section': section,
        'purpose': purpose,
        'status': 'approved',
      });

      // 3. Sync to routine_slots so schedule & TV display show this booking
      await _syncToRoutineSlot(
        offeringId: offeringId,
        roomNumber: roomNumber,
        dayOfWeek: dayOfWeek,
        startTime: '${fromPeriod.start}:00',
        endTime: '${toPeriod.end}:00',
        bookingDate: bookingDate,
        section: section,
      );

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
    required String bookingDate,
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
      // Check for time-based conflicts in the break window on this specific date
      final data = await SupabaseService.client
          .from('room_booking_requests')
          .select('''
            id, teacher_user_id, offering_id, room_number,
            day_of_week, start_period, end_period,
            start_time, end_time, section, purpose, status, requested_at,
            booking_date,
            course_offerings ( courses ( code, title ) ),
            teachers!rbr_teacher_fkey ( full_name )
          ''')
          .eq('room_number', roomNumber)
          .eq('booking_date', bookingDate)
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
        'booking_date': bookingDate,
        'section': section,
        'purpose': purpose,
        'status': 'approved',
      });

      // Sync to routine_slots so schedule & TV display show this booking
      await _syncToRoutineSlot(
        offeringId: offeringId,
        roomNumber: roomNumber,
        dayOfWeek: dayOfWeek,
        startTime: '$startStr:00',
        endTime: '$endStr:00',
        bookingDate: bookingDate,
        section: section,
      );

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
    required String bookingDate,
  }) async {
    try {
      final data = await SupabaseService.client
          .from('room_booking_requests')
          .select('''
            id, teacher_user_id, offering_id, room_number,
            day_of_week, start_period, end_period,
            start_time, end_time, section, purpose, status, requested_at,
            booking_date,
            course_offerings ( courses ( code, title ) ),
            teachers!rbr_teacher_fkey ( full_name )
          ''')
          .eq('room_number', roomNumber)
          .eq('booking_date', bookingDate)
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

  // ─── Compute period statuses for a given date ──────────
  /// Combines permanent routine slots (auto-synced by day_of_week) with
  /// date-specific bookings to show the full schedule for a specific date.
  static List<PeriodStatus> computePeriodStatuses({
    required int day,
    required Map<int, List<RoomSlot>> routineSlots,
    required List<RoomBookingRequest> bookings,
    String? bookingDate,
  }) {
    final daySlots = routineSlots[day] ?? [];
    // Filter bookings for the specific date if provided
    final dayBookings = bookingDate != null
        ? bookings.where((b) => b.bookingDate == bookingDate).toList()
        : bookings.where((b) => b.dayOfWeek == day).toList();

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

  // ─── Sync a booking to routine_slots for schedule & TV display ──
  static Future<void> _syncToRoutineSlot({
    required String offeringId,
    required String roomNumber,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    required String bookingDate,
    String? section,
  }) async {
    try {
      // Check if a routine_slot already exists for this exact slot
      final existing = await SupabaseService.client
          .from('routine_slots')
          .select('id')
          .eq('offering_id', offeringId)
          .eq('room_number', roomNumber)
          .eq('day_of_week', dayOfWeek)
          .eq('start_time', startTime)
          .eq('valid_from', bookingDate)
          .eq('valid_until', bookingDate)
          .limit(1);

      if ((existing as List).isNotEmpty) {
        // Already synced
        return;
      }

      await SupabaseService.client.from('routine_slots').insert({
        'offering_id': offeringId,
        'room_number': roomNumber,
        'day_of_week': dayOfWeek,
        'start_time': startTime,
        'end_time': endTime,
        'section': section,
        'valid_from': bookingDate,
        'valid_until': bookingDate,
      });
    } catch (e) {
      debugPrint('Error syncing to routine_slots: $e');
      // Non-fatal: booking itself succeeded, schedule sync is best-effort
    }
  }

  static String _fmt(String t) => t.length >= 5 ? t.substring(0, 5) : t;
}

/// Result of a booking attempt.
class BookingResult {
  final bool success;
  final String message;
  const BookingResult({required this.success, required this.message});
}
