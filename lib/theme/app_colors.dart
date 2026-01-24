import 'package:flutter/material.dart';

/// Centralized color palette for KUET CSE Automation App
/// Premium Dark Theme with elegant gradients
/// Light Mode: Clean whites with sophisticated accents
class AppColors {
  // ============================================
  // DARK MODE COLORS (Premium Dark Theme)
  // ============================================

  /// Rich dark background
  static const Color darkBackground = Color(0xFF0A0A0F);

  /// Dark surface for cards
  static const Color darkSurface = Color(0xFF12121A);

  /// Elevated surface for cards
  static const Color darkSurfaceElevated = Color(0xFF1C1C28);

  /// Dark border color with subtle glow
  static const Color darkBorder = Color(0xFF2D2D3A);

  /// Primary text color
  static const Color darkTextPrimary = Color(0xFFF8F8FC);

  /// Secondary text color
  static const Color darkTextSecondary = Color(0xFF9CA3AF);

  /// Muted text color
  static const Color darkTextMuted = Color(0xFF6B7280);

  /// Shadow color for dark mode
  static const Color darkShadow = Color(0xFF1A1A24);

  // ============================================
  // LIGHT MODE COLORS
  // ============================================

  /// Light background
  static const Color lightBackground = Color(0xFFF8FAFC);

  /// Light surface for cards
  static const Color lightSurface = Colors.white;

  /// Light surface elevated
  static const Color lightSurfaceElevated = Colors.white;

  /// Light border color
  static const Color lightBorder = Color(0xFFE2E8F0);

  /// Light text primary
  static const Color lightTextPrimary = Color(0xFF0F172A);

  /// Light text secondary
  static const Color lightTextSecondary = Color(0xFF64748B);

  /// Light text muted
  static const Color lightTextMuted = Color(0xFF94A3B8);

  // ============================================
  // PREMIUM ACCENT COLORS
  // ============================================

  /// Primary - Royal Blue
  static const Color primary = Color(0xFF6366F1);

  /// Info - Ocean Cyan
  static const Color info = Color(0xFF0EA5E9);

  /// Success - Emerald Green
  static const Color success = Color(0xFF10B981);

  /// Warning - Golden Amber
  static const Color warning = Color(0xFFF59E0B);

  /// Danger - Ruby Red
  static const Color danger = Color(0xFFEF4444);

  /// Accent - Violet Purple
  static const Color accent = Color(0xFF8B5CF6);

  /// Teal - Aqua
  static const Color teal = Color(0xFF14B8A6);

  /// Indigo - Deep Indigo
  static const Color indigo = Color(0xFF4F46E5);

  /// Gold - Premium Gold
  static const Color gold = Color(0xFFD4AF37);

  /// Rose - Elegant Rose
  static const Color rose = Color(0xFFF43F5E);

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

  static const Color attendance = Color(0xFF10B981);
  static const Color grading = Color(0xFF3B82F6);
  static const Color schedule = Color(0xFFFBBF24);
  static const Color announcements = Color(0xFFEF4444);
  static const Color students = Color(0xFF8B5CF6);
  static const Color courses = Color(0xFF06B6D4);

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
    return isDarkMode ? darkShadow : Colors.black.withOpacity(0.1);
  }

  /// Card decoration with optional accent border
  static BoxDecoration cardDecoration(bool isDarkMode, {Color? accentColor}) {
    return BoxDecoration(
      color: isDarkMode ? darkSurfaceElevated : lightSurface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: accentColor?.withOpacity(0.3) ?? border(isDarkMode),
        width: accentColor != null ? 1.5 : 1,
      ),
      boxShadow: [
        BoxShadow(
          color: isDarkMode
              ? darkShadow.withOpacity(0.3) // Grey shadow for dark mode
              : Colors.black.withOpacity(0.05),
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
          ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
          : [primary, info],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}
