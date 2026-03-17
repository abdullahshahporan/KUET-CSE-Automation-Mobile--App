import 'package:onesignal_flutter/onesignal_flutter.dart';

class PushConfig {
  PushConfig._();

  static const String oneSignalAppId = '7297925c-05fc-4bff-a91a-e8fd85e027bd';

  static Future<void> initialize() async {
    OneSignal.initialize(oneSignalAppId);
    await OneSignal.Notifications.requestPermission(true);
  }

  static void loginUser(String externalId) {
    if (externalId.trim().isEmpty) return;
    OneSignal.login(externalId);
  }

  static void logoutUser() {
    OneSignal.logout();
  }
}
