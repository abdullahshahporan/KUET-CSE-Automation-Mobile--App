import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class ResourcesScreen extends StatelessWidget {
  const ResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Study Resources',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(isDarkMode),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildResourceCard(
                    'Lecture Notes',
                    Icons.description,
                    AppColors.primary,
                    isDarkMode,
                  ),
                  _buildResourceCard(
                    'Previous Papers',
                    Icons.quiz,
                    AppColors.warning,
                    isDarkMode,
                  ),
                  _buildResourceCard(
                    'E-Books',
                    Icons.book,
                    AppColors.success,
                    isDarkMode,
                  ),
                  _buildResourceCard(
                    'Video Lectures',
                    Icons.video_library,
                    AppColors.danger,
                    isDarkMode,
                  ),
                  _buildResourceCard(
                    'Assignments',
                    Icons.assignment,
                    AppColors.accent,
                    isDarkMode,
                  ),
                  _buildResourceCard(
                    'Lab Manuals',
                    Icons.science,
                    AppColors.info,
                    isDarkMode,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceCard(
    String title,
    IconData icon,
    Color color,
    bool isDarkMode,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(isDarkMode),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(isDarkMode)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(isDarkMode),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(isDarkMode),
            ),
          ),
        ],
      ),
    );
  }
}
