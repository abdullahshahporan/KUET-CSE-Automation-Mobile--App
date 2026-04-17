import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/push_config.dart';
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
  static const Duration _reminderResyncInterval = Duration(minutes: 60);
  static const Duration _foregroundFallbackPollInterval = Duration(minutes: 2);
  static const Duration _foregroundHealthPollInterval = Duration(minutes: 10);
  static const Duration _backgroundContextResyncInterval = Duration(hours: 6);

  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;
  Timer? _reminderSyncTimer;
  Timer? _notificationSyncTimer;
  Timer? _realtimeRefreshDebounceTimer;
  bool _isFetchingNotifications = false;
  bool _queuedNotifyForNew = false;
  String? _initializedUserId;
  DateTime? _lastBackgroundContextSyncAt;
  final Set<String> _alertedNotificationIds = <String>{};

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get hasUnread => _unreadCount > 0;
  bool get _shouldUseFallbackBackgroundSync =>
      !PushConfig.hasRemotePushCredentials;
  bool get _shouldShowFallbackLocalAlerts =>
      !PushConfig.hasRemotePushCredentials;

  // ── Initialize: load + subscribe to realtime ───────────────

  Future<void> initialize() async {
    final userId = SessionService.currentUserId;
    if (userId == null) return;

    final sameUser = _initializedUserId == userId;
    if (sameUser && _reminderSyncTimer != null) {
      unawaited(_loadNotifications(silent: true));
      await _ensureBackgroundSyncState(
        userId: userId,
        forceContextRefresh: false,
      );
      return;
    }

    _initializedUserId = userId;
    if (!sameUser) {
      _alertedNotificationIds.clear();
    }

    await LocalNotificationService.initialize();
    await LocalNotificationService.ensureReminderPermissions();
    await _loadNotifications();
    await Future.wait<void>([
      ClassReminderService.syncTodayReminders(),
      ExamReminderService.syncUpcomingReminders(),
    ]);

    _reminderSyncTimer?.cancel();
    _reminderSyncTimer = Timer.periodic(_reminderResyncInterval, (_) {
      unawaited(ClassReminderService.syncTodayReminders());
      unawaited(ExamReminderService.syncUpcomingReminders());
    });

    _notificationSyncTimer?.cancel();
    final pollInterval = _shouldUseFallbackBackgroundSync
        ? _foregroundFallbackPollInterval
        : _foregroundHealthPollInterval;
    _notificationSyncTimer = Timer.periodic(pollInterval, (_) {
      unawaited(
        _loadNotifications(
          silent: true,
          notifyForNew: _shouldUseFallbackBackgroundSync,
        ),
      );
    });

    _subscribeRealtime();
    await _ensureBackgroundSyncState(
      userId: userId,
      forceContextRefresh: !sameUser,
    );
  }

  /// Fetch user profile + enrollment data and persist to SharedPreferences
  /// so the background isolate can filter notifications correctly.
  Future<void> _syncBackgroundUserContext(String userId) async {
    try {
      final profile = await SupabaseCore.from(
        'profiles',
      ).select('role').eq('user_id', userId).maybeSingle();

      final student = await SupabaseCore.from(
        'students',
      ).select('term, section').eq('user_id', userId).maybeSingle();

      final String? role = profile?['role'] as String?;
      final String? term = student?['term'] as String?;
      final String? section = student?['section'] as String?;

      // Build enrolled course codes (for students and teachers)
      List<String> enrolledCodes = [];
      if (term != null) {
        final offerings = await SupabaseCore.from(
          'course_offerings',
        ).select('courses!inner(code)').eq('term', term);
        enrolledCodes.addAll(
          (offerings as List).map((o) {
            final courses = o['courses'] as Map<String, dynamic>?;
            return courses?['code'] as String?;
          }).whereType<String>(),
        );
      }

      // For teachers, also include courses they teach
      if (role?.toUpperCase() == 'TEACHER') {
        final teacherOfferings = await SupabaseCore.from(
          'course_offerings',
        ).select('courses!inner(code)').eq('teacher_user_id', userId);
        enrolledCodes.addAll(
          (teacherOfferings as List).map((o) {
            final courses = o['courses'] as Map<String, dynamic>?;
            return courses?['code'] as String?;
          }).whereType<String>(),
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
          final session = Supabase.instance.client.auth.currentSession;
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
    if (_isFetchingNotifications) {
      _queuedNotifyForNew = _queuedNotifyForNew || notifyForNew;
      return;
    }
    _isFetchingNotifications = true;

    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final previousIds = _notifications.map((n) => n.id).toSet();
      final list = await NotificationService.fetchNotifications(
        limit: silent ? 40 : 80,
      );

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
          if (_shouldShowFallbackLocalAlerts &&
              !_silentLocalAlertTypes.contains(notification.type)) {
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
      _isFetchingNotifications = false;
      _isLoading = false;
      notifyListeners();

      final runQueuedLoad = _queuedNotifyForNew;
      _queuedNotifyForNew = false;
      if (runQueuedLoad) {
        unawaited(_loadNotifications(silent: true, notifyForNew: true));
      }
    }
  }

  // ── Public: refresh ────────────────────────────────────────

  Future<void> refresh() => _loadNotifications();

  // ── Internal: realtime new notification ───────────────────

  void _subscribeRealtime() {
    NotificationService.subscribe((newNotif) {
      _realtimeRefreshDebounceTimer?.cancel();
      _realtimeRefreshDebounceTimer = Timer(
        const Duration(milliseconds: 1200),
        () => unawaited(_loadNotifications(silent: true, notifyForNew: true)),
      );
      debugPrint('[Notifications] New: ${newNotif.title}');
    });
  }

  Future<void> _ensureBackgroundSyncState({
    required String userId,
    required bool forceContextRefresh,
  }) async {
    if (!_shouldUseFallbackBackgroundSync) {
      await BackgroundNotificationService.stop();
      return;
    }

    final now = DateTime.now();
    final needsContextRefresh =
        forceContextRefresh ||
        _lastBackgroundContextSyncAt == null ||
        now.difference(_lastBackgroundContextSyncAt!) >=
            _backgroundContextResyncInterval;

    if (needsContextRefresh) {
      await _syncBackgroundUserContext(userId);
      _lastBackgroundContextSyncAt = now;
    }

    await BackgroundNotificationService.start();
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
    _realtimeRefreshDebounceTimer?.cancel();
    _isFetchingNotifications = false;
    _queuedNotifyForNew = false;
    _initializedUserId = null;
    _lastBackgroundContextSyncAt = null;
    NotificationService.unsubscribe();
    unawaited(BackgroundNotificationService.stop());
    super.dispose();
  }
}
