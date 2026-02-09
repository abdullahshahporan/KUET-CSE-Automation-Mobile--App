import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_colors.dart';

class FacultyInfoScreen extends StatefulWidget {
  const FacultyInfoScreen({super.key});

  @override
  State<FacultyInfoScreen> createState() => _FacultyInfoScreenState();
}

class _FacultyInfoScreenState extends State<FacultyInfoScreen> {
  late Future<Map<String, List<Map<String, dynamic>>>> _facultyFuture;

  // Designation display order
  static const _designationOrder = [
    'PROFESSOR',
    'ASSOCIATE_PROFESSOR',
    'ASSISTANT_PROFESSOR',
    'LECTURER',
  ];

  static const _designationLabels = {
    'PROFESSOR': 'Professors',
    'ASSOCIATE_PROFESSOR': 'Associate Professors',
    'ASSISTANT_PROFESSOR': 'Assistant Professors',
    'LECTURER': 'Lecturers',
  };

  @override
  void initState() {
    super.initState();
    _facultyFuture = _fetchFaculty();
  }

  Future<Map<String, List<Map<String, dynamic>>>> _fetchFaculty() async {
    final data = await SupabaseService.from('teachers')
        .select('full_name, designation, phone, office_room, room_no, is_on_leave, profiles(email)')
        .eq('department', 'CSE')
        .order('full_name');

    final List<Map<String, dynamic>> teachers = List<Map<String, dynamic>>.from(data);

    // Separate on-leave and active, then group active by designation
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    final List<Map<String, dynamic>> onLeave = [];

    for (final t in teachers) {
      if (t['is_on_leave'] == true) {
        onLeave.add(t);
      } else {
        final key = (t['designation'] ?? 'LECTURER').toString().toUpperCase();
        grouped.putIfAbsent(key, () => []).add(t);
      }
    }

    // Build ordered result
    final result = <String, List<Map<String, dynamic>>>{};
    for (final d in _designationOrder) {
      if (grouped.containsKey(d)) result[d] = grouped[d]!;
    }
    if (onLeave.isNotEmpty) result['ON_LEAVE'] = onLeave;

    return result;
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
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary(isDarkMode), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Faculty Information',
          style: TextStyle(color: AppColors.textPrimary(isDarkMode), fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
        future: _facultyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: AppColors.textSecondary(isDarkMode)),
                    const SizedBox(height: 12),
                    Text('Failed to load faculty info', style: TextStyle(color: AppColors.textPrimary(isDarkMode), fontSize: 16)),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _facultyFuture = _fetchFaculty()),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final grouped = snapshot.data!;
          if (grouped.isEmpty) {
            return Center(child: Text('No faculty found', style: TextStyle(color: AppColors.textSecondary(isDarkMode))));
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() => _facultyFuture = _fetchFaculty()),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: grouped.length,
              itemBuilder: (context, sectionIndex) {
                final key = grouped.keys.elementAt(sectionIndex);
                final teachers = grouped[key]!;
                final label = key == 'ON_LEAVE' ? 'Faculty on Leave' : (_designationLabels[key] ?? key);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (sectionIndex > 0) const SizedBox(height: 20),
                    _SectionHeader(title: label, isDarkMode: isDarkMode, isOnLeave: key == 'ON_LEAVE', count: teachers.length),
                    ...teachers.map((t) => _FacultyCard(teacher: t, isDarkMode: isDarkMode)),
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDarkMode;
  final bool isOnLeave;
  final int count;

  const _SectionHeader({required this.title, required this.isDarkMode, this.isOnLeave = false, this.count = 0});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14, top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOnLeave
              ? [Colors.orange.withValues(alpha: 0.12), Colors.orange.withValues(alpha: 0.04)]
              : [AppColors.primary.withValues(alpha: 0.12), AppColors.primary.withValues(alpha: 0.03)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: isOnLeave ? Colors.orange : AppColors.primary, width: 3)),
      ),
      child: Row(
        children: [
          Icon(
            isOnLeave ? Icons.flight_takeoff_rounded : Icons.school_rounded,
            size: 18,
            color: isOnLeave ? Colors.orange : AppColors.primary,
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary(isDarkMode), letterSpacing: 0.3),
          ),
          const Spacer(),
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (isOnLeave ? Colors.orange : AppColors.primary).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('$count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isOnLeave ? Colors.orange : AppColors.primary)),
            ),
        ],
      ),
    );
  }
}

class _FacultyCard extends StatelessWidget {
  final Map<String, dynamic> teacher;
  final bool isDarkMode;

  const _FacultyCard({required this.teacher, required this.isDarkMode});

  String get _name => teacher['full_name'] ?? '';
  String get _designation => _formatDesignation(teacher['designation'] ?? '');
  String get _email => (teacher['profiles'] is Map) ? (teacher['profiles']['email'] ?? '') : '';
  String get _phone => teacher['phone']?.toString() ?? '';
  String get _room {
    if (teacher['room_no'] != null) return teacher['room_no'].toString();
    if (teacher['office_room'] != null && teacher['office_room'].toString().isNotEmpty) return teacher['office_room'];
    return '';
  }

  bool get _isOnLeave => teacher['is_on_leave'] == true;

  static String _formatDesignation(String raw) {
    return raw.split('_').map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}').join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _isOnLeave ? Colors.orange : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface(isDarkMode),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _isOnLeave ? Colors.orange.withValues(alpha: 0.25) : AppColors.border(isDarkMode)),
        boxShadow: [
          BoxShadow(color: AppColors.shadow(isDarkMode), blurRadius: 10, offset: const Offset(0, 3)),
          BoxShadow(color: accentColor.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Top section: Avatar + Name + Designation
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                // Avatar with ring
                Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _isOnLeave
                          ? [Colors.orange.shade300, Colors.orange.shade600]
                          : [AppColors.primary, AppColors.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface(isDarkMode),
                    ),
                    child: Center(
                      child: Text(
                        _name.isNotEmpty ? _name[0].toUpperCase() : '?',
                        style: TextStyle(color: accentColor, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_name, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary(isDarkMode))),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(_designation, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: accentColor)),
                      ),
                    ],
                  ),
                ),
                if (_isOnLeave)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flight_takeoff_rounded, size: 12, color: Colors.orange),
                        SizedBox(width: 4),
                        Text('On Leave', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.orange)),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Divider
          Divider(height: 1, thickness: 0.5, color: AppColors.border(isDarkMode), indent: 16, endIndent: 16),

          // Bottom section: Info grid
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Row(
              children: [
                // Email
                Expanded(
                  flex: 3,
                  child: _InfoChip(
                    icon: Icons.email_outlined,
                    label: _email.isNotEmpty ? _email : '—',
                    isDarkMode: isDarkMode,
                    onTap: _email.isNotEmpty ? () => launchUrl(Uri.parse('mailto:$_email')) : null,
                  ),
                ),
                const SizedBox(width: 8),
                // Phone
                Expanded(
                  flex: 2,
                  child: _InfoChip(
                    icon: Icons.phone_outlined,
                    label: _phone.isNotEmpty ? _phone : '—',
                    isDarkMode: isDarkMode,
                    onTap: _phone.isNotEmpty ? () => launchUrl(Uri.parse('tel:$_phone')) : null,
                  ),
                ),
                if (_room.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.meeting_room_outlined,
                    label: _room,
                    isDarkMode: isDarkMode,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDarkMode;
  final VoidCallback? onTap;

  const _InfoChip({required this.icon, required this.label, required this.isDarkMode, this.onTap});

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: onTap != null ? AppColors.primary : AppColors.textSecondary(isDarkMode)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              color: onTap != null ? AppColors.primary : AppColors.textSecondary(isDarkMode),
              decoration: onTap != null ? TextDecoration.underline : null,
              decorationColor: AppColors.primary.withValues(alpha: 0.4),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    return onTap != null ? GestureDetector(onTap: onTap, child: child) : child;
  }
}
