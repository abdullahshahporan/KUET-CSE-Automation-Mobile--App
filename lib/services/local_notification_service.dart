import 'dart:math';
import 'dart:ui';

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

  // High-priority channel — used for all in-app alerts
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'kuet_notifications',
    'KUET Notifications',
    description: 'Real-time department updates and alerts',
    importance: Importance.high,
    enableVibration: true,
    enableLights: true,
    ledColor: Color(0xFF6366F1), // indigo — matches app primary
    playSound: true,
    showBadge: true,
  );

  // Reminder-specific channel (lower priority)
  static const AndroidNotificationChannel _reminderChannel =
      AndroidNotificationChannel(
    'kuet_reminders',
    'Class & Exam Reminders',
    description: 'Scheduled class and exam reminders',
    importance: Importance.high,
    enableVibration: true,
    enableLights: true,
    ledColor: Color(0xFF0EA5E9), // cyan
    playSound: true,
    showBadge: true,
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
    await androidImpl?.createNotificationChannel(_reminderChannel);

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
          enableVibration: true,
          enableLights: true,
          ledColor: const Color(0xFF6366F1),
          ledOnMs: 1000,
          ledOffMs: 500,
          color: const Color(0xFF6366F1),
          playSound: true,
          // Show heads-up notification even on lock screen
          fullScreenIntent: true,
          visibility: NotificationVisibility.public,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
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
          _reminderChannel.id,
          _reminderChannel.name,
          channelDescription: _reminderChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,
          enableLights: true,
          ledColor: const Color(0xFF0EA5E9),
          ledOnMs: 1000,
          ledOffMs: 500,
          color: const Color(0xFF6366F1),
          playSound: true,
          visibility: NotificationVisibility.public,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _plugin.zonedSchedule(
        id,
        '$rolePrefix: $courseCode in $leadMinutes min',
        '$courseTitle at $classTime, Room $room$sectionText',
        tz.TZDateTime.from(reminderAt, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
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
          _reminderChannel.id,
          _reminderChannel.name,
          channelDescription: _reminderChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,
          enableLights: true,
          ledColor: const Color(0xFF0EA5E9),
          ledOnMs: 1000,
          ledOffMs: 500,
          color: const Color(0xFF6366F1),
          playSound: true,
          visibility: NotificationVisibility.public,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _plugin.zonedSchedule(
        id,
        'Exam reminder: $courseCode in $leadMinutes min',
        '$examLabel at $examTime, Room $room',
        tz.TZDateTime.from(reminderAt, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
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
