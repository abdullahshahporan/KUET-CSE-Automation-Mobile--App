import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme/app_colors.dart';

/// Design System Theme for KUET CSE Automation App
class AppTheme {
  // ── Mono text styles for data labels (course codes, times, room numbers) ──
  static TextStyle get monoStyle => GoogleFonts.ibmPlexMono(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
      );

  static TextStyle get monoLarge => GoogleFonts.ibmPlexMono(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
      );

  // Light Theme - Clean and modern
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.teal,
    scaffoldBackgroundColor: AppColors.lightBackground,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.lightSurface,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      iconTheme: const IconThemeData(color: Colors.black87),
      titleTextStyle: GoogleFonts.ibmPlexSans(
        color: Colors.black87,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.lightSurface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Color(0xFF78909C),
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
    cardTheme: CardThemeData(
      color: AppColors.lightSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.lightBorder),
      ),
    ),
    textTheme: GoogleFonts.ibmPlexSansTextTheme(
      const TextTheme(
        displayLarge: TextStyle(color: Color(0xFF1C1C1E), fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: Color(0xFF1C1C1E), fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: Color(0xFF1C1C1E), fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: Color(0xFF1C1C1E)),
        bodyMedium: TextStyle(color: Color(0xFF1C1C1E)),
        bodySmall: TextStyle(color: Color(0xFF71717A)),
      ),
    ),
    iconTheme: const IconThemeData(color: Colors.black87),
    dividerColor: AppColors.lightBorder,
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.primaryDark,
      surface: AppColors.lightSurface,
      error: AppColors.danger,
    ),
  );

  // Dark Theme - Pitch black with grey shadows
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blueGrey,
    scaffoldBackgroundColor: AppColors.darkBackground,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.darkSurface,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: GoogleFonts.ibmPlexSans(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkSurface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.darkNavUnselected,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
    cardTheme: CardThemeData(
      color: AppColors.darkSurfaceElevated,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.darkBorder),
      ),
    ),
    textTheme: GoogleFonts.ibmPlexSansTextTheme(
      const TextTheme(
        displayLarge: TextStyle(color: Color(0xFFF5F5F5), fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: Color(0xFFF5F5F5), fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: Color(0xFFF5F5F5), fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: Color(0xFFF5F5F5)),
        bodyMedium: TextStyle(color: Color(0xFFF5F5F5)),
        bodySmall: TextStyle(color: Color(0xFFA1A1AA)),
      ),
    ),
    iconTheme: const IconThemeData(color: Colors.white),
    dividerColor: AppColors.darkBorder,
    colorScheme: ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.primary,
      surface: AppColors.darkSurface,
      error: AppColors.danger,
    ),
  );
}

/// Theme Provider for managing app theme state
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false; // Default to light mode

  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  ThemeData get currentTheme =>
      _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setTheme(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
  }
}
