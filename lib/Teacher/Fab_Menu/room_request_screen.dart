import 'package:flutter/material.dart';
//import '../../services/supabase_service.dart';
import '../../theme/app_colors.dart';
import '../Room_info/room_info_screen.dart';
import '../Room_info/room_model.dart';
import '../Room_info/room_schedule_screen.dart';
import '../Room_info/room_service.dart';
import '../Room_info/slot_booking_dialog.dart';
import '../Room_info/room_booking_service.dart';

/// Teacher Room Request Screen — real room booking with conflict detection.
///
/// Flow: select course offering → select date → pick from available rooms →
/// [SlotBookingDialog] for period selection → [RoomBookingService.submitBookingRequest].
/// Enrolled students are notified by [RoomBookingService._notifyStudentsRoomBooked].
class RoomRequestScreen extends StatefulWidget {
  const RoomRequestScreen({super.key});

  @override
  State<RoomRequestScreen> createState() => _RoomRequestScreenState();
}

class _RoomRequestScreenState extends State<RoomRequestScreen> {
  bool _isLoadingRooms = true;
  List<Room> _rooms = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    try {
      final rooms = await RoomService.fetchAllRooms();
      if (mounted) setState(() { _rooms = rooms; _isLoadingRooms = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoadingRooms = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      appBar: AppBar(
        title: const Text('Book a Room'),
        backgroundColor: AppColors.surface(isDarkMode),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary(isDarkMode)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const RoomInfoScreen()),
            ),
            icon: Icon(Icons.grid_view, size: 18, color: AppColors.primary),
            label: Text('Room Grid', style: TextStyle(color: AppColors.primary, fontSize: 13)),
          ),
        ],
      ),
      body: _isLoadingRooms
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, color: AppColors.danger, size: 48),
                      const SizedBox(height: 12),
                      Text('Failed to load rooms', style: TextStyle(color: AppColors.textPrimary(isDarkMode))),
                      const SizedBox(height: 8),
                      ElevatedButton(onPressed: _loadRooms, child: const Text('Retry')),
                    ],
                  ),
                )
              : _buildRoomList(isDarkMode),
    );
  }

  Widget _buildRoomList(bool isDarkMode) {
    final classrooms = _rooms.where((r) => r.roomType.toLowerCase() != 'lab').toList();
    final labs = _rooms.where((r) => r.roomType.toLowerCase() == 'lab').toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header banner
        Container(
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
                    const Text('Book a Room', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(
                      'Tap a room to see its schedule & book a period',
                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (classrooms.isNotEmpty) ...[
          _buildSectionLabel('Classrooms', isDarkMode),
          const SizedBox(height: 10),
          ...classrooms.map((r) => _buildRoomCard(r, isDarkMode)),
          const SizedBox(height: 16),
        ],

        if (labs.isNotEmpty) ...[
          _buildSectionLabel('Labs', isDarkMode),
          const SizedBox(height: 10),
          ...labs.map((r) => _buildRoomCard(r, isDarkMode)),
        ],
      ],
    );
  }

  Widget _buildSectionLabel(String label, bool isDarkMode) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary(isDarkMode),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildRoomCard(Room room, bool isDarkMode) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: AppColors.surface(isDarkMode),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            room.roomType.toLowerCase() == 'lab' ? Icons.computer : Icons.meeting_room,
            color: Colors.orange[700],
            size: 22,
          ),
        ),
        title: Text(
          room.roomNumber,
          style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary(isDarkMode)),
        ),
        subtitle: Text(
          room.roomType,
          style: TextStyle(color: AppColors.textSecondary(isDarkMode), fontSize: 12),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary(isDarkMode)),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RoomScheduleScreen(room: room)),
        ).then((_) {
          // Navigate back-and-out after a successful booking
          if (mounted) Navigator.of(context).maybePop();
        }),
      ),
    );
  }
}
