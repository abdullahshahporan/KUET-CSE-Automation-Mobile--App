import 'package:onesignal_flutter/onesignal_flutter.dart';

class PushConfig {
  PushConfig._();

  static const String oneSignalAppId = '7297925c-05fc-4bff-a91a-e8fd85e027bd';
  static const String oneSignalRestApiKey = 'os_v2_app_oklzexaf7rf77ki25d6ylybhxxsd3efp6lnewan4fxmeoaemkgzu6ivpi3akc2tht6ny2zeclkwsknupstgen3k7cjc76gaksfexyza';
  static const String oneSignalNotificationsApiUrl =
      'https://api.onesignal.com/notifications?c=push';
  static bool _initialized = false;

  static bool get hasRemotePushCredentials =>
      oneSignalAppId.trim().isNotEmpty && oneSignalRestApiKey.trim().isNotEmpty;

  static Future<void> initialize() async {
    if (_initialized) return;
    if (oneSignalAppId.trim().isEmpty) return;

    OneSignal.initialize(oneSignalAppId);
    await OneSignal.Notifications.requestPermission(true);
    _initialized = true;
  }

  static void loginUser(String externalId) {
    if (externalId.trim().isEmpty) return;
    OneSignal.login(externalId);
  }

  static void logoutUser() {
    OneSignal.logout();
  }
}