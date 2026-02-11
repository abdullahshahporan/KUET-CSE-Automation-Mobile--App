import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'room_model.dart';
import 'room_service.dart';
import 'room_schedule_screen.dart';

/// Room Info Screen - View rooms from the database grouped by type.
/// Tap a room card to see its booked schedule and free time-slots.
class RoomInfoScreen extends StatefulWidget {
  const RoomInfoScreen({super.key});

  @override
  State<RoomInfoScreen> createState() => _RoomInfoScreenState();
}

class _RoomInfoScreenState extends State<RoomInfoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Room> _classrooms = [];
  List<Room> _labs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRooms();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRooms() async {
    setState(() => _isLoading = true);
    final rooms = await RoomService.fetchAllRooms();
    if (mounted) {
      setState(() {
        _classrooms = rooms.where((r) => !r.isLab).toList();
        _labs = rooms.where((r) => r.isLab).toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.meeting_room,
                  color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('Room Information'),
          ],
        ),
        backgroundColor: AppColors.surface(isDark),
        elevation: 0,
        automaticallyImplyLeading: false,
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
              labelStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
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
                          Icon(Icons.class_, size: 15),
                          SizedBox(width: 6),
                          Text('Classrooms'),
                        ])),
                Tab(
                    height: 36,
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.computer, size: 15),
                          SizedBox(width: 6),
                          Text('Labs'),
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
                  Text('Loading rooms...',
                      style: TextStyle(
                          color: AppColors.textSecondary(isDark),
                          fontSize: 13)),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRoomList(_classrooms, isDark),
                _buildRoomList(_labs, isDark),
              ],
            ),
    );
  }

  // ─── Room list with summary card ──────────────────────
  Widget _buildRoomList(List<Room> rooms, bool isDark) {
    if (rooms.isEmpty) {
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
              child: Icon(Icons.meeting_room_outlined,
                  size: 48,
                  color: AppColors.primary.withValues(alpha: 0.4)),
            ),
            const SizedBox(height: 16),
            Text('No rooms found',
                style: TextStyle(
                    color: AppColors.textPrimary(isDark),
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('No rooms available in this category',
                style: TextStyle(
                    color: AppColors.textSecondary(isDark),
                    fontSize: 13)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadRooms,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.meeting_room,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${rooms.length} Room${rooms.length > 1 ? 's' : ''} Available',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap a room to view schedule & book',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Room cards
            ...rooms.map((room) => _buildRoomCard(room, isDark)),
          ],
        ),
      ),
    );
  }

  // ─── Individual room card ─────────────────────────────
  Widget _buildRoomCard(Room room, bool isDark) {
    final color = _roomColor(room);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => RoomScheduleScreen(room: room)),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface(isDark),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border(isDark)),
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
            child: Row(
              children: [
                // Type icon
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.15),
                        color.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: color.withValues(alpha: 0.15)),
                  ),
                  child: Icon(_roomIcon(room), color: color, size: 22),
                ),
                const SizedBox(width: 14),

                // Room details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.roomNumber,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary(isDark),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (room.buildingName != null &&
                              room.buildingName!.isNotEmpty) ...[
                            Icon(Icons.business_outlined,
                                size: 12,
                                color:
                                    AppColors.textSecondary(isDark)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                room.buildingName!,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary(
                                        isDark)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 8),
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                color:
                                    AppColors.textSecondary(isDark),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                          Icon(Icons.people_outline_rounded,
                              size: 12,
                              color:
                                  AppColors.textSecondary(isDark)),
                          const SizedBox(width: 4),
                          Text(
                            '${room.capacity} seats',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary(
                                    isDark)),
                          ),
                        ],
                      ),
                      if (room.facilities.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: room.facilities
                              .take(3)
                              .map((f) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: color
                                          .withValues(alpha: 0.08),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                      border: Border.all(
                                          color: color.withValues(
                                              alpha: 0.1)),
                                    ),
                                    child: Text(f,
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: color,
                                            fontWeight:
                                                FontWeight.w500)),
                                  ))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),

                // Chevron
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.grey[800]
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.arrow_forward_ios,
                      size: 12,
                      color: AppColors.textSecondary(isDark)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────
  IconData _roomIcon(Room room) {
    switch (room.typeLabel) {
      case IconLabel.lab:
        return Icons.computer;
      case IconLabel.seminar:
        return Icons.groups;
      case IconLabel.research:
        return Icons.science;
      case IconLabel.classroom:
        return Icons.class_;
    }
  }

  Color _roomColor(Room room) {
    switch (room.typeLabel) {
      case IconLabel.lab:
        return AppColors.accent;
      case IconLabel.seminar:
        return Colors.orange;
      case IconLabel.research:
        return Colors.teal;
      case IconLabel.classroom:
        return AppColors.primary;
    }
  }
}
