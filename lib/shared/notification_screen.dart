import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kuet_cse_automation/Student%20Folder/Attendance/student_geo_attendance_screen.dart';
import 'package:provider/provider.dart';

import '../../services/class_reminder_service.dart';
import '../../services/local_notification_service.dart';
import '../../services/notification_provider.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────
// Notification Screen
// ─────────────────────────────────────────────────────────────

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: isDarkMode
              ? AppColors.darkBackground
              : AppColors.lightBackground,
          appBar: _buildAppBar(context, isDarkMode, provider),
          body: _buildBody(context, isDarkMode, provider),
        );
      },
    );
  }

  // ── AppBar ─────────────────────────────────────────────────

  AppBar _buildAppBar(
    BuildContext context,
    bool isDarkMode,
    NotificationProvider provider,
  ) {
    return AppBar(
      backgroundColor: isDarkMode
          ? AppColors.darkSurface
          : AppColors.lightSurface,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDarkMode
                ? AppColors.darkBorder
                : AppColors.lightBorder.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDarkMode ? Colors.white : Colors.black87,
            size: 18,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.notifications_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          if (provider.unreadCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${provider.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Class Reminder Timing',
          onPressed: () => _showReminderSettingsDialog(context),
          icon: Icon(
            Icons.alarm_rounded,
            color: isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
        if (provider.hasUnread)
          TextButton.icon(
            onPressed: () => provider.markAllRead(),
            icon: Icon(
              Icons.done_all_rounded,
              size: 16,
              color: isDarkMode ? AppColors.primary : AppColors.primary,
            ),
            label: Text(
              'Mark all read',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Future<void> _showReminderSettingsDialog(BuildContext context) async {
    var selectedMinutes = await ClassReminderService.getLeadMinutes();
    if (!context.mounted) return;

    final applied = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Class Reminder Time'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Notify me before class: $selectedMinutes min'),
                  const SizedBox(height: 12),
                  Slider(
                    value: selectedMinutes.toDouble(),
                    min: 1,
                    max: 120,
                    divisions: 119,
                    label: '$selectedMinutes min',
                    onChanged: (value) {
                      setDialogState(() => selectedMinutes = value.round());
                    },
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Works for both Student and Teacher class slots.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (applied != true || !context.mounted) return;

    final granted = await LocalNotificationService.requestPermission();
    await ClassReminderService.setLeadMinutes(selectedMinutes);
    await ClassReminderService.syncTodayReminders();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          granted
              ? 'Class reminder updated: $selectedMinutes min before class.'
              : 'Reminder saved, but notification permission is disabled.',
        ),
      ),
    );
  }

  // ── Body ───────────────────────────────────────────────────

  Widget _buildBody(
    BuildContext context,
    bool isDarkMode,
    NotificationProvider provider,
  ) {
    if (provider.isLoading) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (provider.error != null) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: provider.refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: _buildErrorState(context, isDarkMode, provider),
          ),
        ),
      );
    }

    if (provider.notifications.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: provider.refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: _buildEmptyState(isDarkMode),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: provider.refresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 12, bottom: 32),
        itemCount: provider.notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 0),
        itemBuilder: (context, index) {
          final n = provider.notifications[index];
          return _NotificationCard(
            notification: n,
            isDarkMode: isDarkMode,
            onTap: () => provider.markRead(n.id),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 52,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Notifications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'re all caught up!\nNotifications about classes, exams,\nand room bookings will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    bool isDarkMode,
    NotificationProvider provider,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 48, color: AppColors.danger),
          const SizedBox(height: 16),
          Text(
            provider.error ?? 'Something went wrong',
            style: TextStyle(
              color: isDarkMode
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: provider.refresh,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Notification Card Widget
// ─────────────────────────────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final bool isDarkMode;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final config = _typeConfig(notification.type);
    final isUnread = !notification.isRead;

    return InkWell(
      onTap: () async {
        onTap();
        if (notification.type == 'geo_attendance_open') {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const StudentGeoAttendanceScreen(),
            ),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isUnread
              ? (isDarkMode
                    ? config.color.withOpacity(0.08)
                    : config.color.withOpacity(0.06))
              : (isDarkMode ? AppColors.darkSurface : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnread
                ? config.color.withOpacity(0.35)
                : (isDarkMode ? AppColors.darkBorder : AppColors.lightBorder),
            width: isUnread ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.07),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: config.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(config.icon, color: config.color, size: 20),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isUnread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: isDarkMode ? Colors.white : Colors.black87,
                              height: 1.3,
                            ),
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 6, top: 3),
                            decoration: BoxDecoration(
                              color: config.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDarkMode
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: config.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            config.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: config.color,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.access_time_rounded,
                          size: 11,
                          color: isDarkMode
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _formatDate(notification.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDarkMode
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }
}

// ─────────────────────────────────────────────────────────────
// Type → Icon/Color/Label mapping
// ─────────────────────────────────────────────────────────────

class _TypeConfig {
  final IconData icon;
  final Color color;
  final String label;
  const _TypeConfig(this.icon, this.color, this.label);
}

_TypeConfig _typeConfig(String type) {
  return switch (type) {
    'room_allocated' => _TypeConfig(
      Icons.meeting_room_rounded,
      AppColors.info,
      'Room',
    ),
    'room_request_approved' => _TypeConfig(
      Icons.check_circle_rounded,
      AppColors.success,
      'Approved',
    ),
    'room_request_rejected' => _TypeConfig(
      Icons.cancel_rounded,
      AppColors.danger,
      'Rejected',
    ),
    'cr_room_request_submitted' => _TypeConfig(
      Icons.assignment_turned_in_rounded,
      AppColors.info,
      'CR Request',
    ),
    'attendance_marking_reminder' => _TypeConfig(
      Icons.fact_check_rounded,
      AppColors.warning,
      'Reminder',
    ),
    'course_anomaly_alert' => _TypeConfig(
      Icons.error_outline_rounded,
      AppColors.danger,
      'Alert',
    ),
    'notice_posted' => _TypeConfig(
      Icons.campaign_rounded,
      AppColors.warning,
      'Notice',
    ),
    'exam_result_published' => _TypeConfig(
      Icons.grading_rounded,
      AppColors.success,
      'Result',
    ),
    'exam_scheduled' => _TypeConfig(
      Icons.quiz_rounded,
      AppColors.danger,
      'Exam',
    ),
    'exam_room_assigned' => _TypeConfig(
      Icons.meeting_room_rounded,
      AppColors.info,
      'Exam Room',
    ),
    'exam_reminder' => _TypeConfig(
      Icons.alarm_rounded,
      AppColors.warning,
      'Reminder',
    ),
    'attendance_absent' => _TypeConfig(
      Icons.person_off_rounded,
      AppColors.danger,
      'Absent',
    ),
    'class_cancelled' => _TypeConfig(
      Icons.event_busy_rounded,
      AppColors.rose,
      'Cancelled',
    ),
    'class_rescheduled' => _TypeConfig(
      Icons.event_repeat_rounded,
      AppColors.accent,
      'Rescheduled',
    ),
    'assignment_due' => _TypeConfig(
      Icons.assignment_late_rounded,
      AppColors.warning,
      'Assignment',
    ),
    'attendance_low' => _TypeConfig(
      Icons.warning_rounded,
      AppColors.danger,
      'Attendance',
    ),
    'announcement' => _TypeConfig(
      Icons.announcement_rounded,
      AppColors.primary,
      'Announcement',
    ),
    'term_upgrade' => _TypeConfig(
      Icons.upgrade_rounded,
      AppColors.success,
      'Upgrade',
    ),
    'makeup_class' => _TypeConfig(
      Icons.event_available_rounded,
      AppColors.teal,
      'Makeup',
    ),
    'geo_attendance_open' => _TypeConfig(
      Icons.wifi_tethering_rounded,
      AppColors.success,
      'Attendance',
    ),
    'optional_course' => _TypeConfig(
      Icons.menu_book_rounded,
      AppColors.info,
      'Course',
    ),
    _ => _TypeConfig(Icons.notifications_rounded, AppColors.primary, 'Update'),
  };
}
