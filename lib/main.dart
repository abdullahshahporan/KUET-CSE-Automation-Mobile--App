import 'package:flutter/material.dart';
import 'package:kuet_cse_automation/app.dart';
import 'package:app_links/app_links.dart';
import 'services/supabase_service.dart';
import 'config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase before running app
  await SupabaseService.initialize(
    supabaseUrl: SupabaseConfig.supabaseUrl,
    supabaseAnonKey: SupabaseConfig.supabaseAnonKey,
  );

  // Initialize deep link handling
  initDeepLinks();

  runApp(CSEApp());
}

/// Initialize deep link listener for email verification
void initDeepLinks() {
  final appLinks = AppLinks();

  // Listen for incoming deep links
  appLinks.uriLinkStream.listen((Uri uri) async {
    debugPrint('Deep link received: $uri');

    try {
      // Handle Supabase auth callback - this processes the verification token
      await SupabaseService.auth.getSessionFromUrl(uri);

      final session = SupabaseService.auth.currentSession;

      if (session != null) {
        debugPrint('Email verification successful! User logged in.');
        // The app will automatically navigate based on auth state
      }
    } catch (e) {
      debugPrint('Error handling deep link: $e');
    }
  });

  // Also check for initial link (app opened via link)
  appLinks.getInitialLink().then((Uri? uri) async {
    if (uri != null) {
      debugPrint('Initial deep link: $uri');
      try {
        await SupabaseService.auth.getSessionFromUrl(uri);
      } catch (e) {
        debugPrint('Error handling initial deep link: $e');
      }
    }
  });
}
