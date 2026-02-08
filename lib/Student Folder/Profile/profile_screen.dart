import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;

import '../../Auth/Sign_In_Screen.dart';
import '../../Auth/change_password_screen.dart';
import '../../app_theme.dart';
import '../../services/supabase_service.dart';
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

  void _handleLogout(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
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
    final cgpa = _profileData?['cgpa'];
    final cgpaStr = cgpa != null ? cgpa.toString() : 'N/A';

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Profile Header
              _buildProfileHeader(isDarkMode, fullName, rollNo, yearDisplay, semesterDisplay),

              const SizedBox(height: 16),

              // Quick Stats
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(child: _buildStatCard('CGPA', cgpaStr, Icons.star_rounded, AppColors.gold, isDarkMode)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildStatCard('Year', yearDisplay, Icons.school, AppColors.primary, isDarkMode)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildStatCard('Semester', semesterDisplay, Icons.calendar_today, AppColors.accent, isDarkMode)),
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
                  _buildInfoTile(Icons.badge_outlined, 'Roll Number', rollNo, isDarkMode),
                  _buildInfoTile(Icons.calendar_month, 'Session', session, isDarkMode),
                  _buildInfoTile(Icons.group_outlined, 'Batch', batch, isDarkMode),
                  _buildInfoTile(Icons.category_outlined, 'Section', section, isDarkMode),
                  _buildInfoTile(Icons.timeline, 'Term', '${_profileData?['term'] ?? 'N/A'}', isDarkMode),
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
                    onPressed: () => _handleLogout(context),
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

  Widget _buildProfileHeader(bool isDarkMode, String name, String rollNo, String year, String semester) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 28),
      decoration: BoxDecoration(
        gradient: isDarkMode
            ? const LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF16213E)], begin: Alignment.topLeft, end: Alignment.bottomRight)
            : LinearGradient(colors: [Colors.blue[700]!, Colors.cyan[500]!], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
            ),
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
          Text(
            name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            'Roll: $rollNo',
            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.85)),
          ),
          const SizedBox(height: 2),
          Text(
            'CSE — $year Year, $semester Semester',
            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.75)),
          ),
        ],
      ),
    );
  }

  // ── STAT CARD ───────────────────────────────────────────────────────────────

  Widget _buildStatCard(String label, String value, IconData icon, Color color, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary(isDarkMode)),
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
}
