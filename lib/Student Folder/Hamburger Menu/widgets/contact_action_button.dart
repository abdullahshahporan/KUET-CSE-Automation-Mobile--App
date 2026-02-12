import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class ContactActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const ContactActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isEnabled = onTap != null;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: isEnabled 
                  ? color.withValues(alpha: 0.08)
                  : AppColors.surface(isDarkMode),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isEnabled
                    ? color.withValues(alpha: 0.15)
                    : AppColors.border(isDarkMode),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isEnabled
                        ? color.withValues(alpha: 0.12)
                        : AppColors.textSecondary(isDarkMode).withValues(alpha: 0.08),
                  ),
                  child: Icon(
                    icon,
                    color: isEnabled ? color : AppColors.textSecondary(isDarkMode),
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isEnabled ? color : AppColors.textSecondary(isDarkMode),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
