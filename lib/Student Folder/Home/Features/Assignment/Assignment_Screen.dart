import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kuet_cse_automation/Student%20Folder/providers/app_providers.dart';

class AssignmentScreen extends ConsumerWidget {
  const AssignmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final assignments = ref.watch(assignmentsProvider);

    // Group assignments by status
    final pending = assignments.where((a) => a.status == 'pending').toList();
    final submitted = assignments.where((a) => a.status == 'submitted').toList();
    final overdue = assignments.where((a) => a.status == 'overdue').toList();

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey[100],
      appBar: AppBar(
        title: const Text('Assignments'),
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (overdue.isNotEmpty) ...[
            _buildSectionHeader('Overdue', Colors.red, isDarkMode),
            ...overdue.map((assignment) => _buildAssignmentCard(assignment, Colors.red, isDarkMode)),
          ],
          if (pending.isNotEmpty) ...[
            _buildSectionHeader('Pending', Colors.orange, isDarkMode),
            ...pending.map((assignment) => _buildAssignmentCard(assignment, Colors.orange, isDarkMode)),
          ],
          if (submitted.isNotEmpty) ...[
            _buildSectionHeader('Submitted', Colors.green, isDarkMode),
            ...submitted.map((assignment) => _buildAssignmentCard(assignment, Colors.green, isDarkMode)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(assignment, Color statusColor, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  assignment.title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${assignment.marks} marks',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            assignment.courseName,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.blue[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            assignment.description,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16,
                color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Text(
                'Deadline: ${assignment.deadline}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                ),
              ),
              const Spacer(),
              if (assignment.status == 'pending')
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Submit',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              if (assignment.status == 'submitted')
                Icon(
                  Icons.check_circle,
                  color: Colors.green[600],
                  size: 24,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
