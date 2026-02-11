import 'package:flutter/foundation.dart';
import '../../services/supabase_service.dart';
import 'room_model.dart';

/// Service to fetch room data and schedules from Supabase.
class RoomService {
  /// Working days: Sun(0) – Thu(4) for Bangladesh.
  static const workDays = [0, 1, 2, 3, 4];

  // ─── Fetch all active rooms ───────────────────────────
  static Future<List<Room>> fetchAllRooms() async {
    try {
      final data = await SupabaseService.client
          .from('rooms')
          .select('room_number, building_name, capacity, room_type, facilities, is_active')
          .eq('is_active', true)
          .order('room_number');
      return (data as List)
          .map((e) => Room.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching rooms: $e');
      return [];
    }
  }

  // ─── Fetch schedule for a specific room ───────────────
  static Future<Map<int, List<RoomSlot>>> fetchRoomSchedule(
      String roomNumber) async {
    try {
      final data = await SupabaseService.client
          .from('routine_slots')
          .select('''
            id, room_number, day_of_week, start_time, end_time, section,
            course_offerings!inner (
              id, is_active,
              courses ( code, title, course_type ),
              teachers ( full_name )
            )
          ''')
          .eq('room_number', roomNumber)
          .eq('course_offerings.is_active', true)
          .order('start_time', ascending: true);

      final slots = (data as List)
          .map((e) => RoomSlot.fromMap(e as Map<String, dynamic>))
          .toList();

      // Group by day
      final grouped = <int, List<RoomSlot>>{};
      for (final s in slots) {
        grouped.putIfAbsent(s.dayOfWeek, () => []).add(s);
      }
      for (final list in grouped.values) {
        list.sort((a, b) => a.startTime.compareTo(b.startTime));
      }
      return grouped;
    } catch (e) {
      debugPrint('Error fetching room schedule: $e');
      return {};
    }
  }

}
