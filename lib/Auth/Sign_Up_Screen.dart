import 'package:flutter/material.dart';
import 'package:kuet_cse_automation/Auth/First_password_screen.dart';
import '../theme/app_colors.dart';
import '../services/supabase_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailVerified = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Determine role from email domain
  String _getRoleFromEmail(String email) {
    email = email.toLowerCase();
    if (email.endsWith('@stud.kuet.ac.bd')) {
      return 'STUDENT';
    } else if (email.endsWith('@cse.kuet.ac.bd')) {
      return 'TEACHER';
    } else if (email.endsWith('@kuet.ac.bd')) {
      return 'OFFICER_STAFF';
    }
    return 'STUDENT'; // Default fallback
  }

  Future<void> _verifyEmail() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final email = _emailController.text.trim().toLowerCase();

        // STEP 1: Check if email exists in users table (pre-seeded by admin)
        final response = await SupabaseService.from(
          'users',
        ).select('id, email, password_hash').eq('email', email).maybeSingle();

        if (mounted) {
          setState(() => _isLoading = false);

          if (response == null) {
            // Email not found - Not authorized
            _showErrorDialog(
              'Email Not Found',
              'Your email is not registered in the system. '
                  'Please contact the office to register your email first.',
            );
            return;
          }

          // STEP 2: Check if user has already completed signup
          if (response['password_hash'] != null) {
            _showErrorDialog(
              'Account Already Exists',
              'This email is already registered. Please sign in instead.',
            );
            return;
          }

          // STEP 3: Determine role from email domain
          final role = _getRoleFromEmail(email);

          // STEP 4: Email verified - Proceed to password setup
          setState(() => _emailVerified = true);

          // Show success message with detected role
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Email verified! Registering as ${role.replaceAll('_', ' ')}',
              ),
              backgroundColor: AppColors.success,
            ),
          );

          // Navigate to password screen with user data
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => FirstPasswordScreen(
                  email: email,
                  userId: response['id'],
                  userRole: role,
                ),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showErrorDialog(
            'Connection Error',
            'Failed to verify email. Please check your internet connection and try again.',
          );
        }
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
          'Create Account',
          style: TextStyle(
            color: AppColors.textPrimary(isDarkMode),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Icon
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_add,
                      size: 50,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Register Your Account',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary(isDarkMode),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter your official KUET email address',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary(isDarkMode),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Email Field
                Text(
                  'Official Email Address',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary(isDarkMode),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: AppColors.textPrimary(isDarkMode)),
                  decoration: InputDecoration(
                    hintText: 'student@kuet.ac.bd',
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary(isDarkMode),
                    ),
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: AppColors.textSecondary(isDarkMode),
                    ),
                    suffixIcon: _emailVerified
                        ? Icon(Icons.check_circle, color: AppColors.success)
                        : null,
                    filled: true,
                    fillColor: AppColors.surface(isDarkMode),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.border(isDarkMode),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    // Validate KUET email domain
                    final lowerEmail = value.toLowerCase();
                    if (!lowerEmail.endsWith('@kuet.ac.bd') &&
                        !lowerEmail.endsWith('@stud.kuet.ac.bd') &&
                        !lowerEmail.endsWith('@cse.kuet.ac.bd')) {
                      return 'Please use your official KUET email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Info Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.info.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.info, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your email must be pre-registered by admin',
                          style: TextStyle(
                            color: AppColors.textSecondary(isDarkMode),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Verify Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Verify Email',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 20),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Sign In Link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(
                          color: AppColors.textSecondary(isDarkMode),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Sign In',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
