import 'package:flutter/material.dart';
import 'package:kuet_cse_automation/Tacher%20Folder/Courses/Course_info.dart';

class TeacherHomeScreen extends StatelessWidget {
  const TeacherHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Features Grid
            Text(
              'Teacher Dashboard',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildFeatureCard(
                  context: context,
                  icon: Icons.class_,
                  title: 'My Courses',
                  color: Colors.blue,
                  isDarkMode: isDarkMode,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CourseInfoScreen(),
                      ),
                    );
                  },
                ),
                _buildFeatureCard(
                  context: context,
                  icon: Icons.people,
                  title: 'Students',
                  color: Colors.green,
                  isDarkMode: isDarkMode,
                  onTap: () {},
                ),
                _buildFeatureCard(
                  context: context,
                  icon: Icons.assignment,
                  title: 'Assignments',
                  color: Colors.orange,
                  isDarkMode: isDarkMode,
                  onTap: () {},
                ),
                _buildFeatureCard(
                  context: context,
                  icon: Icons.grade,
                  title: 'Grading',
                  color: Colors.purple,
                  isDarkMode: isDarkMode,
                  onTap: () {},
                ),
                _buildFeatureCard(
                  context: context,
                  icon: Icons.schedule,
                  title: 'Schedule',
                  color: Colors.teal,
                  isDarkMode: isDarkMode,
                  onTap: () {},
                ),
                _buildFeatureCard(
                  context: context,
                  icon: Icons.announcement,
                  title: 'Announcements',
                  color: Colors.red,
                  isDarkMode: isDarkMode,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Recent Activities
            Text(
              'Recent Activities',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildActivityCard(
              title: 'New Assignment Submission',
              subtitle: 'Data Structures - 15 submissions',
              time: '1 hour ago',
              icon: Icons.assignment_turned_in,
              color: Colors.blue,
              isDarkMode: isDarkMode,
            ),
            _buildActivityCard(
              title: 'Class Scheduled',
              subtitle: 'Algorithm Analysis - Tomorrow 10 AM',
              time: '3 hours ago',
              icon: Icons.event,
              color: Colors.green,
              isDarkMode: isDarkMode,
            ),
            _buildActivityCard(
              title: 'Grade Updated',
              subtitle: 'Database Systems - Mid-term results',
              time: '1 day ago',
              icon: Icons.grade,
              color: Colors.orange,
              isDarkMode: isDarkMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard({
    required String title,
    required String subtitle,
    required String time,
    required IconData icon,
    required Color color,
    required bool isDarkMode,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
