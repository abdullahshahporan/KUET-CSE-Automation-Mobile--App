import 'package:flutter/material.dart';

/// Centralized color palette for KUET CSE Automation App
/// Premium Dark Theme with elegant gradients
/// Light Mode: Clean whites with sophisticated accents
class AppColors {
  // ============================================
  // DARK MODE COLORS (Premium Dark Theme)
  // ============================================

  /// Rich dark background
  static const Color darkBackground = Color(0xFF111111);

  /// Dark surface for cards
  static const Color darkSurface = Color(0xFF1A1A1A);

  /// Elevated surface for cards
  static const Color darkSurfaceElevated = Color(0xFF222222);

  /// Dark border color
  static const Color darkBorder = Color(0xFF2A2A2A);

  /// Primary text color
  static const Color darkTextPrimary = Color(0xFFF5F5F5);

  /// Secondary text color
  static const Color darkTextSecondary = Color(0xFFA1A1AA);

  /// Muted text color
  static const Color darkTextMuted = Color(0xFF71717A);

  /// Shadow color for dark mode
  static const Color darkShadow = Color(0xFF0A0A0A);

  // ============================================
  // LIGHT MODE COLORS
  // ============================================

  /// Light background
  static const Color lightBackground = Color(0xFFF8F8F8);

  /// Light surface for cards
  static const Color lightSurface = Colors.white;

  /// Light surface elevated
  static const Color lightSurfaceElevated = Colors.white;

  /// Light border color
  static const Color lightBorder = Color(0xFFEBEBEB);

  /// Light text primary
  static const Color lightTextPrimary = Color(0xFF0F172A);

  /// Light text secondary
  static const Color lightTextSecondary = Color(0xFF64748B);

  /// Light text muted
  static const Color lightTextMuted = Color(0xFF94A3B8);

  // ============================================
  // PREMIUM ACCENT COLORS
  // ============================================

  /// Primary - Teal 700
  static const Color primary = Color(0xFF0D9488);

  /// Primary dark - darker teal for gradients
  static const Color primaryDark = Color(0xFF0B7A71);

  /// Terminal green - for splash screen accent
  static const Color terminalGreen = Color(0xFF00FFC2);

  /// Info — remapped to primary teal
  static const Color info = primary;

  /// Success - Emerald Green (status use only)
  static const Color success = Color(0xFF22C55E);

  /// Warning - Amber (status use only)
  static const Color warning = Color(0xFFF59E0B);

  /// Danger - Red (status use only)
  static const Color danger = Color(0xFFEF4444);

  /// Accent — remapped to primary teal
  static const Color accent = primary;

  /// Teal — remapped to primary
  static const Color teal = primary;

  /// Indigo — remapped to primary teal
  static const Color indigo = primary;

  /// Gold — remapped to primary teal
  static const Color gold = primary;

  /// Rose — remapped to danger
  static const Color rose = danger;

  // ============================================
  // ATTENDANCE STATUS COLORS
  // ============================================

  /// Present - green
  static const Color present = Color(0xFF22C55E);

  /// Late - amber
  static const Color late = Color(0xFFF59E0B);

  /// Absent - red
  static const Color absent = Color(0xFFEF4444);

  // ============================================
  // FEATURE COLORS
  // ============================================

  static const Color attendance = primary;
  static const Color grading = primary;
  static const Color schedule = primary;
  static const Color announcements = primary;
  static const Color students = primary;
  static const Color courses = primary;

  // ============================================
  // MUTED TEXT (static for compatibility)
  // ============================================

  static const Color textMuted = Color(0xFF666666);

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Get background color based on theme
  static Color background(bool isDarkMode) {
    return isDarkMode ? darkBackground : lightBackground;
  }

  /// Get surface color based on theme
  static Color surface(bool isDarkMode) {
    return isDarkMode ? darkSurface : lightSurface;
  }

  /// Get elevated surface color based on theme
  static Color surfaceElevated(bool isDarkMode) {
    return isDarkMode ? darkSurfaceElevated : lightSurfaceElevated;
  }

  /// Get border color based on theme
  static Color border(bool isDarkMode) {
    return isDarkMode ? darkBorder : lightBorder;
  }

  /// Get primary text color based on theme
  static Color textPrimary(bool isDarkMode) {
    return isDarkMode ? darkTextPrimary : lightTextPrimary;
  }

  /// Get secondary text color based on theme
  static Color textSecondary(bool isDarkMode) {
    return isDarkMode ? darkTextSecondary : lightTextSecondary;
  }

  /// Get shadow color based on theme (grey for dark mode)
  static Color shadow(bool isDarkMode) {
    return isDarkMode ? darkShadow : Colors.black.withValues(alpha: 0.1);
  }

  /// Card decoration with optional accent border
  static BoxDecoration cardDecoration(bool isDarkMode, {Color? accentColor}) {
    return BoxDecoration(
      color: isDarkMode ? darkSurfaceElevated : lightSurface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: accentColor?.withValues(alpha: 0.3) ?? border(isDarkMode),
        width: accentColor != null ? 1.5 : 1,
      ),
      boxShadow: [
        BoxShadow(
          color: isDarkMode
              ? darkShadow.withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Gradient for header cards
  static LinearGradient headerGradient(bool isDarkMode, {List<Color>? colors}) {
    if (colors != null) {
      return LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return LinearGradient(
      colors: isDarkMode
          ? [darkSurface, darkSurfaceElevated]
          : [primary, primaryDark],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}
