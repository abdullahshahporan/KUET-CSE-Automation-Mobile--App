import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/teacher_static_data.dart';
import '../../Student Folder/models/course_model.dart';
import '../../Student Folder/models/user_model.dart';
import '../../theme/app_colors.dart';

/// Teacher Grading screen - Course-specific
class TeacherGradingScreen extends StatefulWidget {
  final TeacherCourse? preSelectedCourse;
  
  const TeacherGradingScreen({super.key, this.preSelectedCourse});

  @override
  State<TeacherGradingScreen> createState() => _TeacherGradingScreenState();
}

class _TeacherGradingScreenState extends State<TeacherGradingScreen> {
  String? _selectedComponent;
  String _selectedSection = 'A';
  
  TeacherCourse get course => widget.preSelectedCourse!;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final color = course.type == CourseType.theory ? AppColors.primary : AppColors.accent;

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      appBar: AppBar(
        title: Text(
          '${course.code} - Grading',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface(isDarkMode),
        elevation: 0,
      ),
      body: _selectedComponent == null
          ? _buildComponentList(isDarkMode, color)
          : _buildMarksEntry(isDarkMode),
    );
  }

  Widget _buildComponentList(bool isDarkMode, Color color) {
    final components = course.type == CourseType.theory
        ? [
            {'name': 'CT-1', 'max': 20, 'icon': Icons.quiz, 'color': AppColors.primary},
            {'name': 'CT-2', 'max': 10, 'icon': Icons.quiz, 'color': AppColors.info},
            {'name': 'Spot Test', 'max': 5, 'icon': Icons.flash_on, 'color': AppColors.warning},
            {'name': 'Assignment', 'max': 5, 'icon': Icons.assignment, 'color': AppColors.success},
            {'name': 'Attendance', 'max': 10, 'icon': Icons.fact_check, 'color': AppColors.teal},
          ]
        : [
            {'name': 'Lab Task', 'max': 50, 'icon': Icons.task, 'color': AppColors.accent},
            {'name': 'Lab Report', 'max': 20, 'icon': Icons.description, 'color': AppColors.teal},
            {'name': 'Quiz', 'max': 10, 'icon': Icons.quiz, 'color': AppColors.warning},
            {'name': 'Lab Test', 'max': 30, 'icon': Icons.science, 'color': AppColors.primary},
          ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Component',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDarkMode),
            ),
          ),
          const SizedBox(height: 12),
          ...components.map((comp) => _buildComponentCard(
            comp['name'] as String,
            comp['max'] as int,
            comp['icon'] as IconData,
            comp['color'] as Color,
            isDarkMode,
          )),
        ],
      ),
    );
  }

  Widget _buildComponentCard(String name, int max, IconData icon, Color color, bool isDarkMode) {
    return GestureDetector(
      onTap: () => setState(() => _selectedComponent = name),
      child: Container(
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
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(isDarkMode),
                    ),
                  ),
                  Text(
                    'Maximum: $max marks',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary(isDarkMode),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildMarksEntry(bool isDarkMode) {
    final students = getStudentsForCourse(course, 
        course.type == CourseType.theory ? _selectedSection : '${_selectedSection}1');
    final componentInfo = _getComponentInfo();

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface(isDarkMode),
            border: Border(bottom: BorderSide(color: AppColors.border(isDarkMode))),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedComponent = null),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedComponent!,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(isDarkMode),
                      ),
                    ),
                    Text(
                      'Max: ${componentInfo['max']} marks',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary(isDarkMode),
                      ),
                    ),
                  ],
                ),
              ),
              // Section selector
              ...['A', 'B'].map((s) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedSection = s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _selectedSection == s 
                          ? AppColors.primary 
                          : AppColors.surfaceElevated(isDarkMode),
                      borderRadius: BorderRadius.circular(8),
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
              )),
            ],
          ),
        ),
        
        // Student list
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              return _buildStudentRow(student, componentInfo['max'] as int, isDarkMode);
            },
          ),
        ),
        
        // Save button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface(isDarkMode),
            border: Border(top: BorderSide(color: AppColors.border(isDarkMode))),
          ),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveMarks,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Marks',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentRow(StudentUser student, int maxMarks, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface(isDarkMode),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border(isDarkMode)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated(isDarkMode),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              student.roll.substring(student.roll.length - 3),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.textPrimary(isDarkMode),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              student.name,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary(isDarkMode),
              ),
            ),
          ),
          SizedBox(
            width: 70,
            child: TextField(
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                filled: true,
                fillColor: AppColors.surfaceElevated(isDarkMode),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border(isDarkMode)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border(isDarkMode)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                hintText: '0',
                hintStyle: TextStyle(color: AppColors.textMuted),
              ),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(isDarkMode),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getComponentInfo() {
    final components = {
      'CT-1': {'max': 20},
      'CT-2': {'max': 10},
      'Spot Test': {'max': 5},
      'Assignment': {'max': 5},
      'Attendance': {'max': 10},
      'Lab Task': {'max': 50},
      'Lab Report': {'max': 20},
      'Quiz': {'max': 10},
      'Lab Test': {'max': 30},
    };
    return components[_selectedComponent] ?? {'max': 0};
  }

  void _saveMarks() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$_selectedComponent marks saved for Section $_selectedSection!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    setState(() => _selectedComponent = null);
  }
}
