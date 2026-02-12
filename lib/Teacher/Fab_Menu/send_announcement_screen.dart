import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../services/teacher_course_service.dart';
import '../../services/supabase_service.dart';

/// Announcement type options
enum AnnouncementType { classTest, assignment, notice, labTest, quiz, other }

/// Send Announcement Screen - Create and send announcements to students
class SendAnnouncementScreen extends StatefulWidget {
  const SendAnnouncementScreen({super.key});

  @override
  State<SendAnnouncementScreen> createState() => _SendAnnouncementScreenState();
}

class _SendAnnouncementScreenState extends State<SendAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  String? _selectedCourse;
  AnnouncementType _selectedType = AnnouncementType.notice;
  DateTime? _scheduledDate;
  bool _isLoading = false;
  List<Map<String, dynamic>> _courses = [];
  bool _isLoadingCourses = true;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    try {
      final teacherId = SupabaseService.currentUserId;
      if (teacherId == null) return;
      final data = await SupabaseService.from('course_offerings')
          .select('id, courses(code, title)')
          .eq('teacher_user_id', teacherId)
          .eq('is_active', true);
      setState(() {
        _courses = List<Map<String, dynamic>>.from(data as List);
        _isLoadingCourses = false;
      });
    } catch (e) {
      setState(() => _isLoadingCourses = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      appBar: AppBar(
        title: const Text('New Announcement'),
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
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.campaign, color: Colors.white, size: 32),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Create Announcement',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Notify students instantly',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Course Selection
              _buildLabel('Select Course', isDarkMode),
              const SizedBox(height: 8),
              if (_isLoadingCourses)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface(isDarkMode),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border(isDarkMode)),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      const SizedBox(width: 12),
                      Text('Loading courses...', style: TextStyle(color: AppColors.textSecondary(isDarkMode))),
                    ],
                  ),
                )
              else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface(isDarkMode),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border(isDarkMode)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCourse,
                    isExpanded: true,
                    hint: Text(
                      'Choose a course',
                      style: TextStyle(
                        color: AppColors.textSecondary(isDarkMode),
                      ),
                    ),
                    dropdownColor: AppColors.surface(isDarkMode),
                    items: _courses.map((offering) {
                      final course = offering['courses'] as Map<String, dynamic>?;
                      final code = course?['code'] as String? ?? '';
                      final title = course?['title'] as String? ?? '';
                      return DropdownMenuItem(
                        value: code,
                        child: Text(
                          '$code - $title',
                          style: TextStyle(
                            color: AppColors.textPrimary(isDarkMode),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedCourse = value),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Announcement Type
              _buildLabel('Announcement Type', isDarkMode),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AnnouncementType.values.map((type) {
                  final isSelected = _selectedType == type;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedType = type),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.surface(isDarkMode),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border(isDarkMode),
                        ),
                      ),
                      child: Text(
                        _getTypeName(type),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary(isDarkMode),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Title
              _buildLabel('Title', isDarkMode),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                style: TextStyle(color: AppColors.textPrimary(isDarkMode)),
                decoration: _inputDecoration(
                  'Enter announcement title',
                  isDarkMode,
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Title is required' : null,
              ),
              const SizedBox(height: 20),

              // Content
              _buildLabel('Content', isDarkMode),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contentController,
                style: TextStyle(color: AppColors.textPrimary(isDarkMode)),
                maxLines: 5,
                decoration: _inputDecoration(
                  'Write your announcement...',
                  isDarkMode,
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Content is required' : null,
              ),
              const SizedBox(height: 20),

              // Schedule Date (Optional)
              _buildLabel('Schedule Date (Optional)', isDarkMode),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (date != null) {
                    setState(() => _scheduledDate = date);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface(isDarkMode),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border(isDarkMode)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: AppColors.textSecondary(isDarkMode),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _scheduledDate != null
                            ? '${_scheduledDate!.day}/${_scheduledDate!.month}/${_scheduledDate!.year}'
                            : 'Select a date',
                        style: TextStyle(
                          color: _scheduledDate != null
                              ? AppColors.textPrimary(isDarkMode)
                              : AppColors.textSecondary(isDarkMode),
                        ),
                      ),
                      const Spacer(),
                      if (_scheduledDate != null)
                        GestureDetector(
                          onTap: () => setState(() => _scheduledDate = null),
                          child: Icon(
                            Icons.close,
                            color: AppColors.textSecondary(isDarkMode),
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Send Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendAnnouncement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Send Announcement',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, bool isDarkMode) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary(isDarkMode),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, bool isDarkMode) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textSecondary(isDarkMode)),
      filled: true,
      fillColor: AppColors.surface(isDarkMode),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border(isDarkMode)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border(isDarkMode)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }

  String _getTypeName(AnnouncementType type) {
    switch (type) {
      case AnnouncementType.classTest:
        return 'Class Test';
      case AnnouncementType.assignment:
        return 'Assignment';
      case AnnouncementType.notice:
        return 'Notice';
      case AnnouncementType.labTest:
        return 'Lab Test';
      case AnnouncementType.quiz:
        return 'Quiz';
      case AnnouncementType.other:
        return 'Other';
    }
  }

  Future<void> _sendAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCourse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a course'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Determine priority from type
      final priority = _selectedType == AnnouncementType.classTest ||
              _selectedType == AnnouncementType.labTest
          ? 'high'
          : _selectedType == AnnouncementType.assignment ||
                  _selectedType == AnnouncementType.quiz
              ? 'medium'
              : 'normal';

      final typeName = _getTypeName(_selectedType);
      final title = '[$typeName] ${_titleController.text}';

      final success = await TeacherCourseService.saveAnnouncement(
        title: title,
        body: _contentController.text,
        targetTerm: null,
        targetSession: null,
        priority: priority,
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Announcement sent successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to send announcement'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }
}
