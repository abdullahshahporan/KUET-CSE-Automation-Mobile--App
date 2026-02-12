import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../Student Folder/models/course_model.dart';

class CourseHeaderCard extends StatelessWidget {
  final String code;
  final String title;
  final String semesterName;
  final String creditsString;
  final CourseType type;
  final bool isDarkMode;
  final Color color;

  const CourseHeaderCard({
    super.key,
    required this.code,
    required this.title,
    required this.semesterName,
    required this.creditsString,
    required this.type,
    required this.isDarkMode,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
              : [color.withOpacity(0.8), color.withOpacity(0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: isDarkMode ? Border.all(color: AppColors.darkBorder) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(isDarkMode ? 0.1 : 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  type == CourseType.theory ? Icons.book : Icons.science,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      code,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tags row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CourseTag(label: semesterName, icon: Icons.calendar_today),
              _CourseTag(label: creditsString, icon: Icons.star),
              _CourseTag(
                label: type == CourseType.theory ? 'Theory' : 'Sessional',
                icon: type == CourseType.theory
                    ? Icons.menu_book
                    : Icons.biotech,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CourseTag extends StatelessWidget {
  final String label;
  final IconData icon;

  const _CourseTag({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
