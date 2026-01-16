import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'class_schedule_models.dart';

// Class Schedule Provider
final classScheduleProvider = Provider<List<ClassSchedule>>((ref) {
  return [
    ClassSchedule(
      courseName: 'Data Structures',
      courseCode: 'CSE 2101',
      teacher: 'Dr. Ahmed Rahman',
      room: 'CSE-301',
      time: '10:00 AM - 11:30 AM',
      day: 'Sunday',
    ),
    ClassSchedule(
      courseName: 'Algorithm Analysis',
      courseCode: 'CSE 2103',
      teacher: 'Prof. Fatima Khan',
      room: 'CSE-302',
      time: '12:00 PM - 01:30 PM',
      day: 'Sunday',
    ),
    ClassSchedule(
      courseName: 'Operating Systems',
      courseCode: 'CSE 2102',
      teacher: 'Dr. Sultana Begum',
      room: 'CSE-301',
      time: '02:00 PM - 03:30 PM',
      day: 'Sunday',
    ),
    ClassSchedule(
      courseName: 'Database Management',
      courseCode: 'CSE 2105',
      teacher: 'Dr. Karim Hassan',
      room: 'CSE-303',
      time: '10:00 AM - 11:30 AM',
      day: 'Monday',
    ),
    ClassSchedule(
      courseName: 'Discrete Mathematics',
      courseCode: 'CSE 2104',
      teacher: 'Prof. Rahim Uddin',
      room: 'CSE-302',
      time: '12:00 PM - 01:30 PM',
      day: 'Monday',
    ),
    ClassSchedule(
      courseName: 'Software Engineering',
      courseCode: 'CSE 2107',
      teacher: 'Dr. Nasrin Akter',
      room: 'CSE-304',
      time: '10:00 AM - 11:30 AM',
      day: 'Tuesday',
    ),
    ClassSchedule(
      courseName: 'Web Technologies',
      courseCode: 'CSE 2106',
      teacher: 'Dr. Tasnim Ahmed',
      room: 'CSE-303',
      time: '02:00 PM - 03:30 PM',
      day: 'Tuesday',
    ),
    ClassSchedule(
      courseName: 'Computer Networks',
      courseCode: 'CSE 2109',
      teacher: 'Prof. Shahid Mahmud',
      room: 'CSE-305',
      time: '10:00 AM - 11:30 AM',
      day: 'Wednesday',
    ),
    ClassSchedule(
      courseName: 'Machine Learning',
      courseCode: 'CSE 2108',
      teacher: 'Prof. Jamal Hossain',
      room: 'CSE-304',
      time: '02:00 PM - 03:30 PM',
      day: 'Wednesday',
    ),
  ];
});
