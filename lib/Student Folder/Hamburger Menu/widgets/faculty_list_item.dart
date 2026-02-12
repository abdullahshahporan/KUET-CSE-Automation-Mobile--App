import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../models/faculty.dart';

class FacultyListItem extends StatelessWidget {
  final Faculty faculty;
  final VoidCallback onTap;

  const FacultyListItem({
    super.key,
    required this.faculty,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final accentColor = faculty.isOnLeave ? Colors.orange : AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withValues(alpha: 0.12),
                ),
                child: Center(
                  child: Text(
                    faculty.initial,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Name and designation
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      faculty.fullName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary(isDarkMode),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      faculty.formattedDesignation,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary(isDarkMode),
                      ),
                    ),
                  ],
                ),
              ),
              
              // On-leave badge
              if (faculty.isOnLeave)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Leave',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              
              // Chevron
              Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary(isDarkMode),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
