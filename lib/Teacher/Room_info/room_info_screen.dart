import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Room Info Screen - View room availability and information
class RoomInfoScreen extends StatefulWidget {
  const RoomInfoScreen({super.key});

  @override
  State<RoomInfoScreen> createState() => _RoomInfoScreenState();
}

class _RoomInfoScreenState extends State<RoomInfoScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<RoomData> classrooms = [
    RoomData(name: 'Room 301', building: 'CSE Building', capacity: 60, type: RoomType.classroom, isAvailable: true),
    RoomData(name: 'Room 302', building: 'CSE Building', capacity: 60, type: RoomType.classroom, isAvailable: false, occupiedBy: 'CSE 4101 - Dr. K. M. Azharul'),
    RoomData(name: 'Room 401', building: 'CSE Building', capacity: 80, type: RoomType.classroom, isAvailable: true),
    RoomData(name: 'Room 402', building: 'CSE Building', capacity: 80, type: RoomType.classroom, isAvailable: false, occupiedBy: 'CSE 2101 - Dr. M. M. A. Hashem'),
    RoomData(name: 'Room 501', building: 'CSE Building', capacity: 100, type: RoomType.seminar, isAvailable: true),
  ];

  final List<RoomData> labs = [
    RoomData(name: 'Lab 201', building: 'CSE Building', capacity: 30, type: RoomType.lab, isAvailable: true),
    RoomData(name: 'Lab 202', building: 'CSE Building', capacity: 30, type: RoomType.lab, isAvailable: false, occupiedBy: 'CSE 3202 Lab - Section A1'),
    RoomData(name: 'Lab 203', building: 'CSE Building', capacity: 30, type: RoomType.lab, isAvailable: true),
    RoomData(name: 'Lab 204', building: 'CSE Building', capacity: 30, type: RoomType.lab, isAvailable: false, occupiedBy: 'CSE 2102 Lab - Section B2'),
    RoomData(name: 'Research Lab', building: 'CSE Building', capacity: 15, type: RoomType.research, isAvailable: true),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      appBar: AppBar(
        title: const Text('Room Information'),
        backgroundColor: AppColors.surface(isDarkMode),
        elevation: 0,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary(isDarkMode),
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Classrooms', icon: Icon(Icons.class_, size: 20)),
            Tab(text: 'Labs', icon: Icon(Icons.computer, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRoomList(classrooms, isDarkMode),
          _buildRoomList(labs, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildRoomList(List<RoomData> rooms, bool isDarkMode) {
    final availableRooms = rooms.where((r) => r.isAvailable).length;
    
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.meeting_room, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$availableRooms of ${rooms.length} Available',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Real-time room status',
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
          const SizedBox(height: 20),

          // Room Cards
          ...rooms.map((room) => _buildRoomCard(room, isDarkMode)),
        ],
      ),
    );
  }

  Widget _buildRoomCard(RoomData room, bool isDarkMode) {
    final statusColor = room.isAvailable ? AppColors.success : AppColors.danger;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(isDarkMode),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(isDarkMode)),
      ),
      child: Row(
        children: [
          // Status indicator
          Container(
            width: 4,
            height: 60,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          
          // Room icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getRoomColor(room.type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getRoomIcon(room.type),
              color: _getRoomColor(room.type),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          
          // Room Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      room.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(isDarkMode),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        room.isAvailable ? 'Available' : 'Occupied',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  room.isAvailable 
                      ? '${room.building} • Capacity: ${room.capacity}'
                      : room.occupiedBy ?? 'In use',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary(isDarkMode),
                  ),
                ),
              ],
            ),
          ),
          
          // Action button
          if (room.isAvailable)
            IconButton(
              onPressed: () => _showRequestDialog(room),
              icon: Icon(Icons.add_circle_outline, color: AppColors.primary),
              tooltip: 'Request Room',
            ),
        ],
      ),
    );
  }

  IconData _getRoomIcon(RoomType type) {
    switch (type) {
      case RoomType.classroom:
        return Icons.class_;
      case RoomType.lab:
        return Icons.computer;
      case RoomType.seminar:
        return Icons.groups;
      case RoomType.research:
        return Icons.science;
    }
  }

  Color _getRoomColor(RoomType type) {
    switch (type) {
      case RoomType.classroom:
        return AppColors.primary;
      case RoomType.lab:
        return AppColors.accent;
      case RoomType.seminar:
        return Colors.orange;
      case RoomType.research:
        return Colors.teal;
    }
  }

  void _showRequestDialog(RoomData room) {
    showDialog(
      context: context,
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: AppColors.surface(isDarkMode),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Request ${room.name}?'),
          content: Text('Would you like to request this room for your next class?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary(isDarkMode))),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Room request sent for ${room.name}'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Request', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}

enum RoomType { classroom, lab, seminar, research }

class RoomData {
  final String name;
  final String building;
  final int capacity;
  final RoomType type;
  final bool isAvailable;
  final String? occupiedBy;

  RoomData({
    required this.name,
    required this.building,
    required this.capacity,
    required this.type,
    required this.isAvailable,
    this.occupiedBy,
  });
}
