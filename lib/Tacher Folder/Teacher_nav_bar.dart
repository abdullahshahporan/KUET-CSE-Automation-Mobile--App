import 'package:flutter/material.dart';
import 'package:kuet_cse_automation/Tacher%20Folder/Teacher_Appbar.dart';
import 'package:kuet_cse_automation/Tacher%20Folder/Teacher_Hamburger.dart';
import 'package:kuet_cse_automation/Tacher%20Folder/Teacher_Home_screen.dart';
import 'package:kuet_cse_automation/Student%20Folder/Profile/profile_screen.dart';
import 'package:kuet_cse_automation/app_theme.dart';
import 'package:provider/provider.dart';

class TeacherMainBottomNavBarScreen extends StatefulWidget {
  const TeacherMainBottomNavBarScreen({super.key});

  @override
  State<TeacherMainBottomNavBarScreen> createState() =>
      _TeacherMainBottomNavBarScreenState();
}

class _TeacherMainBottomNavBarScreenState
    extends State<TeacherMainBottomNavBarScreen> {
  int _currentIndex = 0;

  // Screens for each tab
  final List<Widget> _screens = const [
    TeacherHomeScreen(),
    Center(child: Text('Courses', style: TextStyle(fontSize: 24))),
    Center(child: Text('Students', style: TextStyle(fontSize: 24))),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey[100],
      appBar: TeacherAppBar(
        userName: 'Teacher Name',
        isDarkMode: isDarkMode,
        onThemeToggle: (bool isDark) {
          themeProvider.setTheme(isDark);
        },
      ),
      drawer: TeacherHamburgerDrawer(
        isDarkMode: isDarkMode,
        onThemeToggle: (bool isDark) {
          themeProvider.setTheme(isDark);
        },
        userName: 'Teacher Name',
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Colors.blue[600],
          unselectedItemColor: isDarkMode ? Colors.grey[500] : Colors.grey[600],
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.class_), label: 'Courses'),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Students',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
