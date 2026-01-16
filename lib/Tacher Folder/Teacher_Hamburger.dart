import 'package:flutter/material.dart';
import 'package:kuet_cse_automation/Auth/Sign_In_Screen.dart';

class TeacherHamburgerDrawer extends StatelessWidget {
  final bool isDarkMode;
  final Function(bool) onThemeToggle;
  final String userName;

  const TeacherHamburgerDrawer({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[700]!, Colors.cyan[500]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 50, color: Colors.blue[700]),
            ),
            accountName: Text(
              userName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            accountEmail: const Text('Teacher', style: TextStyle(fontSize: 14)),
          ),
          _buildMenuItem(
            icon: Icons.dashboard,
            title: 'Dashboard',
            onTap: () {
              Navigator.pop(context);
            },
          ),
          _buildMenuItem(
            icon: Icons.class_,
            title: 'My Courses',
            onTap: () {
              Navigator.pop(context);
            },
          ),
          _buildMenuItem(
            icon: Icons.people,
            title: 'Students',
            onTap: () {
              Navigator.pop(context);
            },
          ),
          _buildMenuItem(
            icon: Icons.assignment,
            title: 'Assignments',
            onTap: () {
              Navigator.pop(context);
            },
          ),
          _buildMenuItem(
            icon: Icons.grade,
            title: 'Grading',
            onTap: () {
              Navigator.pop(context);
            },
          ),
          _buildMenuItem(
            icon: Icons.schedule,
            title: 'Schedule',
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const Divider(),
          _buildMenuItem(
            icon: Icons.settings,
            title: 'Settings',
            onTap: () {
              Navigator.pop(context);
            },
          ),
          SwitchListTile(
            secondary: Icon(
              isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            title: Text(
              'Dark Mode',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            value: isDarkMode,
            onChanged: onThemeToggle,
            activeColor: Colors.blue[600],
          ),
          const Divider(),
          _buildMenuItem(
            icon: Icons.logout,
            title: 'Logout',
            textColor: Colors.red,
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const SignInScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: textColor ?? (isDarkMode ? Colors.white : Colors.black87),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? (isDarkMode ? Colors.white : Colors.black87),
        ),
      ),
      onTap: onTap,
    );
  }
}
