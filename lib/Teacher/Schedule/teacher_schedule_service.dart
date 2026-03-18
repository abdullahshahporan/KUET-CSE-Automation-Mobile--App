import 'package:flutter/foundation.dart';
import '../../services/supabase_service.dart';
import '../../services/notification_service.dart';
import 'teacher_schedule_model.dart';
import 'teacher_room_allocation_service.dart';

/// Service to fetch and update teacher routine slots from Supabase.
class TeacherScheduleService {
  static Future<List<TeacherSlot>> _fetchTeacherSlots() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return [];

    final data = await SupabaseService.client
        .from('routine_slots')
        .select('''
          id, offering_id, room_number, day_of_week,
          start_time, end_time, section,
          valid_from, valid_until,
          course_offerings!inner (
            id, teacher_user_id, is_active,
            courses ( code, title, course_type )
          )
        ''')
        .eq('course_offerings.teacher_user_id', userId)
        .eq('course_offerings.is_active', true)
        .order('start_time', ascending: true);

    return (data as List)
        .map((e) => TeacherSlot.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch all routine_slots for the currently logged-in teacher.
  ///
  /// Weekly view ignores one-day overrides so they do not appear as recurring.
  static Future<Map<int, List<TeacherSlot>>> fetchSchedule() async {
    try {
      final slots = (await _fetchTeacherSlots())
          .where((slot) => !slot.isDateScoped)
          .toList();

      // Group by day
      final grouped = <int, List<TeacherSlot>>{};
      for (final s in slots) {
        grouped.putIfAbsent(s.dayOfWeek, () => []).add(s);
      }
      // Sort each day's list by start_time
      for (final list in grouped.values) {
        list.sort((a, b) => a.startTime.compareTo(b.startTime));
      }
      return grouped;
    } catch (e) {
      debugPrint('Error fetching teacher schedule: $e');
      return {};
    }
  }

  static Future<List<TeacherSlot>> fetchEffectiveScheduleForDate(
    DateTime date, {
    String? courseCode,
  }) async {
    try {
      final slots = await _fetchTeacherSlots();
      return TeacherSlot.resolveEffectiveSlotsForDate(
        slots,
        date,
        courseCode: courseCode,
      );
    } catch (e) {
      debugPrint('Error fetching effective teacher schedule: $e');
      return [];
    }
  }

  /// Fetch all active rooms from the `rooms` table.
  static Future<List<String>> fetchRooms() async {
    try {
      final data = await SupabaseService.client
          .from('rooms')
          .select('room_number')
          .eq('is_active', true)
          .order('room_number');
      return (data as List).map((e) => e['room_number'] as String).toList();
    } catch (e) {
      debugPrint('Error fetching rooms: $e');
      return [];
    }
  }

  /// Update a single routine slot's editable fields.
  static Future<bool> updateSlot({
    required String slotId,
    required String roomNumber,
    required String startTime,
    required String endTime,
    String? section,
  }) async {
    try {
      // Fetch offering_id before updating so we can notify students
      final offeringId = await _getOfferingIdFromSlot(slotId);

      await SupabaseService.client
          .from('routine_slots')
          .update({
            'room_number': roomNumber,
            'start_time': startTime,
            'end_time': endTime,
            'section': section,
          })
          .eq('id', slotId);

      // Notify students about the schedule change
      if (offeringId != null) {
        await _notifyStudentsScheduleChange(
          changeType: 'class_rescheduled',
          offeringId: offeringId,
          startTime: startTime,
          endTime: endTime,
          room: roomNumber,
        );
      }
      return true;
    } catch (e) {
      debugPrint('Error updating slot: $e');
      return false;
    }
  }

  /// Delete a routine slot by ID.
  static Future<bool> deleteSlot(String slotId) async {
    try {
      // Fetch offering_id before deleting so we can notify students
      final offeringId = await _getOfferingIdFromSlot(slotId);

      await SupabaseService.client
          .from('routine_slots')
          .delete()
          .eq('id', slotId);

      // Notify students about the cancellation
      if (offeringId != null) {
        await _notifyStudentsScheduleChange(
          changeType: 'class_cancelled',
          offeringId: offeringId,
        );
      }
      return true;
    } catch (e) {
      debugPrint('Error deleting slot: $e');
      return false;
    }
  }

  /// Add a new routine slot.
  static Future<bool> addSlot({
    required String offeringId,
    required String roomNumber,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    String? section,
  }) async {
    try {
      await SupabaseService.client.from('routine_slots').insert({
        'offering_id': offeringId,
        'room_number': roomNumber,
        'day_of_week': dayOfWeek,
        'start_time': startTime,
        'end_time': endTime,
        'section': section,
      });

      // Notify students about the new class slot
      await _notifyStudentsScheduleChange(
        changeType: 'new_schedule',
        offeringId: offeringId,
        startTime: startTime,
        endTime: endTime,
        room: roomNumber,
        dayOfWeek: dayOfWeek,
      );
      return true;
    } catch (e) {
      debugPrint('Error adding slot: $e');
      return false;
    }
  }

  // ── Private notification helpers ──────────────────────────

  /// Look up offering_id from a routine slot.
  static Future<String?> _getOfferingIdFromSlot(String slotId) async {
    try {
      final data = await SupabaseService.client
          .from('routine_slots')
          .select('offering_id')
          .eq('id', slotId)
          .maybeSingle();
      return data?['offering_id'] as String?;
    } catch (e) {
      debugPrint('TeacherScheduleService: could not fetch offering_id: $e');
      return null;
    }
  }

  /// Notify enrolled students about a schedule change.
  static Future<void> _notifyStudentsScheduleChange({
    required String changeType,
    required String offeringId,
    String? startTime,
    String? endTime,
    String? room,
    String? scheduleDate,
    int? dayOfWeek,
  }) async {
    try {
      // Look up course info from offering
      final offeringData = await SupabaseService.client
          .from('course_offerings')
          .select('term, section, courses ( code, title )')
          .eq('id', offeringId)
          .maybeSingle();

      if (offeringData == null) return;

      final courses = offeringData['courses'] as Map<String, dynamic>?;
      final courseCode = courses?['code'] as String?;
      if (courseCode == null) return;

      final courseTitle = (courses?['title'] as String?) ?? courseCode;
      final term = offeringData['term'] as String?;
      final section = (offeringData['section'] as String?)?.trim();

      // Mirror web buildStudentAudience logic: SECTION > COURSE
      final String targetType;
      final String? targetValue;
      final String? targetYearTerm;
      if (section != null && section.isNotEmpty) {
        targetType = 'SECTION';
        targetValue = section;
        targetYearTerm = term;
      } else {
        targetType = 'COURSE';
        targetValue = courseCode;
        targetYearTerm = null;
      }

      const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
      final dayLabel = (dayOfWeek != null && dayOfWeek >= 0 && dayOfWeek < days.length)
          ? days[dayOfWeek]
          : null;

      final when = scheduleDate != null
          ? ' on $scheduleDate'
          : (dayLabel != null ? ' on $dayLabel' : '');
      final timeStr = (startTime != null && endTime != null) ? ', $startTime–$endTime' : '';
      final roomStr = room != null ? ', Room $room' : '';

      final Map<String, Map<String, String>> payloads = {
        'class_cancelled': {
          'title': 'Class Cancelled — $courseCode',
          'body': '$courseTitle class$when$timeStr$roomStr has been cancelled.',
        },
        'class_rescheduled': {
          'title': 'Schedule Updated — $courseCode',
          'body': '$courseTitle class has been rescheduled$when$timeStr$roomStr.',
        },
        'new_schedule': {
          'title': 'New Class Scheduled — $courseCode',
          'body': 'A new class slot for $courseTitle has been added$when$timeStr$roomStr.',
        },
      };

      final payload = payloads[changeType] ?? payloads['class_rescheduled']!;
      // 'new_schedule' maps to 'makeup_class' type (used for one-off or new schedule entries)
      final notifType = changeType == 'new_schedule' ? 'makeup_class' : changeType;

      await NotificationService.createNotification(
        type: notifType,
        title: payload['title']!,
        body: payload['body']!,
        targetType: targetType,
        targetValue: targetValue,
        targetYearTerm: targetYearTerm,
        metadata: {
          'course_code': courseCode,
          if (room != null) 'room_number': room,
          if (startTime != null) 'start_time': startTime,
          if (endTime != null) 'end_time': endTime,
        },
      );
    } catch (e) {
      debugPrint('TeacherScheduleService: notification failed: $e');
    }
  }

  /// Fetch offering IDs for the teacher's active courses (for Add Slot).
  static Future<List<Map<String, dynamic>>> fetchTeacherOfferings() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return [];

    try {
      final data = await SupabaseService.client
          .from('course_offerings')
          .select('id, courses ( code, title )')
          .eq('teacher_user_id', userId)
          .eq('is_active', true);
      return (data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error fetching teacher offerings: $e');
      return [];
    }
  }

  static AssignmentMutationPlan buildAssignmentMutationPlan({
    required TeacherSlot slot,
    required String bookingDate,
    required String roomNumber,
    required List<TeacherSlot> exactDateScopedSlots,
  }) {
    final matchingExactSlots = exactDateScopedSlots
        .where(
          (candidate) =>
              candidate.matchesExactDate(bookingDate) &&
              candidate.allocationKey == slot.allocationKey,
        )
        .toList();

    if (matchingExactSlots.isNotEmpty) {
      final target = matchingExactSlots.firstWhere(
        (candidate) => !candidate.isAssigned,
        orElse: () => matchingExactSlots.first,
      );
      return AssignmentMutationPlan(
        type: AssignmentMutationType.updateExisting,
        existingSlotId: target.id,
        payload: {'room_number': roomNumber},
      );
    }

    return AssignmentMutationPlan(
      type: AssignmentMutationType.insertNew,
      payload: {
        'offering_id': slot.offeringId,
        'room_number': roomNumber,
        'day_of_week': slot.dayOfWeek,
        'start_time': slot.startTime,
        'end_time': slot.endTime,
        'section': slot.section,
        'valid_from': bookingDate,
        'valid_until': bookingDate,
      },
    );
  }

  static Future<RoomAssignmentResult> assignRoomForDate({
    required TeacherSlot slot,
    required DateTime date,
    required String roomNumber,
  }) async {
    if (slot.isAssigned) {
      return const RoomAssignmentResult(
        success: false,
        message: 'This class already has a room assigned.',
      );
    }

    final conflictMessage =
        await TeacherRoomAllocationService.findRoomConflictForSlot(
          slot: slot,
          date: date,
          roomNumber: roomNumber,
        );

    if (conflictMessage != null) {
      return RoomAssignmentResult(success: false, message: conflictMessage);
    }

    final bookingDate = _dateKey(date);

    try {
      final matchingData = await SupabaseService.client
          .from('routine_slots')
          .select(
            'id, offering_id, room_number, day_of_week, start_time, end_time, section, valid_from, valid_until',
          )
          .eq('offering_id', slot.offeringId)
          .eq('day_of_week', slot.dayOfWeek)
          .eq('start_time', slot.startTime)
          .eq('end_time', slot.endTime)
          .eq('valid_from', bookingDate)
          .eq('valid_until', bookingDate);

      final matchingSlots = (matchingData as List)
          .map((row) => TeacherSlot.fromMap(row as Map<String, dynamic>))
          .where((candidate) => _sectionsMatch(candidate.section, slot.section))
          .toList();

      final mutation = buildAssignmentMutationPlan(
        slot: slot,
        bookingDate: bookingDate,
        roomNumber: roomNumber,
        exactDateScopedSlots: matchingSlots,
      );

      switch (mutation.type) {
        case AssignmentMutationType.updateExisting:
          await SupabaseService.client
              .from('routine_slots')
              .update(mutation.payload)
              .eq('id', mutation.existingSlotId!);
          break;
        case AssignmentMutationType.insertNew:
          await SupabaseService.client
              .from('routine_slots')
              .insert(mutation.payload);
          break;
      }

      return const RoomAssignmentResult(
        success: true,
        message: 'Room assigned successfully.',
      );
    } catch (e) {
      debugPrint('Error assigning room for date: $e');
      return RoomAssignmentResult(success: false, message: e.toString());
    }
  }

  static bool _sectionsMatch(String? a, String? b) {
    return (a ?? '').trim().toUpperCase() == (b ?? '').trim().toUpperCase();
  }

  static String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

enum AssignmentMutationType { updateExisting, insertNew }

class AssignmentMutationPlan {
  final AssignmentMutationType type;
  final String? existingSlotId;
  final Map<String, dynamic> payload;

  const AssignmentMutationPlan({
    required this.type,
    this.existingSlotId,
    required this.payload,
  });
}

class RoomAssignmentResult {
  final bool success;
  final String message;

  const RoomAssignmentResult({required this.success, required this.message});
}
