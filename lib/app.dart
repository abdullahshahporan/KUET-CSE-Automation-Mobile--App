import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kuet_cse_automation/Student%20Folder/Common%20Screen/splash_screen.dart';
import 'package:kuet_cse_automation/app_theme.dart';
import 'package:kuet_cse_automation/services/notification_provider.dart';
import 'package:kuet_cse_automation/services/push_notification_service.dart';
import 'package:provider/provider.dart' as provider;

class CSEApp extends StatelessWidget {
  const CSEApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: provider.MultiProvider(
        providers: [
          provider.ChangeNotifierProvider(create: (_) => ThemeProvider()),
          provider.ChangeNotifierProvider(
            create: (_) => NotificationProvider(),
          ),
        ],
        child: provider.Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'KUET CSE',
              navigatorKey: PushNotificationService.navigatorKey,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.isDarkMode
                  ? ThemeMode.dark
                  : ThemeMode.light,
              home: const SplashScreen(),
            );
          },
        ),
      ),
    );
  }
}
