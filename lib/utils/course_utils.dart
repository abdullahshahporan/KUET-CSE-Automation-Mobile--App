/// Utility functions for course code parsing and term matching.
///
/// Centralizes the course-code-to-term derivation logic that was previously
/// duplicated across 5+ files (class_schedule_providers, exam_schedule_providers,
/// course_info_service, teacher_course_service, teacher_home_content).
class CourseUtils {
  CourseUtils._(); // prevent instantiation

  /// Extract only digits from a course code string.
  ///
  /// Example: `"CSE 3209"` → `"3209"`
  static String extractDigits(String code) =>
      code.replaceAll(RegExp(r'[^0-9]'), '');

  /// Derive a term string (`"year-term"`) from a course code.
  ///
  /// Convention: the first digit of the numeric part = year,
  /// the second digit = term.
  ///
  /// Example: `"CSE 3209"` → `"3-2"`, `"CSE 2201"` → `"2-2"`
  static String termFromCourseCode(String courseCode) {
    final digits = extractDigits(courseCode);
    if (digits.length < 2) return '1-1';
    return '${digits[0]}-${digits[1]}';
  }

  /// Parse year from a course code's numeric part.
  ///
  /// Example: `"CSE 3209"` → `3`
  static int yearFromCode(String courseCode) {
    final digits = extractDigits(courseCode);
    if (digits.isEmpty) return 1;
    return int.tryParse(digits[0]) ?? 1;
  }

  /// Parse term from a course code's numeric part.
  ///
  /// Example: `"CSE 3209"` → `2`
  static int termFromCode(String courseCode) {
    final digits = extractDigits(courseCode);
    if (digits.length < 2) return 1;
    return int.tryParse(digits[1]) ?? 1;
  }

  /// Check whether a course code matches the given year-term.
  ///
  /// `"CSE 3201"` → digits `"3201"` → starts with `"32"` → matches year=3, term=2.
  static bool codeMatchesTerm(String? code, int year, int term) {
    if (code == null || code.isEmpty) return false;
    final prefix = '$year$term';
    final digits = extractDigits(code);
    return digits.startsWith(prefix);
  }

  /// Parse a `"year-term"` string (e.g. `"3-2"`) into `{year, term}`.
  static ({int year, int term}) parseTerm(String termStr) {
    final parts = termStr.split('-');
    final year = int.tryParse(parts[0]) ?? 1;
    final term = int.tryParse(parts.length > 1 ? parts[1] : '1') ?? 1;
    return (year: year, term: term);
  }

  /// Derive section from roll number.
  ///
  /// Last 3 digits: 001-060 → `"A"`, 061+ → `"B"`
  static String sectionFromRoll(String? rollNo) {
    if (rollNo == null || rollNo.isEmpty) return 'A';
    final digits = extractDigits(rollNo);
    if (digits.isEmpty) return 'A';
    final last3 =
        digits.length >= 3 ? digits.substring(digits.length - 3) : digits;
    final num = int.tryParse(last3) ?? 1;
    return num <= 60 ? 'A' : 'B';
  }

  /// Derive sessional group from roll number.
  ///
  /// `001-030 → A1`, `031-060 → A2`, `061-090 → B1`, `091-120 → B2`
  static String sessionalGroupFromRoll(String rollNo) {
    final digits = extractDigits(rollNo);
    if (digits.isEmpty) return 'A1';
    final last3 =
        digits.length >= 3 ? digits.substring(digits.length - 3) : digits;
    final num = int.tryParse(last3) ?? 1;
    if (num <= 30) return 'A1';
    if (num <= 60) return 'A2';
    if (num <= 90) return 'B1';
    return 'B2';
  }
}
