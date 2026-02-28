/// Shared time and date formatting utilities.
///
/// Eliminates duplication of `_formatTime()`, `formatDate()`, and `dayNames`
/// that were scattered across class_schedule_models, exam_schedule_models,
/// teacher_schedule_model, room_model, profile_widgets, and many screens.
class TimeUtils {
  TimeUtils._();

  // ── Day names (0=Sunday … 6=Saturday) ──────────────────────────────────

  static const List<String> dayNames = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  static const List<String> dayNamesShort = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

  /// Get day name from 0-indexed day of week.
  static String dayName(int dayOfWeek) {
    if (dayOfWeek >= 0 && dayOfWeek < dayNames.length) {
      return dayNames[dayOfWeek];
    }
    return 'Unknown';
  }

  /// Get short day name from 0-indexed day of week.
  static String dayNameShort(int dayOfWeek) {
    if (dayOfWeek >= 0 && dayOfWeek < dayNamesShort.length) {
      return dayNamesShort[dayOfWeek];
    }
    return '???';
  }

  // ── Time formatting ────────────────────────────────────────────────────

  /// Convert 24h time string to 12h AM/PM format.
  ///
  /// Handles `"HH:mm:ss"` and `"HH:mm"` inputs.
  /// Example: `"14:30:00"` → `"2:30 PM"`, `"08:00"` → `"8:00 AM"`
  static String formatTime12h(String time24) {
    try {
      final parts = time24.split(':');
      int hour = int.parse(parts[0]);
      final min = parts.length > 1 ? parts[1] : '00';
      final amPm = hour >= 12 ? 'PM' : 'AM';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      return '$hour:$min $amPm';
    } catch (_) {
      return time24;
    }
  }

  /// Trim a time string to `"HH:mm"` (removes seconds if present).
  ///
  /// Example: `"09:30:00"` → `"09:30"`, `"14:00"` → `"14:00"`
  static String trimToHHmm(String time) =>
      time.length >= 5 ? time.substring(0, 5) : time;

  /// Build a time range string in 24h short form.
  ///
  /// Example: `timeRange("09:00:00", "10:00:00")` → `"09:00 - 10:00"`
  static String timeRange(String startTime, String endTime) =>
      '${trimToHHmm(startTime)} - ${trimToHHmm(endTime)}';

  /// Build a time range string in 12h format.
  ///
  /// Example: `timeRange12h("09:00", "10:00")` → `"9:00 AM - 10:00 AM"`
  static String timeRange12h(String startTime, String endTime) =>
      '${formatTime12h(startTime)} - ${formatTime12h(endTime)}';

  // ── Date formatting ────────────────────────────────────────────────────

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// Format an ISO date string to `"dd MMM yyyy"`.
  ///
  /// Example: `"2026-02-28T12:00:00Z"` → `"28 Feb 2026"`.
  /// Returns `"N/A"` for empty or invalid input.
  static String formatDate(String date) {
    if (date == 'N/A' || date.isEmpty) return 'N/A';
    try {
      final d = DateTime.parse(date);
      return '${d.day} ${_months[d.month - 1]} ${d.year}';
    } catch (_) {
      return date;
    }
  }

  /// Format a [DateTime] to `"dd MMM yyyy"`.
  static String formatDateTime(DateTime dt) =>
      '${dt.day} ${_months[dt.month - 1]} ${dt.year}';

  /// Format a [DateTime] to US-style `"MMM d, yyyy"`.
  ///
  /// Example: `DateTime(2026, 1, 5)` → `"Jan 5, 2026"`
  static String formatDateTimeUS(DateTime dt) =>
      '${_months[dt.month - 1]} ${dt.day}, ${dt.year}';

  /// Format a [DateTime] to `"Weekday, MMM d, yyyy"`.
  ///
  /// Example: `DateTime(2026, 1, 5)` → `"Mon, Jan 5, 2026"`
  static String formatDateTimeWithWeekday(DateTime dt) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[dt.weekday - 1]}, ${_months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  /// Format a [DateTime] to `"dd MMM yyyy, h:mm a"`.
  static String formatDateTimeWithTime(DateTime dt) {
    final hour = dt.hour > 12
        ? dt.hour - 12
        : (dt.hour == 0 ? 12 : dt.hour);
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${_months[dt.month - 1]} ${dt.year}, $hour:$min $amPm';
  }
}
