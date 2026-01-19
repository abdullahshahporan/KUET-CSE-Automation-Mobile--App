import 'package:flutter/material.dart';
import '../Student Folder/Attendance/attendance_screen.dart';
import '../Student Folder/Result/result_screen.dart';
import '../Student Folder/Curriculum/curriculum_screen.dart';
import '../theme/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: isDarkMode
                    ? const LinearGradient(
                        colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [Colors.blue[600]!, Colors.cyan[500]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(20),
                border: isDarkMode ? Border.all(color: AppColors.darkBorder) : null,
                boxShadow: isDarkMode
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(isDarkMode ? 0.1 : 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.computer,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(isDarkMode ? 0.1 : 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.greenAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Online',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Welcome!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'KUET Computer Science & Engineering',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Features Grid
            Text(
              'Features',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(isDarkMode),
              ),
            ),
            const SizedBox(height: 14),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.1,
              children: [
                _buildFeatureCard(
                  context: context,
                  icon: Icons.fact_check,
                  title: 'Attendance',
                  color: AppColors.attendance,
                  isDarkMode: isDarkMode,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AttendanceScreen()),
                  ),
                ),
                _buildFeatureCard(
                  context: context,
                  icon: Icons.grade,
                  title: 'Results',
                  color: AppColors.grading,
                  isDarkMode: isDarkMode,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ResultScreen()),
                  ),
                ),
                _buildFeatureCard(
                  context: context,
                  icon: Icons.library_books,
                  title: 'Curriculum',
                  color: AppColors.teal,
                  isDarkMode: isDarkMode,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CurriculumScreen()),
                  ),
                ),
                _buildFeatureCard(
                  context: context,
                  icon: Icons.schedule,
                  title: 'Schedule',
                  color: AppColors.schedule,
                  isDarkMode: isDarkMode,
                  onTap: () {},
                ),
                _buildFeatureCard(
                  context: context,
                  icon: Icons.notifications,
                  title: 'Notices',
                  color: AppColors.danger,
                  isDarkMode: isDarkMode,
                  onTap: () {},
                ),
                _buildFeatureCard(
                  context: context,
                  icon: Icons.book,
                  title: 'Resources',
                  color: AppColors.indigo,
                  isDarkMode: isDarkMode,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Recent Updates
            Text(
              'Recent Updates',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(isDarkMode),
              ),
            ),
            const SizedBox(height: 14),
            _buildUpdateCard(
              title: 'New Assignment Posted',
              subtitle: 'Data Structures - Assignment 3',
              time: '2 hours ago',
              icon: Icons.assignment_turned_in,
              color: AppColors.primary,
              isDarkMode: isDarkMode,
            ),
            _buildUpdateCard(
              title: 'Class Rescheduled',
              subtitle: 'Algorithm Analysis - Tomorrow 10 AM',
              time: '5 hours ago',
              icon: Icons.event,
              color: AppColors.warning,
              isDarkMode: isDarkMode,
            ),
            _buildUpdateCard(
              title: 'Exam Notice',
              subtitle: 'Mid-term exams starting next week',
              time: '1 day ago',
              icon: Icons.warning,
              color: AppColors.danger,
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 16),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.surface(isDarkMode),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border(isDarkMode)),
          boxShadow: isDarkMode
              ? null
              : [
                  BoxShadow(
                    color: color.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 28,
                color: color,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(isDarkMode),
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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface(isDarkMode),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(isDarkMode)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(isDarkMode),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary(isDarkMode),
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
