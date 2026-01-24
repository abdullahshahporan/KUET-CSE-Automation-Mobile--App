import 'package:flutter/material.dart';
import '../data/teacher_static_data.dart';
import '../../Student Folder/models/course_model.dart';
import '../../Student Folder/models/user_model.dart';
import '../../theme/app_colors.dart';
import 'student_detail_screen.dart';

/// Course-specific Students List Screen
class StudentsListScreen extends StatefulWidget {
  final TeacherCourse? course;

  const StudentsListScreen({super.key, this.course});

  @override
  State<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends State<StudentsListScreen> {
  String _selectedSection = 'A';
  String _searchQuery = '';

  TeacherCourse get course => widget.course!;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Get students for selected section/group
    final sectionOrGroup = course.type == CourseType.theory
        ? _selectedSection
        : '${_selectedSection}1';
    final allStudents = getStudentsForCourse(course, sectionOrGroup);

    // Filter by search
    final students = _searchQuery.isEmpty
        ? allStudents
        : allStudents
              .where(
                (s) =>
                    s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    s.roll.contains(_searchQuery),
              )
              .toList();

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      appBar: AppBar(
        title: Text(
          '${course.code} - Students',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface(isDarkMode),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search and Section Selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface(isDarkMode),
              border: Border(
                bottom: BorderSide(color: AppColors.border(isDarkMode)),
              ),
            ),
            child: Column(
              children: [
                // Search
                TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search by name or roll...',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                    prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surfaceElevated(isDarkMode),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: TextStyle(color: AppColors.textPrimary(isDarkMode)),
                ),
                const SizedBox(height: 12),

                // Section/Group selector
                Row(
                  children: [
                    Text(
                      course.type == CourseType.theory
                          ? 'Section:'
                          : 'Section:',
                      style: TextStyle(
                        color: AppColors.textSecondary(isDarkMode),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ...['A', 'B'].map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedSection = s),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: _selectedSection == s
                                  ? AppColors.primary
                                  : AppColors.surfaceElevated(isDarkMode),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _selectedSection == s
                                    ? AppColors.primary
                                    : AppColors.border(isDarkMode),
                              ),
                            ),
                            child: Text(
                              s,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _selectedSection == s
                                    ? Colors.white
                                    : AppColors.textSecondary(isDarkMode),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${students.length} students',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Students List
          Expanded(
            child: students.isEmpty
                ? Center(
                    child: Text(
                      'No students found',
                      style: TextStyle(
                        color: AppColors.textSecondary(isDarkMode),
                      ),
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final student = students[index];
                      return _buildStudentCard(student, isDarkMode, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(StudentUser student, bool isDarkMode, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StudentDetailScreen(student: student),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface(isDarkMode),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border(isDarkMode)),
        ),
        child: Row(
          children: [
            // Rank/Index
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Student info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(isDarkMode),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Roll: ${student.roll}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary(isDarkMode),
                    ),
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
