import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/class_reminder_service.dart';
import '../services/local_notification_service.dart';
import '../services/notification_service.dart';
import '../services/session_service.dart';

// ─────────────────────────────────────────────────────────────
// NotificationProvider  — ChangeNotifier-based state
//
// Usage:
//   ChangeNotifierProvider(create: (_) => NotificationProvider())
//   Consumer<NotificationProvider>(builder: (ctx, p, _) => ...)
// ─────────────────────────────────────────────────────────────

class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;
  Timer? _reminderSyncTimer;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get hasUnread => _unreadCount > 0;

  // ── Initialize: load + subscribe to realtime ───────────────

  Future<void> initialize() async {
    if (SessionService.currentUserId == null) return;
    await LocalNotificationService.initialize();
    await _loadNotifications();
    await ClassReminderService.syncTodayReminders();
    _reminderSyncTimer?.cancel();
    _reminderSyncTimer = Timer.periodic(const Duration(minutes: 20), (_) {
      ClassReminderService.syncTodayReminders();
    });
    _subscribeRealtime();
  }

  // ── Internal: load from Supabase ──────────────────────────

  Future<void> _loadNotifications({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final list = await NotificationService.fetchNotifications(limit: 80);
      _notifications = list;
      _unreadCount = list.where((n) => !n.isRead).length;
      _error = null;
    } catch (e) {
      _error = 'Failed to load notifications';
      debugPrint('[NotificationProvider] _loadNotifications error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Public: refresh ────────────────────────────────────────

  Future<void> refresh() => _loadNotifications();

  // ── Internal: realtime new notification ───────────────────

  void _subscribeRealtime() {
    NotificationService.subscribe((newNotif) async {
      // Only show local alert when this notification is newly visible to user.
      final latest = await NotificationService.fetchNotifications(limit: 1);
      final newest = latest.isNotEmpty ? latest.first : null;
      final alreadyHad = newest == null
          ? false
          : _notifications.any((n) => n.id == newest.id);

      if (newest != null && !alreadyHad && !newest.isRead) {
        await LocalNotificationService.show(
          title: newest.title,
          body: newest.body,
          payload: newest.id,
        );

        // If schedule changed, rebuild today's class reminders.
        if (newest.type == 'class_rescheduled' ||
            newest.type == 'class_cancelled' ||
            newest.type == 'makeup_class') {
          await ClassReminderService.syncTodayReminders();
        }
      }

      await _loadNotifications(silent: true);
      debugPrint('[Notifications] New: ${newNotif.title}');
    });
  }

  // ── Mark single notification as read ──────────────────────

  Future<void> markRead(String notificationId) async {
    await NotificationService.markAsRead([notificationId]);
    final idx = _notifications.indexWhere((n) => n.id == notificationId);
    if (idx >= 0 && !_notifications[idx].isRead) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      _unreadCount = (_unreadCount - 1).clamp(0, 9999);
      notifyListeners();
    }
  }

  // ── Mark all as read ──────────────────────────────────────

  Future<void> markAllRead() async {
    await NotificationService.markAllAsRead();
    _notifications = _notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    _unreadCount = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _reminderSyncTimer?.cancel();
    NotificationService.unsubscribe();
    super.dispose();
  }
}
