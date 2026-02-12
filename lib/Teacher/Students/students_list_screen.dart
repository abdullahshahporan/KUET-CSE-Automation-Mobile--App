import 'package:flutter/material.dart';
import '../data/teacher_static_data.dart';
import '../../theme/app_colors.dart';
import '../services/teacher_course_service.dart';
import '../models/enrolled_student.dart';
import '../widgets/enrolled_student_card.dart';

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
  List<EnrolledStudent> _allStudents = [];
  bool _isLoading = true;

  TeacherCourse get course => widget.course!;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);

    final offeringId = course.offeringId;
    if (offeringId == null || offeringId.isEmpty) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No offering ID available for this course')),
        );
      }
      return;
    }

    try {
      final students = await TeacherCourseService.getEnrolledStudents(
        courseCode: course.code,
        offeringId: offeringId,
      );

      if (mounted) {
        setState(() {
          _allStudents = students;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load students: $e')),
        );
      }
    }
  }

  List<EnrolledStudent> get _filteredStudents {
    var students = _allStudents;

    // Filter by section (derived from roll number)
    students = students
        .where((s) => s.derivedSection == _selectedSection)
        .toList();

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      students = students
          .where((s) =>
              s.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              s.rollNo.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return students;
  }

  Set<String> get _availableSections {
    final sections = _allStudents
        .map((s) => s.derivedSection)
        .toSet();
    return sections;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final students = _filteredStudents;

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      appBar: AppBar(
        title: Text(
          '${course.code} - Students',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface(isDarkMode),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStudents,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
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

                      // Section selector
                      if (_availableSections.isNotEmpty)
                        Row(
                          children: [
                            Text(
                              'Section:',
                              style: TextStyle(
                                color: AppColors.textSecondary(isDarkMode),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: _availableSections.map(
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
                                  ).toList(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${students.length}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                // Students List
                Expanded(
                  child: _allStudents.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No students enrolled yet',
                                style: TextStyle(
                                  color: AppColors.textSecondary(isDarkMode),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : students.isEmpty
                          ? Center(
                              child: Text(
                                'No students match your search',
                                style: TextStyle(
                                  color: AppColors.textSecondary(isDarkMode),
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadStudents,
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                padding: const EdgeInsets.all(16),
                                itemCount: students.length,
                                itemBuilder: (context, index) {
                                  final student = students[index];
                                  return EnrolledStudentCard(
                                    student: student,
                                    isDarkMode: isDarkMode,
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
    );
  }
}
