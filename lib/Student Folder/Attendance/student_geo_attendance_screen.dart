import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/geo_attendance_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_colors.dart';

/// Student screen to view open geo-attendance rooms and submit attendance.
class StudentGeoAttendanceScreen extends StatefulWidget {
  const StudentGeoAttendanceScreen({super.key});

  @override
  State<StudentGeoAttendanceScreen> createState() =>
      _StudentGeoAttendanceScreenState();
}

class _StudentGeoAttendanceScreenState extends State<StudentGeoAttendanceScreen>
    with WidgetsBindingObserver {
  bool _isLoading = true;
  List<Map<String, dynamic>> _openRooms = [];
  String? _submittingRoomId;
  String? _locationError;
  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final channel = _realtimeChannel;
    if (channel != null) {
      unawaited(SupabaseService.removeChannel(channel));
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_loadData());
    }
  }

  void _subscribeRealtime() {
    final userId = SupabaseService.currentUserId;
    if (userId == null || userId.isEmpty) return;

    _realtimeChannel = SupabaseService.client
        .channel('student-geo-attendance-screen-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'geo_attendance_rooms',
          callback: (_) {
            unawaited(_loadData());
          },
        )
        .subscribe();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final rooms = await GeoAttendanceService.getOpenRoomsForStudent(
        studentUserId: userId,
      );

      if (mounted) {
        setState(() {
          _openRooms = rooms;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Position?> _getPosition() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(
          () => _locationError =
              'Location services are disabled. Please enable GPS.',
        );
        return null;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(
            () => _locationError =
                'Location permission denied. Please allow location access.',
          );
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(
          () => _locationError =
              'Location permission permanently denied. Go to Settings to enable.',
        );
        return null;
      }

      setState(() => _locationError = null);

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      return position;
    } catch (e) {
      setState(() => _locationError = 'Could not get your location: $e');
      return null;
    }
  }

  Future<void> _submitAttendance(String roomId) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;

    setState(() => _submittingRoomId = roomId);

    try {
      // Get current location
      final position = await _getPosition();
      if (position == null) {
        setState(() => _submittingRoomId = null);
        return;
      }

      final locationCheck = await GeoAttendanceService.checkAttendanceLocation(
        geoRoomId: roomId,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (!locationCheck.isWithinRange) {
        if (mounted) {
          setState(() => _submittingRoomId = null);
          _showDistanceAlert(
            distance: locationCheck.distance,
            maxDistance: locationCheck.maxDistance,
            targetLabel: locationCheck.targetLabel,
          );
        }
        return;
      }

      // Submit attendance
      final result = await GeoAttendanceService.submitAttendance(
        geoRoomId: roomId,
        studentUserId: userId,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (mounted) {
        final dist = result['distance'] as int?;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Attendance recorded! You are ${dist}m from the room.',
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
        await _loadData(); // Refresh to update submission status
      }
    } on GeoDistanceException catch (e) {
      if (mounted) {
        _showDistanceAlert(
          distance: e.distance,
          maxDistance: e.maxDistance,
          targetLabel: e.targetLabel,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _submittingRoomId = null);
    }
  }

  void _showDistanceAlert({
    required double distance,
    required double maxDistance,
    required String targetLabel,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: AppColors.surface(isDarkMode),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.location_off, color: AppColors.warning, size: 28),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'You\'re Not Nearby',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.directions_walk_rounded,
                  size: 48,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'You are ${distance.round()}m away',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(isDarkMode),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Please go closer to the $targetLabel.\n'
                'You must be within ${maxDistance.round()}m to submit attendance.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary(isDarkMode),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.info.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: AppColors.info),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Move closer and try again',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.info,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Got it',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      appBar: AppBar(
        title: const Text(
          'Geo-Attendance',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface(isDarkMode),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _openRooms.isEmpty
                  ? _buildEmptyState(isDarkMode)
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Location error banner
                        if (_locationError != null)
                          _buildLocationError(isDarkMode),

                        // Info banner
                        _buildInfoBanner(isDarkMode),
                        const SizedBox(height: 16),

                        // Open rooms
                        Text(
                          'Open Rooms (${_openRooms.length})',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary(isDarkMode),
                          ),
                        ),
                        const SizedBox(height: 10),

                        ..._openRooms.map(
                          (room) => _buildRoomCard(room, isDarkMode),
                        ),
                      ],
                    ),
            ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_off_outlined,
                size: 64,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 16),
              Text(
                'No Open Rooms',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(isDarkMode),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your teacher hasn\'t opened any room yet.\nPull down to refresh.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary(isDarkMode)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationError(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: AppColors.warning, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _locationError!,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary(isDarkMode),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.info.withOpacity(0.12),
            AppColors.primary.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: AppColors.info, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'You must be within 30m of the room to submit attendance.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary(isDarkMode),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCard(Map<String, dynamic> room, bool isDarkMode) {
    final offering = room['course_offerings'] as Map<String, dynamic>?;
    final course = offering?['courses'] as Map<String, dynamic>?;
    final teacher = room['teachers'] as Map<String, dynamic>?;
    final code = course?['code'] ?? 'Course';
    final title = course?['title'] ?? '';
    final teacherName = teacher?['full_name'] ?? 'Teacher';
    final roomNumber = room['room_number'] as String? ?? '';
    final roomSection = room['section'] as String? ?? '';
    final endTime = room['end_time'] as String? ?? '';
    final startTime = room['start_time'] as String? ?? '';
    final alreadySubmitted = room['already_submitted'] == true;
    final roomId = room['id'] as String;
    final isSubmitting = _submittingRoomId == roomId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface(isDarkMode),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: alreadySubmitted
              ? AppColors.success.withOpacity(0.4)
              : AppColors.primary.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:
                        (alreadySubmitted
                                ? AppColors.success
                                : AppColors.primary)
                            .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    alreadySubmitted
                        ? Icons.check_circle
                        : Icons.door_front_door,
                    color: alreadySubmitted
                        ? AppColors.success
                        : AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        code,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary(isDarkMode),
                        ),
                      ),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary(isDarkMode),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                    color: AppColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
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

            const SizedBox(height: 12),

            // Details
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 15,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  teacherName,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary(isDarkMode),
                  ),
                ),
                if (roomNumber.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Icon(
                    Icons.room_outlined,
                    size: 15,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Room $roomNumber',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary(isDarkMode),
                    ),
                  ),
                ],
                if (roomSection.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      roomSection,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 12),
                Icon(Icons.schedule, size: 15, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  _formatTimeRange(startTime, endTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary(isDarkMode),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Action button
            SizedBox(
              width: double.infinity,
              child: alreadySubmitted
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: AppColors.success,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Attendance Submitted',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ElevatedButton.icon(
                      icon: isSubmitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.location_on, size: 20),
                      label: Text(
                        isSubmitting
                            ? 'Checking Location...'
                            : 'Submit Attendance',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      onPressed: isSubmitting
                          ? null
                          : () => _submitAttendance(roomId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.grey.shade400,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeRange(String startIso, String endIso) {
    final start = DateTime.tryParse(startIso);
    final end = DateTime.tryParse(endIso);
    if (start == null || end == null) return '';
    return '${_formatTime(start.toLocal())} - ${_formatTime(end.toLocal())}';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min $amPm';
  }
}
