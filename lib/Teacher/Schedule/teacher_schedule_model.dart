import '../../utils/time_utils.dart';

/// Data model for a single teacher routine slot.
class TeacherSlot {
  final String id;
  final String offeringId;
  final String courseCode;
  final String courseTitle;
  final String roomNumber;
  final int dayOfWeek; // 0=Sun … 6=Sat
  final String startTime; // HH:mm:ss
  final String endTime;
  final String? section;
  final String courseType; // Theory / Lab
  final String? validFrom;
  final String? validUntil;

  TeacherSlot({
    required this.id,
    required this.offeringId,
    required this.courseCode,
    required this.courseTitle,
    required this.roomNumber,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.section,
    this.courseType = 'Theory',
    this.validFrom,
    this.validUntil,
  });

  factory TeacherSlot.fromMap(Map<String, dynamic> m) {
    final offering = m['course_offerings'] as Map<String, dynamic>? ?? {};
    final course = offering['courses'] as Map<String, dynamic>? ?? {};

    return TeacherSlot(
      id: m['id'] as String,
      offeringId: m['offering_id'] as String,
      courseCode: course['code'] as String? ?? '',
      courseTitle: course['title'] as String? ?? '',
      roomNumber: m['room_number'] as String? ?? '',
      dayOfWeek: m['day_of_week'] as int? ?? 0,
      startTime: m['start_time'] as String? ?? '',
      endTime: m['end_time'] as String? ?? '',
      section: m['section'] as String?,
      courseType: course['course_type'] as String? ?? 'Theory',
      validFrom: m['valid_from'] as String?,
      validUntil: m['valid_until'] as String?,
    );
  }

  /// Whether this slot is valid on the given date.
  bool isValidOnDate(DateTime date) {
    if (validFrom != null) {
      final from = DateTime.tryParse(validFrom!);
      if (from != null && date.isBefore(from)) return false;
    }
    if (validUntil != null) {
      final until = DateTime.tryParse(validUntil!);
      if (until != null && date.isAfter(until)) return false;
    }
    return true;
  }

  /// e.g. "09:00 - 10:00"
  String get timeRange => TimeUtils.timeRange(startTime, endTime);

  String get dayName => TimeUtils.dayName(dayOfWeek);

  bool get isAssigned => roomNumber.trim().isNotEmpty;

  bool get isDateScoped =>
      validFrom != null && validUntil != null && validFrom == validUntil;

  bool matchesExactDate(String dateKey) =>
      validFrom == dateKey && validUntil == dateKey;

  String get displayRoomNumber => isAssigned ? roomNumber : 'Unassigned';

  String get allocationKey {
    final sectionKey = (section ?? '').trim().toUpperCase();
    return [
      offeringId,
      dayOfWeek,
      TimeUtils.trimToHHmm(startTime),
      TimeUtils.trimToHHmm(endTime),
      sectionKey,
    ].join('|');
  }

  /// Backward-compatible static accessor for day names list.
  static List<String> get dayNames => TimeUtils.dayNames;

  static List<TeacherSlot> resolveEffectiveSlotsForDate(
    List<TeacherSlot> slots,
    DateTime date, {
    String? courseCode,
  }) {
    final dateKey = _dateKey(date);
    final day = date.weekday == DateTime.sunday ? 0 : date.weekday;
    final resolved = <String, TeacherSlot>{};

    for (final slot in slots) {
      if (slot.dayOfWeek != day) continue;
      if (!slot.isValidOnDate(date)) continue;
      if (courseCode != null && slot.courseCode != courseCode) continue;

      final existing = resolved[slot.allocationKey];
      if (existing == null ||
          _slotPriority(slot, dateKey) > _slotPriority(existing, dateKey)) {
        resolved[slot.allocationKey] = slot;
      }
    }

    final values = resolved.values.toList();
    values.sort((a, b) {
      final timeCmp = a.startTime.compareTo(b.startTime);
      if (timeCmp != 0) return timeCmp;

      final codeCmp = a.courseCode.compareTo(b.courseCode);
      if (codeCmp != 0) return codeCmp;

      return (a.section ?? '').compareTo(b.section ?? '');
    });
    return values;
  }

  static int _slotPriority(TeacherSlot slot, String dateKey) {
    var score = 0;
    if (slot.matchesExactDate(dateKey)) {
      score += 100;
    } else if (slot.validFrom != null || slot.validUntil != null) {
      score += 50;
    }
    if (slot.isAssigned) score += 10;
    if (slot.validFrom != null) score += 1;
    return score;
  }

  static String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
