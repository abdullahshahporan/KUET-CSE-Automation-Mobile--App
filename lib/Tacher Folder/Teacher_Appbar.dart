import 'package:flutter/material.dart';

class TeacherAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String userName;
  final bool isDarkMode;
  final Function(bool) onThemeToggle;

  const TeacherAppBar({
    super.key,
    required this.userName,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70.0);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      elevation: 0,
      toolbarHeight: 70,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(
            Icons.menu,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[700]!, Colors.cyan[500]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.school, size: 24, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KUET CSE',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  'Teacher Portal',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            isDarkMode ? Icons.light_mode : Icons.dark_mode,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          onPressed: () => onThemeToggle(!isDarkMode),
        ),
        IconButton(
          icon: Icon(
            Icons.notifications_outlined,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
