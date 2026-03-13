import 'package:flutter/foundation.dart';
import '../../services/supabase_service.dart';
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
      await SupabaseService.client
          .from('routine_slots')
          .update({
            'room_number': roomNumber,
            'start_time': startTime,
            'end_time': endTime,
            'section': section,
          })
          .eq('id', slotId);
      return true;
    } catch (e) {
      debugPrint('Error updating slot: $e');
      return false;
    }
  }

  /// Delete a routine slot by ID.
  static Future<bool> deleteSlot(String slotId) async {
    try {
      await SupabaseService.client
          .from('routine_slots')
          .delete()
          .eq('id', slotId);
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
      return true;
    } catch (e) {
      debugPrint('Error adding slot: $e');
      return false;
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
