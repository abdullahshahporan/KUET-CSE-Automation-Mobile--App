import 'package:flutter/material.dart';
import '../Attendance/attendance_screen.dart';
import '../Result/result_screen.dart';
import '../Curriculum/curriculum_screen.dart';
import 'package:kuet_cse_automation/Home/Features/Schedule/unified_schedule_screen.dart';
import 'package:kuet_cse_automation/Home/Features/Assignment/Assignment_Screen.dart';
import 'package:kuet_cse_automation/Home/Features/Notice/Notice_Screen.dart';
import 'package:kuet_cse_automation/Home/Features/Attendance/Attendance_tracker_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
              'Features',
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
                  icon: Icons.fact_check,
                  title: 'Attendance',
                  color: Colors.green,
                  isDarkMode: isDarkMode,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AttendanceScreen()),
                  ),
                ),
                _buildFeatureCard(
                  icon: Icons.grade,
                  title: 'Results',
                  color: Colors.blue,
                  isDarkMode: isDarkMode,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ResultScreen()),
                  ),
                ),
                _buildFeatureCard(
                  icon: Icons.library_books,
                  title: 'Curriculum',
                  color: Colors.teal,
                  isDarkMode: isDarkMode,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CurriculumScreen()),
                  ),
                ),
                
                _buildFeatureCard(
                  icon: Icons.schedule,
                  title: 'Class Schedule',
                  color: Colors.purple,
                  isDarkMode: isDarkMode,
                  onTap: () {},
                ),
                _buildFeatureCard(
                  icon: Icons.notifications,
                  title: 'Notices',
                  color: Colors.red,
                  isDarkMode: isDarkMode,
                  onTap: () {},
                ),
               
                _buildFeatureCard(
                  context: context,
                  icon: Icons.present_to_all,
                  title: 'Attendance Tracker',
                  color: Colors.indigo,
                  isDarkMode: isDarkMode,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AttendanceTrackerScreen()),
                    );
                  },
                ),
                
              ],
            ),
            const SizedBox(height: 24),
           // Recent Updates
            Text(
              'Recent Updates',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildUpdateCard(
              title: 'New Assignment Posted',
              subtitle: 'Data Structures - Assignment 3',
              time: '2 hours ago',
              icon: Icons.assignment_turned_in,
              color: Colors.blue,
              isDarkMode: isDarkMode,
            ),
            _buildUpdateCard(
              title: 'Class Rescheduled',
              subtitle: 'Algorithm Analysis - Tomorrow 10 AM',
              time: '5 hours ago',
              icon: Icons.event,
              color: Colors.orange,
              isDarkMode: isDarkMode,
            ),
            _buildUpdateCard(
              title: 'Exam Notice',
              subtitle: 'Mid-term exams starting next week',
              time: '1 day ago',
              icon: Icons.warning,
              color: Colors.red,
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 24),
            Text(
              'Upcoming Schedules',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            
            _buildUpdateCard(
              title: 'Class Rescheduled',
              subtitle: 'Algorithm Analysis - Tomorrow 10 AM',
              time: '5 hours ago',
              icon: Icons.event,
              color: Colors.orange,
              isDarkMode: isDarkMode,
            ),
            _buildUpdateCard(
              title: 'Exam Notice',
              subtitle: 'Mid-term exams starting next week',
              time: '1 day ago',
              icon: Icons.warning,
              color: Colors.red,
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 24),
            
            
            
           
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.blue[600],
        child: const Icon(Icons.add),
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
              child: Icon(
                icon,
                size: 40,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
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

  Widget _buildUpdateCard({
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
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
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
                    fontWeight: FontWeight.bold,
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
