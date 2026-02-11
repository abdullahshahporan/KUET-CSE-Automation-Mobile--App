import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'room_model.dart';
import 'room_booking_model.dart';
import 'room_booking_service.dart';
import 'room_service.dart';

/// Professional "Add Routine Slot" dialog.
/// Teacher picks Course, Room (pre-filled), Day, From/To Period
/// and submits a booking request with timestamp-based conflict resolution.
class SlotBookingDialog extends StatefulWidget {
  final Room room;
  final int initialDay;
  final Map<int, List<RoomSlot>> routineSlots;
  final List<RoomBookingRequest> bookings;

  const SlotBookingDialog({
    super.key,
    required this.room,
    required this.initialDay,
    required this.routineSlots,
    required this.bookings,
  });

  @override
  State<SlotBookingDialog> createState() => _SlotBookingDialogState();
}

class _SlotBookingDialogState extends State<SlotBookingDialog> {
  List<Map<String, dynamic>> _offerings = [];
  Map<String, dynamic>? _selectedOffering;
  late int _selectedDay;
  Period? _fromPeriod;
  Period? _toPeriod;
  String? _selectedSection;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _useCustomTime = false;
  TimeOfDay? _customStart;
  TimeOfDay? _customEnd;

  static const _sections = ['A', 'B'];

  /// Free periods for the currently selected day.
  List<Period> get _freePeriods {
    final statuses = RoomBookingService.computePeriodStatuses(
      day: _selectedDay,
      routineSlots: widget.routineSlots,
      bookings: widget.bookings,
    );
    return statuses
        .where((ps) => ps.state == PeriodState.free)
        .map((ps) => ps.period)
        .toList();
  }

  bool get _canSubmit {
    if (_selectedOffering == null || _isSubmitting) return false;
    if (_useCustomTime) {
      return _customStart != null && _customEnd != null;
    }
    return _fromPeriod != null && _toPeriod != null;
  }

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.initialDay;
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    final offerings = await RoomBookingService.fetchTeacherOfferings();
    if (mounted) {
      setState(() {
        _offerings = offerings;
        _isLoading = false;
      });
    }
  }

  String _offeringLabel(Map<String, dynamic> o) {
    final course = o['courses'] as Map<String, dynamic>? ?? {};
    return '${course['code']} – ${course['title']}';
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    BookingResult result;

    if (_useCustomTime) {
      result = await RoomBookingService.submitCustomBookingRequest(
        roomNumber: widget.room.roomNumber,
        offeringId: _selectedOffering!['id'] as String,
        dayOfWeek: _selectedDay,
        customStart: _customStart!,
        customEnd: _customEnd!,
        section: _selectedSection,
      );
    } else {
      result = await RoomBookingService.submitBookingRequest(
        roomNumber: widget.room.roomNumber,
        offeringId: _selectedOffering!['id'] as String,
        dayOfWeek: _selectedDay,
        fromPeriod: _fromPeriod!,
        toPeriod: _toPeriod!,
        section: _selectedSection,
      );
    }

    if (!mounted) return;

    if (result.success) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _isSubmitting = false;
        _errorMessage = result.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final freePeriods = _freePeriods;

    return Dialog(
      backgroundColor: AppColors.surface(isDark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      child: _isLoading
          ? const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.event_note,
                            color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Request Slot',
                                style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary(isDark))),
                            Text('Book a room for your class',
                                style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        AppColors.textSecondary(isDark))),
                          ],
                        ),
                      ),
                      Material(
                        color: isDark ? Colors.grey[800]! : Colors.grey[100]!,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => Navigator.pop(context),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(Icons.close,
                                size: 18,
                                color: AppColors.textSecondary(isDark)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // ── Error Banner ──
                  if (_errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.danger.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.danger, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(_errorMessage!,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.danger,
                                    fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Course ──
                  _sectionLabel('Course', Icons.book_outlined, isDark),
                  const SizedBox(height: 8),
                  _buildDropdown<Map<String, dynamic>>(
                    value: _selectedOffering,
                    hint: 'Select a course...',
                    items: _offerings,
                    labelFn: _offeringLabel,
                    onChanged: (v) =>
                        setState(() => _selectedOffering = v),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 18),

                  // ── Room (read-only) ──
                  _sectionLabel(
                      'Room', Icons.meeting_room_outlined, isDark),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 15),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[850] : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.border(isDark)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color:
                                AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.meeting_room,
                              size: 16, color: AppColors.primary),
                        ),
                        const SizedBox(width: 10),
                        Text(widget.room.roomNumber,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary(isDark))),
                        const Spacer(),
                        Icon(Icons.lock_outline,
                            size: 14,
                            color: AppColors.textSecondary(isDark)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── Day ──
                  _sectionLabel(
                      'Day', Icons.calendar_today_outlined, isDark),
                  const SizedBox(height: 8),
                  _buildDropdown<int>(
                    value: _selectedDay,
                    hint: 'Select day',
                    items: RoomService.workDays,
                    labelFn: (d) => RoomSlot.dayNames[d],
                    onChanged: (v) => setState(() {
                      _selectedDay = v!;
                      _fromPeriod = null;
                      _toPeriod = null;
                      _errorMessage = null;
                    }),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 18),

                  // ── Section ──
                  _sectionLabel(
                      'Section', Icons.group_outlined, isDark),
                  const SizedBox(height: 8),
                  _buildDropdown<String>(
                    value: _selectedSection,
                    hint: 'Select section (optional)',
                    items: _sections,
                    labelFn: (s) => 'Section $s',
                    onChanged: (v) =>
                        setState(() => _selectedSection = v),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 18),

                  // ── Time Slot Mode Toggle ──
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text('Time Slot',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary(isDark))),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceElevated
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildModeChip(
                                'Period', !_useCustomTime, isDark,
                                () => setState(() {
                                      _useCustomTime = false;
                                      _customStart = null;
                                      _customEnd = null;
                                      _errorMessage = null;
                                    })),
                            _buildModeChip(
                                'Custom', _useCustomTime, isDark,
                                () => setState(() {
                                      _useCustomTime = true;
                                      _fromPeriod = null;
                                      _toPeriod = null;
                                      _errorMessage = null;
                                    })),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (!_useCustomTime) ...[
                    // ── Standard Period Selectors ──
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionLabel('From', Icons.start, isDark),
                              const SizedBox(height: 8),
                              _buildDropdown<Period>(
                                value: _fromPeriod,
                                hint: 'Select',
                                items: freePeriods,
                                labelFn: (p) => Period.to12h(p.start),
                                onChanged: (v) => setState(() {
                                  _fromPeriod = v;
                                  _errorMessage = null;
                                  if (_toPeriod != null &&
                                      Period.all.indexWhere((x) =>
                                              x.label ==
                                              _toPeriod!.label) <
                                          Period.all.indexWhere((x) =>
                                              x.label == v!.label)) {
                                    _toPeriod = null;
                                  }
                                }),
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionLabel('To', Icons.last_page, isDark),
                              const SizedBox(height: 8),
                              _buildDropdown<Period>(
                                value: _toPeriod,
                                hint: 'Select',
                                items: _toOptions(freePeriods),
                                labelFn: (p) => Period.to12h(p.end),
                                onChanged: (v) => setState(() {
                                  _toPeriod = v;
                                  _errorMessage = null;
                                }),
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // ── Custom Time Picker (Break: 1:10 PM – 2:30 PM) ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          AppColors.accent.withValues(alpha: 0.06),
                          AppColors.primary.withValues(alpha: 0.04),
                        ]),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color:
                                AppColors.accent.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.free_breakfast_outlined,
                                  size: 14, color: AppColors.accent),
                              const SizedBox(width: 6),
                              Text('Break Period',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.accent)),
                              const Spacer(),
                              Text('1:10 PM – 2:30 PM',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors
                                          .textSecondary(isDark))),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTimePicker(
                                  label: 'Start Time',
                                  value: _customStart,
                                  isDark: isDark,
                                  onTap: () => _pickTime(isStart: true),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10),
                                child: Icon(Icons.arrow_forward,
                                    size: 16,
                                    color:
                                        AppColors.textSecondary(isDark)),
                              ),
                              Expanded(
                                child: _buildTimePicker(
                                  label: 'End Time',
                                  value: _customEnd,
                                  isDark: isDark,
                                  onTap: () => _pickTime(isStart: false),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),

                  // ── Info banner ──
                  if (_selectedOffering != null) _buildInfoBanner(isDark),

                  const SizedBox(height: 22),

                  // ── Submit button ──
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: _canSubmit
                            ? const LinearGradient(
                                colors: [AppColors.primary, AppColors.accent],
                              )
                            : null,
                        color: _canSubmit ? null : Colors.grey[700],
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: _canSubmit
                            ? [
                                BoxShadow(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _canSubmit ? _submit : null,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.send_rounded,
                                color: Colors.white, size: 18),
                        label: Text(
                            _isSubmitting ? 'Submitting...' : 'Request Slot',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          disabledBackgroundColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────

  Widget _sectionLabel(String text, IconData icon, bool isDark) => Row(
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(isDark))),
        ],
      );

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<T> items,
    required String Function(T) labelFn,
    required ValueChanged<T?> onChanged,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceElevated
            : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.25), width: 1.2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint,
              style: TextStyle(
                  color: AppColors.textSecondary(isDark), fontSize: 13)),
          isExpanded: true,
          borderRadius: BorderRadius.circular(14),
          dropdownColor: AppColors.surface(isDark),
          icon: const Icon(Icons.keyboard_arrow_down,
              color: AppColors.primary, size: 20),
          items: items
              .map((item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(labelFn(item),
                      style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary(isDark)))))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildInfoBanner(bool isDark) {
    final o = _selectedOffering!;
    final term = o['term'] ?? '';
    final session = o['session'] ?? '';
    final batch = o['batch'] ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.06),
            AppColors.accent.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline,
              size: 16, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary(isDark)),
                children: [
                  const TextSpan(text: 'Term '),
                  TextSpan(
                      text: term,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary)),
                  const TextSpan(text: '  •  '),
                  TextSpan(
                      text: session,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold)),
                  if (batch.toString().isNotEmpty) ...[
                    const TextSpan(text: '  •  Batch '),
                    TextSpan(
                        text: batch.toString(),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Period> _toOptions(List<Period> available) {
    if (_fromPeriod == null) return available;
    final fromIdx =
        Period.all.indexWhere((x) => x.label == _fromPeriod!.label);
    return available.where((p) {
      final pIdx = Period.all.indexWhere((x) => x.label == p.label);
      return pIdx >= fromIdx;
    }).toList();
  }

  // ─── Mode toggle chip ─────────────────────────────────
  Widget _buildModeChip(
      String label, bool active, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent])
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: active
                    ? Colors.white
                    : AppColors.textSecondary(isDark))),
      ),
    );
  }

  // ─── Custom time picker tile ──────────────────────────
  Widget _buildTimePicker({
    required String label,
    required TimeOfDay? value,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceElevated
              : AppColors.lightBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: value != null
                  ? AppColors.accent.withValues(alpha: 0.4)
                  : AppColors.border(isDark)),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary(isDark))),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.schedule,
                    size: 14,
                    color: value != null
                        ? AppColors.accent
                        : AppColors.textSecondary(isDark)),
                const SizedBox(width: 6),
                Text(
                  value != null ? _formatTime12(value) : 'Tap to set',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        value != null ? FontWeight.bold : FontWeight.normal,
                    color: value != null
                        ? AppColors.textPrimary(isDark)
                        : AppColors.textSecondary(isDark),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime12(TimeOfDay? t) {
    if (t == null) return '';
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final ampm = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart
        ? (_customStart ?? const TimeOfDay(hour: 13, minute: 10))
        : (_customEnd ?? const TimeOfDay(hour: 14, minute: 30));

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: isStart ? 'SELECT START TIME' : 'SELECT END TIME',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: AppColors.surface(
                  Theme.of(context).brightness == Brightness.dark),
              hourMinuteColor: AppColors.primary.withValues(alpha: 0.1),
              dialHandColor: AppColors.primary,
              dialBackgroundColor: AppColors.primary.withValues(alpha: 0.08),
              entryModeIconColor: AppColors.primary,
            ),
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                  secondary: AppColors.accent,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      // Constrain to break period: 1:10 PM (13:10) – 2:30 PM (14:30)
      final mins = picked.hour * 60 + picked.minute;
      const minAllowed = 13 * 60 + 10;
      const maxAllowed = 14 * 60 + 30;

      if (mins < minAllowed || mins > maxAllowed) {
        setState(() {
          _errorMessage = 'Custom time must be between 1:10 PM and 2:30 PM.';
        });
        return;
      }

      setState(() {
        _errorMessage = null;
        if (isStart) {
          _customStart = picked;
          // Auto-clear end if it's before or equal to start
          if (_customEnd != null) {
            final endMins = _customEnd!.hour * 60 + _customEnd!.minute;
            if (endMins <= mins) _customEnd = null;
          }
        } else {
          _customEnd = picked;
        }
      });
    }
  }
}
