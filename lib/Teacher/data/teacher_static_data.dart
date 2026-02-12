/// Static data for teacher features - Multi-Semester Support
/// This will be replaced with dynamic data from database later

import '../../Student Folder/models/user_model.dart';
import '../../Student Folder/models/course_model.dart';

/// Extended course model for teacher with semester info
class TeacherCourse {
  final String code;
  final String title;
  final double credits;
  final CourseType type;
  final int year;
  final int term;
  final int expectedClasses; // Total expected classes in semester
  final List<String> sections; // For theory: ['A', 'B']
  final List<String> groups; // For sessional: ['A1', 'A2', 'B1', 'B2']
  final List<String> teachers;
  final String? offeringId; // Supabase course_offerings.id
  final String? session; // Supabase course_offerings.session

  const TeacherCourse({
    required this.code,
    required this.title,
    required this.credits,
    required this.type,
    required this.year,
    required this.term,
    required this.expectedClasses,
    this.sections = const [],
    this.groups = const [],
    this.teachers = const [],
    this.offeringId,
    this.session,
  });

  String get semesterName {
    final yearSuffix = year == 1
        ? 'st'
        : year == 2
        ? 'nd'
        : year == 3
        ? 'rd'
        : 'th';
    final termSuffix = term == 1 ? 'st' : 'nd';
    return '$year-$term ($year$yearSuffix Year $term$termSuffix Term)';
  }

  String get shortSemester => '$year-$term';

  String get creditsString =>
      '${credits.toStringAsFixed(credits == credits.roundToDouble() ? 0 : 1)} Credits';

  /// Get batch roll prefix based on year (assuming current year is 2026)
  String get batchRollPrefix {
    // Current year 3-2 means batch 21 (2021)
    // Year 1 = batch 24, Year 2 = batch 23, Year 3 = batch 22, Year 4 = batch 21
    final batchYear = 25 - year;
    return '2${batchYear.toString().padLeft(2, '0')}7';
  }
}

/// Sample teacher user
const TeacherUser currentTeacher = TeacherUser(
  id: 'T001',
  name: 'Dr. M. M. A. Hashem',
  email: 'hashem@cse.kuet.ac.bd',
  phone: '+880 1711-123456',
  employeeId: 'EMP-CSE-001',
  designation: 'Professor',
  department: 'Computer Science & Engineering',
  experience: 15,
  officeRoom: 'Room 301, CSE Building',
  assignedCourses: ['CSE 2101', 'CSE 2102', 'CSE 3201', 'CSE 3202'],
);

/// Multi-semester courses for teacher
final List<TeacherCourse> teacherCourses = [
  // 2nd Year 1st Term - Theory
  const TeacherCourse(
    code: 'CSE 2101',
    title: 'Data Structures',
    credits: 3.0,
    type: CourseType.theory,
    year: 2,
    term: 1,
    expectedClasses: 18,
    sections: ['A', 'B'],
    teachers: ['Dr. M. M. A. Hashem', 'Dr. K. M. Azharul Hasan'],
  ),
  // 2nd Year 1st Term - Sessional
  const TeacherCourse(
    code: 'CSE 2102',
    title: 'Data Structures Lab',
    credits: 1.5,
    type: CourseType.lab,
    year: 2,
    term: 1,
    expectedClasses: 10, // 1.5 credit = ~10 labs
    groups: ['A1', 'A2', 'B1', 'B2'],
    teachers: ['Dr. M. M. A. Hashem'],
  ),
  // 3rd Year 2nd Term - Theory
  const TeacherCourse(
    code: 'CSE 3201',
    title: 'Software Engineering',
    credits: 3.0,
    type: CourseType.theory,
    year: 3,
    term: 2,
    expectedClasses: 18,
    sections: ['A', 'B'],
    teachers: ['Dr. M. M. A. Hashem', 'Dr. K. M. Azharul Hasan'],
  ),
  // 3rd Year 2nd Term - Sessional
  const TeacherCourse(
    code: 'CSE 3202',
    title: 'Software Engineering Lab',
    credits: 1.5,
    type: CourseType.lab,
    year: 3,
    term: 2,
    expectedClasses: 10,
    groups: ['A1', 'A2', 'B1', 'B2'],
    teachers: ['Dr. M. M. A. Hashem'],
  ),
  // 4th Year 1st Term - Theory (0.75 credit sessional)
  const TeacherCourse(
    code: 'CSE 4100',
    title: 'Thesis/Project',
    credits: 0.75,
    type: CourseType.lab,
    year: 4,
    term: 1,
    expectedClasses: 5, // 0.75 credit = ~5 labs
    groups: ['A1', 'A2', 'B1', 'B2'],
    teachers: ['Dr. M. M. A. Hashem'],
  ),
];

/// Generate students for a specific batch/semester
List<StudentUser> generateStudentsForBatch(int batchYear, String section) {
  final rollPrefix = '2${batchYear.toString().padLeft(2, '0')}7';
  final startRoll = section == 'A' ? 1 : 61;
  final endRoll = section == 'A' ? 60 : 120;

  return List.generate(endRoll - startRoll + 1, (index) {
    final rollNum = startRoll + index;
    final formattedRoll = '$rollPrefix${rollNum.toString().padLeft(3, '0')}';
    return StudentUser(
      id: 'S$rollNum',
      name: _getStudentName(rollNum),
      email: '$formattedRoll@stud.kuet.ac.bd',
      roll: formattedRoll,
      batch: batchYear.toString(),
      currentYear: 25 - batchYear,
      currentTerm: 2,
      section: section,
    );
  });
}

/// Get students for a specific course
List<StudentUser> getStudentsForCourse(
  TeacherCourse course,
  String sectionOrGroup,
) {
  final batchYear = 25 - course.year;

  if (course.type == CourseType.theory) {
    return generateStudentsForBatch(batchYear, sectionOrGroup);
  } else {
    // Sessional groups
    final section = sectionOrGroup.startsWith('A') ? 'A' : 'B';
    final students = generateStudentsForBatch(batchYear, section);

    // Filter by group
    switch (sectionOrGroup) {
      case 'A1':
        return students.where((s) {
          final rollNum = int.parse(s.roll.substring(s.roll.length - 3));
          return rollNum >= 1 && rollNum <= 30;
        }).toList();
      case 'A2':
        return students.where((s) {
          final rollNum = int.parse(s.roll.substring(s.roll.length - 3));
          return rollNum >= 31 && rollNum <= 60;
        }).toList();
      case 'B1':
        return students.where((s) {
          final rollNum = int.parse(s.roll.substring(s.roll.length - 3));
          return rollNum >= 61 && rollNum <= 90;
        }).toList();
      case 'B2':
        return students.where((s) {
          final rollNum = int.parse(s.roll.substring(s.roll.length - 3));
          return rollNum >= 91 && rollNum <= 120;
        }).toList();
      default:
        return students;
    }
  }
}

/// Sample student names
String _getStudentName(int rollNum) {
  final names = [
    'Asif Jawad',
    'Mehedi Hasan',
    'Sakib Rahman',
    'Tanvir Ahmed',
    'Rafiq Islam',
    'Nusrat Jahan',
    'Farhana Akter',
    'Sadia Islam',
    'Riya Das',
    'Priya Roy',
    'Abdullah Al Mamun',
    'Md. Rakib',
    'Jahid Hasan',
    'Imran Khan',
    'Farhan Sadik',
    'Sumaiya Akter',
    'Tahmina Begum',
    'Roksana Parvin',
    'Mitu Rani',
    'Shapla Khatun',
    'Kamal Ahmed',
    'Jamal Uddin',
    'Rahim Mia',
    'Karim Sheikh',
    'Salim Khan',
    'Fatima Begum',
    'Ayesha Siddika',
    'Hasina Akter',
    'Kulsum Begum',
    'Nasrin Jahan',
  ];
  return names[rollNum % names.length];
}

/// Attendance status enum
enum AttendanceStatus { present, absent, late }

/// Attendance record for a single class session
class AttendanceSession {
  final String id;
  final String courseCode;
  final DateTime date;
  final String sectionOrGroup;
  final Map<String, AttendanceStatus> studentAttendance;
  final DateTime createdAt;

  AttendanceSession({
    required this.id,
    required this.courseCode,
    required this.date,
    required this.sectionOrGroup,
    required this.studentAttendance,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  int get presentCount => studentAttendance.values
      .where((s) => s == AttendanceStatus.present)
      .length;
  int get absentCount => studentAttendance.values
      .where((s) => s == AttendanceStatus.absent)
      .length;
  int get lateCount =>
      studentAttendance.values.where((s) => s == AttendanceStatus.late).length;
  int get totalCount => studentAttendance.length;
  double get attendanceRate =>
      totalCount > 0 ? (presentCount + lateCount) / totalCount * 100 : 0;
}

/// Sample attendance sessions
final List<AttendanceSession> attendanceSessions = [
  AttendanceSession(
    id: 'ATT001',
    courseCode: 'CSE 3201',
    date: DateTime(2026, 1, 15),
    sectionOrGroup: 'A',
    studentAttendance: {
      for (var i = 1; i <= 60; i++)
        '2122${i.toString().padLeft(3, '0')}': i % 5 == 0
            ? AttendanceStatus.absent
            : i % 7 == 0
            ? AttendanceStatus.late
            : AttendanceStatus.present,
    },
  ),
  AttendanceSession(
    id: 'ATT002',
    courseCode: 'CSE 3201',
    date: DateTime(2026, 1, 13),
    sectionOrGroup: 'A',
    studentAttendance: {
      for (var i = 1; i <= 60; i++)
        '2122${i.toString().padLeft(3, '0')}': i % 6 == 0
            ? AttendanceStatus.absent
            : i % 8 == 0
            ? AttendanceStatus.late
            : AttendanceStatus.present,
    },
  ),
  AttendanceSession(
    id: 'ATT003',
    courseCode: 'CSE 3201',
    date: DateTime(2026, 1, 11),
    sectionOrGroup: 'B',
    studentAttendance: {
      for (var i = 61; i <= 120; i++)
        '2122${i.toString().padLeft(3, '0')}': i % 4 == 0
            ? AttendanceStatus.absent
            : AttendanceStatus.present,
    },
  ),
];

/// Get attendance sessions for a course and section
List<AttendanceSession> getAttendanceForCourse(
  String courseCode,
  String sectionOrGroup,
) {
  return attendanceSessions
      .where(
        (s) => s.courseCode == courseCode && s.sectionOrGroup == sectionOrGroup,
      )
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));
}

/// Get attendance count for a course
int getAttendanceCount(String courseCode, String sectionOrGroup) {
  return attendanceSessions
      .where(
        (s) => s.courseCode == courseCode && s.sectionOrGroup == sectionOrGroup,
      )
      .length;
}

/// Theory grading components
class TheoryGrades {
  final String roll;
  final double ct1; // out of 20
  final double ct2; // out of 10
  final double spotTest; // out of 5
  final double assignment; // out of 5
  final double attendance; // out of 10
  final double? termExam; // out of 105

  const TheoryGrades({
    required this.roll,
    this.ct1 = 0,
    this.ct2 = 0,
    this.spotTest = 0,
    this.assignment = 0,
    this.attendance = 0,
    this.termExam,
  });

  double get classTestTotal => ct1 + ct2;
  double get caTotal => classTestTotal + spotTest + assignment + attendance;
}

/// Sessional grading components
class SessionalGrades {
  final String roll;
  final double labTask;
  final double labReport;
  final double quiz;
  final double labTest;
  final double project;
  final double centralViva;

  const SessionalGrades({
    required this.roll,
    this.labTask = 0,
    this.labReport = 0,
    this.quiz = 0,
    this.labTest = 0,
    this.project = 0,
    this.centralViva = 0,
  });

  double get total =>
      labTask + labReport + quiz + labTest + project + centralViva;
}

/// Sample theory grades
final List<TheoryGrades> sampleTheoryGrades = List.generate(120, (index) {
  final roll = '2122${(index + 1).toString().padLeft(3, '0')}';
  return TheoryGrades(
    roll: roll,
    ct1: 12 + (index % 8).toDouble(),
    ct2: 4 + (index % 6).toDouble(),
    spotTest: 2 + (index % 3).toDouble(),
    assignment: 3 + (index % 2).toDouble(),
    attendance: 6 + (index % 4).toDouble(),
  );
});

/// Announcement model
class Announcement {
  final String id;
  final String title;
  final String content;
  final String courseCode;
  final String teacherName;
  final DateTime createdAt;
  final AnnouncementType type;
  final DateTime? scheduledDate;

  const Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.courseCode,
    required this.teacherName,
    required this.createdAt,
    required this.type,
    this.scheduledDate,
  });
}

enum AnnouncementType { classTest, assignment, notice, labTest, quiz, other }

/// Sample announcements
final List<Announcement> sampleAnnouncements = [
  Announcement(
    id: 'A001',
    title: 'CT-1 Scheduled',
    content:
        'Class Test 1 for CSE 3201 will be held on January 25, 2026. Syllabus: Chapter 1-3.',
    courseCode: 'CSE 3201',
    teacherName: 'Dr. M. M. A. Hashem',
    createdAt: DateTime(2026, 1, 18),
    type: AnnouncementType.classTest,
    scheduledDate: DateTime(2026, 1, 25),
  ),
  Announcement(
    id: 'A002',
    title: 'Assignment Submission',
    content:
        'Submit Assignment 2 by January 30, 2026. Topic: Software Design Patterns.',
    courseCode: 'CSE 3201',
    teacherName: 'Dr. M. M. A. Hashem',
    createdAt: DateTime(2026, 1, 16),
    type: AnnouncementType.assignment,
    scheduledDate: DateTime(2026, 1, 30),
  ),
  Announcement(
    id: 'A003',
    title: 'Data Structures Quiz',
    content: 'Quiz on Linked Lists and Trees. Date: January 22, 2026.',
    courseCode: 'CSE 2101',
    teacherName: 'Dr. M. M. A. Hashem',
    createdAt: DateTime(2026, 1, 14),
    type: AnnouncementType.quiz,
    scheduledDate: DateTime(2026, 1, 22),
  ),
];

/// Legacy compatibility - get students by section
List<StudentUser> getStudentsBySection(String section) {
  return generateStudentsForBatch(22, section); // Batch 22 for 3rd year
}

/// Legacy compatibility - get students by sessional group
List<StudentUser> getStudentsBySessionalGroup(String group) {
  final course = teacherCourses.firstWhere(
    (c) => c.type == CourseType.lab,
    orElse: () => teacherCourses.first,
  );
  return getStudentsForCourse(course, group);
}
