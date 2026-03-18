import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/geo_attendance_service.dart';
import '../../services/notification_service.dart';
import '../../services/supabase_service.dart';
import '../../Student Folder/models/course_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/course_utils.dart';

import '../models/teacher_course.dart';

/// Teacher screen to open/close geo-attendance rooms.
class GeoAttendanceRoomScreen extends StatefulWidget {
  final TeacherCourse? preSelectedCourse;
  final List<TeacherCourse>? courses;
  final String? teacherUserId;

  const GeoAttendanceRoomScreen({
    super.key,
    this.preSelectedCourse,
    this.courses,
    this.teacherUserId,
  });

  @override
  State<GeoAttendanceRoomScreen> createState() =>
      _GeoAttendanceRoomScreenState();
}

class _GeoAttendanceRoomScreenState extends State<GeoAttendanceRoomScreen> {
  TeacherCourse? _selectedCourse;
  String? _selectedSection;
  int _durationMinutes = 50;
  String _roomNumber = '';
  bool _isOpening = false;
  bool _isLoading = true;

  List<TeacherCourse> _courses = [];
  String _teacherUserId = '';
  List<Map<String, dynamic>> _activeRooms = [];
  List<Map<String, dynamic>> _recentRooms = [];
  Timer? _autoRefreshTimer;

  /// Whether the screen was opened from a specific course
  bool get _isCourseScoped => widget.preSelectedCourse != null;

  List<String> get _availableSections {
    final course = _selectedCourse;
    if (course == null) return [];
    return course.type == CourseType.theory ? course.sections : course.groups;
  }

  @override
  void initState() {
    super.initState();
    _selectedCourse = widget.preSelectedCourse;
    _initData();
    // Auto-refresh every 15 seconds so expired rooms move to recent
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _loadRooms(),
    );
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initData() async {
    // Use provided data or load from Supabase
    _teacherUserId =
        widget.teacherUserId ?? SupabaseService.currentUserId ?? '';

    if (widget.courses != null && widget.courses!.isNotEmpty) {
      _courses = widget.courses!;
    } else {
      await _loadCourses();
    }

    await _loadRooms();
  }

  Future<void> _loadCourses() async {
    try {
      final offerings = await SupabaseService.getTeacherAssignedCourses();
      _courses = offerings.map((offering) {
        final course = offering['courses'] as Map<String, dynamic>? ?? {};
        final courseCode = course['code'] as String? ?? '';
        final year = CourseUtils.yearFromCode(courseCode);
        final termNum = CourseUtils.termFromCode(courseCode);
        final typeStr = (course['course_type'] as String? ?? 'Theory')
            .toLowerCase();
        final courseType = typeStr == 'lab'
            ? CourseType.lab
            : CourseType.theory;
        final credit = (course['credit'] as num?)?.toDouble() ?? 3.0;
        return TeacherCourse(
          code: courseCode,
          title: course['title'] as String? ?? '',
          credits: credit,
          type: courseType,
          year: year,
          term: termNum,
          expectedClasses: courseType == CourseType.lab
              ? (credit * 6.67).round()
              : (credit * 6).round(),
          sections: courseType == CourseType.theory ? ['A', 'B'] : [],
          groups: courseType == CourseType.lab ? ['A1', 'A2', 'B1', 'B2'] : [],
          teachers: [],
          offeringId: offering['id'] as String?,
          session: offering['session'] as String?,
        );
      }).toList();
    } catch (_) {}
  }

  Future<void> _loadRooms() async {
    setState(() => _isLoading = true);
    try {
      final active = await GeoAttendanceService.getActiveRooms(
        teacherUserId: _teacherUserId,
      );
      final recent = await GeoAttendanceService.getRecentRooms(
        teacherUserId: _teacherUserId,
      );
      if (mounted) {
        setState(() {
          _activeRooms = active;
          _recentRooms = recent;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openRoom() async {
    if (_selectedCourse == null || _selectedCourse!.offeringId == null) return;

    setState(() => _isOpening = true);
    try {
      final now = DateTime.now();
      final endTime = now.add(Duration(minutes: _durationMinutes));

      final roomData = await GeoAttendanceService.openRoom(
        offeringId: _selectedCourse!.offeringId!,
        teacherUserId: _teacherUserId,
        startTime: now,
        endTime: endTime,
        roomNumber: _roomNumber.isNotEmpty ? _roomNumber : null,
        section: _selectedSection,
      );

      if (mounted) {
        // Capture values before state reset
        final courseCode = _selectedCourse!.code;
        final term = _selectedCourse!.shortSemester; // e.g., "3-2"
        final section = _selectedSection;
        final roomNo = _roomNumber;
        final durationMin = _durationMinutes;
        final sectionLabel = section != null ? ' ($section)' : '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Room opened for $courseCode$sectionLabel! Students within 200m can submit attendance.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        await NotificationService.notifyGeoAttendanceOpened(
          courseCode: courseCode,
          term: term,
          section: section,
          roomNumber: roomNo.isNotEmpty ? roomNo : null,
          durationMinutes: durationMin,
          endTime: endTime,
          roomId: roomData['id']?.toString(),
        );
        if (!_isCourseScoped) _selectedCourse = null;
        _selectedSection = null;
        _roomNumber = '';
        await _loadRooms();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open room: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isOpening = false);
    }
  }

  Future<void> _closeRoom(String roomId) async {
    try {
      await GeoAttendanceService.closeRoom(roomId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Room closed successfully'),
            backgroundColor: Colors.orange,
          ),
        );
        await _loadRooms();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to close room: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _showAttendanceLogs(
    String roomId,
    String courseCode,
    bool isDarkMode,
  ) async {
    final logs = await GeoAttendanceService.getRoomAttendanceLogs(roomId);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface(isDarkMode),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          maxChildSize: 0.85,
          minChildSize: 0.3,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border(isDarkMode),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$courseCode — Attendance Logs',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(isDarkMode),
                    ),
                  ),
                  Text(
                    '${logs.length} student(s) submitted',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary(isDarkMode),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: logs.isEmpty
                        ? Center(
                            child: Text(
                              'No submissions yet',
                              style: TextStyle(
                                color: AppColors.textSecondary(isDarkMode),
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: logs.length,
                            itemBuilder: (context, index) {
                              final log = logs[index];
                              final student =
                                  log['students'] as Map<String, dynamic>?;
                              final rollNo = student?['roll_no'] ?? 'Unknown';
                              final name = student?['full_name'] ?? 'Unknown';
                              final dist = log['distance_meters'] as num? ?? 0;
                              final time = DateTime.tryParse(
                                log['submitted_at'] as String? ?? '',
                              );

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevated(isDarkMode),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.border(isDarkMode),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: AppColors.success
                                          .withOpacity(0.15),
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: AppColors.success,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '$rollNo — $name',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary(
                                                isDarkMode,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '${dist}m from building • ${time != null ? _formatTime(time) : ""}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary(
                                                isDarkMode,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.success.withOpacity(
                                          0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Present',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
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

  String _timeRemaining(String endTimeStr) {
    final end = DateTime.tryParse(endTimeStr);
    if (end == null) return '';
    final endLocal = end.toLocal();
    final diff = endLocal.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    if (diff.inHours > 0) {
      return '${diff.inHours}h ${diff.inMinutes % 60}m left';
    }
    return '${diff.inMinutes}m left';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min $amPm';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      appBar: AppBar(
        title: Text(
          _isCourseScoped
              ? '${widget.preSelectedCourse!.code} — Geo-Attendance'
              : 'Geo-Attendance',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface(isDarkMode),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRooms,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRooms,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info banner
                    _buildInfoBanner(isDarkMode),
                    const SizedBox(height: 20),

                    // Active rooms
                    if (_activeRooms.isNotEmpty) ...[
                      _buildSectionTitle(
                        'Active Rooms',
                        Icons.radio_button_on,
                        AppColors.success,
                        isDarkMode,
                      ),
                      const SizedBox(height: 10),
                      ..._activeRooms.map(
                        (room) => _buildActiveRoomCard(room, isDarkMode),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Open room form
                    _buildSectionTitle(
                      'Open New Room',
                      Icons.add_circle,
                      AppColors.primary,
                      isDarkMode,
                    ),
                    const SizedBox(height: 10),
                    _buildOpenRoomForm(isDarkMode),
                    const SizedBox(height: 24),

                    // Recent sessions
                    if (_recentRooms.isNotEmpty) ...[
                      _buildSectionTitle(
                        'Recent Sessions',
                        Icons.history,
                        AppColors.textMuted,
                        isDarkMode,
                      ),
                      const SizedBox(height: 10),
                      ..._recentRooms.map(
                        (room) => _buildRecentRoomCard(room, isDarkMode),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoBanner(bool isDarkMode) {
    // Calculate room limits
    final courseType = _selectedCourse?.type;
    final maxRooms = courseType == CourseType.lab
        ? GeoAttendanceService.maxLabRooms
        : GeoAttendanceService.maxTheoryRooms;
    final activeCount = _activeRooms.length;
    final canOpen = activeCount < maxRooms;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.info.withOpacity(0.15),
            AppColors.primary.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: AppColors.info, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Proximity-Based Attendance',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(isDarkMode),
                      ),
                    ),
                    Text(
                      'Students must be within 200m of CSE Building to submit',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary(isDarkMode),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: canOpen
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.danger.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  canOpen ? Icons.check_circle : Icons.warning_amber,
                  size: 16,
                  color: canOpen ? AppColors.success : AppColors.danger,
                ),
                const SizedBox(width: 6),
                Text(
                  '$activeCount/$maxRooms rooms active'
                  '${courseType != null ? " (${courseType == CourseType.lab ? "Lab" : "Theory"})" : ""}'
                  '${!canOpen ? " — Close a room first" : ""}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: canOpen ? AppColors.success : AppColors.danger,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    String title,
    IconData icon,
    Color color,
    bool isDarkMode,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary(isDarkMode),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveRoomCard(Map<String, dynamic> room, bool isDarkMode) {
    final offering = room['course_offerings'] as Map<String, dynamic>?;
    final course = offering?['courses'] as Map<String, dynamic>?;
    final code = course?['code'] ?? 'Course';
    final title = course?['title'] ?? '';
    final roomNum = room['room_number'] as String? ?? '';
    final roomSection = room['section'] as String? ?? '';
    final endTime = room['end_time'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.success.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.door_front_door,
                  color: AppColors.success,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$code — $title${roomSection.isNotEmpty ? ' ($roomSection)' : ''}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(isDarkMode),
                      ),
                    ),
                    Row(
                      children: [
                        if (roomNum.isNotEmpty) ...[
                          Icon(
                            Icons.room,
                            size: 13,
                            color: AppColors.textSecondary(isDarkMode),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            roomNum,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary(isDarkMode),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _timeRemaining(endTime),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.people, size: 18),
                  label: const Text('View Logs'),
                  onPressed: () => _showAttendanceLogs(
                    room['id'] as String,
                    code,
                    isDarkMode,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final isExpired = _timeRemaining(endTime) == 'Expired';
                    return ElevatedButton.icon(
                      icon: Icon(
                        isExpired ? Icons.lock : Icons.close,
                        size: 18,
                      ),
                      label: Text(isExpired ? 'Expired' : 'Close Room'),
                      onPressed: isExpired
                          ? null
                          : () => _closeRoom(room['id'] as String),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isExpired
                            ? Colors.grey
                            : AppColors.danger,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade400,
                        disabledForegroundColor: Colors.white70,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOpenRoomForm(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(isDarkMode),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(isDarkMode)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course dropdown (hidden when course is pre-selected)
          if (!_isCourseScoped) ...[
            Text(
              'Course',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary(isDarkMode),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.background(isDarkMode),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border(isDarkMode)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedCourse?.offeringId,
                  hint: Text(
                    'Select a course',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                  ),
                  items: _courses
                      .where((c) => c.offeringId != null)
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.offeringId,
                          child: Text(
                            '${c.code} — ${c.title}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedCourse = _courses.firstWhere(
                        (c) => c.offeringId == val,
                        orElse: () => _courses.first,
                      );
                      _selectedSection = null;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Section selector
          if (_availableSections.isNotEmpty) ...[
            Text(
              _selectedCourse?.type == CourseType.theory
                  ? 'Select Section'
                  : 'Select Group',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary(isDarkMode),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: _availableSections.map((section) {
                final isSelected = _selectedSection == section;
                return ChoiceChip(
                  label: Text(
                    _selectedCourse?.type == CourseType.theory
                        ? 'Section $section'
                        : 'Group $section',
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedSection = selected ? section : null;
                    });
                  },
                  selectedColor: const Color(0xFF0D9488).withOpacity(0.2),
                  labelStyle: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF0D9488)
                        : AppColors.textPrimary(isDarkMode),
                  ),
                  checkmarkColor: const Color(0xFF0D9488),
                  backgroundColor: AppColors.background(isDarkMode),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF0D9488)
                        : AppColors.border(isDarkMode),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
          ],

          // Room number + Duration
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Room (optional)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary(isDarkMode),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      onChanged: (v) => _roomNumber = v,
                      decoration: InputDecoration(
                        hintText: 'e.g. 301',
                        hintStyle: TextStyle(color: AppColors.textMuted),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: AppColors.border(isDarkMode),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: AppColors.border(isDarkMode),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Duration',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary(isDarkMode),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border(isDarkMode)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: _durationMinutes,
                          items: const [
                            DropdownMenuItem(value: 30, child: Text('30 min')),
                            DropdownMenuItem(
                              value: 50,
                              child: Text('50 min (1 period)'),
                            ),
                            DropdownMenuItem(value: 80, child: Text('80 min')),
                            DropdownMenuItem(
                              value: 100,
                              child: Text('100 min (2 periods)'),
                            ),
                            DropdownMenuItem(
                              value: 150,
                              child: Text('150 min (3 periods)'),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _durationMinutes = v);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Open button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: _isOpening
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.radio_button_checked, size: 20),
              label: Text(
                _isOpening ? 'Opening...' : 'Open Room',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              onPressed: (_selectedCourse == null || _isOpening)
                  ? null
                  : _openRoom,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.grey.shade400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRoomCard(Map<String, dynamic> room, bool isDarkMode) {
    final offering = room['course_offerings'] as Map<String, dynamic>?;
    final course = offering?['courses'] as Map<String, dynamic>?;
    final code = course?['code'] ?? '';
    final date = room['date'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface(isDarkMode),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(isDarkMode)),
      ),
      child: Row(
        children: [
          Icon(Icons.history, size: 20, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  code,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(isDarkMode),
                  ),
                ),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary(isDarkMode),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () =>
                _showAttendanceLogs(room['id'] as String, code, isDarkMode),
            child: Text(
              'Logs',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
