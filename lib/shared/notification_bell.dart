import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_provider.dart';
import '../theme/app_colors.dart';
import 'notification_screen.dart';

// ─────────────────────────────────────────────────────────────
// NotificationBell — icon + badge for AppBar
//
// Usage: place in AppBar actions list
//   NotificationBell(isDarkMode: isDarkMode)
// ─────────────────────────────────────────────────────────────

class NotificationBell extends StatelessWidget {
  final bool isDarkMode;

  const NotificationBell({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        final count = provider.unreadCount;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: 'Notifications',
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? AppColors.darkBorder
                      : AppColors.lightBorder.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  count > 0
                      ? Icons.notifications_rounded
                      : Icons.notifications_outlined,
                  color: count > 0
                      ? AppColors.primary
                      : (isDarkMode ? Colors.white : Colors.black87),
                  size: 22,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationScreen(),
                  ),
                );
              },
            ),

            // Unread badge
            if (count > 0)
              Positioned(
                top: 6,
                right: 6,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDarkMode
                            ? AppColors.darkBackground
                            : AppColors.lightBackground,
                        width: 1.5,
                      ),
                    ),
                    constraints: const BoxConstraints(minWidth: 16),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
