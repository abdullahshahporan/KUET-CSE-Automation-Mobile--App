/// General-purpose formatting helpers used across the app.
///
/// Centralizes ordinal suffix generation, designation display,
/// and other display-related utilities.
class DisplayUtils {
  DisplayUtils._();

  // ── Ordinal suffixes ───────────────────────────────────────────────────

  /// Get ordinal suffix for a number: `1` → `"1st"`, `2` → `"2nd"`, etc.
  static String ordinal(int n) {
    if (n >= 11 && n <= 13) return '${n}th';
    switch (n % 10) {
      case 1:
        return '${n}st';
      case 2:
        return '${n}nd';
      case 3:
        return '${n}rd';
      default:
        return '${n}th';
    }
  }

  /// Format year display: `1` → `"1st"`, `2` → `"2nd"`, etc.
  static String yearDisplay(int? year) => ordinal(year ?? 1);

  /// Format semester display: `1` → `"1st"`, `2` → `"2nd"`.
  static String semesterDisplay(int? semester) => ordinal(semester ?? 1);

  /// Full semester name: `year=3, term=2` → `"3-2 (3rd Year 2nd Term)"`.
  static String semesterName(int year, int term) =>
      '$year-$term (${ordinal(year)} Year ${ordinal(term)} Term)';

  // ── Designation display ────────────────────────────────────────────────

  static const _designationMap = {
    'LECTURER': 'Lecturer',
    'ASSISTANT_PROFESSOR': 'Assistant Professor',
    'ASSOCIATE_PROFESSOR': 'Associate Professor',
    'PROFESSOR': 'Professor',
  };

  /// Convert DB enum to readable designation string.
  static String designationDisplay(String? designation) =>
      _designationMap[designation] ?? designation ?? 'Faculty';

  // ── Name helpers ───────────────────────────────────────────────────────

  /// Get first name from a full name. Returns `"User"` for null/empty.
  static String firstName(String? fullName) {
    if (fullName == null || fullName.isEmpty) return 'User';
    return fullName.split(' ').first;
  }

  /// Get initial letter (uppercase) from a name. Returns `"?"` for empty.
  static String initial(String name) =>
      name.isNotEmpty ? name[0].toUpperCase() : '?';

  // ── Credits display ────────────────────────────────────────────────────

  /// Format credits: `3.0` → `"3 Credits"`, `1.5` → `"1.5 Credits"`.
  static String creditsString(double credits) {
    final formatted = credits.truncateToDouble() == credits
        ? credits.toStringAsFixed(0)
        : credits.toStringAsFixed(1);
    return '$formatted Credit${credits > 1 ? 's' : ''}';
  }
}
