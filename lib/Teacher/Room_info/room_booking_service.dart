import '../../services/session_token_store.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import '../../config/supabase_config.dart';
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

  static Future<Map<String, dynamic>> _postToBackend(
    String path,
    Map<String, dynamic> body,
  ) async {
    final client = HttpClient();
    try {
      final token = await SessionTokenStore.read() ?? '';

      final uri = Uri.parse('${SupabaseConfig.backendUrl}$path');
      final request = await client
          .postUrl(uri)
          .timeout(const Duration(seconds: 15));
      request.headers.contentType = ContentType.json;
      request.headers.set('Authorization', 'Bearer $token');
      request.headers.set('x-client-type', 'mobile');

      request.write(jsonEncode(body));

      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200 && response.statusCode != 201) {
        try {
          final errJson = jsonDecode(responseBody);
          return {
            'success': false,
            'message':
                errJson['error'] ?? 'Request failed (${response.statusCode})',
          };
        } catch (_) {
          return {
            'success': false,
            'message': 'Request failed with status code ${response.statusCode}',
          };
        }
      }

      final resJson = jsonDecode(responseBody);
      return {'success': true, 'data': resJson['data']};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    } finally {
      client.close();
    }
  }

  // ─── Submit a new booking request (timestamp-priority) ─
  /// Submits a room booking request to the Next.js backend for admin approval.
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
      final res = await _postToBackend('/api/teacher-portal/room-requests', {
        'offering_id': offeringId,
        'room_number': roomNumber,
        'date': bookingDate,
        'start_time': '${fromPeriod.start}:00',
        'end_time': '${toPeriod.end}:00',
        'purpose': purpose ?? 'Class Booking',
      });

      if (res['success'] == true) {
        return const BookingResult(
          success: true,
          message: 'Room request submitted for approval!',
        );
      } else {
        return BookingResult(
          success: false,
          message: res['message'] ?? 'Failed to submit room request.',
        );
      }
    } catch (e) {
      return BookingResult(success: false, message: e.toString());
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
      final res = await _postToBackend('/api/teacher-portal/room-requests', {
        'offering_id': offeringId,
        'room_number': roomNumber,
        'date': bookingDate,
        'start_time': '$startStr:00',
        'end_time': '$endStr:00',
        'purpose': purpose ?? 'Class Booking',
      });

      if (res['success'] == true) {
        return const BookingResult(
          success: true,
          message: 'Custom room request submitted for approval!',
        );
      } else {
        return BookingResult(
          success: false,
          message: res['message'] ?? 'Failed to submit custom room request.',
        );
      }
    } catch (e) {
      return BookingResult(success: false, message: e.toString());
    }
  }

  // ─── Check for conflicts across all occupancy sources ───────────────────

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

  static String _fmt(String t) => t.length >= 5 ? t.substring(0, 5) : t;

  static String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  // ─── Notify students when teacher books a room ───────────────────────────
  /// Fire-and-forget: resolves course/term/section from offeringId and sends
  /// both a Supabase notification row and server-side FCM push to enrolled students.
}

class BookingResult {
  final bool success;
  final String message;
  const BookingResult({required this.success, required this.message});
}
