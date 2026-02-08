import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kuet_cse_automation/Student%20Folder/models/app_models.dart';

// Providers for Notice, Assignment, and Attendance features
// Schedule providers are in Home/Features/Schedule folder

// Notices Provider
final noticesProvider = Provider<List<Notice>>((ref) {
  return [
    Notice(
      id: '1',
      title: 'Mid-Term Exam Schedule Published',
      description:
          'The mid-term examination schedule for Spring 2026 semester has been published. Please check your respective class groups.',
      date: 'January 12, 2026',
      category: 'Exam',
      isImportant: true,
    ),
    Notice(
      id: '2',
      title: 'Department Seminar on AI',
      description:
          'A seminar on "Recent Advances in Artificial Intelligence" will be held on January 20, 2026 at 3:00 PM in the seminar hall.',
      date: 'January 10, 2026',
      category: 'Event',
      isImportant: false,
    ),
    Notice(
      id: '3',
      title: 'Lab Report Submission Deadline',
      description:
          'All pending lab reports must be submitted by January 25, 2026. Late submissions will not be accepted.',
      date: 'January 8, 2026',
      category: 'Academic',
      isImportant: true,
    ),
    Notice(
      id: '4',
      title: 'University Closed - National Holiday',
      description:
          'The university will remain closed on January 26, 2026 due to national holiday.',
      date: 'January 5, 2026',
      category: 'Holiday',
      isImportant: false,
    ),
    Notice(
      id: '5',
      title: 'Project Proposal Submission',
      description:
          'Final year students are requested to submit their project proposals by February 1, 2026.',
      date: 'January 3, 2026',
      category: 'Project',
      isImportant: true,
    ),
  ];
});

// Assignments Provider
final assignmentsProvider = Provider<List<Assignment>>((ref) {
  return [
    Assignment(
      id: '1',
      title: 'Binary Search Tree Implementation',
      courseName: 'Data Structures (CSE 2101)',
      description:
          'Implement a complete BST with insert, delete, search, and traversal operations.',
      deadline: 'January 20, 2026',
      status: 'pending',
      marks: 20,
    ),
    Assignment(
      id: '2',
      title: 'Dijkstra\'s Algorithm Analysis',
      courseName: 'Algorithm Analysis (CSE 2103)',
      description:
          'Analyze the time complexity of Dijkstra\'s algorithm and implement it in C++.',
      deadline: 'January 18, 2026',
      status: 'pending',
      marks: 15,
    ),
    Assignment(
      id: '3',
      title: 'Database Normalization',
      courseName: 'Database Management (CSE 2105)',
      description:
          'Normalize the given database schema up to 3NF and create ER diagram.',
      deadline: 'January 25, 2026',
      status: 'pending',
      marks: 25,
    ),
    Assignment(
      id: '4',
      title: 'UML Diagrams for Library System',
      courseName: 'Software Engineering (CSE 2107)',
      description:
          'Create complete UML diagrams (Use Case, Class, Sequence) for a library management system.',
      deadline: 'January 15, 2026',
      status: 'submitted',
      marks: 20,
    ),
    Assignment(
      id: '5',
      title: 'Socket Programming',
      courseName: 'Computer Networks (CSE 2109)',
      description:
          'Implement a simple client-server chat application using socket programming.',
      deadline: 'January 10, 2026',
      status: 'overdue',
      marks: 15,
    ),
  ];
});

// Attendance Provider
final attendanceProvider = Provider<List<AttendanceRecord>>((ref) {
  return [
    AttendanceRecord(
      courseCode: 'CSE 2101',
      courseName: 'Data Structures',
      totalClasses: 30,
      attendedClasses: 28,
    ),
    AttendanceRecord(
      courseCode: 'CSE 2103',
      courseName: 'Algorithm Analysis',
      totalClasses: 28,
      attendedClasses: 26,
    ),
    AttendanceRecord(
      courseCode: 'CSE 2105',
      courseName: 'Database Management',
      totalClasses: 32,
      attendedClasses: 25,
    ),
    AttendanceRecord(
      courseCode: 'CSE 2107',
      courseName: 'Software Engineering',
      totalClasses: 30,
      attendedClasses: 29,
    ),
    AttendanceRecord(
      courseCode: 'CSE 2109',
      courseName: 'Computer Networks',
      totalClasses: 26,
      attendedClasses: 20,
    ),
    AttendanceRecord(
      courseCode: 'CSE 2102',
      courseName: 'Operating Systems',
      totalClasses: 28,
      attendedClasses: 24,
    ),
  ];
});
