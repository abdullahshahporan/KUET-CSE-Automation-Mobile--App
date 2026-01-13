import 'package:flutter/material.dart';
import 'package:kuet_cse_automation/Common%20Screen/splash_screen.dart';
import 'package:kuet_cse_automation/app_theme.dart';
import 'package:provider/provider.dart';

class CSEApp extends StatelessWidget {
  const CSEApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}