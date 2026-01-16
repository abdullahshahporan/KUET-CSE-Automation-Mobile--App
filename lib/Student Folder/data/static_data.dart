/// Static sample data for KUET CSE Automation App
/// This will be replaced with dynamic data from database later

import '../models/student_model.dart';
import '../models/course_model.dart';
import '../models/attendance_model.dart';
import '../models/result_model.dart';

/// Sample current student
const Student currentStudent = Student(
  roll: '2107001',
  name: 'Asif Jawad',
  batch: '21',
  currentYear: 3,
  currentTerm: 2,
  email: 'asif@cse.kuet.ac.bd',
);

/// Sample courses for 3rd Year 2nd Term (3-2)
final List<Course> courses32 = [
  const Course(
    code: 'CSE 3201',
    title: 'Software Engineering',
    credits: 3.0,
    type: CourseType.theory,
    teachers: ['Dr. M. M. A. Hashem', 'Dr. K. M. Azharul Hasan'],
    year: 3,
    term: 2,
  ),
  const Course(
    code: 'CSE 3203',
    title: 'Computer Networks',
    credits: 3.0,
    type: CourseType.theory,
    teachers: ['Dr. Muhammad Sheikh Sadi', 'Dr. Md. Aminul Haque Akhand'],
    year: 3,
    term: 2,
  ),
  const Course(
    code: 'CSE 3205',
    title: 'Database Management Systems',
    credits: 3.0,
    type: CourseType.theory,
    teachers: ['Dr. Kazi Md. Rokibul Alam', 'Dr. Pintu Chandra Shill'],
    year: 3,
    term: 2,
  ),
  const Course(
    code: 'CSE 3207',
    title: 'Microprocessors & Microcontrollers',
    credits: 3.0,
    type: CourseType.theory,
    teachers: ['Mr. Al-Mahmud', 'Mr. Md. Abdul Awal'],
    year: 3,
    term: 2,
  ),
  const Course(
    code: 'CSE 3200',
    title: 'System Development Project',
    credits: 1.5,
    type: CourseType.lab,
    teachers: ['Project Supervisor'],
    year: 3,
    term: 2,
  ),
  const Course(
    code: 'CSE 3202',
    title: 'Software Engineering Lab',
    credits: 1.5,
    type: CourseType.lab,
    teachers: ['Dr. M. M. A. Hashem'],
    year: 3,
    term: 2,
  ),
  const Course(
    code: 'CSE 3204',
    title: 'Computer Networks Lab',
    credits: 0.75,
    type: CourseType.lab,
    teachers: ['Dr. Muhammad Sheikh Sadi'],
    year: 3,
    term: 2,
  ),
  const Course(
    code: 'CSE 3206',
    title: 'Database Management Systems Lab',
    credits: 0.75,
    type: CourseType.lab,
    teachers: ['Dr. Kazi Md. Rokibul Alam'],
    year: 3,
    term: 2,
  ),
  const Course(
    code: 'CSE 3208',
    title: 'Microprocessors Lab',
    credits: 0.75,
    type: CourseType.lab,
    teachers: ['Mr. Al-Mahmud'],
    year: 3,
    term: 2,
  ),
];

/// Sample attendance records for 3-2 semester
final List<AttendanceRecord> sampleAttendanceRecords = [
  const AttendanceRecord(
    courseCode: 'CSE 3201',
    courseName: 'Software Engineering',
    totalClasses: 26,
    attendedClasses: 24,
  ),
  const AttendanceRecord(
    courseCode: 'CSE 3203',
    courseName: 'Computer Networks',
    totalClasses: 26,
    attendedClasses: 20,
  ),
  const AttendanceRecord(
    courseCode: 'CSE 3205',
    courseName: 'Database Management Systems',
    totalClasses: 26,
    attendedClasses: 17,
  ),
  const AttendanceRecord(
    courseCode: 'CSE 3207',
    courseName: 'Microprocessors & Microcontrollers',
    totalClasses: 26,
    attendedClasses: 15,
  ),
  const AttendanceRecord(
    courseCode: 'CSE 3202',
    courseName: 'Software Engineering Lab',
    totalClasses: 10,
    attendedClasses: 10,
  ),
  const AttendanceRecord(
    courseCode: 'CSE 3204',
    courseName: 'Computer Networks Lab',
    totalClasses: 6,
    attendedClasses: 5,
  ),
  const AttendanceRecord(
    courseCode: 'CSE 3206',
    courseName: 'DBMS Lab',
    totalClasses: 6,
    attendedClasses: 4,
  ),
];

/// Sample theory results for 3-2 semester
final List<TheoryResult> sampleTheoryResults = [
  const TheoryResult(
    courseCode: 'CSE 3201',
    courseName: 'Software Engineering',
    classTests: [18.0, 16.5, 17.0],
    assignment: 8.5,
    attendance: 9.0,
  ),
  const TheoryResult(
    courseCode: 'CSE 3203',
    courseName: 'Computer Networks',
    classTests: [15.0, 17.0, 14.5],
    assignment: 7.5,
    attendance: 7.5,
  ),
  const TheoryResult(
    courseCode: 'CSE 3205',
    courseName: 'Database Management Systems',
    classTests: [19.0, 18.0, 16.0],
    attendance: 6.5,
  ),
  const TheoryResult(
    courseCode: 'CSE 3207',
    courseName: 'Microprocessors & Microcontrollers',
    classTests: [14.0, 15.5, 13.0],
    attendance: 5.5,
  ),
];

/// Sample lab results for 3-2 semester
final List<LabResult> sampleLabResults = [
  const LabResult(
    courseCode: 'CSE 3202',
    courseName: 'Software Engineering Lab',
    labTask: 45.0,
    labReport: 18.0,
    labQuiz: 8.5,
  ),
  const LabResult(
    courseCode: 'CSE 3204',
    courseName: 'Computer Networks Lab',
    labTask: 22.0,
    labReport: 9.0,
    labQuiz: 7.5,
  ),
  const LabResult(
    courseCode: 'CSE 3206',
    courseName: 'DBMS Lab',
    labTask: 20.0,
    labReport: 8.0,
    labQuiz: 6.5,
  ),
];

/// Get all courses for a specific year and term
List<Course> getCoursesForSemester(int year, int term) {
  // For now, only 3-2 has sample data
  if (year == 3 && term == 2) {
    return courses32;
  }
  // Return empty list for other semesters
  return [];
}

/// Calculate overall attendance percentage
double calculateOverallAttendance(List<AttendanceRecord> records) {
  if (records.isEmpty) return 0;
  int totalClasses = 0;
  int totalAttended = 0;
  for (final record in records) {
    totalClasses += record.totalClasses;
    totalAttended += record.attendedClasses;
  }
  return totalClasses > 0 ? (totalAttended / totalClasses) * 100 : 0;
}
