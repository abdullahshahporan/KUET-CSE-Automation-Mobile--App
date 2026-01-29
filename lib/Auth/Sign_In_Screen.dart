import 'package:flutter/material.dart';
import 'package:kuet_cse_automation/Auth/Reset_Password_Screen.dart';
import 'package:kuet_cse_automation/Auth/Sign_Up_Screen.dart';
import 'package:kuet_cse_automation/Student Folder/Common Screen/main_bottom_navbar_screen.dart';
import 'package:kuet_cse_automation/Teacher/teacher_navbar/teacher_navbar_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import '../theme/app_colors.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final email = _emailController.text.trim().toLowerCase();
        final password = _passwordController.text;

        // Sign in with Supabase Auth
        final authResponse = await SupabaseService.auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (authResponse.user == null) {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Sign in failed. Please try again.'),
                backgroundColor: AppColors.danger,
              ),
            );
          }
          return;
        }

        // Check if email is verified
        if (authResponse.user!.emailConfirmedAt == null) {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Please verify your email first. Check your inbox.',
                ),
                backgroundColor: AppColors.warning,
              ),
            );
          }
          return;
        }

        // Get user role from custom users table
        final userResponse = await SupabaseService.from('users')
            .select('id, role, status')
            .eq('email', email)
            .maybeSingle();

        if (mounted) {
          setState(() => _isLoading = false);

          if (userResponse == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'User profile not found. Please contact admin.',
                ),
                backgroundColor: AppColors.danger,
              ),
            );
            return;
          }

          // Check if account is disabled
          if (userResponse['status'] == 'DISABLED') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Your account has been disabled. Contact admin.',
                ),
                backgroundColor: AppColors.danger,
              ),
            );
            return;
          }

          // Sign in successful - Navigate based on role
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Sign in successful!'),
              backgroundColor: AppColors.success,
            ),
          );

          await Future.delayed(const Duration(milliseconds: 300));

          if (mounted) {
            final role = userResponse['role'];
            if (role == 'TEACHER') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const TeacherMainScreen(),
                ),
              );
            } else if (role == 'STUDENT') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const MainBottomNavBarScreen(),
                ),
              );
            } else {
              // OFFICER_STAFF or ADMIN - default to student screen for now
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const MainBottomNavBarScreen(),
                ),
              );
            }
          }
        }
      } on AuthException catch (e) {
        // Handle specific auth errors
        if (mounted) {
          setState(() => _isLoading = false);
          String errorMessage;
          
          if (e.message.contains('Invalid login credentials')) {
            errorMessage = 'Wrong email or password. Please try again.';
          } else if (e.message.contains('Email not confirmed')) {
            errorMessage = 'Please verify your email first. Check your inbox.';
          } else if (e.message.contains('User not found')) {
            errorMessage = 'No account found with this email.';
          } else {
            errorMessage = e.message;
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // Logo/Icon
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.accent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.school,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Welcome Text
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary(isDarkMode),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to KUET CSE Automation',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary(isDarkMode),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // Email Field
                Text(
                  'Email Address',
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
                    hintText: 'Enter your email',
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary(isDarkMode),
                    ),
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: AppColors.textSecondary(isDarkMode),
                    ),
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
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Password Field
                Text(
                  'Password',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary(isDarkMode),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(color: AppColors.textPrimary(isDarkMode)),
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary(isDarkMode),
                    ),
                    prefixIcon: Icon(
                      Icons.lock_outlined,
                      color: AppColors.textSecondary(isDarkMode),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.textSecondary(isDarkMode),
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
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
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ResetPasswordScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Sign In Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signIn,
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
                        : const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Divider
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: AppColors.border(isDarkMode)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: AppColors.textSecondary(isDarkMode),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: AppColors.border(isDarkMode)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Sign Up Link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          color: AppColors.textSecondary(isDarkMode),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignUpScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Database Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.info.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.info, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Use your registered email and password to sign in',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary(isDarkMode),
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
