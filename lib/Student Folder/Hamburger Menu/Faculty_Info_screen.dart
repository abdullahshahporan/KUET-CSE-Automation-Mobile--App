import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_colors.dart';
import 'models/faculty.dart';
import 'widgets/faculty_list_item.dart';
import 'faculty_detail_screen.dart';

class FacultyInfoScreen extends StatefulWidget {
  const FacultyInfoScreen({super.key});

  @override
  State<FacultyInfoScreen> createState() => _FacultyInfoScreenState();
}

class _FacultyInfoScreenState extends State<FacultyInfoScreen> {
  late Future<List<Faculty>> _facultyFuture;

  @override
  void initState() {
    super.initState();
    _facultyFuture = _fetchFaculty();
  }

  Future<List<Faculty>> _fetchFaculty() async {
    final data = await SupabaseService.from('teachers')
        .select('full_name, designation, phone, office_room, room_no, is_on_leave, profiles(email)')
        .eq('department', 'CSE');

    final teachers = (data as List)
        .map((json) => Faculty.fromJson(json as Map<String, dynamic>))
        .toList();

    // Sort: by designation, then by name, on-leave at bottom
    teachers.sort(Faculty.compare);

    return teachers;
  }

  Map<String, List<Faculty>> _groupByDesignation(List<Faculty> faculty) {
    final groups = <String, List<Faculty>>{};
    
    for (final f in faculty) {
      if (f.isOnLeave) {
        groups.putIfAbsent('On Leave', () => []).add(f);
      } else {
        groups.putIfAbsent(f.formattedDesignation, () => []).add(f);
      }
    }
    
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      appBar: AppBar(
        backgroundColor: AppColors.surface(isDarkMode),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textPrimary(isDarkMode),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Faculty',
          style: TextStyle(
            color: AppColors.textPrimary(isDarkMode),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: FutureBuilder<List<Faculty>>(
        future: _facultyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.textSecondary(isDarkMode),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load faculty',
                    style: TextStyle(
                      color: AppColors.textPrimary(isDarkMode),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _facultyFuture = _fetchFaculty()),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final faculty = snapshot.data!;
          if (faculty.isEmpty) {
            return Center(
              child: Text(
                'No faculty found',
                style: TextStyle(color: AppColors.textSecondary(isDarkMode)),
              ),
            );
          }

          final groups = _groupByDesignation(faculty);

          return RefreshIndicator(
            onRefresh: () async => setState(() => _facultyFuture = _fetchFaculty()),
            child: ListView.builder(
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final designation = groups.keys.elementAt(index);
                final members = groups[designation]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      color: isDarkMode
                          ? Colors.grey[850]
                          : Colors.grey[200],
                      child: Text(
                        designation,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary(isDarkMode),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    
                    // Faculty list items
                    ...members.map((f) => FacultyListItem(
                      faculty: f,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FacultyDetailScreen(faculty: f),
                          ),
                        );
                      },
                    )),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}