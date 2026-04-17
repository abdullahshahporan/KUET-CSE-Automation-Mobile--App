import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kuet_cse_automation/Auth/Sign_In_Screen.dart';
import 'package:kuet_cse_automation/Teacher/teacher_navbar/teacher_navbar_screen.dart';
import 'package:kuet_cse_automation/services/push_notification_service.dart';

import '../../services/supabase_service.dart';
import 'main_bottom_navbar_screen.dart';

// Terminal color constants — intentionally separate from AppColors
// so the splash always renders dark regardless of the selected theme.
const _kBg = Color(0xFF0C0C0C);
const _kGreen = Color(0xFF00FFC2);
const _kGreenDim = Color(0xFF00C49A);
const _kGray = Color(0xFF4A5568);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── typing lines ──────────────────────────────────────────────────────────
  final List<_TermLine> _lines = [
    _TermLine(text: r'$ init kuet-cse-mainframe --auth', duration: 800),
    _TermLine(text: 'Establishing connection...', duration: 700),
    _TermLine(text: 'Authenticating session token...', duration: 600),
    _TermLine(text: 'Loading department modules...', duration: 500),
    _TermLine(
      text: '[OK] Connected to campus_server',
      duration: 400,
      isOk: true,
    ),
    _TermLine(text: '[OK] Status: Authenticated', duration: 300, isOk: true),
  ];

  int _visibleLines = 0; // how many lines have started typing
  int _charIndex = 0; // chars typed in current line
  bool _cursorVisible = true; // blinking cursor
  double _progress = 0.0; // 0..1 progress bar

  late AnimationController _exitController;
  late Animation<Offset> _slideUpAnimation;
  late Animation<double> _exitFadeAnimation;

  Timer? _typeTimer;
  Timer? _cursorTimer;
  Timer? _progressTimer;
  Timer? _typingStartTimer;
  Timer? _lineAdvanceTimer;
  Timer? _progressStartTimer;
  Timer? _exitDelayTimer;

  @override
  void initState() {
    super.initState();
    PushNotificationService.markAppNotReady();

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideUpAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(0, -1)).animate(
          CurvedAnimation(parent: _exitController, curve: Curves.easeInCubic),
        );
    _exitFadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _exitController, curve: Curves.easeIn));

    // Blinking cursor
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 530), (_) {
      if (mounted) setState(() => _cursorVisible = !_cursorVisible);
    });

    _startTypingSequence();
  }

  void _startTypingSequence() {
    _typingStartTimer?.cancel();
    _typingStartTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _typeNextLine();
    });
  }

  void _typeNextLine() {
    if (!mounted || _visibleLines >= _lines.length) {
      _startProgressBar();
      return;
    }

    if (_visibleLines == 0 || _charIndex == 0) {
      if (mounted) setState(() {}); // trigger rebuild to show new line stub
    }

    final line = _lines[_visibleLines];
    final charDelay = line.duration ~/ line.text.length;

    _typeTimer = Timer.periodic(
      Duration(milliseconds: charDelay.clamp(18, 60)),
      (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        setState(() => _charIndex++);
        if (_charIndex >= line.text.length) {
          t.cancel();
          _charIndex = 0;
          _visibleLines++;
          _lineAdvanceTimer?.cancel();
          _lineAdvanceTimer = Timer(const Duration(milliseconds: 120), () {
            if (!mounted) return;
            _typeNextLine();
          });
        }
      },
    );
  }

  void _startProgressBar() {
    _progressStartTimer?.cancel();
    _progressStartTimer = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      _progressTimer = Timer.periodic(const Duration(milliseconds: 40), (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        setState(() => _progress = (_progress + 0.012).clamp(0.0, 1.0));
        if (_progress >= 1.0) {
          t.cancel();
          _exitDelayTimer?.cancel();
          _exitDelayTimer = Timer(const Duration(milliseconds: 400), () {
            if (!mounted) return;
            _triggerExit();
          });
        }
      });
    });
  }

  void _triggerExit() {
    _exitController.forward().then((_) => _navigateBasedOnSession());
  }

  void _navigateBasedOnSession() {
    if (!mounted) return;
    Widget destination;
    if (SupabaseService.isLoggedIn) {
      final role = SupabaseService.currentRole;
      destination = role == 'TEACHER' || role == 'HEAD'
          ? const TeacherMainScreen()
          : const MainBottomNavBarScreen();
    } else {
      destination = const SignInScreen();
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (ctx, anim, secAnim) => destination,
        transitionsBuilder: (ctx, anim, secAnim, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _cursorTimer?.cancel();
    _progressTimer?.cancel();
    _typingStartTimer?.cancel();
    _lineAdvanceTimer?.cancel();
    _progressStartTimer?.cancel();
    _exitDelayTimer?.cancel();
    _exitController.dispose();
    super.dispose();
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SlideTransition(
        position: _slideUpAnimation,
        child: FadeTransition(
          opacity: _exitFadeAnimation,
          child: _buildTerminal(),
        ),
      ),
    );
  }

  Widget _buildTerminal() {
    return Container(
      color: _kBg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWindowBar(),
              const SizedBox(height: 28),
              _buildBigTitle(),
              const SizedBox(height: 32),
              Expanded(child: _buildLogLines()),
              const SizedBox(height: 24),
              if (_progress > 0) _buildProgressBar(),
              if (_progress > 0) const SizedBox(height: 8),
              if (_progress > 0) _buildProgressLabel(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // Fake macOS-style traffic lights + path
  Widget _buildWindowBar() {
    return Row(
      children: [
        _dot(const Color(0xFFFF5F57)),
        const SizedBox(width: 8),
        _dot(const Color(0xFFFFBD2E)),
        const SizedBox(width: 8),
        _dot(const Color(0xFF28C840)),
        const SizedBox(width: 16),
        Text(
          'kuet-cse — bash — 80×24',
          style: GoogleFonts.ibmPlexMono(fontSize: 11, color: _kGray),
        ),
      ],
    );
  }

  Widget _dot(Color c) => Container(
    width: 12,
    height: 12,
    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
  );

  // Large monospaced title
  Widget _buildBigTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CSE KUET',
          style: GoogleFonts.ibmPlexMono(
            fontSize: 38,
            fontWeight: FontWeight.w700,
            color: _kGreen,
            letterSpacing: 4,
            shadows: [
              Shadow(color: _kGreen.withValues(alpha: 0.45), blurRadius: 18),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Department of Computer Science & Engineering',
          style: GoogleFonts.ibmPlexMono(
            fontSize: 11,
            color: _kGreenDim.withValues(alpha: 0.7),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // Scrolling terminal log
  Widget _buildLogLines() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < _visibleLines; i++) _buildCompletedLine(i),
          if (_visibleLines < _lines.length) _buildCurrentLine(),
        ],
      ),
    );
  }

  Widget _buildCompletedLine(int i) {
    final line = _lines[i];
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        line.text,
        style: GoogleFonts.ibmPlexMono(
          fontSize: 13,
          color: line.isOk ? _kGreen : _kGreenDim,
          fontWeight: line.isOk ? FontWeight.w600 : FontWeight.w400,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildCurrentLine() {
    final line = _lines[_visibleLines];
    final visible = line.text.substring(
      0,
      _charIndex.clamp(0, line.text.length),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: visible,
              style: GoogleFonts.ibmPlexMono(
                fontSize: 13,
                color: _kGreenDim,
                height: 1.5,
              ),
            ),
            TextSpan(
              text: _cursorVisible ? '█' : ' ',
              style: GoogleFonts.ibmPlexMono(fontSize: 13, color: _kGreen),
            ),
          ],
        ),
      ),
    );
  }

  // Block-style progress bar [████████░░░░]
  Widget _buildProgressBar() {
    const totalBlocks = 24;
    final filled = (_progress * totalBlocks).round();
    final empty = totalBlocks - filled;
    final bar = '${'█' * filled}${'░' * empty}';

    return Text(
      '[$bar]',
      style: GoogleFonts.ibmPlexMono(
        fontSize: 15,
        color: _kGreen,
        letterSpacing: 1,
        shadows: [
          Shadow(color: _kGreen.withValues(alpha: 0.35), blurRadius: 10),
        ],
      ),
    );
  }

  Widget _buildProgressLabel() {
    final pct = (_progress * 100).round();
    return Text(
      '${pct.toString().padLeft(3)}%  Loading system modules...',
      style: GoogleFonts.ibmPlexMono(fontSize: 11, color: _kGray),
    );
  }
}

class _TermLine {
  final String text;
  final int duration; // total ms for the typing animation
  final bool isOk;

  const _TermLine({
    required this.text,
    required this.duration,
    this.isOk = false,
  });
}
