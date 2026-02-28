import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Shared UI helper widgets and builders used across the app.
///
/// Eliminates duplication of SnackBar styling, InputDecoration,
/// form labels, and common dialog patterns.

// ── SnackBar helpers ──────────────────────────────────────────────────────

/// Show a success/error SnackBar with consistent styling.
void showAppSnackBar(
  BuildContext context, {
  required String message,
  bool isSuccess = true,
  Duration duration = const Duration(seconds: 3),
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
      backgroundColor: isSuccess ? AppColors.success : AppColors.danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: duration,
    ),
  );
}

// ── InputDecoration builder ───────────────────────────────────────────────

/// Build a consistent [InputDecoration] for text fields across the app.
InputDecoration buildAppInputDecoration({
  required bool isDarkMode,
  required String label,
  String? hint,
  IconData? prefixIcon,
  Widget? suffix,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
    suffix: suffix,
    filled: true,
    fillColor: AppColors.surface(isDarkMode),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.border(isDarkMode)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.border(isDarkMode)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
    labelStyle: TextStyle(color: AppColors.textSecondary(isDarkMode)),
    hintStyle: TextStyle(color: AppColors.textSecondary(isDarkMode)),
  );
}

// ── Form label widget ─────────────────────────────────────────────────────

/// A consistent section label used in form screens.
///
/// Replaces `_buildLabel()` and `_sectionLabel()` duplicated in
/// send_announcement_screen, room_request_screen, slot_booking_dialog, etc.
class FormSectionLabel extends StatelessWidget {
  final String text;
  final bool isDarkMode;

  const FormSectionLabel({
    super.key,
    required this.text,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary(isDarkMode),
        ),
      ),
    );
  }
}

// ── Empty state widget ────────────────────────────────────────────────────

/// Reusable empty state placeholder with icon, title, and subtitle.
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isDarkMode;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(isDarkMode),
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary(isDarkMode),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Loading state widget ──────────────────────────────────────────────────

/// Reusable loading placeholder with optional message.
class LoadingWidget extends StatelessWidget {
  final String? message;
  final bool isDarkMode;

  const LoadingWidget({
    super.key,
    this.message,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary(isDarkMode),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────

/// A consistent section header row with title and optional trailing text/widget.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? trailingText;
  final Widget? trailing;
  final bool isDarkMode;

  const SectionHeader({
    super.key,
    required this.title,
    this.trailingText,
    this.trailing,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary(isDarkMode),
          ),
        ),
        if (trailing != null)
          trailing!
        else if (trailingText != null)
          Text(
            trailingText!,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary(isDarkMode),
            ),
          ),
      ],
    );
  }
}

// ── isDarkMode extension ──────────────────────────────────────────────────

/// Convenience extension to avoid repeating `Theme.of(context).brightness`.
extension DarkModeContext on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
