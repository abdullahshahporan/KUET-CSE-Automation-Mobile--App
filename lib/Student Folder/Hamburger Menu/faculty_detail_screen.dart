import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_colors.dart';
import 'models/faculty.dart';
import 'widgets/contact_action_button.dart';

class FacultyDetailScreen extends StatelessWidget {
  final Faculty faculty;

  const FacultyDetailScreen({
    super.key,
    required this.faculty,
  });

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Handle error silently or show a snackbar if needed
      debugPrint('Could not launch $url: $e');
    }
  }

  void _callPhone() {
    if (faculty.phone != null) {
      _launchUrl('tel:${faculty.phone}');
    }
  }

  void _sendWhatsApp() {
    if (faculty.phone != null) {
      // Remove any non-digit characters
      final cleanPhone = faculty.phone!.replaceAll(RegExp(r'\D'), '');
      _launchUrl('https://wa.me/$cleanPhone');
    }
  }

  void _sendEmail() {
    if (faculty.email != null) {
      _launchUrl('mailto:${faculty.email}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final accentColor = faculty.isOnLeave ? Colors.orange : AppColors.primary;

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
          'Faculty Details',
          style: TextStyle(
            color: AppColors.textPrimary(isDarkMode),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            
            // Avatar
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withValues(alpha: 0.12),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.2),
                  width: 3,
                ),
              ),
              child: Center(
                child: Text(
                  faculty.initial,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 42,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Name
            Text(
              faculty.fullName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary(isDarkMode),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Designation
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                faculty.formattedDesignation,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
            ),
            
            // On-leave badge
            if (faculty.isOnLeave) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.flight_takeoff_rounded,
                      size: 16,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Currently on Leave',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Contact Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  ContactActionButton(
                    icon: Icons.phone,
                    label: 'Call',
                    color: Colors.green,
                    onTap: faculty.phone != null ? _callPhone : null,
                  ),
                  const SizedBox(width: 12),
                  ContactActionButton(
                    icon: Icons.chat,
                    label: 'WhatsApp',
                    color: const Color(0xFF25D366),
                    onTap: faculty.phone != null ? _sendWhatsApp : null,
                  ),
                  const SizedBox(width: 12),
                  ContactActionButton(
                    icon: Icons.email,
                    label: 'Email',
                    color: Colors.blue,
                    onTap: faculty.email != null ? _sendEmail : null,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Information Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface(isDarkMode),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border(isDarkMode)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary(isDarkMode),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Phone
                  if (faculty.phone != null)
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: faculty.phone!,
                      isDarkMode: isDarkMode,
                    ),
                  
                  if (faculty.phone != null && faculty.email != null)
                    const SizedBox(height: 16),
                  
                  // Email
                  if (faculty.email != null)
                    _InfoRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: faculty.email!,
                      isDarkMode: isDarkMode,
                    ),
                  
                  if (faculty.room != null) ...[
                    if (faculty.phone != null || faculty.email != null)
                      const SizedBox(height: 16),
                    
                    // Room
                    _InfoRow(
                      icon: Icons.meeting_room_outlined,
                      label: 'Room',
                      value: faculty.room!,
                      isDarkMode: isDarkMode,
                    ),
                  ],
                  
                  // Show message if no contact info
                  if (faculty.phone == null && faculty.email == null && faculty.room == null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'No contact information available',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary(isDarkMode),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDarkMode;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(alpha: 0.1),
          ),
          child: Icon(
            icon,
            size: 18,
            color: AppColors.primary,
          ),
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
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary(isDarkMode),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
