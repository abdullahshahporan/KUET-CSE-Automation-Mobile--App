import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Handles runtime notification permission and foreground local alerts.
class LocalNotificationService {
  LocalNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static bool _tzInitialized = false;
  static const _classReminderPayloadPrefix = 'class_reminder|';
  static const _examReminderPayloadPrefix = 'exam_reminder|';

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'kuet_notifications',
    'KUET Notifications',
    description: 'Real-time department updates and alerts',
    importance: Importance.high,
  );

  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);

    if (!_tzInitialized) {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));
      _tzInitialized = true;
    }

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(_channel);

    _initialized = true;
  }

  static Future<bool> requestPermission() async {
    try {
      final status = await Permission.notification.status;
      if (status.isGranted) return true;

      final result = await Permission.notification.request();
      return result.isGranted;
    } catch (e) {
      debugPrint('[LocalNotificationService] requestPermission error: $e');
      return false;
    }
  }

  static Future<void> show({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      if (!_initialized) await initialize();

      final status = await Permission.notification.status;
      if (!status.isGranted) return;

      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      );

      final id = Random().nextInt(1 << 31);
      await _plugin.show(id, title, body, details, payload: payload);
    } catch (e) {
      debugPrint('[LocalNotificationService] show error: $e');
    }
  }

  static Future<void> cancelClassReminders() async {
    try {
      if (!_initialized) await initialize();
      final pending = await _plugin.pendingNotificationRequests();
      for (final req in pending) {
        final payload = req.payload ?? '';
        if (payload.startsWith(_classReminderPayloadPrefix)) {
          await _plugin.cancel(req.id);
        }
      }
    } catch (e) {
      debugPrint('[LocalNotificationService] cancelClassReminders error: $e');
    }
  }

  static Future<void> cancelExamReminders() async {
    try {
      if (!_initialized) await initialize();
      final pending = await _plugin.pendingNotificationRequests();
      for (final req in pending) {
        final payload = req.payload ?? '';
        if (payload.startsWith(_examReminderPayloadPrefix)) {
          await _plugin.cancel(req.id);
        }
      }
    } catch (e) {
      debugPrint('[LocalNotificationService] cancelExamReminders error: $e');
    }
  }

  static Future<void> scheduleClassReminder({
    required String reminderKey,
    required DateTime classStartAt,
    required int leadMinutes,
    required String courseCode,
    required String courseTitle,
    required String room,
    required bool isTeacher,
    String? section,
  }) async {
    try {
      if (!_initialized) await initialize();

      final status = await Permission.notification.status;
      if (!status.isGranted) return;

      final reminderAt = classStartAt.subtract(Duration(minutes: leadMinutes));
      final now = DateTime.now();
      if (!reminderAt.isAfter(now)) return;

      final id = _stableNotificationId('class|$reminderKey|$leadMinutes');
      final classTime =
          '${classStartAt.hour.toString().padLeft(2, '0')}:${classStartAt.minute.toString().padLeft(2, '0')}';
      final rolePrefix = isTeacher ? 'Teacher reminder' : 'Class reminder';
      final sectionText = (section == null || section.isEmpty)
          ? ''
          : ', Section $section';

      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      );

      await _plugin.zonedSchedule(
        id,
        '$rolePrefix: $courseCode in $leadMinutes min',
        '$courseTitle at $classTime, Room $room$sectionText',
        tz.TZDateTime.from(reminderAt, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: '$_classReminderPayloadPrefix$reminderKey',
      );
    } catch (e) {
      debugPrint('[LocalNotificationService] scheduleClassReminder error: $e');
    }
  }

  static Future<void> scheduleExamReminder({
    required String reminderKey,
    required DateTime examStartsAt,
    required int leadMinutes,
    required String courseCode,
    required String examLabel,
    required String room,
  }) async {
    try {
      if (!_initialized) await initialize();

      final status = await Permission.notification.status;
      if (!status.isGranted) return;

      final reminderAt = examStartsAt.subtract(Duration(minutes: leadMinutes));
      final now = DateTime.now();
      if (!reminderAt.isAfter(now)) return;

      final id = _stableNotificationId('exam|$reminderKey|$leadMinutes');
      final examTime =
          '${examStartsAt.hour.toString().padLeft(2, '0')}:${examStartsAt.minute.toString().padLeft(2, '0')}';
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      );

      await _plugin.zonedSchedule(
        id,
        'Exam reminder: $courseCode in $leadMinutes min',
        '$examLabel at $examTime, Room $room',
        tz.TZDateTime.from(reminderAt, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: '$_examReminderPayloadPrefix$reminderKey',
      );
    } catch (e) {
      debugPrint('[LocalNotificationService] scheduleExamReminder error: $e');
    }
  }

  static int _stableNotificationId(String key) {
    var hash = 0;
    for (final rune in key.runes) {
      hash = ((hash * 31) + rune) & 0x7fffffff;
    }
    return hash;
  }
}
