import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'room_model.dart';
import 'room_booking_model.dart';
import 'room_booking_service.dart';
import 'room_service.dart';
import 'slot_booking_dialog.dart';

/// Displays the weekly schedule of a single room (booked & free slots).
class RoomScheduleScreen extends StatefulWidget {
  final Room room;
  const RoomScheduleScreen({super.key, required this.room});

  @override
  State<RoomScheduleScreen> createState() => _RoomScheduleScreenState();
}

class _RoomScheduleScreenState extends State<RoomScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<int, List<RoomSlot>> _booked = {};
  List<RoomBookingRequest> _bookings = [];
  int _selectedDay = 0;
  bool _initialLoad = true;

  static const _dayOrder = [0, 1, 2, 3, 4, 5, 6]; // Sun–Sat

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSchedule();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSchedule() async {
    setState(() => _isLoading = true);
    final booked = await RoomService.fetchRoomSchedule(widget.room.roomNumber);
    final bookings = await RoomBookingService.fetchRoomBookings(
        widget.room.roomNumber);
    if (mounted) {
      setState(() {
        _booked = booked;
        _bookings = bookings;
        _isLoading = false;
        // Only set day to today on first load, preserve on refresh
        if (_initialLoad) {
          _initialLoad = false;
          final now = DateTime.now().weekday;
          final todayIdx = now == 7 ? 0 : now;
          _selectedDay = RoomService.workDays.contains(todayIdx)
              ? todayIdx
              : RoomService.workDays.first;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.surface(isDark),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              size: 18, color: AppColors.textPrimary(isDark)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.meeting_room,
                  color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.room.roomNumber,
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(isDark))),
                if (widget.room.buildingName != null)
                  Text(widget.room.buildingName!,
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary(isDark))),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceElevated
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary(isDark),
              labelStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 13),
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent]),
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(
                    height: 36,
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today, size: 14),
                          SizedBox(width: 6),
                          Text('Schedule'),
                        ])),
                Tab(
                    height: 36,
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_available, size: 14),
                          SizedBox(width: 6),
                          Text('Request Slot'),
                        ])),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text('Loading schedule...',
                      style: TextStyle(
                          color: AppColors.textSecondary(isDark),
                          fontSize: 13)),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBookedTab(isDark),
                _buildRequestTab(isDark),
              ],
            ),
    );
  }

  // ═══════════════════ Booked Schedule Tab ═══════════════════
  Widget _buildBookedTab(bool isDark) {
    final daysWithSlots =
        _dayOrder.where((d) => _booked.containsKey(d)).toList();

    if (daysWithSlots.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.event_busy,
                  size: 48, color: AppColors.primary.withValues(alpha: 0.4)),
            ),
            const SizedBox(height: 16),
            Text('No classes scheduled',
                style: TextStyle(
                    color: AppColors.textPrimary(isDark),
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('This room has no scheduled classes yet',
                style: TextStyle(
                    color: AppColors.textSecondary(isDark), fontSize: 13)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadSchedule,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.all(16),
        itemCount: daysWithSlots.length,
        itemBuilder: (_, i) {
          final day = daysWithSlots[i];
          final slots = _booked[day]!;
          return _buildDaySection(day, slots, isDark);
        },
      ),
    );
  }

  Widget _buildDaySection(int day, List<RoomSlot> slots, bool isDark) {
    final isToday = _isTodayDay(day);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.border(isDark),
          width: isToday ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: isToday
                  ? LinearGradient(colors: [
                      AppColors.primary.withValues(alpha: 0.1),
                      AppColors.accent.withValues(alpha: 0.05),
                    ])
                  : null,
              color: isToday ? null : AppColors.background(isDark),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isToday
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : (isDark ? Colors.grey[800] : Colors.grey[100]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isToday ? Icons.today : Icons.calendar_today,
                    size: 14,
                    color: isToday
                        ? AppColors.primary
                        : AppColors.textSecondary(isDark),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  RoomSlot.dayNames[day],
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: isToday
                        ? AppColors.primary
                        : AppColors.textPrimary(isDark),
                  ),
                ),
                if (isToday) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.accent]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Today',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                      '${slots.length} class${slots.length > 1 ? 'es' : ''}',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary(isDark))),
                ),
              ],
            ),
          ),
          Divider(
              height: 1,
              color: AppColors.border(isDark)),
          ...slots.map((s) => _buildSlotItem(s, isDark)),
        ],
      ),
    );
  }

  Widget _buildSlotItem(RoomSlot slot, bool isDark) {
    final isLab = slot.courseType.toLowerCase().contains('lab') ||
        slot.courseType.toLowerCase().contains('sessional');
    final color = isLab ? AppColors.accent : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 3.5,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color, color.withValues(alpha: 0.4)],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(slot.courseCode,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textPrimary(isDark),
                          ),
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (slot.section != null &&
                        slot.section!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: color.withValues(alpha: 0.2)),
                        ),
                        child: Text(slot.section!,
                            style: TextStyle(
                                fontSize: 10,
                                color: color,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                    if (isLab) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Lab',
                            style: TextStyle(
                                fontSize: 9,
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(slot.courseTitle,
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary(isDark)),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 12, color: AppColors.textSecondary(isDark)),
                    const SizedBox(width: 4),
                    Text(slot.timeRange,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary(isDark))),
                    const SizedBox(width: 14),
                    Icon(Icons.person_outline_rounded,
                        size: 12, color: AppColors.textSecondary(isDark)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(slot.teacherName,
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary(isDark)),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════ Request Slot Tab ═══════════════════
  Widget _buildRequestTab(bool isDark) {
    final statuses = RoomBookingService.computePeriodStatuses(
      day: _selectedDay,
      routineSlots: _booked,
      bookings: _bookings,
    );

    final freeCount = statuses.where((s) => s.state == PeriodState.free).length;
    final occupiedCount =
        statuses.where((s) => s.state == PeriodState.occupied).length;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadSchedule,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Day selector ──
            Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text('Select Day',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textPrimary(isDark))),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: RoomService.workDays.map((day) {
                  final selected = day == _selectedDay;
                  final isToday = _isTodayDay(day);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => setState(() => _selectedDay = day),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: selected
                                ? const LinearGradient(colors: [
                                    AppColors.primary,
                                    AppColors.accent
                                  ])
                                : null,
                            color: selected
                                ? null
                                : (isDark
                                    ? AppColors.darkSurfaceElevated
                                    : Colors.grey[100]),
                            borderRadius: BorderRadius.circular(10),
                            border: !selected && isToday
                                ? Border.all(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.4))
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              RoomSlot.dayNames[day].substring(0, 3),
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : (isToday
                                        ? AppColors.primary
                                        : AppColors.textSecondary(isDark)),
                                fontWeight: selected || isToday
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 18),

            // ── Summary chips ──
            Row(
              children: [
                _buildMiniChip(
                    '$freeCount Free', AppColors.success, isDark),
                const SizedBox(width: 8),
                _buildMiniChip(
                    '$occupiedCount Occupied', AppColors.danger, isDark),
                const SizedBox(width: 8),
                _buildMiniChip(
                    '${statuses.length - freeCount - occupiedCount} Booked',
                    AppColors.warning,
                    isDark),
              ],
            ),

            const SizedBox(height: 18),

            // ── Period status header ──
            Row(
              children: [
                Icon(Icons.grid_view_rounded,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text('Period Status',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textPrimary(isDark))),
                const Spacer(),
                Text(RoomSlot.dayNames[_selectedDay],
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 10),

            // ── Custom bookings for this day ──
            ..._bookings
                .where((b) =>
                    b.dayOfWeek == _selectedDay &&
                    b.isCustom &&
                    b.status == 'approved')
                .map((b) => _buildCustomBookingTile(b, isDark)),

            ...statuses.map((ps) => _buildPeriodStatusTile(ps, isDark)),

            const SizedBox(height: 22),

            // ── Request a Slot button ──
            SizedBox(
              width: double.infinity,
              height: 50,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _openBookingDialog,
                  icon: const Icon(Icons.add_circle_outline,
                      color: Colors.white, size: 18),
                  label: const Text('Request a Slot',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniChip(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildCustomBookingTile(RoomBookingRequest b, bool isDark) {
    final color = AppColors.accent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Colored sidebar
            Container(
              width: 3.5,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color, color.withValues(alpha: 0.3)],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 14),
            // Booking info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Break Period',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textPrimary(isDark))),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 12,
                          color: AppColors.textSecondary(isDark)),
                      const SizedBox(width: 4),
                      Text(
                          '${Period.to12h(b.startTime)} - ${Period.to12h(b.endTime)}',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary(isDark))),
                      if (b.courseCode != null) ...[
                        const SizedBox(width: 10),
                        Icon(Icons.book_outlined,
                            size: 12,
                            color: AppColors.textSecondary(isDark)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(b.courseCode!,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: color),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Custom Booking badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_available_rounded,
                      size: 12, color: Colors.white),
                  SizedBox(width: 4),
                  Text('Custom Booking',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodStatusTile(PeriodStatus ps, bool isDark) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (ps.state) {
      case PeriodState.free:
        statusColor = AppColors.success;
        statusLabel = 'Free';
        statusIcon = Icons.check_circle_outline;
      case PeriodState.occupied:
        statusColor = AppColors.danger;
        statusLabel = 'Occupied';
        statusIcon = Icons.block;
      case PeriodState.booked:
        statusColor = AppColors.warning;
        statusLabel = 'Booked';
        statusIcon = Icons.verified_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.surface(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Colored sidebar
          Container(
            width: 3.5,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [statusColor, statusColor.withValues(alpha: 0.3)],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          // Period info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ps.period.label,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textPrimary(isDark))),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 12,
                        color: AppColors.textSecondary(isDark)),
                    const SizedBox(width: 4),
                    Text('${Period.to12h(ps.period.start)} - ${Period.to12h(ps.period.end)}',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary(isDark))),
                    if (ps.courseCode != null) ...[
                      const SizedBox(width: 10),
                      Icon(Icons.book_outlined,
                          size: 12,
                          color: AppColors.textSecondary(isDark)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(ps.courseCode!,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: statusColor),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Status badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: statusColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 12, color: statusColor),
                const SizedBox(width: 4),
                Text(statusLabel,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openBookingDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => SlotBookingDialog(
        room: widget.room,
        initialDay: _selectedDay,
        routineSlots: _booked,
        bookings: _bookings,
      ),
    );
    if (result == true) {
      await _loadSchedule();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Expanded(
                    child: Text('Booking request submitted successfully!')),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  // ─── Helpers ──────────────────────────────────────────
  bool _isTodayDay(int dayOfWeek) {
    final now = DateTime.now().weekday; // 1=Mon…7=Sun
    final todayIndex = now == 7 ? 0 : now; // Sun=0
    return todayIndex == dayOfWeek;
  }
}
