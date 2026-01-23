import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'send_announcement_screen.dart';
import 'room_request_screen.dart';

/// FAB Menu Widget with expandable options
class TeacherFabMenu extends StatefulWidget {
  const TeacherFabMenu({super.key});

  @override
  State<TeacherFabMenu> createState() => _TeacherFabMenuState();
}

class _TeacherFabMenuState extends State<TeacherFabMenu> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.125).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Menu Items
        if (_isExpanded) ...[
          // Room Request Option
          ScaleTransition(
            scale: _scaleAnimation,
            child: _buildMenuItem(
              icon: Icons.meeting_room,
              label: 'Room Request',
              color: Colors.orange,
              onTap: () {
                _toggleMenu();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RoomRequestScreen()),
                );
              },
              isDarkMode: isDarkMode,
            ),
          ),
          const SizedBox(height: 12),
          
          // Announcement Option
          ScaleTransition(
            scale: _scaleAnimation,
            child: _buildMenuItem(
              icon: Icons.campaign,
              label: 'Announcement',
              color: AppColors.primary,
              onTap: () {
                _toggleMenu();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SendAnnouncementScreen()),
                );
              },
              isDarkMode: isDarkMode,
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Main FAB
        RotationTransition(
          turns: _rotateAnimation,
          child: FloatingActionButton(
            onPressed: _toggleMenu,
            backgroundColor: _isExpanded ? AppColors.danger : AppColors.primary,
            elevation: 6,
            child: Icon(
              _isExpanded ? Icons.close : Icons.add,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface(isDarkMode),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(isDarkMode),
            ),
          ),
        ),
        const SizedBox(width: 12),
        
        // Mini FAB
        FloatingActionButton.small(
          heroTag: label,
          onPressed: onTap,
          backgroundColor: color,
          elevation: 4,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ],
    );
  }
}
