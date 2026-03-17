import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../config/push_config.dart';
import 'session_service.dart';

class PushNotificationService {
  PushNotificationService._();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) {
      await syncUserIdentity();
      return;
    }

    final appId = PushConfig.oneSignalAppId.trim();
    if (appId.isEmpty) {
      debugPrint('[PushNotificationService] OneSignal App ID missing; push disabled.');
      return;
    }

    OneSignal.initialize(appId);
    await OneSignal.Notifications.requestPermission(true);
    _initialized = true;

    await syncUserIdentity();
  }

  static Future<void> syncUserIdentity() async {
    if (!_initialized) return;

    final userId = SessionService.currentUserId;
    if (userId == null || userId.isEmpty) {
      OneSignal.logout();
      return;
    }

    OneSignal.login(userId);
  }

  static Future<void> clearUserIdentity() async {
    if (!_initialized) return;
    OneSignal.logout();
  }
}
