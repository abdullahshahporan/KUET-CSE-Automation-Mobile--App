import 'package:flutter/material.dart';
import 'package:kuet_cse_automation/app.dart';

import 'config/push_config.dart';
import 'config/supabase_config.dart';
import 'services/background_notification_service.dart';
import 'services/local_notification_service.dart';
import 'services/push_notification_service.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase before running app
  await SupabaseService.initialize(
    supabaseUrl: SupabaseConfig.supabaseUrl,
    supabaseAnonKey: SupabaseConfig.supabaseAnonKey,
  );

  // Setup foreground notifications and request runtime notification permission.
  await LocalNotificationService.initialize();
  await LocalNotificationService.requestPermission();
  await PushConfig.initialize();
  await PushNotificationService.initialize();

  // Configure background notification polling service (started on login)
  await BackgroundNotificationService.initialize();

  runApp(CSEApp());
}
