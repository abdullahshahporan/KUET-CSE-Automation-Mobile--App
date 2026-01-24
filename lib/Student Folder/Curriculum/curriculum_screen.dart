import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../data/static_data.dart';
import 'widgets/course_card.dart';
import '../../theme/app_colors.dart';

/// Main Curriculum screen displaying semester-wise courses
class CurriculumScreen extends StatefulWidget {
  const CurriculumScreen({super.key});

  @override
  State<CurriculumScreen> createState() => _CurriculumScreenState();
}

class _CurriculumScreenState extends State<CurriculumScreen> {
  int _selectedYear = 3;
  int _selectedTerm = 2;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final courses = getCoursesForSemester(_selectedYear, _selectedTerm);
    final theoryCourses = courses
        .where((c) => c.type == CourseType.theory)
        .toList();
    final labCourses = courses.where((c) => c.type == CourseType.lab).toList();
    final totalCredits = courses.fold(0.0, (sum, c) => sum + c.credits);

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      appBar: AppBar(
        title: Text(
          'Curriculum',
          style: TextStyle(color: AppColors.textPrimary(isDarkMode)),
        ),
        backgroundColor: AppColors.surface(isDarkMode),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary(isDarkMode),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Semester selector
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.library_books,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Course Curriculum',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Computer Science & Engineering',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSelector(
                          'Year',
                          _selectedYear,
                          [1, 2, 3, 4],
                          (value) => setState(() => _selectedYear = value!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSelector(
                          'Term',
                          _selectedTerm,
                          [1, 2],
                          (value) => setState(() => _selectedTerm = value!),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Summary stats
            if (courses.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface(isDarkMode),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border(isDarkMode)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      Icons.menu_book,
                      '${theoryCourses.length}',
                      'Theory',
                      AppColors.primary,
                      isDarkMode,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppColors.border(isDarkMode),
                    ),
                    _buildStatItem(
                      Icons.science,
                      '${labCourses.length}',
                      'Lab',
                      AppColors.accent,
                      isDarkMode,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppColors.border(isDarkMode),
                    ),
                    _buildStatItem(
                      Icons.star,
                      totalCredits.toStringAsFixed(
                        totalCredits.truncateToDouble() == totalCredits ? 0 : 2,
                      ),
                      'Credits',
                      AppColors.warning,
                      isDarkMode,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Courses list
            if (courses.isEmpty) ...[
              Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.folder_open,
                        size: 64,
                        color: AppColors.textSecondary(isDarkMode),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No courses available',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary(isDarkMode),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Course data for this semester will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary(isDarkMode),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Theory Courses
              if (theoryCourses.isNotEmpty) ...[
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.menu_book,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Theory Courses',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(isDarkMode),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...theoryCourses.map((course) => CourseCard(course: course)),
                const SizedBox(height: 24),
              ],

              // Lab Courses
              if (labCourses.isNotEmpty) ...[
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.science,
                        color: AppColors.accent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Lab Courses',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(isDarkMode),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...labCourses.map((course) => CourseCard(course: course)),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSelector(
    String label,
    int value,
    List<int> items,
    void Function(int?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          DropdownButton<int>(
            value: value,
            dropdownColor: AppColors.primary,
            underline: const SizedBox(),
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            items: items.map((item) {
              final suffix = label == 'Year'
                  ? (item == 1
                        ? 'st'
                        : item == 2
                        ? 'nd'
                        : item == 3
                        ? 'rd'
                        : 'th')
                  : (item == 1 ? 'st' : 'nd');
              return DropdownMenuItem(
                value: item,
                child: Text('$item$suffix $label'),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    Color color,
    bool isDarkMode,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary(isDarkMode),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary(isDarkMode),
          ),
        ),
      ],
    );
  }
}
