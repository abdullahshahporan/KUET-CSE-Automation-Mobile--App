import 'package:flutter/material.dart';
import 'package:kuet_cse_automation/app.dart';
import 'services/local_notification_service.dart';
import 'services/push_notification_service.dart';
import 'services/supabase_service.dart';
import 'config/supabase_config.dart';

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
  await PushNotificationService.initialize();

  runApp(CSEApp());
}
