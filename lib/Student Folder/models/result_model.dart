/// Result models for KUET CSE Automation App

/// Theory course result with class tests, assignment, attendance, and term final
class TheoryResult {
  final String courseCode;
  final String courseName;
  final List<double> classTests; // 3 class tests, each out of 20
  final double? assignment; // Optional, out of assigned marks
  final double attendance; // Out of assigned marks
  final double? termFinal; // Out of 210 (105 per teacher)

  const TheoryResult({
    required this.courseCode,
    required this.courseName,
    required this.classTests,
    this.assignment,
    required this.attendance,
    this.termFinal,
  });

  /// Total class test marks (out of 60)
  double get totalClassTest => classTests.fold(0.0, (sum, ct) => sum + ct);

  /// Average class test score
  double get avgClassTest => classTests.isNotEmpty ? totalClassTest / classTests.length : 0;

  /// Continuous assessment total (CT + attendance + assignment)
  double get continuousAssessment => totalClassTest + attendance + (assignment ?? 0);
}

/// Lab course result with various components
class LabResult {
  final String courseCode;
  final String courseName;
  final double labTask;      // Weekly task marks
  final double labReport;    // Report marks
  final double labQuiz;      // Quiz marks
  final double? labTest;     // Lab test marks (after 10 labs)
  final double? centralViva; // Central viva marks

  const LabResult({
    required this.courseCode,
    required this.courseName,
    required this.labTask,
    required this.labReport,
    required this.labQuiz,
    this.labTest,
    this.centralViva,
  });

  /// Total continuous marks
  double get continuousTotal => labTask + labReport + labQuiz;

  /// Total lab marks (if all components available)
  double get totalMarks => continuousTotal + (labTest ?? 0) + (centralViva ?? 0);
}
