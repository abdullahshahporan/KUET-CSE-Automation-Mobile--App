import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:functions_client/functions_client.dart';
import 'package:flutter/material.dart';

import '../Student Folder/Attendance/student_geo_attendance_screen.dart';
import '../config/push_config.dart';
import '../shared/notification_screen.dart';
import 'local_notification_service.dart';
import 'session_service.dart';
import 'supabase_core.dart';

@pragma('vm:entry-point')
Future<void> kuetFirebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    debugPrint('[FCM] Background message: ${message.messageId}');
  } catch (e) {
    debugPrint('[FCM] Background handler error: $e');
  }
}

class PushNotificationService {
  PushNotificationService._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static bool _initialized = false;
  static bool _listenersRegistered = false;
  static bool _appReadyForNavigation = false;
  static String? _lastRegisteredToken;
  static StreamSubscription<String>? _tokenRefreshSubscription;
  static _PushNavigationRequest? _pendingNavigation;
  static const Duration _recentHandledTtl = Duration(seconds: 20);
  static final Map<String, DateTime> _recentHandledNotificationIds =
      <String, DateTime>{};

  static Future<void> initialize() async {
    if (!PushConfig.enableFcmPush) return;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      FirebaseMessaging.onBackgroundMessage(
        kuetFirebaseMessagingBackgroundHandler,
      );

      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );

      _registerListeners();
      _initialized = true;

      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null) {
        _queueNavigation(initialMessage.data);
      }

      await syncUserIdentity();
    } catch (e) {
      debugPrint('[PushNotificationService] FCM initialization error: $e');
    }
  }

  static void markAppReady() {
    _appReadyForNavigation = true;
    unawaited(flushPendingNavigation());
  }

  static void markAppNotReady() {
    _appReadyForNavigation = false;
  }

  static Future<void> flushPendingNavigation() async {
    if (!_appReadyForNavigation) return;

    final navigator = navigatorKey.currentState;
    final request = _pendingNavigation;

    if (navigator == null || request == null || !SessionService.isLoggedIn) {
      return;
    }

    _pendingNavigation = null;

    switch (request.type) {
      case _PushNavigationType.studentGeoAttendance:
        final role = SessionService.currentRole;
        if (role == 'TEACHER' || role == 'HEAD') return;
        await navigator.push(
          MaterialPageRoute(builder: (_) => const StudentGeoAttendanceScreen()),
        );
      case _PushNavigationType.notificationInbox:
        await navigator.push(
          MaterialPageRoute(builder: (_) => const NotificationScreen()),
        );
    }
  }

  static Future<void> syncUserIdentity() async {
    if (!_initialized || !PushConfig.enableFcmPush) return;

    final userId = SessionService.currentUserId;
    if (userId == null || userId.isEmpty) {
      await clearUserIdentity();
      return;
    }

    await _registerCurrentFcmToken(userId);

    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh
        .listen(
          (token) {
            unawaited(_saveFcmToken(userId: userId, token: token));
          },
          onError: (Object error) {
            debugPrint('[PushNotificationService] token refresh error: $error');
          },
        );
  }

  static Future<void> clearUserIdentity() async {
    _pendingNavigation = null;
    _appReadyForNavigation = false;
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;

    final userId = SessionService.currentUserId;
    final token = _lastRegisteredToken;
    if (userId == null || token == null) return;

    try {
      await SupabaseCore.from('device_push_tokens')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('provider', 'fcm')
          .eq('token', token);
    } catch (e) {
      debugPrint('[PushNotificationService] clear token error: $e');
    }
  }

  static Future<void> dispatchNotification(String notificationId) async {
    if (notificationId.trim().isEmpty) return;

    try {
      final headers = <String, String>{};
      final dispatchKey = PushConfig.notificationDispatchKey.trim();
      if (dispatchKey.isNotEmpty) {
        headers['x-notification-dispatch-key'] = dispatchKey;
      }
      final response = await SupabaseCore.client.functions.invoke(
        PushConfig.supabaseEdgeFunctionName,
        headers: headers.isEmpty ? null : headers,
        body: {'notification_id': notificationId},
      );
      final payload = response.data;
      final hasExplicitFailure = payload is Map && payload['success'] == false;
      if (response.status >= 400 || hasExplicitFailure) {
        debugPrint(
          '[PushNotificationService] edge dispatch failed '
          '(${response.status}): $payload',
        );
      }
    } on FunctionException catch (e) {
      if (e.status == 401 &&
          PushConfig.notificationDispatchKey.trim().isEmpty) {
        debugPrint(
          '[PushNotificationService] edge dispatch unauthorized. '
          'If the edge function uses NOTIFICATION_DISPATCH_KEY, set '
          'PushConfig.notificationDispatchKey or move dispatch behind a '
          'trusted backend.',
        );
      }
      debugPrint(
        '[PushNotificationService] edge dispatch error '
        '(${e.status}): ${e.details ?? e.reasonPhrase}',
      );
    } catch (e) {
      debugPrint('[PushNotificationService] edge dispatch error: $e');
    }
  }

  static Future<void> sendNotificationToUsers({
    required List<String> userIds,
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
    String? collapseId,
  }) async {
    debugPrint(
      '[PushNotificationService] Direct client push is disabled. '
      'Create a Supabase notification row and dispatch it server-side.',
    );
  }

  static void _registerListeners() {
    if (_listenersRegistered) return;

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _queueNavigation(message.data);
    });
    _listenersRegistered = true;
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    _rememberHandledNotification(message.data['notification_id']?.toString());
    final title =
        message.notification?.title ?? message.data['title']?.toString();
    final body = message.notification?.body ?? message.data['body']?.toString();

    if (title != null && body != null) {
      await LocalNotificationService.show(
        title: title,
        body: body,
        payload: message.data['notification_id']?.toString(),
      );
    }
  }

  static void _queueNavigation(Map<String, dynamic> data) {
    _rememberHandledNotification(data['notification_id']?.toString());
    final request = _PushNavigationRequest.fromData(data);
    if (request == null) return;

    _pendingNavigation = request;
    if (_appReadyForNavigation) {
      unawaited(flushPendingNavigation());
    }
  }

  static Future<void> _registerCurrentFcmToken(String userId) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.trim().isEmpty) return;
      await _saveFcmToken(userId: userId, token: token);
    } catch (e) {
      debugPrint('[PushNotificationService] get token error: $e');
    }
  }

  static Future<void> _saveFcmToken({
    required String userId,
    required String token,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final row = {
      'user_id': userId,
      'platform': Platform.isAndroid ? 'android' : Platform.operatingSystem,
      'provider': 'fcm',
      'token': token,
      'is_active': true,
      'last_seen_at': now,
      'updated_at': now,
      'device_info': {
        'os': Platform.operatingSystem,
        'os_version': Platform.operatingSystemVersion,
      },
    };

    try {
      await SupabaseCore.from(
        'device_push_tokens',
      ).upsert(row, onConflict: 'token');
      _lastRegisteredToken = token;
    } catch (e) {
      debugPrint('[PushNotificationService] token upsert fallback: $e');
      await _saveFcmTokenWithoutUniqueIndex(row, token);
    }
  }

  static Future<void> _saveFcmTokenWithoutUniqueIndex(
    Map<String, Object?> row,
    String token,
  ) async {
    try {
      final existing = await SupabaseCore.from(
        'device_push_tokens',
      ).select('id').eq('token', token).eq('provider', 'fcm').maybeSingle();

      if (existing != null) {
        await SupabaseCore.from(
          'device_push_tokens',
        ).update(row).eq('id', existing['id']);
      } else {
        await SupabaseCore.from('device_push_tokens').insert(row);
      }
      _lastRegisteredToken = token;
    } catch (e) {
      debugPrint('[PushNotificationService] save token error: $e');
    }
  }

  static bool hasRecentlyHandledNotification(String? notificationId) {
    _cleanupRecentlyHandledNotifications();
    final normalized = notificationId?.trim();
    if (normalized == null || normalized.isEmpty) return false;
    return _recentHandledNotificationIds.containsKey(normalized);
  }

  static void _rememberHandledNotification(String? notificationId) {
    final normalized = notificationId?.trim();
    if (normalized == null || normalized.isEmpty) return;
    _cleanupRecentlyHandledNotifications();
    _recentHandledNotificationIds[normalized] = DateTime.now();
  }

  static void _cleanupRecentlyHandledNotifications() {
    if (_recentHandledNotificationIds.isEmpty) return;

    final now = DateTime.now();
    final expired = _recentHandledNotificationIds.entries
        .where((entry) => now.difference(entry.value) > _recentHandledTtl)
        .map((entry) => entry.key)
        .toList();
    for (final key in expired) {
      _recentHandledNotificationIds.remove(key);
    }
  }
}

enum _PushNavigationType { studentGeoAttendance, notificationInbox }

class _PushNavigationRequest {
  final _PushNavigationType type;

  const _PushNavigationRequest._(this.type);

  factory _PushNavigationRequest.studentGeoAttendance() =>
      const _PushNavigationRequest._(_PushNavigationType.studentGeoAttendance);

  factory _PushNavigationRequest.notificationInbox() =>
      const _PushNavigationRequest._(_PushNavigationType.notificationInbox);

  static _PushNavigationRequest? fromData(Map<String, dynamic>? data) {
    final type =
        _readString(data, 'type') ?? _readString(data, 'notification_type');
    final openScreen =
        _readString(data, 'open_screen') ?? _readString(data, 'target_screen');

    if (type == 'geo_attendance_open' ||
        openScreen == 'student_geo_attendance') {
      return _PushNavigationRequest.studentGeoAttendance();
    }

    return _PushNavigationRequest.notificationInbox();
  }

  static String? _readString(Map<String, dynamic>? data, String key) {
    final raw = data?[key]?.toString().trim();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }
}
