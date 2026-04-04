import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../shared/ui_helpers.dart';
import '../../../../theme/app_colors.dart';
import '../../../../Teacher/Room_info/room_booking_model.dart';
import '../../../../Teacher/Room_info/room_model.dart';
import '../../../models/cr_room_request_model.dart';
import '../../../services/cr_room_request_service.dart';

/// Screen for CR (Class Representative) to submit and track room requests.
///
/// Flow: Course → Teacher → Date → Room → Available Slots → Submit
class CRRoomRequestScreen extends StatefulWidget {
  const CRRoomRequestScreen({super.key});

  @override
  State<CRRoomRequestScreen> createState() => _CRRoomRequestScreenState();
}

class _CRRoomRequestScreenState extends State<CRRoomRequestScreen> {
  final _reasonController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isSlotsLoading = false;

  // Data
  List<Map<String, dynamic>> _allOfferings = [];
  List<Map<String, dynamic>> _uniqueCourses = [];
  List<Map<String, dynamic>> _teachersForCourse = [];
  List<String> _availableRooms = [];
  List<PeriodStatus> _periodStatuses = [];
  List<CRRoomRequest> _myRequests = [];

  // Form selections
  Map<String, dynamic>? _selectedCourse;
  Map<String, dynamic>? _selectedTeacher;
  DateTime? _selectedDate;
  String? _selectedRoom;
  String? _selectedStartTime;
  String? _selectedEndTime;

  // Student info
  String _term = '';
  String _session = '';
  String? _selectedSection;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final offerings = await CRRoomRequestService.getCoursesForTerm();
      final rooms = await CRRoomRequestService.getAvailableRooms();
      final requests = await CRRoomRequestService.getMyRequests();

      if (offerings.isNotEmpty) {
        final first = offerings.first;
        _term = first['term'] as String? ?? '';
        _session = first['session'] as String? ?? '';
      }

      // Build unique courses list
      final seen = <String>{};
      final unique = <Map<String, dynamic>>[];
      for (final o in offerings) {
        final course = o['courses'] as Map<String, dynamic>;
        final code = course['code'] as String? ?? '';
        if (seen.add(code)) {
          unique.add(course);
        }
      }

      if (mounted) {
        setState(() {
          _allOfferings = offerings;
          _uniqueCourses = unique;
          _availableRooms = rooms;
          _myRequests = requests;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showAppSnackBar(context,
            message: 'Failed to load data', isSuccess: false);
      }
    }
  }

  /// Section options based on the selected course's type.
  List<String> get _sectionOptions {
    final courseType =
        (_selectedCourse?['course_type'] as String?)?.toLowerCase() ?? 'theory';
    return courseType == 'lab'
        ? ['A1', 'A2', 'B1', 'B2']
        : ['A', 'B'];
  }

  void _onCourseSelected(Map<String, dynamic>? course) {
    setState(() {
      _selectedCourse = course;
      _selectedTeacher = null;
      _selectedSection = null;
      _selectedDate = null;
      _selectedRoom = null;
      _selectedStartTime = null;
      _selectedEndTime = null;
      _periodStatuses = [];

      // Build teachers list for this course
      if (course != null) {
        final code = course['code'] as String;
        final teachers = <Map<String, dynamic>>[];
        final seen = <String>{};
        for (final o in _allOfferings) {
          final c = o['courses'] as Map<String, dynamic>;
          if (c['code'] == code) {
            final teacher = o['teachers'] as Map<String, dynamic>;
            final uid = teacher['user_id'] as String? ?? '';
            if (seen.add(uid)) {
              teachers.add({
                ...teacher,
                'offering_id': o['id'],
                'section': o['section'],
              });
            }
          }
        }
        _teachersForCourse = teachers;
        // Auto-select if only one teacher
        if (teachers.length == 1) {
          _selectedTeacher = teachers.first;
        }
      } else {
        _teachersForCourse = [];
      }
    });
  }

  void _onTeacherSelected(Map<String, dynamic>? teacher) {
    setState(() {
      _selectedTeacher = teacher;
      _selectedSection = null;
      _selectedDate = null;
      _selectedRoom = null;
      _selectedStartTime = null;
      _selectedEndTime = null;
      _periodStatuses = [];
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      // Skip Saturday (6 in DateTime.saturday) — KUET weekday map: Sun=0..Sat=6
      // DateTime: Mon=1..Sun=7
      if (picked.weekday == DateTime.saturday) {
        if (mounted) {
          showAppSnackBar(context,
              message: 'Saturday is not a valid class day',
              isSuccess: false);
        }
        return;
      }
      setState(() {
        _selectedDate = picked;
        _selectedRoom = null;
        _selectedStartTime = null;
        _selectedEndTime = null;
        _periodStatuses = [];
      });
    }
  }

  Future<void> _onRoomSelected(String? room) async {
    setState(() {
      _selectedRoom = room;
      _selectedStartTime = null;
      _selectedEndTime = null;
      _periodStatuses = [];
    });
    if (room != null && _selectedDate != null) {
      await _loadSlots(room);
    }
  }

  Future<void> _loadSlots(String roomNumber) async {
    if (_selectedDate == null) return;
    setState(() => _isSlotsLoading = true);

    // Convert DateTime weekday to KUET day (Sun=0..Sat=6)
    // DateTime: Mon=1, Tue=2, Wed=3, Thu=4, Fri=5, Sat=6, Sun=7
    final dayOfWeek = _selectedDate!.weekday == 7
        ? 0
        : _selectedDate!.weekday; // Sun=0 mapping

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final statuses = await CRRoomRequestService.getAvailableSlotsForRoom(
      roomNumber: roomNumber,
      dayOfWeek: dayOfWeek,
      requestDate: dateStr,
    );

    if (mounted) {
      setState(() {
        _periodStatuses = statuses;
        _isSlotsLoading = false;
      });
    }
  }

  int get _selectedDayOfWeek {
    if (_selectedDate == null) return 0;
    return _selectedDate!.weekday == 7 ? 0 : _selectedDate!.weekday;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      appBar: AppBar(
        title: const Text('Room Request'),
        backgroundColor: AppColors.surface(isDarkMode),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: AppColors.textPrimary(isDarkMode)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(isDarkMode),
                    const SizedBox(height: 24),
                    _buildRequestForm(isDarkMode),
                    const SizedBox(height: 28),
                    _buildMyRequests(isDarkMode),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[600]!, Colors.deepOrange[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.meeting_room, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CR Room Request',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Request a room for your class',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestForm(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 1. Select Course ──
        FormSectionLabel(text: 'Select Course', isDarkMode: isDarkMode),
        const SizedBox(height: 8),
        _buildDropdownContainer(
          isDarkMode: isDarkMode,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Map<String, dynamic>>(
              value: _selectedCourse,
              isExpanded: true,
              hint: Text('Choose a course',
                  style: TextStyle(
                      color: AppColors.textSecondary(isDarkMode))),
              dropdownColor: AppColors.surface(isDarkMode),
              items: _uniqueCourses.map((course) {
                final code = course['code'] as String? ?? '';
                final title = course['title'] as String? ?? '';
                return DropdownMenuItem(
                  value: course,
                  child: Text(
                    '$code - $title',
                    style: TextStyle(
                      color: AppColors.textPrimary(isDarkMode),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: _onCourseSelected,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ── 2. Select Teacher (visible after course selected) ──
        if (_selectedCourse != null) ...[
          FormSectionLabel(
              text: 'Select Teacher', isDarkMode: isDarkMode),
          const SizedBox(height: 8),
          if (_teachersForCourse.length == 1)
            _buildInfoChip(
              icon: Icons.person,
              label: _teachersForCourse.first['full_name'] as String? ??
                  'Teacher',
              isDarkMode: isDarkMode,
            )
          else
            _buildDropdownContainer(
              isDarkMode: isDarkMode,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Map<String, dynamic>>(
                  value: _selectedTeacher,
                  isExpanded: true,
                  hint: Text('Choose a teacher',
                      style: TextStyle(
                          color: AppColors.textSecondary(isDarkMode))),
                  dropdownColor: AppColors.surface(isDarkMode),
                  items: _teachersForCourse.map((teacher) {
                    final name =
                        teacher['full_name'] as String? ?? 'Unknown';
                    return DropdownMenuItem(
                      value: teacher,
                      child: Text(
                        name,
                        style: TextStyle(
                          color: AppColors.textPrimary(isDarkMode),
                          fontSize: 14,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: _onTeacherSelected,
                ),
              ),
            ),
          const SizedBox(height: 20),
        ],

        // ── 3. Select Section (visible after teacher selected) ──
        if (_selectedTeacher != null) ...[
          FormSectionLabel(
              text: 'Select Section', isDarkMode: isDarkMode),
          const SizedBox(height: 8),
          _buildDropdownContainer(
            isDarkMode: isDarkMode,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedSection,
                isExpanded: true,
                hint: Text('Choose a section',
                    style: TextStyle(
                        color: AppColors.textSecondary(isDarkMode))),
                dropdownColor: AppColors.surface(isDarkMode),
                items: _sectionOptions.map((sec) {
                  return DropdownMenuItem(
                    value: sec,
                    child: Text(
                      'Section $sec',
                      style: TextStyle(
                        color: AppColors.textPrimary(isDarkMode),
                        fontSize: 14,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedSection = val;
                    _selectedDate = null;
                    _selectedRoom = null;
                    _selectedStartTime = null;
                    _selectedEndTime = null;
                    _periodStatuses = [];
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // ── 4. Select Date (visible after section selected) ──
        if (_selectedSection != null) ...[
          FormSectionLabel(
              text: 'Select Date', isDarkMode: isDarkMode),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface(isDarkMode),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.border(isDarkMode)),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 18,
                      color: AppColors.textSecondary(isDarkMode)),
                  const SizedBox(width: 12),
                  Text(
                    _selectedDate != null
                        ? DateFormat('EEEE, MMM d, yyyy')
                            .format(_selectedDate!)
                        : 'Tap to pick a date',
                    style: TextStyle(
                      color: _selectedDate != null
                          ? AppColors.textPrimary(isDarkMode)
                          : AppColors.textSecondary(isDarkMode),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // ── 5. Select Room (visible after date selected) ──
        if (_selectedDate != null) ...[
          FormSectionLabel(
              text: 'Select Room', isDarkMode: isDarkMode),
          const SizedBox(height: 8),
          _buildDropdownContainer(
            isDarkMode: isDarkMode,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedRoom,
                isExpanded: true,
                hint: Text('Choose a room',
                    style: TextStyle(
                        color: AppColors.textSecondary(isDarkMode))),
                dropdownColor: AppColors.surface(isDarkMode),
                items: _availableRooms.map((room) {
                  return DropdownMenuItem(
                    value: room,
                    child: Text(
                      room,
                      style: TextStyle(
                        color: AppColors.textPrimary(isDarkMode),
                        fontSize: 14,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: _onRoomSelected,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // ── 6. Available Slots (visible after room selected) ──
        if (_selectedRoom != null) ...[
          FormSectionLabel(
              text: 'Available Slots', isDarkMode: isDarkMode),
          const SizedBox(height: 8),
          if (_isSlotsLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: CircularProgressIndicator(
                    color: AppColors.primary),
              ),
            )
          else if (_periodStatuses.isEmpty)
            _buildEmptySlotMessage(isDarkMode)
          else
            _buildSlotGrid(isDarkMode),
          const SizedBox(height: 20),
        ],

        // ── 7. Reason ──
        if (_selectedRoom != null &&
            _selectedStartTime != null) ...[
          FormSectionLabel(
              text: 'Reason (Optional)', isDarkMode: isDarkMode),
          const SizedBox(height: 8),
          TextFormField(
            controller: _reasonController,
            style: TextStyle(
                color: AppColors.textPrimary(isDarkMode)),
            maxLines: 3,
            decoration: InputDecoration(
              hintText:
                  'e.g., Extra class needed, Lab session, Make-up class...',
              hintStyle: TextStyle(
                  color: AppColors.textSecondary(isDarkMode)),
              filled: true,
              fillColor: AppColors.surface(isDarkMode),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: AppColors.border(isDarkMode)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: AppColors.border(isDarkMode)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: AppColors.primary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // ── Submit Button ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white),
                      ),
                    )
                  : const Text(
                      'Submit Request',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSlotGrid(bool isDarkMode) {
    final freeSlots =
        _periodStatuses.where((s) => s.state == PeriodState.free).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (freeSlots.isEmpty)
          _buildNoFreeSlotMessage(isDarkMode)
        else ...[
          // Instruction
          Text(
            'Tap to select start time, then end time',
            style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary(isDarkMode)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: freeSlots.map((ps) {
              final isStart = _selectedStartTime == '${ps.period.start}:00';
              final isEnd = _selectedEndTime == '${ps.period.end}:00';
              final isInRange = _isInSelectedRange(ps.period);
              final isSelected = isStart || isEnd || isInRange;

              return GestureDetector(
                onTap: () => _onSlotTapped(ps),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.success.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ps.period.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : AppColors.success,
                        ),
                      ),
                      Text(
                        '${ps.period.start}-${ps.period.end}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.9)
                              : AppColors.textSecondary(isDarkMode),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          // Selected range summary
          if (_selectedStartTime != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Selected: ${_formatTime(_selectedStartTime!)} - ${_formatTime(_selectedEndTime ?? _selectedStartTime!)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],

        // Legend
        const SizedBox(height: 12),
        Row(
          children: [
            _buildLegendDot(AppColors.success, 'Free', isDarkMode),
            const SizedBox(width: 16),
            _buildLegendDot(AppColors.primary, 'Selected', isDarkMode),
          ],
        ),
      ],
    );
  }

  void _onSlotTapped(PeriodStatus ps) {
    final startTime = '${ps.period.start}:00';
    final endTime = '${ps.period.end}:00';

    setState(() {
      if (_selectedStartTime == null) {
        // First tap: set start
        _selectedStartTime = startTime;
        _selectedEndTime = endTime;
      } else if (_selectedEndTime == _selectedStartTime ||
          startTime.compareTo(_selectedStartTime!) < 0) {
        // Re-selecting or selecting before start: reset
        _selectedStartTime = startTime;
        _selectedEndTime = endTime;
      } else {
        // Second tap after start: set end (validate continuous free range)
        if (_isRangeFree(_selectedStartTime!, endTime)) {
          _selectedEndTime = endTime;
        } else {
          showAppSnackBar(context,
              message:
                  'Cannot select range — occupied slot(s) in between',
              isSuccess: false);
        }
      }
    });
  }

  bool _isRangeFree(String start, String end) {
    final startShort = _fmtShort(start);
    final endShort = _fmtShort(end);
    for (final ps in _periodStatuses) {
      if (ps.period.start.compareTo(startShort) >= 0 &&
          ps.period.end.compareTo(endShort) <= 0) {
        if (ps.state != PeriodState.free) return false;
      }
    }
    return true;
  }

  bool _isInSelectedRange(Period period) {
    if (_selectedStartTime == null || _selectedEndTime == null) return false;
    final startShort = _fmtShort(_selectedStartTime!);
    final endShort = _fmtShort(_selectedEndTime!);
    return period.start.compareTo(startShort) >= 0 &&
        period.end.compareTo(endShort) <= 0;
  }

  Widget _buildLegendDot(Color color, String label, bool isDarkMode) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary(isDarkMode))),
      ],
    );
  }

  Widget _buildEmptySlotMessage(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(isDarkMode),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(isDarkMode)),
      ),
      child: Text(
        'No slot data available for this room.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textSecondary(isDarkMode)),
      ),
    );
  }

  Widget _buildNoFreeSlotMessage(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: const Text(
        'All slots are occupied for this room on the selected date.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.danger),
      ),
    );
  }

  Widget _buildDropdownContainer({
    required bool isDarkMode,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface(isDarkMode),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(isDarkMode)),
      ),
      child: child,
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textPrimary(isDarkMode),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyRequests(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Requests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(isDarkMode),
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${_myRequests.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_myRequests.isEmpty)
          EmptyStateWidget(
            icon: Icons.inbox_rounded,
            title: 'No requests yet',
            subtitle: 'Your room requests will appear here',
            isDarkMode: isDarkMode,
          )
        else
          ..._myRequests
              .map((req) => _buildRequestCard(req, isDarkMode)),
      ],
    );
  }

  Widget _buildRequestCard(CRRoomRequest request, bool isDarkMode) {
    final statusColor = switch (request.status) {
      'approved' => AppColors.success,
      'rejected' => AppColors.danger,
      _ => AppColors.warning,
    };
    final statusLabel =
        request.status[0].toUpperCase() + request.status.substring(1);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppColors.cardDecoration(isDarkMode),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  request.courseCode,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary(isDarkMode),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (request.teacherName != null)
            _buildInfoRow(
                Icons.person, request.teacherName!, isDarkMode),
          if (request.section != null)
            _buildInfoRow(
                Icons.group, 'Section ${request.section}', isDarkMode),
          if (request.requestDate != null)
            _buildInfoRow(
                Icons.date_range, request.requestDate!, isDarkMode),
          _buildInfoRow(
            Icons.calendar_today,
            '${request.dayName} | ${_formatTime(request.startTime)} - ${_formatTime(request.endTime)}',
            isDarkMode,
          ),
          if (request.roomNumber != null)
            _buildInfoRow(Icons.room,
                'Room: ${request.roomNumber}', isDarkMode),
          if (request.reason != null && request.reason!.isNotEmpty)
            _buildInfoRow(Icons.notes, request.reason!, isDarkMode),
          if (request.adminRemarks != null &&
              request.adminRemarks!.isNotEmpty) ...[
            const SizedBox(height: 4),
            _buildInfoRow(Icons.comment,
                'Admin: ${request.adminRemarks}', isDarkMode),
          ],
          if (request.status == 'pending') ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _deleteRequest(request),
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: AppColors.danger),
                label: const Text('Cancel',
                    style: TextStyle(color: AppColors.danger)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      IconData icon, String text, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon,
              size: 16,
              color: AppColors.textSecondary(isDarkMode)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary(isDarkMode),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String time) {
    return time.length >= 5 ? time.substring(0, 5) : time;
  }

  String _fmtShort(String t) => t.length >= 5 ? t.substring(0, 5) : t;

  Future<void> _submitRequest() async {
    if (_selectedCourse == null) {
      showAppSnackBar(context,
          message: 'Please select a course', isSuccess: false);
      return;
    }
    if (_selectedTeacher == null) {
      showAppSnackBar(context,
          message: 'Please select a teacher', isSuccess: false);
      return;
    }
    if (_selectedDate == null) {
      showAppSnackBar(context,
          message: 'Please select a date', isSuccess: false);
      return;
    }
    if (_selectedSection == null) {
      showAppSnackBar(context,
          message: 'Please select a section', isSuccess: false);
      return;
    }
    if (_selectedRoom == null) {
      showAppSnackBar(context,
          message: 'Please select a room', isSuccess: false);
      return;
    }
    if (_selectedStartTime == null || _selectedEndTime == null) {
      showAppSnackBar(context,
          message: 'Please select time slot(s)', isSuccess: false);
      return;
    }

    setState(() => _isSubmitting = true);

    final courseCode = _selectedCourse!['code'] as String;
    final teacherUserId =
        _selectedTeacher!['user_id'] as String;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);

    final result = await CRRoomRequestService.submitRequest(
      courseCode: courseCode,
      teacherUserId: teacherUserId,
      dayOfWeek: _selectedDayOfWeek,
      startTime: _selectedStartTime!,
      endTime: _selectedEndTime!,
      term: _term,
      session: _session,
      section: _selectedSection,
      roomNumber: _selectedRoom,
      requestDate: dateStr,
      reason: _reasonController.text.trim().isNotEmpty
          ? _reasonController.text.trim()
          : null,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      showAppSnackBar(context,
          message: result.message, isSuccess: result.success);

      if (result.success) {
        setState(() {
          _selectedCourse = null;
          _selectedTeacher = null;
          _selectedSection = null;
          _selectedDate = null;
          _selectedRoom = null;
          _selectedStartTime = null;
          _selectedEndTime = null;
          _periodStatuses = [];
          _teachersForCourse = [];
          _reasonController.clear();
        });
        _loadData();
      }
    }
  }

  Future<void> _deleteRequest(CRRoomRequest request) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Request'),
        content: const Text(
            'Are you sure you want to cancel this room request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Cancel',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success =
        await CRRoomRequestService.deleteRequest(request.id);
    if (mounted) {
      showAppSnackBar(
        context,
        message: success
            ? 'Request cancelled'
            : 'Failed to cancel request',
        isSuccess: success,
      );
      if (success) _loadData();
    }
  }
}
