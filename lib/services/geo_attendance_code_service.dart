import 'dart:math' show Random;
import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

/// Service to manage temporary 6-digit verification codes.
class GeoAttendanceCodeService {
  GeoAttendanceCodeService._();

  /// Generates a random 6-digit code and associates it with the given [roomId].
  static Future<String> generateCode(String roomId) async {
    try {
      final code = (100000 + Random.secure().nextInt(900000)).toString();
      await SupabaseService.from(
        'geo_attendance_codes',
      ).insert({'room_id': roomId, 'code': code});
      return code;
    } catch (e) {
      debugPrint('Error generating verification code: $e');
      rethrow;
    }
  }

  /// Retrieves the verification code for the given [roomId].
  static Future<String?> getCode(String roomId) async {
    try {
      final data = await SupabaseService.from(
        'geo_attendance_codes',
      ).select('code').eq('room_id', roomId).maybeSingle();
      return data?['code'] as String?;
    } catch (e) {
      debugPrint('Error fetching verification code: $e');
      return null;
    }
  }

  /// Deletes the verification code for the given [roomId].
  static Future<void> deleteCode(String roomId) async {
    try {
      await SupabaseService.from(
        'geo_attendance_codes',
      ).delete().eq('room_id', roomId);
    } catch (e) {
      debugPrint('Error deleting verification code: $e');
    }
  }

  /// Deletes verification codes for the given list of [roomIds].
  static Future<void> deleteCodes(List<String> roomIds) async {
    if (roomIds.isEmpty) return;
    try {
      await SupabaseService.from(
        'geo_attendance_codes',
      ).delete().inFilter('room_id', roomIds);
    } catch (e) {
      debugPrint('Error bulk deleting verification codes: $e');
    }
  }

  /// Verifies if the [enteredCode] matches the one stored for the given [roomId].
  static Future<bool> verifyCode(String roomId, String enteredCode) async {
    final code = await getCode(roomId);
    if (code == null) return false;
    return code.trim() == enteredCode.trim();
  }
}
