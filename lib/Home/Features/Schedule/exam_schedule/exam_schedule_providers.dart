import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'exam_schedule_models.dart';

// Exam Category Provider (CT, Term Final, Quiz/Viva)
final selectedExamCategoryProvider = StateProvider<String>((ref) => 'CT');

// Exam Schedule Provider
final examScheduleProvider = Provider<List<ExamSchedule>>((ref) {
  return [
    // CT Exams
    ExamSchedule(
      courseName: 'Data Structures',
      courseCode: 'CSE 2101',
      examType: 'Class Test 1',
      category: 'CT',
      date: 'January 20, 2026',
      time: '10:00 AM - 11:00 AM',
      room: 'CSE-301',
      syllabus: 'Arrays, Linked Lists, Stacks',
    ),
    ExamSchedule(
      courseName: 'Algorithm Analysis',
      courseCode: 'CSE 2103',
      examType: 'Class Test 1',
      category: 'CT',
      date: 'January 22, 2026',
      time: '02:00 PM - 03:00 PM',
      room: 'CSE-302',
      syllabus: 'Time Complexity, Sorting Algorithms',
    ),
    ExamSchedule(
      courseName: 'Database Management',
      courseCode: 'CSE 2105',
      examType: 'Class Test 2',
      category: 'CT',
      date: 'January 25, 2026',
      time: '11:00 AM - 12:00 PM',
      room: 'CSE-303',
      syllabus: 'SQL Queries, Joins',
    ),
    
    // Term Final Exams
    ExamSchedule(
      courseName: 'Data Structures',
      courseCode: 'CSE 2101',
      examType: 'Mid-Term',
      category: 'Term Final',
      date: 'February 15, 2026',
      time: '10:00 AM - 12:00 PM',
      room: 'Exam Hall - 1',
      syllabus: 'Chapters 1-5: All data structures',
    ),
    ExamSchedule(
      courseName: 'Algorithm Analysis',
      courseCode: 'CSE 2103',
      examType: 'Mid-Term',
      category: 'Term Final',
      date: 'February 18, 2026',
      time: '02:00 PM - 04:00 PM',
      room: 'Exam Hall - 2',
      syllabus: 'Sorting, Searching, Graph Algorithms',
    ),
    ExamSchedule(
      courseName: 'Software Engineering',
      courseCode: 'CSE 2107',
      examType: 'Final Exam',
      category: 'Term Final',
      date: 'May 10, 2026',
      time: '02:00 PM - 05:00 PM',
      room: 'Exam Hall - 3',
      syllabus: 'All Topics - Complete Syllabus',
    ),
    
    // Quiz/Viva
    ExamSchedule(
      courseName: 'Database Management',
      courseCode: 'CSE 2105',
      examType: 'Quiz',
      category: 'Quiz/Viva',
      date: 'January 18, 2026',
      time: '03:00 PM - 03:30 PM',
      room: 'CSE-303',
      syllabus: 'ER Diagrams, Normalization',
    ),
    ExamSchedule(
      courseName: 'Software Engineering',
      courseCode: 'CSE 2107',
      examType: 'Viva Voce',
      category: 'Quiz/Viva',
      date: 'January 28, 2026',
      time: '10:00 AM - 01:00 PM',
      room: 'Faculty Room - 204',
      syllabus: 'UML Diagrams, SDLC Models',
    ),
    ExamSchedule(
      courseName: 'Computer Networks',
      courseCode: 'CSE 2109',
      examType: 'Quiz',
      category: 'Quiz/Viva',
      date: 'February 5, 2026',
      time: '11:00 AM - 11:30 AM',
      room: 'CSE-305',
      syllabus: 'OSI Model, TCP/IP',
    ),
  ];
});
