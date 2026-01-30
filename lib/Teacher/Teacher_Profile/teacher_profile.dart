import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;

import '../../Auth/Sign_In_Screen.dart';
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
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
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
        _addressController.text = profile?['address'] ?? '';
      });
    }
  }

  Future<void> _updateContactInfo() async {
    setState(() => _isUpdating = true);
    
    final success = await SupabaseService.updateContactInfo(
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
    );
    
    if (mounted) {
      setState(() => _isUpdating = false);
      
      if (success) {
        setState(() {
          _profileData?['phone'] = _phoneController.text.trim();
          _profileData?['address'] = _addressController.text.trim();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Contact information updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to update. Please try again.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _showEditContactDialog(BuildContext context, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? AppColors.darkSurfaceElevated : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Edit Contact Info',
            style: TextStyle(color: AppColors.textPrimary(isDarkMode)),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '+880 1XXXXXXXXX',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: AppColors.surface(isDarkMode),
                  ),
                  style: TextStyle(color: AppColors.textPrimary(isDarkMode)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    hintText: 'Enter your office address',
                    prefixIcon: const Icon(Icons.location_on),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: AppColors.surface(isDarkMode),
                  ),
                  style: TextStyle(color: AppColors.textPrimary(isDarkMode)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary(isDarkMode)),
              ),
            ),
            ElevatedButton(
              onPressed: _isUpdating
                  ? null
                  : () {
                      Navigator.pop(context);
                      _updateContactInfo();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isUpdating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _handleLogout(BuildContext context, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? AppColors.darkSurfaceElevated : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Logout',
            style: TextStyle(color: AppColors.textPrimary(isDarkMode)),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: AppColors.textSecondary(isDarkMode)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary(isDarkMode)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await SupabaseService.auth.signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const SignInScreen()),
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background(isDarkMode),
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: AppColors.surface(isDarkMode),
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Extract data with fallbacks
    final fullName = _profileData?['full_name'] ?? 'Teacher';
    final email = _profileData?['email'] ?? 'N/A';
    final phone = _profileData?['phone'] ?? 'Not set';
    final address = _profileData?['address'] ?? 'Not set';
    final department = _profileData?['department'] ?? 'Computer Science & Engineering';
    final designation = _profileData?['designation_display'] ?? 'Faculty';
    final employeeId = _profileData?['employee_id'] ?? 'N/A';
    final experience = _profileData?['experience_years'] ?? 0;
    final officeRoom = _profileData?['office_room'] ?? 'N/A';

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.surface(isDarkMode),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary(isDarkMode)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
              _buildQuickStats(isDarkMode, experience),

              const SizedBox(height: 16),

              // Personal Information
              _buildPersonalInfo(isDarkMode, email, phone, address, employeeId),

              const SizedBox(height: 16),

              // Academic Information
              _buildAcademicInfo(isDarkMode, department, designation, experience, officeRoom),

              const SizedBox(height: 16),

              // Settings Section
              _buildSettingsSection(isDarkMode),

              const SizedBox(height: 24),

              // Logout Button
              _buildLogoutButton(isDarkMode),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(bool isDarkMode, String name, String designation, String department) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            designation,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            department,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(bool isDarkMode, int experience) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard('Courses', '0', Icons.book, AppColors.primary, isDarkMode),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard('Students', '0', Icons.people, AppColors.accent, isDarkMode),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard('Experience', '${experience}Y', Icons.workspace_premium, Colors.amber, isDarkMode),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(isDarkMode),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(isDarkMode)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDarkMode),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary(isDarkMode),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo(bool isDarkMode, String email, String phone, String address, String employeeId) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(isDarkMode),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(isDarkMode)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(isDarkMode),
                ),
              ),
              IconButton(
                onPressed: () => _showEditContactDialog(context, isDarkMode),
                icon: Icon(Icons.edit, color: AppColors.primary, size: 20),
                tooltip: 'Edit Contact Info',
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.email, 'Email', email, isDarkMode, false),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.phone, 'Phone', phone, isDarkMode, true),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.location_on, 'Address', address, isDarkMode, true),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.badge, 'Employee ID', employeeId, isDarkMode, false),
        ],
      ),
    );
  }

  Widget _buildAcademicInfo(bool isDarkMode, String department, String designation, int experience, String officeRoom) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(isDarkMode),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(isDarkMode)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Academic Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDarkMode),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.school, 'Department', department, isDarkMode, false),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.work, 'Designation', designation, isDarkMode, false),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.calendar_today, 'Experience', '$experience years', isDarkMode, false),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.meeting_room, 'Office Room', officeRoom, isDarkMode, false),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDarkMode, bool isEditable) {
    final hasValue = value != 'Not set' && value != 'N/A' && value.isNotEmpty;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (isEditable ? AppColors.accent : AppColors.primary).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: isEditable ? AppColors.accent : AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary(isDarkMode),
                ),
              ),
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
        Icon(
          isEditable ? Icons.edit_outlined : Icons.lock,
          size: 14,
          color: isEditable ? AppColors.accent : AppColors.textMuted,
        ),
      ],
    );
  }

  Widget _buildSettingsSection(bool isDarkMode) {
    final themeProvider = provider.Provider.of<ThemeProvider>(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(isDarkMode),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(isDarkMode)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDarkMode),
            ),
          ),
          const SizedBox(height: 16),

          // Dark Mode Toggle
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (isDarkMode ? Colors.amber : Colors.indigo).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  size: 20,
                  color: isDarkMode ? Colors.amber : Colors.indigo,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dark Mode',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary(isDarkMode),
                      ),
                    ),
                    Text(
                      isDarkMode ? 'On' : 'Off',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary(isDarkMode),
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: isDarkMode,
                onChanged: (value) => themeProvider.toggleTheme(),
                activeColor: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _handleLogout(context, isDarkMode),
          icon: const Icon(Icons.logout, size: 20),
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
    );
  }
}
