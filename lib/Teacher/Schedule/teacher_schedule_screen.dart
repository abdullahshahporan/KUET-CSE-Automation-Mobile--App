import 'package:flutter/material.dart';
import '../data/teacher_static_data.dart';

/// Teacher Schedule screen - view and manage class schedule
class TeacherScheduleScreen extends StatelessWidget {
  const TeacherScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final schedule = [
      {
        'day': 'Sunday',
        'classes': [
          {
            'time': '09:00 - 10:00',
            'course': 'CSE 3201',
            'room': 'Room 301',
            'section': 'A',
          },
          {
            'time': '11:00 - 12:00',
            'course': 'CSE 3201',
            'room': 'Room 301',
            'section': 'B',
          },
        ],
      },
      {
        'day': 'Monday',
        'classes': [
          {
            'time': '10:00 - 01:00',
            'course': 'CSE 3202',
            'room': 'Lab 201',
            'section': 'A1',
          },
        ],
      },
      {
        'day': 'Tuesday',
        'classes': [
          {
            'time': '09:00 - 10:00',
            'course': 'CSE 3201',
            'room': 'Room 301',
            'section': 'A',
          },
          {
            'time': '10:00 - 11:00',
            'course': 'CSE 3201',
            'room': 'Room 301',
            'section': 'B',
          },
        ],
      },
      {
        'day': 'Wednesday',
        'classes': [
          {
            'time': '10:00 - 01:00',
            'course': 'CSE 3202',
            'room': 'Lab 201',
            'section': 'A2',
          },
        ],
      },
      {'day': 'Thursday', 'classes': []},
    ];

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey[100],
      appBar: AppBar(
        title: const Text('My Schedule'),
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_calendar),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Schedule modification coming soon!'),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple[600]!, Colors.indigo[500]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Weekly Schedule',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${teacherCourses.length} Courses | ${_countTotalClasses(schedule)} Classes/Week',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Schedule by Day
            ...schedule.map(
              (day) => _buildDayCard(
                day['day'] as String,
                (day['classes'] as List)
                    .cast<Map<String, dynamic>>()
                    .map((e) => Map<String, String>.from(e))
                    .toList(),
                isDarkMode,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _countTotalClasses(List<Map<String, dynamic>> schedule) {
    return schedule.fold(
      0,
      (sum, day) => sum + (day['classes'] as List).length,
    );
  }

  Widget _buildDayCard(
    String day,
    List<Map<String, String>> classes,
    bool isDarkMode,
  ) {
    final isToday = _isToday(day);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isToday ? Border.all(color: Colors.purple, width: 2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isToday
                  ? Colors.purple.withOpacity(0.1)
                  : (isDarkMode ? Colors.grey[850] : Colors.grey[100]),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Text(
                  day,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isToday
                        ? Colors.purple
                        : (isDarkMode ? Colors.white : Colors.black87),
                  ),
                ),
                if (isToday) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Today',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  '${classes.length} ${classes.length == 1 ? 'class' : 'classes'}',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // Classes
          if (classes.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No classes scheduled',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...classes.map((cls) => _buildClassItem(cls, isDarkMode)),
        ],
      ),
    );
  }

  Widget _buildClassItem(Map<String, String> cls, bool isDarkMode) {
    final isLab = cls['course']!.contains('02');
    final color = isLab ? Colors.purple : Colors.blue;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      cls['course']!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        cls['section']!,
                        style: TextStyle(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      cls['time']!,
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.room, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      cls['room']!,
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(String day) {
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final today = DateTime.now().weekday - 1;
    return weekdays[today] == day;
  }
}
