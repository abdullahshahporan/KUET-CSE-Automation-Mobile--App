import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;

import '../../Auth/Sign_In_Screen.dart';
import '../../Auth/change_password_screen.dart';
import '../../app_theme.dart';
import '../../services/supabase_service.dart';
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
      if (success) {
        setState(() => _profileData?['phone'] = phone);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Phone number updated!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to update. Try again.'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _showEditPhoneDialog(bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated(isDarkMode),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit Phone', style: TextStyle(color: AppColors.textPrimary(isDarkMode))),
        content: TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: TextStyle(color: AppColors.textPrimary(isDarkMode)),
          decoration: InputDecoration(
            labelText: 'Phone Number',
            hintText: '+880 1XXXXXXXXX',
            prefixIcon: const Icon(Icons.phone),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: AppColors.surface(isDarkMode),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary(isDarkMode))),
          ),
          ElevatedButton(
            onPressed: _isUpdating
                ? null
                : () {
                    Navigator.pop(context);
                    _updatePhone();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated(isDarkMode),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Logout', style: TextStyle(color: AppColors.textPrimary(isDarkMode))),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: AppColors.textSecondary(isDarkMode)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary(isDarkMode))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await SupabaseService.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const SignInScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = provider.Provider.of<ThemeProvider>(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background(isDarkMode),
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
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
              // Profile Header
              _buildProfileHeader(isDarkMode, fullName, designation, department),

              const SizedBox(height: 16),

              // Quick Stats
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(child: _buildStatCard('Department', department, Icons.apartment_rounded, AppColors.primary, isDarkMode)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildStatCard('Room', roomNo != 'N/A' ? roomNo : '—', Icons.meeting_room_rounded, AppColors.accent, isDarkMode)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildStatCard('UID', _shortenUid(teacherUid), Icons.fingerprint_rounded, AppColors.teal, isDarkMode)),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Academic Info
              _buildSection(
                isDarkMode,
                'Academic Information',
                Icons.school_outlined,
                [
                  _buildInfoTile(Icons.fingerprint, 'Teacher UID', teacherUid, isDarkMode),
                  _buildInfoTile(Icons.work_outline, 'Designation', designation, isDarkMode),
                  _buildInfoTile(Icons.apartment, 'Department', department, isDarkMode),
                  _buildInfoTile(Icons.meeting_room_outlined, 'Office Room', officeRoom, isDarkMode),
                  _buildInfoTile(Icons.door_sliding_outlined, 'Room No', roomNo, isDarkMode),
                  _buildInfoTile(Icons.date_range_outlined, 'Date of Joining', _formatDate(dateOfJoin), isDarkMode),
                ],
              ),

              const SizedBox(height: 12),

              // Contact Info
              _buildSection(
                isDarkMode,
                'Contact Information',
                Icons.contact_mail_outlined,
                [
                  _buildInfoTile(Icons.email_outlined, 'Email', email, isDarkMode),
                  _buildInfoTile(Icons.phone_outlined, 'Phone', phone, isDarkMode, editable: true, onEdit: () => _showEditPhoneDialog(isDarkMode)),
                ],
              ),

              const SizedBox(height: 12),

              // Settings
              _buildSection(
                isDarkMode,
                'Settings',
                Icons.settings_outlined,
                [
                  // Dark Mode Toggle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: (isDarkMode ? Colors.amber : Colors.indigo).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                            size: 20,
                            color: isDarkMode ? Colors.amber : Colors.indigo,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Dark Mode',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary(isDarkMode),
                            ),
                          ),
                        ),
                        Switch.adaptive(
                          value: isDarkMode,
                          onChanged: (_) => themeProvider.toggleTheme(),
                          activeColor: Colors.white,
                          activeTrackColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  _buildActionTile(Icons.lock_outline, 'Change Password', isDarkMode, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen()));
                  }),
                ],
              ),

              const SizedBox(height: 16),

              // Logout
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _handleLogout(context, isDarkMode),
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? AppColors.darkSurfaceElevated : Colors.red[50],
                      foregroundColor: AppColors.danger,
                      side: BorderSide(color: AppColors.danger.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── HEADER ──────────────────────────────────────────────────────────────────

  Widget _buildProfileHeader(bool isDarkMode, String name, String designation, String department) {
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
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'T',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            designation,
            style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            'Department of $department',
            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.75)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── STAT CARD ───────────────────────────────────────────────────────────────

  Widget _buildStatCard(String label, String value, IconData icon, Color color, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface(isDarkMode),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(isDarkMode)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary(isDarkMode)),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: AppColors.textSecondary(isDarkMode))),
        ],
      ),
    );
  }

  // ── SECTION CONTAINER ───────────────────────────────────────────────────────

  Widget _buildSection(bool isDarkMode, String title, IconData headerIcon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface(isDarkMode),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(isDarkMode)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(headerIcon, size: 20, color: AppColors.primary),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(isDarkMode),
                  ),
                ),
              ],
            ),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── INFO TILE ───────────────────────────────────────────────────────────────

  Widget _buildInfoTile(IconData icon, String label, String value, bool isDarkMode, {bool editable = false, VoidCallback? onEdit}) {
    final hasValue = value != 'Not set' && value != 'N/A' && value.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: (editable ? AppColors.accent : AppColors.primary).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: editable ? AppColors.accent : AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: AppColors.textSecondary(isDarkMode))),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: hasValue ? AppColors.textPrimary(isDarkMode) : AppColors.textMuted,
                    fontStyle: hasValue ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          if (editable && onEdit != null)
            InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(Icons.edit_outlined, size: 16, color: AppColors.accent),
              ),
            )
          else
            Icon(Icons.lock, size: 14, color: AppColors.textMuted),
        ],
      ),
    );
  }

  // ── ACTION TILE ─────────────────────────────────────────────────────────────

  Widget _buildActionTile(IconData icon, String label, bool isDarkMode, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary(isDarkMode)),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  // ── HELPERS ─────────────────────────────────────────────────────────────────

  String _shortenUid(String uid) {
    if (uid.length > 6) return uid.substring(0, 6);
    return uid;
  }

  String _formatDate(String date) {
    if (date == 'N/A' || date.isEmpty) return 'N/A';
    try {
      final d = DateTime.parse(date);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return date;
    }
  }
}
