import 'package:flutter/material.dart';

class CourseInfoScreen extends StatelessWidget {
  const CourseInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDarkMode ? Colors.white : Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Courses',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.search,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistics Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.book,
                    title: 'Active Courses',
                    value: '5',
                    color: Colors.blue,
                    isDarkMode: isDarkMode,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.people,
                    title: 'Total Students',
                    value: '240',
                    color: Colors.green,
                    isDarkMode: isDarkMode,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Courses Section
            Text(
              'Current Semester Courses',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Course Cards
            _buildCourseCard(
              courseCode: 'CSE 3101',
              courseName: 'Data Structures',
              section: 'A',
              students: 48,
              schedule: 'Sun, Tue 10:00 AM',
              color: Colors.blue,
              isDarkMode: isDarkMode,
              context: context,
            ),
            _buildCourseCard(
              courseCode: 'CSE 3201',
              courseName: 'Algorithm Analysis',
              section: 'B',
              students: 52,
              schedule: 'Mon, Wed 11:30 AM',
              color: Colors.purple,
              isDarkMode: isDarkMode,
              context: context,
            ),
            _buildCourseCard(
              courseCode: 'CSE 3301',
              courseName: 'Database Systems',
              section: 'A',
              students: 45,
              schedule: 'Tue, Thu 2:00 PM',
              color: Colors.orange,
              isDarkMode: isDarkMode,
              context: context,
            ),
            _buildCourseCard(
              courseCode: 'CSE 3401',
              courseName: 'Software Engineering',
              section: 'C',
              students: 50,
              schedule: 'Sun, Wed 9:00 AM',
              color: Colors.teal,
              isDarkMode: isDarkMode,
              context: context,
            ),
            _buildCourseCard(
              courseCode: 'CSE 3501',
              courseName: 'Computer Networks',
              section: 'A',
              students: 45,
              schedule: 'Mon, Thu 3:30 PM',
              color: Colors.indigo,
              isDarkMode: isDarkMode,
              context: context,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: Colors.blue[600],
        icon: const Icon(Icons.add),
        label: const Text('Add Course'),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard({
    required String courseCode,
    required String courseName,
    required String section,
    required int students,
    required String schedule,
    required Color color,
    required bool isDarkMode,
    required BuildContext context,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Navigate to course details
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                                courseCode,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Section $section',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            courseName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.more_vert,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 18,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$students students',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Icon(
                      Icons.schedule,
                      size: 18,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      schedule,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.people, size: 18),
                        label: const Text('View Students'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: color,
                          side: BorderSide(color: color),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.assignment, size: 18),
                        label: const Text('Assignments'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
