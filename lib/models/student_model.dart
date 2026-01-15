/// Student model for KUET CSE Automation App
class Student {
  final String roll;
  final String name;
  final String batch; // "21", "22", "23", "24"
  final int currentYear; // 1-4
  final int currentTerm; // 1, 2
  final String email;
  final String department;

  const Student({
    required this.roll,
    required this.name,
    required this.batch,
    required this.currentYear,
    required this.currentTerm,
    this.email = '',
    this.department = 'Computer Science & Engineering',
  });

  /// Returns formatted year-term string like "3-2"
  String get yearTermString => '$currentYear-$currentTerm';

  /// Returns formatted batch string like "2k21"
  String get formattedBatch => '2k$batch';

  /// Returns full semester name like "3rd Year 2nd Term"
  String get semesterName {
    final yearSuffix = currentYear == 1
        ? 'st'
        : currentYear == 2
            ? 'nd'
            : currentYear == 3
                ? 'rd'
                : 'th';
    final termSuffix = currentTerm == 1 ? 'st' : 'nd';
    return '$currentYear$yearSuffix Year $currentTerm$termSuffix Term';
  }
}
