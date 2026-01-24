import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../teacher_home_content.dart';
import '../Schedule/teacher_schedule_screen.dart';
import '../Room_info/room_info_screen.dart';
import '../Teacher_Profile/teacher_profile.dart';
import '../Fab_Menu/fab_menu_widget.dart';

/// Main Teacher Navigation Screen with Bottom Navbar
class TeacherMainScreen extends StatefulWidget {
  const TeacherMainScreen({super.key});

  @override
  State<TeacherMainScreen> createState() => _TeacherMainScreenState();
}

class _TeacherMainScreenState extends State<TeacherMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    TeacherHomeContent(),
    TeacherScheduleScreen(),
    RoomInfoScreen(),
    TeacherProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildBottomNavBar(isDarkMode),
      floatingActionButton: _currentIndex == 0 ? const TeacherFabMenu() : null,
    );
  }

  Widget _buildBottomNavBar(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(isDarkMode),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(top: BorderSide(color: AppColors.border(isDarkMode))),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                0,
                Icons.home_outlined,
                Icons.home,
                'Home',
                isDarkMode,
              ),
              _buildNavItem(
                1,
                Icons.schedule_outlined,
                Icons.schedule,
                'Schedule',
                isDarkMode,
              ),
              _buildNavItem(
                2,
                Icons.meeting_room_outlined,
                Icons.meeting_room,
                'Room Info',
                isDarkMode,
              ),
              _buildNavItem(
                3,
                Icons.person_outline,
                Icons.person,
                'Profile',
                isDarkMode,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
    bool isDarkMode,
  ) {
    final isSelected = _currentIndex == index;
    final color = isSelected
        ? AppColors.primary
        : AppColors.textSecondary(isDarkMode);

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? activeIcon : icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
