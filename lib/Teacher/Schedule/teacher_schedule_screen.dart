import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../theme/app_colors.dart';
import 'teacher_room_allocation_service.dart';
import 'teacher_schedule_model.dart';
import 'teacher_schedule_service.dart';

typedef TeacherScheduleLoader =
    Future<List<TeacherSlot>> Function(DateTime date, {String? courseCode});
typedef RoomAvailabilityLoader =
    Future<List<RoomAvailabilityOption>> Function(
      TeacherSlot slot,
      DateTime date,
    );
typedef RoomAssigner =
    Future<RoomAssignmentResult> Function({
      required TeacherSlot slot,
      required DateTime date,
      required String roomNumber,
    });

class TeacherScheduleScreen extends StatefulWidget {
  final String? courseCode;
  final DateTime? initialDate;
  final TeacherScheduleLoader? scheduleLoader;
  final RoomAvailabilityLoader? availabilityLoader;
  final RoomAssigner? roomAssigner;

  const TeacherScheduleScreen({
    super.key,
    this.courseCode,
    this.initialDate,
    this.scheduleLoader,
    this.availabilityLoader,
    this.roomAssigner,
  });

  @override
  State<TeacherScheduleScreen> createState() => _TeacherScheduleScreenState();
}

class _TeacherScheduleScreenState extends State<TeacherScheduleScreen> {
  late DateTime _selectedDate;
  bool _isLoading = true;
  List<TeacherSlot> _slots = [];

  TeacherScheduleLoader get _scheduleLoader =>
      widget.scheduleLoader ??
      TeacherScheduleService.fetchEffectiveScheduleForDate;

  RoomAvailabilityLoader get _availabilityLoader =>
      widget.availabilityLoader ??
      ((slot, date) =>
          TeacherRoomAllocationService.fetchRoomAvailabilityForSlot(
            slot: slot,
            date: date,
          ));

  RoomAssigner get _roomAssigner =>
      widget.roomAssigner ?? TeacherScheduleService.assignRoomForDate;

  int get _assignedCount => _slots.where((slot) => slot.isAssigned).length;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final slots = await _scheduleLoader(
      _selectedDate,
      courseCode: widget.courseCode,
    );
    if (!mounted) return;
    setState(() {
      _slots = slots;
      _isLoading = false;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked == null) return;
    setState(() => _selectedDate = picked);
    await _load();
  }

  Future<void> _assignSlot(TeacherSlot slot) async {
    final result = await showModalBottomSheet<RoomAssignmentResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AssignRoomSheet(
        slot: slot,
        date: _selectedDate,
        availabilityLoader: _availabilityLoader,
        roomAssigner: _roomAssigner,
      ),
    );

    if (result == null || !result.success) return;
    await _load();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateText = DateFormat('EEEE, MMM d, yyyy').format(_selectedDate);
    final unassignedCount = _slots.length - _assignedCount;

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        title: Text(
          widget.courseCode != null
              ? '${widget.courseCode} Allocation'
              : 'Room Allocation',
        ),
        backgroundColor: AppColors.surface(isDark),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHero(dateText),
                  const SizedBox(height: 14),
                  _buildDatePicker(isDark, dateText),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStat(
                          'Total',
                          _slots.length,
                          AppColors.info,
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildStat(
                          'Assigned',
                          _assignedCount,
                          AppColors.success,
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildStat(
                          'Unassigned',
                          unassignedCount,
                          AppColors.warning,
                          isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (_slots.isEmpty)
                    _buildEmptyState(isDark)
                  else
                    ..._slots.map((slot) => _buildSlotCard(slot, isDark)),
                ],
              ),
            ),
    );
  }

  Widget _buildHero(String dateText) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.accent],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.meeting_room_outlined, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Allocate Rooms by Date',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateText,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker(bool isDark, String dateText) {
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface(isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border(isDark)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                dateText,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(isDark),
                ),
              ),
            ),
            const Text('Change', style: TextStyle(color: AppColors.primary)),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, int value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(isDark)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_busy_outlined,
            size: 36,
            color: AppColors.primary.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          Text(
            'No classes scheduled for this date',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textPrimary(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotCard(TeacherSlot slot, bool isDark) {
    final highlight = slot.isAssigned ? AppColors.success : AppColors.warning;
    final isLab =
        slot.courseType.toLowerCase().contains('lab') ||
        slot.courseType.toLowerCase().contains('sessional');
    final stripColor = isLab ? AppColors.labColor : AppColors.theoryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: highlight.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 88,
            decoration: BoxDecoration(
              color: stripColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        slot.courseCode,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary(isDark),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: highlight.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        slot.isAssigned ? 'Allocated' : 'Unassigned',
                        style: TextStyle(
                          color: highlight,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  slot.courseTitle,
                  style: TextStyle(color: AppColors.textSecondary(isDark)),
                ),
                const SizedBox(height: 10),
                Text(
                  '${slot.timeRange}${(slot.section ?? '').isNotEmpty ? ' • Section ${slot.section}' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary(isDark),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  slot.isAssigned
                      ? 'Room: ${slot.roomNumber}'
                      : 'Room: Unassigned',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: slot.isAssigned
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ),
                const SizedBox(height: 12),
                if (slot.isAssigned)
                  Text(
                    'Previously allocated classes cannot be reassigned here.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary(isDark),
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () => _assignSlot(slot),
                    icon: const Icon(Icons.add_business_outlined, size: 16),
                    label: const Text('Assign Room'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.25),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignRoomSheet extends StatefulWidget {
  final TeacherSlot slot;
  final DateTime date;
  final RoomAvailabilityLoader availabilityLoader;
  final RoomAssigner roomAssigner;

  const _AssignRoomSheet({
    required this.slot,
    required this.date,
    required this.availabilityLoader,
    required this.roomAssigner,
  });

  @override
  State<_AssignRoomSheet> createState() => _AssignRoomSheetState();
}

class _AssignRoomSheetState extends State<_AssignRoomSheet> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _selectedRoom;
  String? _errorMessage;
  List<RoomAvailabilityOption> _options = [];

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    final options = await widget.availabilityLoader(widget.slot, widget.date);
    if (!mounted) return;
    setState(() {
      _options = options;
      _isLoading = false;
    });
  }

  Future<void> _submit() async {
    if (_selectedRoom == null || _isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final result = await widget.roomAssigner(
      slot: widget.slot,
      date: widget.date,
      roomNumber: _selectedRoom!,
    );

    if (!mounted) return;
    if (result.success) {
      Navigator.of(context).pop(result);
      return;
    }

    setState(() {
      _isSubmitting = false;
      _errorMessage = result.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(isDark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Assign Room',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDark),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.slot.courseCode} • ${widget.slot.timeRange}',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary(isDark),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (_options.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No rooms are available to evaluate right now.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary(isDark),
                ),
              ),
            )
          else
            SizedBox(
              height: 340,
              child: ListView.separated(
                itemCount: _options.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, index) {
                  final option = _options[index];
                  final selected = _selectedRoom == option.room.roomNumber;
                  return InkWell(
                    onTap: option.isAvailable
                        ? () => setState(
                            () => _selectedRoom = option.room.roomNumber,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated(isDark),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : option.isAvailable
                              ? AppColors.border(isDark)
                              : AppColors.danger.withValues(alpha: 0.2),
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  option.room.roomNumber,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary(isDark),
                                  ),
                                ),
                              ),
                              Text(
                                option.isAvailable
                                    ? 'Available'
                                    : 'Unavailable',
                                style: TextStyle(
                                  color: option.isAvailable
                                      ? AppColors.success
                                      : AppColors.danger,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            [
                              if ((option.room.buildingName ?? '').isNotEmpty)
                                option.room.buildingName!,
                              '${option.room.capacity} seats',
                              option.room.roomType,
                            ].join(' • '),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary(isDark),
                            ),
                          ),
                          if ((option.conflictLabel ?? '').isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              option.conflictLabel!,
                              style: const TextStyle(
                                color: AppColors.danger,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _selectedRoom != null && !_isSubmitting
                  ? _submit
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: Colors.white,
                    ),
              label: Text(
                _isSubmitting ? 'Assigning...' : 'Confirm Room Allocation',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
