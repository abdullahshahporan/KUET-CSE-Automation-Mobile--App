import 'package:flutter/material.dart';
import '../models/course_model.dart';
import 'course_info_service.dart';
import 'widgets/course_card.dart';
import '../../theme/app_colors.dart';

/// Main Course Info screen displaying semester-wise courses fetched from Supabase
class CourseInfoScreen extends StatefulWidget {
  const CourseInfoScreen({super.key});

  @override
  State<CourseInfoScreen> createState() => _CourseInfoScreenState();
}

class _CourseInfoScreenState extends State<CourseInfoScreen> {
  int _selectedYear = 1;
  int _selectedTerm = 1;

  List<Course> _courses = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final courses = await CourseInfoService.fetchCourses(
        year: _selectedYear,
        term: _selectedTerm,
      );
      if (mounted) {
        setState(() {
          _courses = courses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to load courses. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theoryCourses =
        _courses.where((c) => c.type == CourseType.theory).toList();
    final labCourses =
        _courses.where((c) => c.type == CourseType.lab).toList();
    final totalCredits = _courses.fold(0.0, (sum, c) => sum + c.credits);

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      appBar: AppBar(
        title: Text(
          'Course Info',
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
      body: RefreshIndicator(
        onRefresh: _fetchCourses,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                          Icons.info_outline_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Course Info',
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
                            (value) {
                              setState(() => _selectedYear = value!);
                              _fetchCourses();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSelector(
                            'Term',
                            _selectedTerm,
                            [1, 2],
                            (value) {
                              setState(() => _selectedTerm = value!);
                              _fetchCourses();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Loading state
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 16),
                        Text(
                          'Loading courses...',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),

              // Error state
              if (_errorMessage != null && !_isLoading)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.cloud_off_rounded,
                          size: 64,
                          color: AppColors.textSecondary(isDarkMode),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary(isDarkMode),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _fetchCourses,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Summary stats
              if (!_isLoading && _errorMessage == null && _courses.isNotEmpty)
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
                          totalCredits.truncateToDouble() == totalCredits
                              ? 0
                              : 2,
                        ),
                        'Credits',
                        AppColors.warning,
                        isDarkMode,
                      ),
                    ],
                  ),
                ),
              if (!_isLoading && _errorMessage == null && _courses.isNotEmpty)
                const SizedBox(height: 24),

              // Courses list
              if (!_isLoading &&
                  _errorMessage == null &&
                  _courses.isEmpty) ...[
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
              ],

              if (!_isLoading &&
                  _errorMessage == null &&
                  _courses.isNotEmpty) ...[
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
