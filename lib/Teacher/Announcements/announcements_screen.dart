import 'package:flutter/material.dart';
import '../../Student Folder/data/teacher_static_data.dart';
import '../../theme/app_colors.dart';

/// Course-specific Announcements Screen
class AnnouncementsScreen extends StatefulWidget {
  final TeacherCourse? course;
  
  const AnnouncementsScreen({super.key, this.course});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final List<Map<String, dynamic>> _announcements = [];

  TeacherCourse get course => widget.course!;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      appBar: AppBar(
        title: Text(
          '${course.code} - Announcements',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface(isDarkMode),
        elevation: 0,
      ),
      body: _announcements.isEmpty
          ? _buildEmptyState(isDarkMode)
          : _buildAnnouncementsList(isDarkMode),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateAnnouncement(context, isDarkMode),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.campaign, size: 48, color: AppColors.warning),
            ),
            const SizedBox(height: 20),
            Text(
              'No Announcements Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(isDarkMode),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create an announcement to notify students in ${course.code}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary(isDarkMode),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementsList(bool isDarkMode) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _announcements.length,
      itemBuilder: (context, index) {
        final announcement = _announcements[index];
        return _buildAnnouncementCard(announcement, isDarkMode);
      },
    );
  }

  Widget _buildAnnouncementCard(Map<String, dynamic> announcement, bool isDarkMode) {
    final typeColors = {
      'Class Test': AppColors.danger,
      'Assignment': AppColors.primary,
      'Quiz': AppColors.warning,
      'Notice': AppColors.info,
    };
    final color = typeColors[announcement['type']] ?? AppColors.info;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(isDarkMode),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(isDarkMode)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  announcement['type'],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                announcement['date'],
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            announcement['title'],
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDarkMode),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            announcement['content'],
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary(isDarkMode),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.group, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                'Will notify all students in ${course.code}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCreateAnnouncement(BuildContext context, bool isDarkMode) {
    String selectedType = 'Notice';
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface(isDarkMode),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border(isDarkMode),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                Text(
                  'New Announcement',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(isDarkMode),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'This will notify all students in ${course.code}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary(isDarkMode),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Type selector
                Text(
                  'Type',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary(isDarkMode),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['Notice', 'Class Test', 'Assignment', 'Quiz'].map((type) {
                    final isSelected = selectedType == type;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedType = type),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.surfaceElevated(isDarkMode),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border(isDarkMode),
                          ),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textSecondary(isDarkMode),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                
                // Title
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    filled: true,
                    fillColor: AppColors.surfaceElevated(isDarkMode),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.border(isDarkMode)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.border(isDarkMode)),
                    ),
                  ),
                  style: TextStyle(color: AppColors.textPrimary(isDarkMode)),
                ),
                const SizedBox(height: 12),
                
                // Content
                TextField(
                  controller: contentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Content',
                    filled: true,
                    fillColor: AppColors.surfaceElevated(isDarkMode),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.border(isDarkMode)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.border(isDarkMode)),
                    ),
                  ),
                  style: TextStyle(color: AppColors.textPrimary(isDarkMode)),
                ),
                const SizedBox(height: 20),
                
                // Post button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (titleController.text.isNotEmpty && contentController.text.isNotEmpty) {
                        setState(() {
                          _announcements.insert(0, {
                            'type': selectedType,
                            'title': titleController.text,
                            'content': contentController.text,
                            'date': 'Just now',
                          });
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Announcement posted!'),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Post Announcement',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
