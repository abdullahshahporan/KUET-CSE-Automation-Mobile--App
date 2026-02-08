import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;

import '../../Auth/change_password_screen.dart';
import '../../app_theme.dart';
import '../../services/supabase_service.dart';
import '../../shared/profile_widgets.dart';
import '../../theme/app_colors.dart';

class TeacherProfileScreen extends StatefulWidget {
  const TeacherProfileScreen({super.key});

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
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
    final profile = await SupabaseService.getTeacherProfile();
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
    final success = await SupabaseService.updateTeacherPhone(phone);
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
        appBar: AppBar(title: const Text('Profile'), backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final fullName = _profileData?['full_name'] ?? 'Teacher';
    final email = _profileData?['email'] ?? 'N/A';
    final phone = _profileData?['phone'] ?? 'Not set';
    final department = _profileData?['department'] ?? 'CSE';
    final designation = _profileData?['designation_display'] ?? 'Faculty';
    final teacherUid = _profileData?['teacher_uid'] ?? 'N/A';
    final officeRoom = _profileData?['office_room'] ?? 'N/A';
    final roomNo = _profileData?['room_no']?.toString() ?? 'N/A';
    final dateOfJoin = _profileData?['date_of_join'] ?? 'N/A';

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Header
              _buildHeader(isDarkMode, fullName, designation, department),
              const SizedBox(height: 16),

              // Stats
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(child: buildStatCard('Department', department, Icons.apartment_rounded, AppColors.primary, isDarkMode)),
                    const SizedBox(width: 10),
                    Expanded(child: buildStatCard('Room', roomNo != 'N/A' ? roomNo : '—', Icons.meeting_room_rounded, AppColors.accent, isDarkMode)),
                    const SizedBox(width: 10),
                    Expanded(child: buildStatCard('UID', _shortenUid(teacherUid), Icons.fingerprint_rounded, AppColors.teal, isDarkMode)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Academic Info
              buildProfileSection(isDarkMode, 'Academic Information', Icons.school_outlined, [
                buildInfoTile(Icons.fingerprint, 'Teacher UID', teacherUid, isDarkMode),
                buildInfoTile(Icons.work_outline, 'Designation', designation, isDarkMode),
                buildInfoTile(Icons.apartment, 'Department', department, isDarkMode),
                buildInfoTile(Icons.meeting_room_outlined, 'Office Room', officeRoom, isDarkMode),
                buildInfoTile(Icons.door_sliding_outlined, 'Room No', roomNo, isDarkMode),
                buildInfoTile(Icons.date_range_outlined, 'Date of Joining', formatDate(dateOfJoin), isDarkMode),
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

  Widget _buildHeader(bool isDarkMode, String name, String designation, String department) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
              : [AppColors.primary, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'T',
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(designation, style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9)), textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text('Department of $department', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.75)), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  String _shortenUid(String uid) => uid.length > 6 ? uid.substring(0, 6) : uid;
}
