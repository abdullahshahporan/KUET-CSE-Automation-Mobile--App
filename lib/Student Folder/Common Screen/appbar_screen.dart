import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String userName;
  final bool isDarkMode;
  final Function(bool) onThemeToggle;

  const CustomAppBar({
    super.key,
    required this.userName,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      toolbarHeight: 60,
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(
            Icons.menu,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
      ),
      title: Text(
        'KUET CSE Automation',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.search,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          onPressed: () {
            // Search functionality can be added later
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Search functionality coming soon!'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ],
    );
  }
}
