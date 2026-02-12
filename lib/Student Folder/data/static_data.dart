/// Static sample data for result screens (to be migrated to Supabase later)

import '../models/student_model.dart';
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
