import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kuet_cse_automation/Student%20Folder/Home/Features/Schedule/class_schedule/class_schedule_providers.dart';
import 'package:intl/intl.dart';

class ClassScheduleScreen extends ConsumerWidget {
  const ClassScheduleScreen({super.key});

  String _getCurrentDay() {
    final now = DateTime.now();
    return DateFormat('EEEE').format(now);
  }

  Map<String, List<dynamic>> _groupClassesByDay(List<dynamic> classes) {
    final currentDay = _getCurrentDay();
    final weekDays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    
    final currentDayIndex = weekDays.indexOf(currentDay);
    final orderedDays = [
      ...weekDays.sublist(currentDayIndex),
      ...weekDays.sublist(0, currentDayIndex),
    ];

    final Map<String, List<dynamic>> grouped = {};
    
    for (final day in orderedDays) {
      final dayClasses = classes.where((c) => c.day == day).toList();
      if (dayClasses.isNotEmpty) {
        grouped[day] = dayClasses;
      }
    }
    
    return grouped;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final allClasses = ref.watch(classScheduleProvider);
    final groupedClasses = _groupClassesByDay(allClasses);
    final currentDay = _getCurrentDay();

    return Container(
      color: isDarkMode ? const Color(0xFF121212) : Colors.grey[50],
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Today's Classes Section
          if (groupedClasses.containsKey(currentDay)) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[600]!, Colors.teal[500]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.today_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TODAY',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentDay,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${groupedClasses[currentDay]!.length} Classes',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...groupedClasses[currentDay]!.map((classItem) {
              return _buildClassCard(classItem, isDarkMode, isToday: true);
            }).toList(),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                    thickness: 1.5,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'UPCOMING',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                    thickness: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // Upcoming Days
          ...groupedClasses.entries.where((entry) => entry.key != currentDay).map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 16, top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.blue[600],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${entry.value.length}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ...entry.value.map((classItem) {
                  return _buildClassCard(classItem, isDarkMode);
                }).toList(),
                const SizedBox(height: 16),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildClassCard(dynamic classItem, bool isDarkMode, {bool isToday = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isToday
            ? Border.all(color: Colors.green.withOpacity(0.5), width: 2)
            : Border.all(color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: isToday
                ? Colors.green.withOpacity(0.15)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isToday
                      ? [Colors.green[600]!, Colors.teal[500]!]
                      : [Colors.blue[600]!, Colors.cyan[500]!],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue[600]!, Colors.cyan[500]!],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            classItem.courseCode,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        if (isToday) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.green.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.circle, size: 8, color: Colors.green[600]),
                                const SizedBox(width: 4),
                                Text(
                                  'Today',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      classItem.courseName,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.access_time_rounded,
                      text: classItem.time,
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: 6),
                    _buildInfoRow(
                      icon: Icons.person_outline_rounded,
                      text: classItem.teacher,
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: 6),
                    _buildInfoRow(
                      icon: Icons.location_on_outlined,
                      text: classItem.room,
                      isDarkMode: isDarkMode,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String text,
    required bool isDarkMode,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
              height: 1.3,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
