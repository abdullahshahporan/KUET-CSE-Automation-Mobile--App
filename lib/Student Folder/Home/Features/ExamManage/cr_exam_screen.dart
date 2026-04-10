import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../services/session_service.dart';
import '../../../../theme/app_colors.dart';
import '../../../providers/app_providers.dart';
import '../../../services/cr_exam_service.dart';
import '../Schedule/exam_schedule/exam_schedule_providers.dart';

/// CR-only screen to Add / Edit / Delete exam entries.
/// Only accessible when [_isCR] is true (verified on open and on every action).
class CRExamScreen extends ConsumerStatefulWidget {
  const CRExamScreen({super.key});

  @override
  ConsumerState<CRExamScreen> createState() => _CRExamScreenState();
}

class _CRExamScreenState extends ConsumerState<CRExamScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  List<Map<String, dynamic>> _offerings = [];
  List<CRExam> _exams = [];

  // ── Form state (for add / edit modal) ─────────────────────
  CRExam? _editingExam;
  Map<String, dynamic>? _selectedOffering; // used when editing
  // Two-step course → teacher selection (for new exams)
  String? _selectedCourseCode;
  String? _selectedExamType;
  String? _selectedTeacherUserId;
  String? _selectedTeacherName;
  final _marksCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _syllabusCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _marksCtrl.dispose();
    _dateCtrl.dispose();
    _syllabusCtrl.dispose();
    super.dispose();
  }

  // ── Data loading ───────────────────────────────────────────

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        CRExamService.fetchMyOfferings(),
        CRExamService.fetchMyExams(),
      ]);
      if (mounted) {
        setState(() {
          _offerings = results[0] as List<Map<String, dynamic>>;
          _exams = results[1] as List<CRExam>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ── Helpers ────────────────────────────────────────────────

  String _typeLabel(String type) {
    switch (type.toUpperCase()) {
      case 'CT':
      case 'CLASS_TEST':
        return 'Class Test (CT)';
      case 'TERM_FINAL':
      case 'FINAL':
        return 'Term Final';
      case 'QUIZ_VIVA':
      case 'QUIZ':
      case 'VIVA':
        return 'Quiz / Viva';
      default:
        return type;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'CT':
        return const Color(0xFFF97316);
      case 'TERM_FINAL':
        return const Color(0xFFDC2626);
      case 'MID':
        return const Color(0xFF2563EB);
      case 'QUIZ_VIVA':
        return const Color(0xFF9333EA);
      default:
        return AppColors.primary;
    }
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return 'TBA';
    try {
      return DateFormat('d MMM yyyy').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  String _formatTime(String? t) {
    if (t == null || t.isEmpty) return 'TBA';
    try {
      final parts = t.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final period = h < 12 ? 'AM' : 'PM';
      final hDisplay = h == 0 ? 12 : (h > 12 ? h - 12 : h);
      return '${hDisplay.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $period';
    } catch (_) {
      return t;
    }
  }

  // ── Modal form ─────────────────────────────────────────────

  void _openForm({CRExam? exam}) {
    _editingExam = exam;
    if (exam != null) {
      final off = _offerings.firstWhere(
        (o) => o['id']?.toString() == exam.offeringId,
        orElse: () => {},
      );
      _selectedOffering = off.isNotEmpty ? off : null;
      _selectedCourseCode =
          (off['courses'] as Map<String, dynamic>?)?['code'] as String?;
      _selectedTeacherUserId = off['teacher_user_id']?.toString();
      _selectedTeacherName = exam.teacherName;
      _selectedExamType = exam.examType;
      _marksCtrl.text =
          exam.maxMarks > 0 ? exam.maxMarks.toStringAsFixed(0) : '';
      _dateCtrl.text = exam.examDate ?? '';
      _syllabusCtrl.text = exam.syllabus ?? '';
    } else {
      _selectedOffering = null;
      _selectedCourseCode = null;
      _selectedExamType = null;
      _selectedTeacherUserId = null;
      _selectedTeacherName = null;
      _marksCtrl.clear();
      _dateCtrl.clear();
      _syllabusCtrl.clear();
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildFormSheet(),
    );
  }

  Widget _buildFormSheet() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bg = isDarkMode ? const Color(0xFF1A1A2E) : Colors.white;

    return StatefulBuilder(
      builder: (ctx, setModalState) {
        return DraggableScrollableSheet(
          initialChildSize: 0.92,
          minChildSize: 0.5,
          maxChildSize: 0.97,
          expand: false,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary, AppColors.info],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.edit_calendar_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _editingExam == null ? 'Add Exam' : 'Edit Exam',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 16),
                  Expanded(
                    child: ListView(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                      children: [
                        // Course picker
                        _sectionLabel('Course', isDarkMode),
                        _buildCourseDropdown(isDarkMode, setModalState),
                        const SizedBox(height: 16),

                        // Exam type chips
                        _sectionLabel('Exam Type *', isDarkMode),
                        _buildExamTypeSelector(setModalState, isDarkMode),
                        const SizedBox(height: 16),

                        // Teacher (CT and Term Final only)
                        if (_selectedExamType == 'CT' ||
                            _selectedExamType == 'TERM_FINAL') ...([
                          _sectionLabel('Course Teacher', isDarkMode),
                          _buildTeacherDropdown(isDarkMode, setModalState),
                          const SizedBox(height: 16),
                        ]),

                        // Max marks
                        _sectionLabel('Max Marks *', isDarkMode),
                        _buildTextField(
                          controller: _marksCtrl,
                          hint: '30',
                          keyboardType: TextInputType.number,
                          isDarkMode: isDarkMode,
                        ),
                        const SizedBox(height: 16),

                        // Date
                        _sectionLabel('Exam Date *', isDarkMode),
                        _buildDateField(isDarkMode),
                        const SizedBox(height: 16),

                        // Syllabus
                        _sectionLabel('Syllabus / Topics', isDarkMode),
                        _buildTextField(
                          controller: _syllabusCtrl,
                          hint: 'Topics to be covered in this exam...',
                          maxLines: 4,
                          isDarkMode: isDarkMode,
                        ),
                        const SizedBox(height: 28),

                        // Submit button
                        _buildSubmitButton(setModalState, isDarkMode, ctx),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _sectionLabel(String text, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    required bool isDarkMode,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF252540) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black87,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
            fontSize: 14,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildDateField(bool isDarkMode) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate:
              _dateCtrl.text.isNotEmpty
                  ? DateTime.tryParse(_dateCtrl.text) ?? DateTime.now()
                  : DateTime.now().add(const Duration(days: 3)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) {
          _dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
        }
      },
      child: AbsorbPointer(
        child: _buildTextField(
          controller: _dateCtrl,
          hint: 'Tap to select date',
          isDarkMode: isDarkMode,
        ),
      ),
    );
  }

  // ── Helpers: unique courses and teachers from offerings ────

  List<Map<String, dynamic>> _uniqueCourses() {
    final seen = <String>{};
    final result = <Map<String, dynamic>>[];
    for (final o in _offerings) {
      final course = o['courses'] as Map<String, dynamic>? ?? {};
      final code = (course['code'] as String?) ?? '';
      if (code.isNotEmpty && seen.add(code)) result.add(course);
    }
    return result;
  }

  List<Map<String, dynamic>> _getTeachersForCourse(String courseCode) {
    final seen = <String>{};
    final result = <Map<String, dynamic>>[];
    for (final o in _offerings) {
      final code =
          (o['courses'] as Map<String, dynamic>?)?['code'] as String? ?? '';
      if (code != courseCode) continue;
      final tid = o['teacher_user_id']?.toString() ?? '';
      if (tid.isEmpty || !seen.add(tid)) continue;
      final t = o['teachers'] as Map<String, dynamic>? ?? {};
      result.add({
        'teacher_user_id': tid,
        'full_name': t['full_name'] as String? ?? 'TBA',
        'short_name': '',
      });
    }
    return result;
  }

  /// Resolves the best-matching offering from course + (optional) teacher
  /// selections.  Returns null if no course selected yet.
  Map<String, dynamic>? _resolvedOffering() {
    if (_selectedCourseCode == null) return null;
    final needsTeacher = _selectedExamType == 'CT' || _selectedExamType == 'TERM_FINAL';
    for (final o in _offerings) {
      final code =
          (o['courses'] as Map<String, dynamic>?)?['code'] as String? ?? '';
      if (code != _selectedCourseCode) continue;
      if (needsTeacher) {
        if (_selectedTeacherUserId != null &&
            o['teacher_user_id']?.toString() == _selectedTeacherUserId) {
          return o;
        }
      } else {
        return o; // first offering for the course suffices
      }
    }
    return null;
  }

  // ── Exam type selector ─────────────────────────────────────

  static const _examTypes = [
    ('CT', 'Class Test'),
    ('TERM_FINAL', 'Term Final'),
    ('QUIZ_VIVA', 'Quiz / Viva'),
  ];

  Widget _buildExamTypeSelector(StateSetter setModalState, bool isDarkMode) {
    return Row(
      children: _examTypes.map(((String, String) e) {
        final value = e.$1;
        final label = e.$2;
        final selected = _selectedExamType == value;
        return Expanded(
          child: GestureDetector(
            onTap: () => setModalState(() {
              _selectedExamType = value;
              // Clear teacher when switching to sessional type
              if (value == 'QUIZ_VIVA') {
                _selectedTeacherUserId = null;
                _selectedTeacherName = null;
              }
            }),
            child: Container(
              margin: EdgeInsets.only(
                right: value != 'QUIZ_VIVA' ? 8 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary
                    : (isDarkMode ? const Color(0xFF252540) : Colors.grey[50]),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected
                      ? AppColors.primary
                      : (isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
                ),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? Colors.white
                      : (isDarkMode ? Colors.grey[300] : Colors.grey[700]),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Course picker (step 1) — tap to show dialog ────────────

  Widget _buildCourseDropdown(bool isDarkMode, StateSetter setModalState) {
    final courses = _uniqueCourses();
    final selectedTitle = courses
        .where((c) => c['code'] == _selectedCourseCode)
        .map((c) => '${c['code']} — ${c['title']}')
        .firstOrNull;

    return GestureDetector(
      onTap: () async {
        if (courses.isEmpty) return;
        final picked = await showDialog<String>(
          context: context,
          builder: (ctx) {
            final dlgDark = Theme.of(ctx).brightness == Brightness.dark;
            return AlertDialog(
              backgroundColor: dlgDark ? const Color(0xFF1A1A2E) : Colors.white,
              title: Text(
                'Select Course',
                style: TextStyle(
                  color: dlgDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: courses.map((c) {
                    final code = c['code'] as String? ?? '';
                    final title = c['title'] as String? ?? '';
                    final selected = code == _selectedCourseCode;
                    return ListTile(
                      title: Text(
                        code,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: selected
                              ? AppColors.primary
                              : (dlgDark ? Colors.white : Colors.black87),
                        ),
                      ),
                      subtitle: Text(
                        title,
                        style: TextStyle(
                          fontSize: 12,
                          color: dlgDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      trailing: selected
                          ? Icon(Icons.check_circle_rounded,
                              color: AppColors.primary)
                          : null,
                      onTap: () => Navigator.pop(ctx, code),
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
        if (picked != null) {
          setModalState(() {
            _selectedCourseCode = picked;
            _selectedTeacherUserId = null;
            _selectedTeacherName = null;
            // Auto-select teacher when only one option
            final teachers = _getTeachersForCourse(picked);
            if (teachers.length == 1) {
              _selectedTeacherUserId =
                  teachers.first['teacher_user_id'] as String?;
              _selectedTeacherName = teachers.first['full_name'] as String?;
            }
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF252540) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selectedTitle ?? 'Select course',
                style: TextStyle(
                  fontSize: 15,
                  color: selectedTitle != null
                      ? (isDarkMode ? Colors.white : Colors.black87)
                      : (isDarkMode ? Colors.grey[500] : Colors.grey[400]),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.arrow_drop_down_rounded,
              color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  // ── Teacher picker (step 2, CT only) ──────────────────────

  Widget _buildTeacherDropdown(bool isDarkMode, StateSetter setModalState) {
    final teachers = _selectedCourseCode != null
        ? _getTeachersForCourse(_selectedCourseCode!)
        : <Map<String, dynamic>>[];

    if (teachers.isEmpty) {
      return Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF252540) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        child: Text(
          'No teacher assigned to this course',
          style: TextStyle(
            color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
            fontSize: 14,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF252540) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(
            'Select teacher',
            style: TextStyle(
              color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
              fontSize: 14,
            ),
          ),
          value: _selectedTeacherUserId,
          dropdownColor: isDarkMode ? const Color(0xFF252540) : Colors.white,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontSize: 15,
          ),
          items: teachers.map((t) {
            final id = t['teacher_user_id'] as String;
            final name = t['full_name'] as String;
            return DropdownMenuItem<String>(
              value: id,
              child: Text(name, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (val) {
            setModalState(() {
              _selectedTeacherUserId = val;
              _selectedTeacherName = teachers
                  .firstWhere(
                    (t) => t['teacher_user_id'] == val,
                    orElse: () => {'full_name': ''},
                  )['full_name'] as String?;
            });
          },
        ),
      ),
    );
  }

  Widget _buildSubmitButton(
      StateSetter setModalState, bool isDarkMode, BuildContext ctx) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed:
            _isSubmitting ? null : () => _submitForm(setModalState, ctx),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                _editingExam == null ? 'Create Exam & Notify' : 'Save Changes',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  /// Shows a dialog on top of the modal so the user can always see errors.
  Future<void> _showModalError(BuildContext ctx, String message) {
    return showDialog<void>(
      context: ctx,
      builder: (dctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm(
      StateSetter setModalState, BuildContext ctx) async {
    final isEditing = _editingExam != null;

    // Resolve the offering (editing keeps _selectedOffering; new uses 2-step)
    final offering =
        isEditing ? (_selectedOffering ?? {}) : (_resolvedOffering() ?? {});

    if (offering.isEmpty) {
      await _showModalError(ctx, 'Please select a course first.');
      return;
    }

    // Exam type required
    if (_selectedExamType == null) {
      await _showModalError(ctx, 'Please select an exam type.');
      return;
    }

    // Require teacher selection for CT / Term Final
    if (!isEditing &&
        (_selectedExamType == 'CT' || _selectedExamType == 'TERM_FINAL') &&
        _selectedTeacherUserId == null) {
      await _showModalError(ctx, 'Please select the course teacher.');
      return;
    }

    if (_dateCtrl.text.isEmpty) {
      await _showModalError(ctx, 'Please select an exam date.');
      return;
    }
    if (_marksCtrl.text.isEmpty) {
      await _showModalError(ctx, 'Please enter max marks.');
      return;
    }

    final course = offering['courses'] as Map<String, dynamic>? ?? {};
    final teacherMap = offering['teachers'] as Map<String, dynamic>? ?? {};

    // Get current user id
    final userId = SessionService.currentUserId;

    setModalState(() => _isSubmitting = true);

    late ({bool success, String message}) result;

    final courseCode = course['code'] as String? ?? '';
    final examType = _selectedExamType!;
    final autoName = '${_typeLabel(examType)} — $courseCode';

    if (_editingExam == null) {
      result = await CRExamService.createExam(
        offeringId: offering['id'].toString(),
        teacherUserId: offering['teacher_user_id']?.toString() ?? '',
        courseCode: courseCode,
        courseName: course['title'] as String? ?? '',
        teacherName: teacherMap['full_name'] as String? ?? '',
        examType: examType,
        name: autoName,
        maxMarks: double.tryParse(_marksCtrl.text.trim()) ?? 0,
        examDate: _dateCtrl.text.trim(),
        syllabus: _syllabusCtrl.text.trim(),
      );
    } else {
      result = await CRExamService.updateExam(
        examId: _editingExam!.id,
        originalCreatorId: userId ?? '',
        maxMarks: double.tryParse(_marksCtrl.text.trim()),
        examDate: _dateCtrl.text.trim(),
        syllabus: _syllabusCtrl.text.trim(),
      );
    }

    setModalState(() => _isSubmitting = false);

    if (result.success) {
      if (ctx.mounted) Navigator.pop(ctx);
      _showSnack(result.message, isError: false);
      _loadData();
      // Refresh exam schedule and notices screens for all users
      ref.invalidate(examScheduleProvider);
      ref.invalidate(noticesProvider);
    } else {
      if (ctx.mounted) await _showModalError(ctx, result.message);
    }
  }

  Future<void> _confirmDelete(CRExam exam) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Exam?'),
        content: Text(
          'Delete "${_typeLabel(exam.examType)} — ${exam.courseCode}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final userId = SessionService.currentUserId ?? '';
    final result = await CRExamService.deleteExam(
      examId: exam.id,
      originalCreatorId: userId,
    );
    _showSnack(result.message, isError: !result.success);
    if (result.success) _loadData();
  }

  void _showSnack(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F0F1A) : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Manage Exams'),
        backgroundColor: isDarkMode ? const Color(0xFF1A1A2E) : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Exam'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(isDarkMode),
    );
  }

  Widget _buildBody(bool isDarkMode) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 64,
                color: isDarkMode ? Colors.grey[600] : Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Failed to load exams',
                style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600])),
            const SizedBox(height: 12),
            ElevatedButton(
                onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_exams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.event_note_rounded,
                  size: 56, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            const Text('No exams scheduled yet',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add a CT or exam',
              style: TextStyle(
                  color: isDarkMode ? Colors.grey[500] : Colors.grey[500]),
            ),
            const SizedBox(height: 80),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _exams.length,
        itemBuilder: (_, i) => _buildExamCard(_exams[i], isDarkMode),
      ),
    );
  }

  Widget _buildExamCard(CRExam exam, bool isDarkMode) {
    final color = _typeColor(exam.examType);
    final canEdit = true; // CR can edit all their term exams; server validates creator

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.35), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header strip
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.12), color.withOpacity(0.04)],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.75)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _typeLabel(exam.examType),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Text(
                    exam.courseCode,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                const Spacer(),
                if (canEdit) ...[
                  IconButton(
                    icon: Icon(Icons.edit_rounded,
                        size: 18, color: Colors.blue[400]),
                    onPressed: () => _openForm(exam: exam),
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 18, color: Colors.red),
                    onPressed: () => _confirmDelete(exam),
                    tooltip: 'Delete',
                  ),
                ],
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exam.courseName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                if (exam.teacherName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    exam.teacherName,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _chip(Icons.calendar_today_rounded,
                        _formatDate(exam.examDate), isDarkMode, color),
                    _chip(Icons.access_time_rounded,
                        _formatTime(exam.examTime), isDarkMode, color),
                    if (exam.roomNumbers.isNotEmpty)
                      _chip(Icons.location_on_outlined,
                          exam.roomNumbers.join(', '), isDarkMode, color),
                    if (exam.maxMarks > 0)
                      _chip(Icons.star_rounded,
                          '${exam.maxMarks.toStringAsFixed(0)} marks',
                          isDarkMode, color),
                  ],
                ),
                if (exam.syllabus?.isNotEmpty == true) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: color.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Syllabus',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          exam.syllabus!,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDarkMode
                                ? Colors.grey[300]
                                : Colors.grey[700],
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, bool isDarkMode, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
      ],
    );
  }
}
