import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../shared/profile_widgets.dart';
import '../../theme/app_colors.dart';

/// Full-screen editor for all teacher profile fields.
class EditTeacherProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profileData;

  const EditTeacherProfileScreen({super.key, required this.profileData});

  @override
  State<EditTeacherProfileScreen> createState() => _EditTeacherProfileScreenState();
}

class _EditTeacherProfileScreenState extends State<EditTeacherProfileScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _officeRoomCtrl;
  late final TextEditingController _roomNoCtrl;
  String _designation = 'LECTURER';
  String _department = 'CSE';
  bool _isSaving = false;

  static const _designations = [
    'LECTURER',
    'ASSISTANT_PROFESSOR',
    'ASSOCIATE_PROFESSOR',
    'PROFESSOR',
  ];

  static const _designationLabels = {
    'LECTURER': 'Lecturer',
    'ASSISTANT_PROFESSOR': 'Assistant Professor',
    'ASSOCIATE_PROFESSOR': 'Associate Professor',
    'PROFESSOR': 'Professor',
  };

  @override
  void initState() {
    super.initState();
    final d = widget.profileData;
    _nameCtrl = TextEditingController(text: d['full_name'] ?? '');
    _phoneCtrl = TextEditingController(text: d['phone'] ?? '');
    _officeRoomCtrl = TextEditingController(text: d['office_room'] ?? '');
    _roomNoCtrl = TextEditingController(text: d['room_no']?.toString() ?? '');
    _designation = d['designation'] ?? 'LECTURER';
    _department = d['department'] ?? 'CSE';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _officeRoomCtrl.dispose();
    _roomNoCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _showSnack('Name cannot be empty', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    final fields = <String, dynamic>{
      'full_name': name,
      'phone': _phoneCtrl.text.trim(),
      'designation': _designation,
      'department': _department,
      'office_room': _officeRoomCtrl.text.trim().isNotEmpty
          ? _officeRoomCtrl.text.trim()
          : null,
      'room_no': _roomNoCtrl.text.trim().isNotEmpty
          ? int.tryParse(_roomNoCtrl.text.trim())
          : null,
    };

    final success = await SupabaseService.updateTeacherProfile(fields);

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        showResultSnackBar(context, success: true, message: 'Profile updated successfully!');
        Navigator.pop(context, true); // true = changed
      } else {
        _showSnack('Failed to update profile. Try again.', isError: true);
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary(isDark),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Save',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    (_nameCtrl.text.isNotEmpty ? _nameCtrl.text[0] : 'T').toUpperCase(),
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            _buildField('Full Name', _nameCtrl, Icons.person_outline, isDark),
            _buildField('Phone', _phoneCtrl, Icons.phone_outlined, isDark,
                keyboardType: TextInputType.phone),
            _buildDropdown(
              label: 'Designation',
              icon: Icons.work_outline,
              value: _designation,
              items: _designations,
              displayMap: _designationLabels,
              isDark: isDark,
              onChanged: (v) => setState(() => _designation = v!),
            ),
            _buildDropdown(
              label: 'Department',
              icon: Icons.apartment,
              value: _department,
              items: const ['CSE', 'EEE', 'ME', 'CE', 'ECE', 'IEM', 'BME', 'MTE', 'URP', 'Chem', 'Math', 'Physics', 'Hum', 'ESE'],
              isDark: isDark,
              onChanged: (v) => setState(() => _department = v!),
            ),
            _buildField('Office Room', _officeRoomCtrl, Icons.meeting_room_outlined, isDark),
            _buildField('Room No', _roomNoCtrl, Icons.door_sliding_outlined, isDark,
                keyboardType: TextInputType.number),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl,
    IconData icon,
    bool isDark, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary(isDark),
              )),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            keyboardType: keyboardType,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary(isDark),
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
              filled: true,
              fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.border(isDark)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.border(isDark)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required bool isDark,
    required ValueChanged<String?> onChanged,
    Map<String, String>? displayMap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary(isDark),
              )),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: items.contains(value) ? value : items.first,
            isExpanded: true,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
              filled: true,
              fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.border(isDark)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.border(isDark)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
            dropdownColor: AppColors.surface(isDark),
            items: items.map((v) => DropdownMenuItem(
              value: v,
              child: Text(
                displayMap?[v] ?? v,
                style: TextStyle(fontSize: 15, color: AppColors.textPrimary(isDark)),
              ),
            )).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
