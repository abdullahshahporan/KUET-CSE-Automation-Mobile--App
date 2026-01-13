import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
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
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(70);
}

class _CustomAppBarState extends State<CustomAppBar> {
  late Timer _timer;
  String _currentTime = '';
  String _currentDate = '';

  @override
  void initState() {
    super.initState();
    _updateDateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateDateTime();
    });
  }

  void _updateDateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime = DateFormat('hh:mm:ss a').format(now);
      _currentDate = DateFormat('MMM dd, yyyy').format(now);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      toolbarHeight: 70,
      backgroundColor: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      title: Row(
        children: [
          // Left side - User info and DateTime
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.userName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _currentDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _currentTime,
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Right side - Theme toggle
          _buildThemeToggle(),
        ],
      ),
    );
  }

  Widget _buildThemeToggle() {
    return GestureDetector(
      onTap: () {
        widget.onThemeToggle(!widget.isDarkMode);
      },
      child: Container(
        width: 70,
        height: 35,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: widget.isDarkMode 
              ? const Color(0xFF2C2C2C) 
              : Colors.grey[300],
          border: Border.all(
            color: widget.isDarkMode 
                ? Colors.grey[700]! 
                : Colors.grey[400]!,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            // Light mode icon (left)
            Positioned(
              left: 8,
              top: 6,
              child: Icon(
                Icons.wb_sunny,
                size: 20,
                color: !widget.isDarkMode 
                    ? Colors.orange[700] 
                    : Colors.grey[600],
              ),
            ),
            // Dark mode icon (right)
            Positioned(
              right: 8,
              top: 6,
              child: Icon(
                Icons.nightlight_round,
                size: 20,
                color: widget.isDarkMode 
                    ? Colors.blue[300] 
                    : Colors.grey[600],
              ),
            ),
            // Sliding circle
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: widget.isDarkMode ? 38 : 3,
              top: 3,
              child: Container(
                width: 29,
                height: 29,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isDarkMode 
                      ? const Color(0xFF1E3A8A) 
                      : Colors.orange[600],
                  boxShadow: [
                    BoxShadow(
                      color: widget.isDarkMode 
                          ? Colors.blue.withOpacity(0.3)
                          : Colors.orange.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  widget.isDarkMode 
                      ? Icons.nightlight_round 
                      : Icons.wb_sunny,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
