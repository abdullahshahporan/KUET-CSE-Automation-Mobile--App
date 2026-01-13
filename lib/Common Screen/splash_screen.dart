import 'package:flutter/material.dart';
import 'dart:async';
import 'package:kuet_cse_automation/Common%20Screen/main_bottom_navbar_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _animationController.forward();
    
    Timer(const Duration(seconds: 4), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainBottomNavBarScreen()),
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Monitor frame
              Container(
                width: 320,
                height: 240,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey[700]!,
                    width: 8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.grey[900]!,
                          Colors.black,
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Coding background effect
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.3,
                            child: SingleChildScrollView(
                              physics: const NeverScrollableScrollPhysics(),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  '''void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CSE',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

int fibonacci(int n) {
  if (n <= 1) return n;
  return fibonacci(n - 1) + fibonacci(n - 2);
}''',
                                  style: TextStyle(
                                    fontFamily: 'Courier',
                                    fontSize: 10,
                                    color: Colors.green[400],
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // CSE Title with gradient and glow
                        Center(
                          child: ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                Colors.blue[300]!,
                                Colors.cyan[300]!,
                                Colors.blue[400]!,
                              ],
                            ).createShader(bounds),
                            child: Text(
                              'CSE',
                              style: TextStyle(
                                fontSize: 56,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 8,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.blue.withOpacity(0.8),
                                    blurRadius: 20,
                                  ),
                                  Shadow(
                                    color: Colors.cyan.withOpacity(0.6),
                                    blurRadius: 40,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Monitor stand
              Container(
                width: 80,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 120,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 40),
              // Loading indicator
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[400]!),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'KUET CSE Automation',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}