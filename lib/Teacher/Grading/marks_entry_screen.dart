import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../Student Folder/data/teacher_static_data.dart';
import '../../Student Folder/models/course_model.dart';
import '../../Student Folder/models/user_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/animated_components.dart';

/// Marks Entry screen with premium dark UI
class MarksEntryScreen extends StatefulWidget {
  final TeacherCourse course;
  final String component;
  final int maxMarks;

  const MarksEntryScreen({
    super.key,
    required this.course,
    required this.component,
    required this.maxMarks,
  });

  @override
  State<MarksEntryScreen> createState() => _MarksEntryScreenState();
}

class _MarksEntryScreenState extends State<MarksEntryScreen> {
  late List<StudentUser> _students;
  final Map<String, TextEditingController> _controllers = {};
  bool _isSaving = false;
  String _selectedSection = 'A';

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  void _loadStudents() {
    if (widget.course.type == CourseType.theory) {
      _students = getStudentsForCourse(widget.course, _selectedSection);
    } else {
      _students = getStudentsForCourse(widget.course, '${_selectedSection}1');
    }
    for (var student in _students) {
      _controllers[student.roll] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.component,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.course.code,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary(isDarkMode),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surface(isDarkMode),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Section Selector & Max Marks
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface(isDarkMode),
              border: Border(
                bottom: BorderSide(color: AppColors.border(isDarkMode)),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Section:',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary(isDarkMode),
                  ),
                ),
                const SizedBox(width: 12),
                _buildSectionChip('A', isDarkMode),
                const SizedBox(width: 8),
                _buildSectionChip('B', isDarkMode),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: AppColors.primary, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Max: ${widget.maxMarks}',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Header Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated(isDarkMode),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    'Roll',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(isDarkMode),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Name',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(isDarkMode),
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    'Marks',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(isDarkMode),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Student List
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final student = _students[index];
                return _buildStudentRow(student, index, isDarkMode);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface(isDarkMode),
          border: Border(
            top: BorderSide(color: AppColors.border(isDarkMode)),
          ),
        ),
        child: SafeArea(
          child: AnimatedPressButton(
            onTap: _isSaving ? null : _saveMarks,
            backgroundColor: AppColors.primary,
            shadowColor: AppColors.primary,
            borderRadius: BorderRadius.circular(14),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isSaving)
                  const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else ...[
                  const Icon(Icons.save, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  const Text(
                    'Save Marks',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionChip(String section, bool isDarkMode) {
    final isSelected = _selectedSection == section;
    return GestureDetector(
      onTap: () {
        if (_selectedSection != section) {
          setState(() {
            _selectedSection = section;
            _controllers.clear();
            _loadStudents();
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceElevated(isDarkMode),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border(isDarkMode),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          section,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary(isDarkMode),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildStudentRow(StudentUser student, int index, bool isDarkMode) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 200 + (index * 20).clamp(0, 200)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.border(isDarkMode)),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 76,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated(isDarkMode),
                borderRadius: BorderRadius.circular(8),
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
                  color: AppColors.textPrimary(isDarkMode),
                ),
              ),
            ),
            SizedBox(
              width: 80,
              child: TextField(
                controller: _controllers[student.roll],
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  filled: true,
                  fillColor: AppColors.surfaceElevated(isDarkMode),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.border(isDarkMode)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.border(isDarkMode)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  hintText: '0',
                  hintStyle: TextStyle(color: AppColors.textMuted),
                ),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(isDarkMode),
                ),
                onChanged: (value) {
                  final marks = double.tryParse(value) ?? 0;
                  if (marks > widget.maxMarks) {
                    _controllers[student.roll]!.text = widget.maxMarks.toString();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveMarks() async {
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 1000));

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('${widget.component} marks saved for Section $_selectedSection!'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context);
    }
  }
}
