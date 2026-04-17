class PushConfig {
  PushConfig._();

  static const bool enableFcmPush = true;
  static const String supabaseEdgeFunctionName = 'send-push-notification';
  static const String notificationDispatchKey = '';

  static bool get hasRemotePushCredentials => enableFcmPush;

  static Future<void> initialize() async {}

  static void loginUser(String externalId) {}

  static void logoutUser() {}
}
