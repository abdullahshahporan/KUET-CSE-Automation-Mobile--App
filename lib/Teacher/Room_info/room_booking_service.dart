import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import '../../services/notification_service.dart';
import '../../services/supabase_service.dart';
import 'room_booking_model.dart';
import 'room_model.dart';
import 'room_service.dart';

/// Service for room booking requests (CRUD + period status computation).
class RoomBookingService {
  // ─── Fetch pending/approved bookings for a room on a specific date ───────
  static Future<List<RoomBookingRequest>> fetchRoomBookings(
    String roomNumber, {
    String? bookingDate,
  }) async {
    try {
      final roomVariants = RoomService.roomNumberVariants(roomNumber);
      var teacherQuery = SupabaseService.client
          .from('room_booking_requests')
          .select('''
            id, teacher_user_id, offering_id, room_number,
            day_of_week, start_period, end_period,
            start_time, end_time, section, purpose, status, requested_at,
            booking_date,
            course_offerings ( courses ( code, title ) ),
            teachers!rbr_teacher_fkey ( full_name )
          ''')
          .inFilter('room_number', roomVariants)
          .eq('status', 'approved');

      var crQuery = SupabaseService.client
          .from('cr_room_requests')
          .select('''
            id, teacher_user_id, room_number, day_of_week,
            start_time, end_time, section, reason, status,
            created_at, request_date, course_code,
            teachers!cr_room_requests_teacher_user_id_fkey ( full_name )
          ''')
          .inFilter('room_number', roomVariants)
          .eq('status', 'approved');

      if (bookingDate != null) {
        teacherQuery = teacherQuery.eq('booking_date', bookingDate);
        crQuery = crQuery.eq('request_date', bookingDate);
      }

      final results = await Future.wait([
        teacherQuery.order('day_of_week').order('start_time'),
        crQuery.order('day_of_week').order('start_time'),
      ]);

      final teacherBookings = (results[0] as List)
          .map((e) => RoomBookingRequest.fromMap(e as Map<String, dynamic>))
          .toList();

      final crBookings = (results[1] as List)
          .map(
            (e) => RoomBookingRequest.fromCrRoomRequestMap(
              e as Map<String, dynamic>,
            ),
          )
          .toList();

      final allBookings = [...teacherBookings, ...crBookings];
      allBookings.sort((a, b) {
        final dateCmp = (a.bookingDate ?? '').compareTo(b.bookingDate ?? '');
        if (dateCmp != 0) return dateCmp;

        final dayCmp = a.dayOfWeek.compareTo(b.dayOfWeek);
        if (dayCmp != 0) return dayCmp;

        final timeCmp = _fmt(a.startTime).compareTo(_fmt(b.startTime));
        if (timeCmp != 0) return timeCmp;

        return (a.requestedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(b.requestedAt ?? DateTime.fromMillisecondsSinceEpoch(0));
      });

      return allBookings;
    } catch (e) {
      debugPrint('Error fetching room bookings: $e');
      return [];
    }
  }

  // ─── Submit a new booking request (timestamp-priority) ─
  /// Inserts a booking with auto-approved status if no conflicting
  /// booking exists for the same room + date + overlapping time range.
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
      final conflictMessage = await _findConflictMessage(
        roomNumber: roomNumber,
        dayOfWeek: dayOfWeek,
        startTime: '${fromPeriod.start}:00',
        endTime: '${toPeriod.end}:00',
        bookingDate: bookingDate,
      );

      if (conflictMessage != null) {
        return BookingResult(success: false, message: conflictMessage);
      }

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

      await _syncToRoutineSlot(
        offeringId: offeringId,
        roomNumber: roomNumber,
        dayOfWeek: dayOfWeek,
        startTime: '${fromPeriod.start}:00',
        endTime: '${toPeriod.end}:00',
        bookingDate: bookingDate,
        section: section,
      );

      // Fire-and-forget: notify students of the booked room
      _notifyStudentsRoomBooked(
        offeringId: offeringId,
        roomNumber: roomNumber,
        startTime: '${fromPeriod.start}:00',
        endTime: '${toPeriod.end}:00',
        bookingDate: bookingDate,
        section: section,
      );

      return const BookingResult(
        success: true,
        message: 'Slot booked successfully!',
      );
    } catch (e) {
      debugPrint('Error submitting booking request: $e');
      String msg = e.toString();
      if (msg.contains('row-level security') || msg.contains('policy')) {
        msg =
            'Permission denied. RLS INSERT policy missing on '
            'room_booking_requests table. Ask admin to add it.';
      } else if (msg.contains('violates foreign key')) {
        msg =
            'Invalid reference. Check that the course offering and '
            'teacher records exist.';
      } else if (msg.length > 150) {
        msg = msg.substring(0, 150);
      }
      return BookingResult(success: false, message: msg);
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
    const breakEnd = 14 * 60 + 30; // 2:30 PM

    if (startMin < breakStart || endMin > breakEnd || startMin >= endMin) {
      return const BookingResult(
        success: false,
        message:
            'Custom time must be within 1:10 PM – 2:30 PM '
            'and start must be before end.',
      );
    }

    final startStr =
        '${customStart.hour.toString().padLeft(2, '0')}:${customStart.minute.toString().padLeft(2, '0')}';
    final endStr =
        '${customEnd.hour.toString().padLeft(2, '0')}:${customEnd.minute.toString().padLeft(2, '0')}';

    try {
      final conflictMessage = await _findConflictMessage(
        roomNumber: roomNumber,
        dayOfWeek: dayOfWeek,
        startTime: '$startStr:00',
        endTime: '$endStr:00',
        bookingDate: bookingDate,
      );

      if (conflictMessage != null) {
        return BookingResult(success: false, message: conflictMessage);
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

      // Fire-and-forget: notify students of the booked room
      _notifyStudentsRoomBooked(
        offeringId: offeringId,
        roomNumber: roomNumber,
        startTime: '$startStr:00',
        endTime: '$endStr:00',
        bookingDate: bookingDate,
        section: section,
      );

      return const BookingResult(
        success: true,
        message: 'Custom slot booked successfully!',
      );
    } catch (e) {
      debugPrint('Error submitting custom booking: $e');
      String msg = e.toString();
      if (msg.length > 150) msg = msg.substring(0, 150);
      return BookingResult(success: false, message: msg);
    }
  }

  // ─── Check for conflicts across all occupancy sources ───────────────────
  static Future<String?> _findConflictMessage({
    required String roomNumber,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    required String bookingDate,
  }) async {
    final reqStart = _fmt(startTime);
    final reqEnd = _fmt(endTime);
    final roomVariants = RoomService.roomNumberVariants(roomNumber);

    try {
      final routineData = await SupabaseService.client
          .from('routine_slots')
          .select('''
            id, room_number, day_of_week, start_time, end_time,
            valid_from, valid_until,
            course_offerings!inner (
              is_active,
              courses ( code, title ),
              teachers ( full_name )
            )
          ''')
          .inFilter('room_number', roomVariants)
          .eq('day_of_week', dayOfWeek)
          .eq('course_offerings.is_active', true);

      final requestDateValue = DateTime.tryParse(bookingDate);
      for (final row in (routineData as List)) {
        final vFrom = row['valid_from'] as String?;
        final vUntil = row['valid_until'] as String?;
        if (requestDateValue != null) {
          final from = vFrom != null ? DateTime.tryParse(vFrom) : null;
          final until = vUntil != null ? DateTime.tryParse(vUntil) : null;
          if (from != null && requestDateValue.isBefore(from)) continue;
          if (until != null && requestDateValue.isAfter(until)) continue;
        }

        final sStart = _fmt(row['start_time'] as String? ?? '');
        final sEnd = _fmt(row['end_time'] as String? ?? '');
        if (sStart.compareTo(reqEnd) < 0 && sEnd.compareTo(reqStart) > 0) {
          final offering =
              row['course_offerings'] as Map<String, dynamic>? ?? {};
          final course = offering['courses'] as Map<String, dynamic>? ?? {};
          final code = course['code'] ?? 'A class';
          return 'Slot conflict! $code is already scheduled in this room during that time.';
        }
      }

      final teacherBookingData = await SupabaseService.client
          .from('room_booking_requests')
          .select('''
            id, start_time, end_time, requested_at,
            course_offerings ( courses ( code, title ) ),
            teachers!rbr_teacher_fkey ( full_name )
          ''')
          .inFilter('room_number', roomVariants)
          .eq('booking_date', bookingDate)
          .eq('status', 'approved')
          .order('requested_at', ascending: true);

      for (final row in (teacherBookingData as List)) {
        final bStart = _fmt(row['start_time'] as String? ?? '');
        final bEnd = _fmt(row['end_time'] as String? ?? '');
        if (bStart.compareTo(reqEnd) < 0 && bEnd.compareTo(reqStart) > 0) {
          final offering =
              row['course_offerings'] as Map<String, dynamic>? ?? {};
          final course = offering['courses'] as Map<String, dynamic>? ?? {};
          final teacher = row['teachers'] as Map<String, dynamic>? ?? {};
          final code = course['code'] ?? 'A course';
          final name = teacher['full_name'] ?? 'another teacher';
          return 'Slot already booked! $code was booked by $name first.';
        }
      }

      final crBookingData = await SupabaseService.client
          .from('cr_room_requests')
          .select('''
            id, course_code, start_time, end_time, created_at,
            teachers!cr_room_requests_teacher_user_id_fkey ( full_name )
          ''')
          .inFilter('room_number', roomVariants)
          .eq('request_date', bookingDate)
          .eq('status', 'approved')
          .order('created_at', ascending: true);

      for (final row in (crBookingData as List)) {
        final cStart = _fmt(row['start_time'] as String? ?? '');
        final cEnd = _fmt(row['end_time'] as String? ?? '');
        if (cStart.compareTo(reqEnd) < 0 && cEnd.compareTo(reqStart) > 0) {
          final code = row['course_code'] ?? 'A course';
          return 'Slot already taken! $code has an approved CR booking in this room.';
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error checking conflicts: $e');
      return 'Failed to verify slot availability. Please try again.';
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

  static Future<List<PeriodStatus>> fetchPeriodStatusesForDate({
    required String roomNumber,
    required DateTime date,
  }) async {
    final bookingDate = _dateKey(date);
    final routineSlots = await RoomService.fetchRoomSchedule(
      roomNumber,
      date: date,
    );
    final bookings = await fetchRoomBookings(
      roomNumber,
      bookingDate: bookingDate,
    );

    final day = date.weekday == 7 ? 0 : date.weekday;
    return computePeriodStatuses(
      day: day,
      routineSlots: routineSlots,
      bookings: bookings,
      bookingDate: bookingDate,
    );
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
          .select('id, section')
          .eq('offering_id', offeringId)
          .eq('day_of_week', dayOfWeek)
          .eq('start_time', startTime)
          .eq('end_time', endTime)
          .eq('valid_from', bookingDate)
          .eq('valid_until', bookingDate)
          .limit(20);

      final matching = (existing as List)
          .map((row) => row as Map<String, dynamic>)
          .where(
            (row) =>
                ((row['section'] as String?) ?? '').trim().toUpperCase() ==
                (section ?? '').trim().toUpperCase(),
          )
          .toList();

      if (matching.isNotEmpty) {
        await SupabaseService.client
            .from('routine_slots')
            .update({'room_number': roomNumber, 'section': section})
            .eq('id', matching.first['id']);
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

  static String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  // ─── Notify students when teacher books a room ───────────────────────────
  /// Fire-and-forget: resolves course/term/section from offeringId and sends
  /// both a Supabase notification row and OneSignal push to enrolled students.
  static void _notifyStudentsRoomBooked({
    required String offeringId,
    required String roomNumber,
    required String startTime,
    required String endTime,
    required String bookingDate,
    String? section,
  }) {
    Future(() async {
      try {
        final offeringData = await SupabaseService.client
            .from('course_offerings')
            .select('term, section, courses(code)')
            .eq('id', offeringId)
            .maybeSingle();

        if (offeringData == null) return;

        final course = offeringData['courses'] as Map<String, dynamic>?;
        final courseCode =
            (course?['code'] as String?)?.trim();
        if (courseCode == null || courseCode.isEmpty) return;

        final term = (offeringData['term'] as String?)?.trim();
        final effectiveSection =
            section?.trim().isEmpty ?? true ? null : section?.trim();

        final start = _fmt(startTime);
        final end = _fmt(endTime);

        final targetType = effectiveSection != null ? 'SECTION' : (term != null ? 'YEAR_TERM' : 'COURSE');
        final targetValue = effectiveSection ?? term ?? courseCode;

        await NotificationService.createNotification(
          type: 'room_allocated',
          title: 'Room $roomNumber Booked — $courseCode',
          body: 'Class on $bookingDate, $start–$end has been assigned Room $roomNumber.',
          targetType: targetType,
          targetValue: targetValue,
          targetYearTerm: effectiveSection != null ? term : null,
          metadata: {
            'course_code': courseCode,
            'room_number': roomNumber,
            'booking_date': bookingDate,
            'start_time': start,
            'end_time': end,
          },
        );
      } catch (e) {
        debugPrint('[RoomBookingService] _notifyStudentsRoomBooked error: $e');
      }
    });
  }
}

/// Result of a booking attempt.
class BookingResult {
  final bool success;
  final String message;
  const BookingResult({required this.success, required this.message});
}
