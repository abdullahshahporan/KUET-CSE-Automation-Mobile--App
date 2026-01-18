import 'package:flutter/material.dart';

class AssignmentScreen extends StatefulWidget {
  const AssignmentScreen({super.key});

  @override
  State<AssignmentScreen> createState() => _AssignmentScreenState();
}

class _AssignmentScreenState extends State<AssignmentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Assignments',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.search,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            onPressed: () {
              // Implement search functionality
            },
          ),
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            onPressed: () {
              _showFilterOptions(context, isDarkMode);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.orange,
          unselectedLabelColor: isDarkMode
              ? Colors.grey[400]
              : Colors.grey[600],
          indicatorColor: Colors.orange,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Graded'),
            Tab(text: 'Drafts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAssignmentList(context, isDarkMode, 'active'),
          _buildAssignmentList(context, isDarkMode, 'graded'),
          _buildAssignmentList(context, isDarkMode, 'drafts'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showCreateAssignmentDialog(context, isDarkMode);
        },
        icon: const Icon(Icons.add),
        label: const Text('New Assignment'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildAssignmentList(
    BuildContext context,
    bool isDarkMode,
    String type,
  ) {
    final assignments = _getAssignmentsByType(type);

    if (assignments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 80,
              color: isDarkMode ? Colors.grey[700] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No ${type} assignments',
              style: TextStyle(
                fontSize: 18,
                color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: assignments.length,
      itemBuilder: (context, index) {
        return _buildAssignmentCard(context, isDarkMode, assignments[index]);
      },
    );
  }

  Widget _buildAssignmentCard(
    BuildContext context,
    bool isDarkMode,
    Map<String, dynamic> assignment,
  ) {
    final isOverdue = assignment['status'] == 'overdue';
    final isPending = assignment['status'] == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _showAssignmentDetails(context, isDarkMode, assignment);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        assignment['title'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    _buildStatusChip(assignment['status'], isDarkMode),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  assignment['course'],
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: isOverdue
                          ? Colors.red
                          : (isDarkMode ? Colors.grey[500] : Colors.grey[600]),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Due: ${assignment['dueDate']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isOverdue
                            ? Colors.red
                            : (isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[600]),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.people,
                      size: 16,
                      color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${assignment['submissions']}/${assignment['totalStudents']} submitted',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value:
                      assignment['submissions'] / assignment['totalStudents'],
                  backgroundColor: isDarkMode
                      ? Colors.grey[700]
                      : Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isPending ? Colors.orange : Colors.green,
                  ),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                if (assignment['status'] != 'draft') ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          // View submissions
                        },
                        icon: const Icon(Icons.visibility, size: 18),
                        label: const Text('View Submissions'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, bool isDarkMode) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status) {
      case 'active':
        backgroundColor = Colors.blue.withOpacity(0.2);
        textColor = Colors.blue;
        label = 'Active';
        break;
      case 'graded':
        backgroundColor = Colors.green.withOpacity(0.2);
        textColor = Colors.green;
        label = 'Graded';
        break;
      case 'overdue':
        backgroundColor = Colors.red.withOpacity(0.2);
        textColor = Colors.red;
        label = 'Overdue';
        break;
      case 'pending':
        backgroundColor = Colors.orange.withOpacity(0.2);
        textColor = Colors.orange;
        label = 'Pending';
        break;
      case 'draft':
        backgroundColor = Colors.grey.withOpacity(0.2);
        textColor = isDarkMode ? Colors.grey[400]! : Colors.grey[700]!;
        label = 'Draft';
        break;
      default:
        backgroundColor = Colors.grey.withOpacity(0.2);
        textColor = Colors.grey;
        label = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  void _showFilterOptions(BuildContext context, bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Assignments',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              _buildFilterOption(
                context,
                isDarkMode,
                'All Courses',
                Icons.class_,
              ),
              _buildFilterOption(
                context,
                isDarkMode,
                'Due This Week',
                Icons.calendar_today,
              ),
              _buildFilterOption(
                context,
                isDarkMode,
                'Needs Grading',
                Icons.grade,
              ),
              _buildFilterOption(
                context,
                isDarkMode,
                'Low Submission Rate',
                Icons.trending_down,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(
    BuildContext context,
    bool isDarkMode,
    String label,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.orange),
      title: Text(
        label,
        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
      ),
      onTap: () {
        Navigator.pop(context);
        // Apply filter
      },
    );
  }

  void _showCreateAssignmentDialog(BuildContext context, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Create New Assignment',
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Assignment Title',
                  labelStyle: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                  ),
                ),
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                  ),
                ),
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Create assignment
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _showAssignmentDetails(
    BuildContext context,
    bool isDarkMode,
    Map<String, dynamic> assignment,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              assignment['title'],
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ),
                          _buildStatusChip(assignment['status'], isDarkMode),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        assignment['course'],
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildDetailRow(
                        isDarkMode,
                        Icons.calendar_today,
                        'Due Date',
                        assignment['dueDate'],
                      ),
                      _buildDetailRow(
                        isDarkMode,
                        Icons.people,
                        'Submissions',
                        '${assignment['submissions']}/${assignment['totalStudents']}',
                      ),
                      _buildDetailRow(
                        isDarkMode,
                        Icons.grade,
                        'Max Points',
                        '${assignment['maxPoints']} points',
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        assignment['description'],
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode
                              ? Colors.grey[400]
                              : Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Edit assignment
                              },
                              icon: const Icon(Icons.edit),
                              label: const Text('Edit'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // Delete assignment
                              },
                              icon: const Icon(Icons.delete),
                              label: const Text('Delete'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
    bool isDarkMode,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.orange),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getAssignmentsByType(String type) {
    // Sample data - replace with actual data from your backend
    final allAssignments = [
      {
        'title': 'Data Structures Assignment 1',
        'course': 'CSE 2101 - Data Structures',
        'dueDate': 'Jan 25, 2026',
        'submissions': 45,
        'totalStudents': 60,
        'status': 'active',
        'maxPoints': 100,
        'description':
            'Implement various tree traversal algorithms including in-order, pre-order, and post-order traversal for binary trees.',
      },
      {
        'title': 'Algorithm Analysis Quiz',
        'course': 'CSE 2102 - Algorithms',
        'dueDate': 'Jan 20, 2026',
        'submissions': 30,
        'totalStudents': 55,
        'status': 'pending',
        'maxPoints': 50,
        'description':
            'Complete the quiz on time complexity analysis and Big-O notation.',
      },
      {
        'title': 'Database Design Project',
        'course': 'CSE 3101 - Database Systems',
        'dueDate': 'Jan 15, 2026',
        'submissions': 50,
        'totalStudents': 50,
        'status': 'graded',
        'maxPoints': 150,
        'description':
            'Design and implement a complete database system for a library management system.',
      },
      {
        'title': 'OOP Mid-term Assignment',
        'course': 'CSE 1102 - Object Oriented Programming',
        'dueDate': 'Jan 10, 2026',
        'submissions': 20,
        'totalStudents': 58,
        'status': 'overdue',
        'maxPoints': 100,
        'description': 'Implement a banking system using OOP principles.',
      },
      {
        'title': 'Web Development Project',
        'course': 'CSE 4101 - Web Technologies',
        'dueDate': 'Feb 1, 2026',
        'submissions': 0,
        'totalStudents': 45,
        'status': 'draft',
        'maxPoints': 200,
        'description':
            'Create a full-stack web application using modern web technologies.',
      },
    ];

    if (type == 'active') {
      return allAssignments
          .where(
            (a) =>
                a['status'] == 'active' ||
                a['status'] == 'pending' ||
                a['status'] == 'overdue',
          )
          .toList();
    } else if (type == 'graded') {
      return allAssignments.where((a) => a['status'] == 'graded').toList();
    } else if (type == 'drafts') {
      return allAssignments.where((a) => a['status'] == 'draft').toList();
    }

    return [];
  }
}
