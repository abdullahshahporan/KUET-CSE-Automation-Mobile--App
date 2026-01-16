import 'package:flutter/material.dart';
import 'package:kuet_cse_automation/Student%20Folder/Home/Features/Schedule/class_schedule/class_schedule_screen.dart';
import 'package:kuet_cse_automation/Student%20Folder/Home/Features/Schedule/exam_schedule/exam_schedule_screen.dart';

class UnifiedScheduleScreen extends StatefulWidget {
  final bool showBackButton;
  
  const UnifiedScheduleScreen({super.key, this.showBackButton = true});

  @override
  State<UnifiedScheduleScreen> createState() => _UnifiedScheduleScreenState();
}

class _UnifiedScheduleScreenState extends State<UnifiedScheduleScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: widget.showBackButton ? IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDarkMode ? Colors.white : Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ) : null,
        title: Text(
          'My Schedule',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[600]!, Colors.cyan[500]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: isDarkMode ? Colors.grey[500] : Colors.grey[600],
              labelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(
                  icon: Icon(Icons.calendar_today, size: 20),
                  text: 'Classes',
                ),
                Tab(
                  icon: Icon(Icons.assignment, size: 20),
                  text: 'Exams',
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ClassScheduleScreen(),
          ExamScheduleScreen(),
        ],
      ),
    );
  }
}
