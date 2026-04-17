import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../Student Folder/Attendance/student_geo_attendance_screen.dart';
import '../config/push_config.dart';
import '../shared/notification_screen.dart';
import 'session_service.dart';

class PushNotificationService {
  PushNotificationService._();

  static const String _androidAlertChannelId = 'kuet_notifications';
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static bool _initialized = false;
  static bool _listenersRegistered = false;
  static bool _appReadyForNavigation = false;
  static _PushNavigationRequest? _pendingNavigation;

  static Future<void> initialize() async {
    final appId = PushConfig.oneSignalAppId.trim();
    if (appId.isEmpty) {
      debugPrint(
        '[PushNotificationService] OneSignal App ID missing; push disabled.',
      );
      return;
    }

    await PushConfig.initialize();
    _registerListeners();
    _initialized = true;

    await syncUserIdentity();
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
        if (SessionService.currentRole == 'TEACHER') return;
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
    if (!_initialized) return;

    final userId = SessionService.currentUserId;
    final role = SessionService.currentRole;

    if (userId == null || userId.isEmpty) {
      await OneSignal.logout();
      return;
    }

    await OneSignal.login(userId);

    if (role != null && role.trim().isNotEmpty) {
      await OneSignal.User.addTags({'role': role.trim().toUpperCase()});
    }
  }

  static Future<void> clearUserIdentity() async {
    if (!_initialized) return;

    _pendingNavigation = null;
    _appReadyForNavigation = false;
    await OneSignal.logout();
  }

  static Future<void> sendNotificationToUsers({
    required List<String> userIds,
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
    String? collapseId,
  }) async {
    final recipients = userIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    if (recipients.isEmpty) return;

    if (!PushConfig.hasRemotePushCredentials) {
      debugPrint(
        '[PushNotificationService] Missing OneSignal REST API key; '
        'skipping remote push for "$title".',
      );
      return;
    }

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20);

    try {
      for (final batch in _chunkRecipients(recipients, 200)) {
        final payload = <String, dynamic>{
          'app_id': PushConfig.oneSignalAppId,
          'target_channel': 'push',
          'include_aliases': {'external_id': batch},
          'headings': {'en': title},
          'contents': {'en': body},
          'data': data,
          // Route all Android pushes through our vibration-enabled channel.
          'android_channel_id': _androidAlertChannelId,
          'android_sound': 'default',
          'priority': 10,
          if (collapseId != null && collapseId.trim().isNotEmpty)
            'collapse_id': collapseId.trim(),
        };

        final request = await client.postUrl(
          Uri.parse(PushConfig.oneSignalNotificationsApiUrl),
        );
        request.headers.set(
          HttpHeaders.authorizationHeader,
          'Key ${PushConfig.oneSignalRestApiKey}',
        );
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(payload));

        final response = await request.close();
        final responseBody = await utf8.decodeStream(response);
        if (response.statusCode < 200 || response.statusCode >= 300) {
          debugPrint(
            '[PushNotificationService] Remote push failed '
            '(${response.statusCode}): $responseBody',
          );
        }
      }
    } catch (e) {
      debugPrint('[PushNotificationService] sendNotificationToUsers error: $e');
    } finally {
      client.close(force: true);
    }
  }

  static void _registerListeners() {
    if (_listenersRegistered) return;

    OneSignal.Notifications.addClickListener(_handleNotificationClick);
    OneSignal.Notifications.addForegroundWillDisplayListener(
      _handleForegroundNotification,
    );
    _listenersRegistered = true;
  }

  static void _handleForegroundNotification(
    OSNotificationWillDisplayEvent event,
  ) {
    // Display the push notification banner even when the app is in the foreground
    event.notification.display();
  }

  static void _handleNotificationClick(OSNotificationClickEvent event) {
    final request = _PushNavigationRequest.fromAdditionalData(
      event.notification.additionalData,
    );
    if (request == null) return;

    _pendingNavigation = request;
    if (_appReadyForNavigation) {
      unawaited(flushPendingNavigation());
    }
  }

  static List<List<String>> _chunkRecipients(
    List<String> recipients,
    int size,
  ) {
    final chunks = <List<String>>[];
    for (var index = 0; index < recipients.length; index += size) {
      final end = (index + size < recipients.length)
          ? index + size
          : recipients.length;
      chunks.add(recipients.sublist(index, end));
    }
    return chunks;
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

  static _PushNavigationRequest? fromAdditionalData(
    Map<String, dynamic>? data,
  ) {
    final type =
        _readString(data, 'type') ?? _readString(data, 'notification_type');
    final openScreen = _readString(data, 'open_screen');

    // Geo-attendance: open attendance submission screen directly
    if (type == 'geo_attendance_open' ||
        openScreen == 'student_geo_attendance') {
      return _PushNavigationRequest.studentGeoAttendance();
    }

    // All other notification types (announcement, room_allocated,
    // notice_posted, exam_scheduled, assignment_due, class_rescheduled,
    // class_cancelled, makeup_class, term_upgrade, optional_course, …)
    // → open the notification inbox so users see all details.
    // Also open inbox when no type is present (generic FCM tap).
    return _PushNavigationRequest.notificationInbox();
  }

  static String? _readString(Map<String, dynamic>? data, String key) {
    final raw = data?[key]?.toString().trim();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }
}
