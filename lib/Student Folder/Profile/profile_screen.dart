import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;

import '../../Auth/change_password_screen.dart';
import '../../app_theme.dart';
import '../../services/supabase_service.dart';
import '../../shared/profile_widgets.dart';
import '../../theme/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;
  bool _isUpdating = false;
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final profile = await SupabaseService.getStudentProfile();
    if (mounted) {
      setState(() {
        _profileData = profile;
        _isLoading = false;
        _phoneController.text = profile?['phone'] ?? '';
      });
    }
  }

  Future<void> _updatePhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    setState(() => _isUpdating = true);
    final success = await SupabaseService.updateStudentPhone(phone);
    if (mounted) {
      setState(() => _isUpdating = false);
      if (success) setState(() => _profileData?['phone'] = phone);
      showResultSnackBar(
        context,
        success: success,
        message: success ? 'Phone number updated!' : 'Failed to update. Try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = provider.Provider.of<ThemeProvider>(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background(isDarkMode),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final fullName = _profileData?['full_name'] ?? 'Student';
    final rollNo = _profileData?['roll_no'] ?? 'N/A';
    final email = _profileData?['email'] ?? 'N/A';
    final phone = _profileData?['phone'] ?? 'Not set';
    final session = _profileData?['session'] ?? 'N/A';
    final yearDisplay = _profileData?['year_display'] ?? '1st';
    final semesterDisplay = _profileData?['semester_display'] ?? '1st';
    final batch = _profileData?['batch'] ?? 'N/A';
    final section = _profileData?['section'] ?? 'N/A';
    final cgpaStr = _profileData?['cgpa']?.toString() ?? 'N/A';

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Header
              _buildHeader(isDarkMode, fullName, rollNo, yearDisplay, semesterDisplay),
              const SizedBox(height: 16),

              // Stats
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(child: buildStatCard('CGPA', cgpaStr, Icons.star_rounded, AppColors.gold, isDarkMode)),
                    const SizedBox(width: 10),
                    Expanded(child: buildStatCard('Year', yearDisplay, Icons.school, AppColors.primary, isDarkMode)),
                    const SizedBox(width: 10),
                    Expanded(child: buildStatCard('Semester', semesterDisplay, Icons.calendar_today, AppColors.accent, isDarkMode)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Academic Info
              buildProfileSection(isDarkMode, 'Academic Information', Icons.school_outlined, [
                buildInfoTile(Icons.badge_outlined, 'Roll Number', rollNo, isDarkMode),
                buildInfoTile(Icons.calendar_month, 'Session', session, isDarkMode),
                buildInfoTile(Icons.group_outlined, 'Batch', batch, isDarkMode),
                buildInfoTile(Icons.category_outlined, 'Section', section, isDarkMode),
                buildInfoTile(Icons.timeline, 'Term', '${_profileData?['term'] ?? 'N/A'}', isDarkMode),
              ]),
              const SizedBox(height: 12),

              // Contact
              buildProfileSection(isDarkMode, 'Contact Information', Icons.contact_mail_outlined, [
                buildInfoTile(Icons.email_outlined, 'Email', email, isDarkMode),
                buildInfoTile(Icons.phone_outlined, 'Phone', phone, isDarkMode,
                  editable: true,
                  onEdit: () => showEditPhoneDialog(
                    context: context,
                    isDarkMode: isDarkMode,
                    controller: _phoneController,
                    isUpdating: _isUpdating,
                    onSave: _updatePhone,
                  ),
                ),
              ]),
              const SizedBox(height: 12),

              // Settings
              buildProfileSection(isDarkMode, 'Settings', Icons.settings_outlined, [
                buildDarkModeToggle(isDarkMode, themeProvider.toggleTheme),
                const Divider(height: 1),
                buildActionTile(Icons.lock_outline, 'Change Password', isDarkMode, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen()));
                }),
              ]),
              const SizedBox(height: 16),

              // Logout
              buildLogoutButton(context, isDarkMode),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode, String name, String rollNo, String year, String semester) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 28),
      decoration: BoxDecoration(
        gradient: isDarkMode
            ? const LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF16213E)], begin: Alignment.topLeft, end: Alignment.bottomRight)
            : LinearGradient(colors: [Colors.blue[700]!, Colors.cyan[500]!], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.3), width: 3)),
            child: CircleAvatar(
              radius: 44,
              backgroundColor: Colors.white.withOpacity(isDarkMode ? 0.1 : 0.2),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'S',
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text('Roll: $rollNo', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.85))),
          const SizedBox(height: 2),
          Text('CSE — $year Year, $semester Semester', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.75))),
        ],
      ),
    );
  }
}
