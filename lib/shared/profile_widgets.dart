import 'package:flutter/material.dart';
import '../Auth/Sign_In_Screen.dart';
import '../services/class_reminder_service.dart';
import '../services/local_notification_service.dart';
import '../services/notification_service.dart';
import '../services/session_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_colors.dart';
import '../utils/time_utils.dart';
import 'ui_helpers.dart';

/// Shared profile UI components used by both Student and Teacher profile screens.
/// Eliminates code duplication across profile implementations.

// ── SECTION CONTAINER ─────────────────────────────────────────────────────────

Widget buildProfileSection(
  bool isDarkMode,
  String title,
  IconData headerIcon,
  List<Widget> children,
) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: AppColors.surface(isDarkMode),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border(isDarkMode)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(headerIcon, size: 20, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(isDarkMode),
                ),
              ),
            ],
          ),
        ),
        ...children,
        const SizedBox(height: 8),
      ],
    ),
  );
}

// ── INFO TILE ─────────────────────────────────────────────────────────────────

Widget buildInfoTile(
  IconData icon,
  String label,
  String value,
  bool isDarkMode, {
  bool editable = false,
  VoidCallback? onEdit,
}) {
  final hasValue = value != 'Not set' && value != 'N/A' && value.isNotEmpty;
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: (editable ? AppColors.accent : AppColors.primary)
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: editable ? AppColors.accent : AppColors.primary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary(isDarkMode),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: hasValue
                      ? AppColors.textPrimary(isDarkMode)
                      : AppColors.textMuted,
                  fontStyle: hasValue ? FontStyle.normal : FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        if (editable && onEdit != null)
          InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.edit_outlined, size: 16, color: AppColors.accent),
            ),
          )
        else
          Icon(Icons.lock, size: 14, color: AppColors.textMuted),
      ],
    ),
  );
}

// ── ACTION TILE ───────────────────────────────────────────────────────────────

Widget buildActionTile(
  IconData icon,
  String label,
  bool isDarkMode,
  VoidCallback onTap,
) {
  return InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary(isDarkMode),
              ),
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textMuted),
        ],
      ),
    ),
  );
}

// ── STAT CARD ─────────────────────────────────────────────────────────────────

Widget buildStatCard(
  String label,
  String value,
  IconData icon,
  Color color,
  bool isDarkMode,
) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
    decoration: BoxDecoration(
      color: AppColors.surface(isDarkMode),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border(isDarkMode)),
    ),
    child: Column(
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary(isDarkMode),
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary(isDarkMode),
          ),
        ),
      ],
    ),
  );
}

// ── LOGOUT BUTTON ─────────────────────────────────────────────────────────────

Widget buildLogoutButton(BuildContext context, bool isDarkMode) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => showLogoutDialog(context, isDarkMode),
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: const Text('Logout'),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isDarkMode ? AppColors.darkSurfaceElevated : Colors.red[50],
          foregroundColor: AppColors.danger,
          side: BorderSide(color: AppColors.danger.withOpacity(0.3)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    ),
  );
}

// ── DIALOGS ───────────────────────────────────────────────────────────────────

void showLogoutDialog(BuildContext context, bool isDarkMode) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surfaceElevated(isDarkMode),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Logout',
        style: TextStyle(color: AppColors.textPrimary(isDarkMode)),
      ),
      content: Text(
        'Are you sure you want to logout?',
        style: TextStyle(color: AppColors.textSecondary(isDarkMode)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            'Cancel',
            style: TextStyle(color: AppColors.textSecondary(isDarkMode)),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(ctx);
            await SupabaseService.signOut();
            if (context.mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const SignInScreen()),
                (route) => false,
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Logout', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

void showEditPhoneDialog({
  required BuildContext context,
  required bool isDarkMode,
  required TextEditingController controller,
  required bool isUpdating,
  required VoidCallback onSave,
}) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surfaceElevated(isDarkMode),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Edit Phone',
        style: TextStyle(color: AppColors.textPrimary(isDarkMode)),
      ),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.phone,
        style: TextStyle(color: AppColors.textPrimary(isDarkMode)),
        decoration: InputDecoration(
          labelText: 'Phone Number',
          hintText: '+880 1XXXXXXXXX',
          prefixIcon: const Icon(Icons.phone),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: AppColors.surface(isDarkMode),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            'Cancel',
            style: TextStyle(color: AppColors.textSecondary(isDarkMode)),
          ),
        ),
        ElevatedButton(
          onPressed: isUpdating
              ? null
              : () {
                  Navigator.pop(ctx);
                  onSave();
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

// ── DARK MODE TOGGLE ──────────────────────────────────────────────────────────

Widget buildDarkModeToggle(bool isDarkMode, VoidCallback onToggle) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (isDarkMode ? Colors.amber : Colors.indigo).withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            size: 20,
            color: isDarkMode ? Colors.amber : Colors.indigo,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            'Dark Mode',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary(isDarkMode),
            ),
          ),
        ),
        Switch.adaptive(
          value: isDarkMode,
          onChanged: (_) => onToggle(),
          activeColor: Colors.white,
          activeTrackColor: AppColors.primary,
        ),
      ],
    ),
  );
}

// ── SNACKBAR HELPER ───────────────────────────────────────────────────────────

/// @deprecated Use [showAppSnackBar] from `ui_helpers.dart` instead.
void showResultSnackBar(BuildContext context, {required bool success, required String message}) {
  showAppSnackBar(context, message: message, isSuccess: success);
}

// ── DATE FORMATTING ───────────────────────────────────────────────────────────

/// @deprecated Use [TimeUtils.formatDate] from `time_utils.dart` instead.
String formatDate(String date) => TimeUtils.formatDate(date);

// ── TEST NOTIFICATION ─────────────────────────────────────────────────────────

Widget buildTestNotificationTile(BuildContext context, bool isDarkMode) {
  return _TestNotificationTile(isDarkMode: isDarkMode);
}

class _TestNotificationTile extends StatefulWidget {
  final bool isDarkMode;
  const _TestNotificationTile({required this.isDarkMode});

  @override
  State<_TestNotificationTile> createState() => _TestNotificationTileState();
}

class _TestNotificationTileState extends State<_TestNotificationTile> {
  bool _isSending = false;

  Future<void> _sendTestNotification() async {
    final userId = SessionService.currentUserId;
    if (userId == null) {
      if (mounted) {
        showAppSnackBar(context, message: 'Not logged in', isSuccess: false);
      }
      return;
    }

    setState(() => _isSending = true);

    try {
      // 1) Fire immediate local notification to verify local push works
      await LocalNotificationService.show(
        title: 'Test Notification',
        body: 'If you see this, local notifications are working!',
        payload: 'test_notification',
      );

      // 2) Create a real notification in Supabase targeting self
      //    This tests the full pipeline: DB insert → push outbox → OneSignal
      await NotificationService.createNotification(
        type: 'test_notification',
        title: 'Test Push Notification',
        body:
            'This test notification was sent at ${TimeOfDay.now().format(context)}. '
            'If you see this in the notification tray, push delivery is working!',
        targetType: 'USER',
        targetValue: userId,
        metadata: {
          'test': true,
          'sent_at': DateTime.now().toIso8601String(),
        },
      );

      if (mounted) {
        showAppSnackBar(
          context,
          message: 'Test notification sent! Check your notification tray.',
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          message: 'Failed to send test notification: $e',
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _isSending ? null : _sendTestNotification,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _isSending
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(
                      Icons.notifications_active_outlined,
                      size: 18,
                      color: Colors.orange,
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Send Test Notification',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary(widget.isDarkMode),
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

// ── CLASS REMINDER TIME SETTING ───────────────────────────────────────────────

Widget buildReminderTimeTile(BuildContext context, bool isDarkMode) {
  return _ReminderTimeTile(isDarkMode: isDarkMode);
}

class _ReminderTimeTile extends StatefulWidget {
  final bool isDarkMode;
  const _ReminderTimeTile({required this.isDarkMode});

  @override
  State<_ReminderTimeTile> createState() => _ReminderTimeTileState();
}

class _ReminderTimeTileState extends State<_ReminderTimeTile> {
  int _leadMinutes = ClassReminderService.defaultLeadMinutes;

  @override
  void initState() {
    super.initState();
    _loadValue();
  }

  Future<void> _loadValue() async {
    final val = await ClassReminderService.getLeadMinutes();
    if (mounted) setState(() => _leadMinutes = val);
  }

  Future<void> _showPicker() async {
    final options = [5, 10, 15, 20, 30, 45, 60];
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.surface(widget.isDarkMode),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border(widget.isDarkMode),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Reminder Before Class',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(widget.isDarkMode),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Get notified before each class starts',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary(widget.isDarkMode),
                ),
              ),
              const SizedBox(height: 16),
              ...options.map((min) {
                final isSelected = min == _leadMinutes;
                return ListTile(
                  leading: Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: isSelected ? AppColors.primary : AppColors.textMuted,
                  ),
                  title: Text(
                    '$min minutes before',
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: AppColors.textPrimary(widget.isDarkMode),
                    ),
                  ),
                  onTap: () => Navigator.pop(ctx, min),
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );

    if (picked != null && picked != _leadMinutes) {
      setState(() => _leadMinutes = picked);
      await ClassReminderService.setLeadMinutes(picked);
      // Re-schedule all reminders with new lead time
      await ClassReminderService.syncTodayReminders();
      if (mounted) {
        showAppSnackBar(
          context,
          message: 'Reminder set to $picked minutes before class',
          isSuccess: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _showPicker,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.alarm,
                size: 18,
                color: AppColors.teal,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Class Reminder',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary(widget.isDarkMode),
                    ),
                  ),
                  Text(
                    '$_leadMinutes min before class',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary(widget.isDarkMode),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
