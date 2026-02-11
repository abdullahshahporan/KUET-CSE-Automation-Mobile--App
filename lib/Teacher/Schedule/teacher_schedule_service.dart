import 'package:flutter/foundation.dart';
import '../../services/supabase_service.dart';
import 'teacher_schedule_model.dart';

/// Service to fetch and update teacher routine slots from Supabase.
class TeacherScheduleService {
  /// Fetch all routine_slots for the currently logged-in teacher.
  ///
  /// Joins: routine_slots → course_offerings(is_active) → courses
  /// Returns slots grouped by day_of_week (0-6).
  static Future<Map<int, List<TeacherSlot>>> fetchSchedule() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return {};

    try {
      final data = await SupabaseService.client
          .from('routine_slots')
          .select('''
            id, offering_id, room_number, day_of_week,
            start_time, end_time, section,
            course_offerings!inner (
              id, teacher_user_id, is_active,
              courses ( code, title, course_type )
            )
          ''')
          .eq('course_offerings.teacher_user_id', userId)
          .eq('course_offerings.is_active', true)
          .order('start_time', ascending: true);

      final slots = (data as List)
          .map((e) => TeacherSlot.fromMap(e as Map<String, dynamic>))
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

  /// Fetch all active rooms from the `rooms` table.
  static Future<List<String>> fetchRooms() async {
    try {
      final data = await SupabaseService.client
          .from('rooms')
          .select('room_number')
          .eq('is_active', true)
          .order('room_number');
      return (data as List)
          .map((e) => e['room_number'] as String)
          .toList();
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
}
