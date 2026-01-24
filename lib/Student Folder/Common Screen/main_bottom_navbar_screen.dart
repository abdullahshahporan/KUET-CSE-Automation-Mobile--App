import 'package:flutter/material.dart';
import 'package:kuet_cse_automation/Student%20Folder/Common%20Screen/appbar_screen.dart';
import 'package:kuet_cse_automation/Student%20Folder/Hamburger%20Menu/hamburger_screen.dart';
import 'package:kuet_cse_automation/Student%20Folder/Home_Central/home_screen.dart';
import 'package:kuet_cse_automation/Student%20Folder/Home/Features/Schedule/unified_schedule_screen.dart';
import 'package:kuet_cse_automation/Student%20Folder/Resource/resource_screen.dart';
import 'package:kuet_cse_automation/Student%20Folder/Profile/profile_screen.dart';
import 'package:kuet_cse_automation/app_theme.dart';
import 'package:kuet_cse_automation/theme/app_colors.dart';
import 'package:provider/provider.dart';

class MainBottomNavBarScreen extends StatefulWidget {
  const MainBottomNavBarScreen({super.key});

  @override
  State<MainBottomNavBarScreen> createState() => _MainBottomNavBarScreenState();
}

class _MainBottomNavBarScreenState extends State<MainBottomNavBarScreen> {
  int _currentIndex = 0;

  // Screens for each tab
  final List<Widget> _screens = const [
    HomeScreen(),
    UnifiedScheduleScreen(showBackButton: false),
    ResourcesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: CustomAppBar(
        userName: 'Student Name',
        isDarkMode: isDarkMode,
        onThemeToggle: (bool isDark) {
          themeProvider.setTheme(isDark);
        },
      ),
      drawer: HamburgerDrawer(
        isDarkMode: isDarkMode,
        onThemeToggle: (bool isDark) {
          themeProvider.setTheme(isDark);
        },
        userName: 'Student Name',
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.4)
                  : Colors.grey.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isDarkMode: isDarkMode,
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.calendar_month_rounded,
                  label: 'Schedule',
                  isDarkMode: isDarkMode,
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.library_books_rounded,
                  label: 'Resources',
                  isDarkMode: isDarkMode,
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  isDarkMode: isDarkMode,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isDarkMode,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.primary
                  : (isDarkMode
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextSecondary),
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
