import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/background_notification_service.dart';
import '../services/class_reminder_service.dart';
import '../services/exam_reminder_service.dart';
import '../services/local_notification_service.dart';
import '../services/notification_service.dart';
import '../services/session_service.dart';
import '../services/supabase_core.dart';

// ─────────────────────────────────────────────────────────────
// NotificationProvider  — ChangeNotifier-based state
//
// Usage:
//   ChangeNotifierProvider(create: (_) => NotificationProvider())
//   Consumer<NotificationProvider>(builder: (ctx, p, _) => ...)
// ─────────────────────────────────────────────────────────────

class NotificationProvider extends ChangeNotifier {
  // No notification types are silenced — every type (including geo attendance)
  // shows a system pop-up so students get push-style alerts like Facebook.
  static const Set<String> _silentLocalAlertTypes = <String>{};

  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;
  Timer? _reminderSyncTimer;
  Timer? _notificationSyncTimer;
  final Set<String> _alertedNotificationIds = <String>{};

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get hasUnread => _unreadCount > 0;

  // ── Initialize: load + subscribe to realtime ───────────────

  Future<void> initialize() async {
    final userId = SessionService.currentUserId;
    if (userId == null) return;
    await LocalNotificationService.initialize();
    await _loadNotifications();
    await ClassReminderService.syncTodayReminders();
    await ExamReminderService.syncUpcomingReminders();
    _reminderSyncTimer?.cancel();
    _reminderSyncTimer = Timer.periodic(const Duration(minutes: 20), (_) {
      ClassReminderService.syncTodayReminders();
      ExamReminderService.syncUpcomingReminders();
    });

    _notificationSyncTimer?.cancel();
    _notificationSyncTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _loadNotifications(silent: true, notifyForNew: true);
    });

    _subscribeRealtime();

    // Save user context for background isolate and start background service
    await _syncBackgroundUserContext(userId);
    await BackgroundNotificationService.start();
  }

  /// Fetch user profile + enrollment data and persist to SharedPreferences
  /// so the background isolate can filter notifications correctly.
  Future<void> _syncBackgroundUserContext(String userId) async {
    try {
      final profile = await SupabaseCore.from('profiles')
          .select('role')
          .eq('user_id', userId)
          .maybeSingle();

      final student = await SupabaseCore.from('students')
          .select('term, section')
          .eq('user_id', userId)
          .maybeSingle();

      final String? role = profile?['role'] as String?;
      final String? term = student?['term'] as String?;
      final String? section = student?['section'] as String?;

      // Build enrolled course codes (for students and teachers)
      List<String> enrolledCodes = [];
      if (term != null) {
        final offerings = await SupabaseCore.from('course_offerings')
            .select('courses!inner(code)')
            .eq('term', term);
        enrolledCodes.addAll(
          (offerings as List)
              .map((o) {
                final courses = o['courses'] as Map<String, dynamic>?;
                return courses?['code'] as String?;
              })
              .whereType<String>(),
        );
      }

      // For teachers, also include courses they teach
      if (role?.toUpperCase() == 'TEACHER') {
        final teacherOfferings = await SupabaseCore.from('course_offerings')
            .select('courses!inner(code)')
            .eq('teacher_user_id', userId);
        enrolledCodes.addAll(
          (teacherOfferings as List)
              .map((o) {
                final courses = o['courses'] as Map<String, dynamic>?;
                return courses?['code'] as String?;
              })
              .whereType<String>(),
        );
      }

      await BackgroundNotificationService.saveUserContext(
        userId: userId,
        role: role,
        term: term,
        section: section,
        enrolledCodes: enrolledCodes,
        // Pass the current Supabase session so the background isolate can
        // authenticate its own SupabaseClient and read RLS-protected rows.
        sessionJson: () {
          final session =
              Supabase.instance.client.auth.currentSession;
          if (session == null) return null;
          return jsonEncode(session.toJson());
        }(),
      );
    } catch (e) {
      debugPrint('[NotificationProvider] _syncBackgroundUserContext error: $e');
    }
  }

  // ── Internal: load from Supabase ──────────────────────────

  Future<void> _loadNotifications({
    bool silent = false,
    bool notifyForNew = false,
  }) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final previousIds = _notifications.map((n) => n.id).toSet();
      final list = await NotificationService.fetchNotifications(limit: 80);

      if (notifyForNew) {
        final newUnread = list
            .where(
              (n) =>
                  !n.isRead &&
                  !previousIds.contains(n.id) &&
                  !_alertedNotificationIds.contains(n.id),
            )
            .toList();

        for (final notification in newUnread) {
          await NotificationService.saveLocalInboxNotification(
            id: notification.id,
            type: notification.type,
            title: notification.title,
            body: notification.body,
            targetType: notification.targetType,
            targetValue: notification.targetValue,
            targetYearTerm: notification.targetYearTerm,
            metadata: {
              ...notification.metadata,
              'server_notification_id': notification.id,
            },
            createdAt: notification.createdAt,
            isRead: notification.isRead,
          );
          // Show a real local push notification so the user sees it immediately,
          // even if OneSignal push delivery is delayed or fails.
          // _alertedNotificationIds prevents duplicates across polling ticks.
          if (!_silentLocalAlertTypes.contains(notification.type)) {
            await LocalNotificationService.show(
              title: notification.title,
              body: notification.body,
              payload: notification.id,
            );
          }
          _alertedNotificationIds.add(notification.id);
        }

        if (newUnread.any(
          (n) =>
              n.type == 'class_rescheduled' ||
              n.type == 'class_cancelled' ||
              n.type == 'makeup_class',
        )) {
          await ClassReminderService.syncTodayReminders();
        }

        if (newUnread.any(
          (n) => n.type == 'exam_scheduled' || n.type == 'exam_room_assigned',
        )) {
          await ExamReminderService.syncUpcomingReminders();
        }
      }

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
      await _loadNotifications(silent: true, notifyForNew: true);
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
    _notificationSyncTimer?.cancel();
    NotificationService.unsubscribe();
    BackgroundNotificationService.stop();
    super.dispose();
  }
}
