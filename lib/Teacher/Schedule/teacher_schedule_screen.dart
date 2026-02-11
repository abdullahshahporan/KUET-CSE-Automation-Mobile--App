import 'package:flutter/material.dart';
import 'teacher_schedule_model.dart';
import 'teacher_schedule_service.dart';

/// Teacher Schedule screen — fetches from Supabase, supports edit/add/delete.
class TeacherScheduleScreen extends StatefulWidget {
  const TeacherScheduleScreen({super.key});

  @override
  State<TeacherScheduleScreen> createState() => _TeacherScheduleScreenState();
}

class _TeacherScheduleScreenState extends State<TeacherScheduleScreen> {
  Map<int, List<TeacherSlot>> _schedule = {};
  bool _isLoading = true;

  /// Days to show (Sun–Thu typical for KUET)
  static const _displayDays = [0, 1, 2, 3, 4]; // Sun–Thu

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final data = await TeacherScheduleService.fetchSchedule();
    if (mounted) setState(() { _schedule = data; _isLoading = false; });
  }

  int get _totalClasses =>
      _schedule.values.fold(0, (s, list) => s + list.length);

  int get _courseCount {
    final codes = <String>{};
    for (final list in _schedule.values) {
      for (final slot in list) {
        codes.add(slot.courseCode);
      }
    }
    return codes.length;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey[100],
      appBar: AppBar(
        title: const Text('My Schedule'),
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header card
                    _buildHeaderCard(isDarkMode),
                    const SizedBox(height: 24),
                    // Day cards
                    ..._displayDays.map((d) => _buildDayCard(d, isDarkMode)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderCard(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[600]!, Colors.indigo[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Weekly Schedule',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Text(
                '$_courseCount Courses | $_totalClasses Classes/Week',
                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(int day, bool isDarkMode) {
    final slots = _schedule[day] ?? [];
    final isToday = _isTodayDay(day);
    final dayName = TeacherSlot.dayNames[day];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isToday ? Border.all(color: Colors.purple, width: 2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isToday
                  ? Colors.purple.withOpacity(0.1)
                  : (isDarkMode ? Colors.grey[850] : Colors.grey[100]),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Text(
                  dayName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isToday
                        ? Colors.purple
                        : (isDarkMode ? Colors.white : Colors.black87),
                  ),
                ),
                if (isToday) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.purple,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Today',
                        style: TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                ],
                const Spacer(),
                Text(
                  '${slots.length} ${slots.length == 1 ? 'class' : 'classes'}',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 13,
                  ),
                ),

              ],
            ),
          ),
          // Slots
          if (slots.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No classes scheduled',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...slots.map((s) => _buildSlotItem(s, isDarkMode)),
        ],
      ),
    );
  }

  Widget _buildSlotItem(TeacherSlot slot, bool isDarkMode) {
    final isLab = slot.courseType.toLowerCase().contains('lab') ||
        slot.courseType.toLowerCase().contains('sessional');
    final color = isLab ? Colors.purple : Colors.blue;

    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 50,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          slot.courseCode,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (slot.section != null && slot.section!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            slot.section!,
                            style: TextStyle(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    slot.courseTitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(slot.timeRange,
                          style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                      const SizedBox(width: 12),
                      Icon(Icons.room, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(slot.roomNumber,
                          style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }

  bool _isTodayDay(int dayOfWeek) {
    // DateTime.now().weekday: 1=Mon…7=Sun → convert to 0=Sun…6=Sat
    final now = DateTime.now().weekday; // 1-7
    final todayIndex = now == 7 ? 0 : now; // Sun=0
    return todayIndex == dayOfWeek;
  }
}
