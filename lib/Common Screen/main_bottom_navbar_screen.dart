import 'package:flutter/material.dart';
import 'package:kuet_cse_automation/Common%20Screen/appbar_screen.dart';
import 'package:kuet_cse_automation/Home/home_screen.dart';
import 'package:kuet_cse_automation/Schedule/schedule_screen.dart';
import 'package:kuet_cse_automation/Resource/resource_screen.dart';
import 'package:kuet_cse_automation/Profile/profile_screen.dart';
import 'package:kuet_cse_automation/app_theme.dart';
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
    ScheduleScreen(),
    ResourcesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey[100],
      appBar: CustomAppBar(
        userName: 'Student Name',
        isDarkMode: isDarkMode,
        onThemeToggle: (bool isDark) {
          themeProvider.setTheme(isDark);
        },
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
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
          backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          selectedItemColor: isDarkMode ? Colors.blue[300] : Colors.blue[700],
          unselectedItemColor: isDarkMode ? Colors.grey[600] : Colors.grey[500],
          selectedFontSize: 12,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.schedule_outlined),
              activeIcon: Icon(Icons.schedule),
              label: 'Schedule',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.library_books_outlined),
              activeIcon: Icon(Icons.library_books),
              label: 'Resources',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
