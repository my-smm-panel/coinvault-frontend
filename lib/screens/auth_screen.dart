import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_theme.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = await AuthService().signInWithGoogle();
      if (user != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else if (mounted) {
        setState(() {
          _error = 'Sign-in cancelled. Please try again.';
        });
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthScreen Firebase error: ${e.code} ${e.message}');
      setState(() => _error = 'Sign-in failed (${e.code}): ${e.message ?? "Please try again."}');
    } catch (e) {
      debugPrint('AuthScreen error: $e');
      setState(() => _error = 'Sign-in error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Google "G" logo drawn in code (always available, no asset needed).
  Widget _googleLogo({double size = 24}) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleGPainter(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final logoD = size.width * 0.41; // reference: ~41% of screen width

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.087),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: size.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom,
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: size.height * 0.055),

                      // ===== Logo: orange circle w/ dark separator ring + glow =====
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF7A00).withOpacity(0.38),
                              blurRadius: 65,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Container(
                          width: logoD,
                          height: logoD,
                          padding: const EdgeInsets.all(5), // dark separator ring
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF0D0D0F),
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.fromBorderSide(
                                BorderSide(color: Color(0xFFFF7A00), width: 3),
                              ),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/logo_circle.png',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFFFF8C1A),
                                  child: const Icon(
                                    Icons.savings_rounded,
                                    size: 64,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: size.height * 0.045),

                      // ===== Title: Coin(white) Vault(orange) + bear =====
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Coin',
                            style: GoogleFonts.inter(
                              fontSize: 31,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.05,
                            ),
                          ),
                          Text(
                            'Vault',
                            style: GoogleFonts.inter(
                              fontSize: 31,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFFF8C00),
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('🐻', style: TextStyle(fontSize: 24)),
                        ],
                      ),

                      SizedBox(height: size.height * 0.018),

                      // ===== Subtitle =====
                      Text(
                        'Earn coins. Cash out real money.',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFB3B3B8),
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: size.height * 0.046),

                      // ===== Feature chips — left-aligned, horizontally clipped =====
                      SizedBox(
                        height: 38,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _benefitChip(Icons.autorenew_rounded, 'Spin & Win'),
                            const SizedBox(width: 8),
                            _benefitChip(Icons.check_circle_outline_rounded, 'Easy Tasks'),
                            const SizedBox(width: 8),
                            _benefitChip(Icons.account_balance_wallet_rounded, 'UPI Cashout'),
                          ],
                        ),
                      ),

                      SizedBox(height: size.height * 0.085),

                      // ===== Error banner =====
                      if (_error != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFFEF4444).withOpacity(0.35)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: Color(0xFFEF4444), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: GoogleFonts.inter(
                                      color: const Color(0xFFEF4444),
                                      fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // ===== Google Sign-In (white pill) =====
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _signInWithGoogle,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1A1A1A),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(27),
                            ),
                          ),
                          child: _loading
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                            const Color(0xFFFF7A00)),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Signing you in...',
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF1A1A1A),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _googleLogo(size: 24),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Continue with Google',
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF1A1A1A),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      SizedBox(height: size.height * 0.024),

                      // ===== Trust hint =====
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_rounded,
                              size: 13, color: Color(0xFF9E9E9E)),
                          const SizedBox(width: 5),
                          Text(
                            '100% secure sign-in via Google',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF9E9E9E),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ===== Terms pinned near bottom =====
            Padding(
              padding: EdgeInsets.only(
                left: size.width * 0.087,
                right: size.width * 0.087,
                bottom: size.height * 0.035,
              ),
              child: Text.rich(
                TextSpan(
                  text: 'By continuing, you agree to our ',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF7C7F86),
                    fontSize: 12,
                    height: 1.5,
                  ),
                  children: [
                    TextSpan(
                      text: 'Terms of Service',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFB9BCC2),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: ' & ',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF7C7F86),
                        fontSize: 12,
                      ),
                    ),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFB9BCC2),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _benefitChip(IconData icon, String label) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: ShapeDecoration(
        shape: StadiumBorder(
          side: BorderSide(
            color: const Color(0xFFFF9800).withOpacity(0.4),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: const Color(0xFFFF9800)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Official multi-color Google "G" painted in code.
class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width;
    final Paint blue = Paint()..color = const Color(0xFF4285F4);
    final Paint green = Paint()..color = const Color(0xFF34A853);
    final Paint yellow = Paint()..color = const Color(0xFFFBBC05);
    final Paint red = Paint()..color = const Color(0xFFEA4335);

    final double stroke = s * 0.115;
    final Rect arcRect = Rect.fromLTWH(s * 0.04, s * 0.04, s * 0.92, s * 0.92);

    canvas.drawArc(
      arcRect,
      -math.pi * 0.25,
      math.pi * 1.0,
      false,
      blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt,
    );

    canvas.drawArc(
      arcRect,
      math.pi * 0.75,
      math.pi * 0.5,
      false,
      green
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt,
    );

    canvas.drawArc(
      arcRect,
      math.pi * 0.25,
      math.pi * 0.5,
      false,
      yellow
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt,
    );

    canvas.drawArc(
      arcRect,
      math.pi * 1.75,
      math.pi * 0.5,
      false,
      red
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt,
    );

    final Path bar = Path()
      ..moveTo(s * 0.48, s * 0.47)
      ..lineTo(s, s * 0.47)
      ..lineTo(s, s * 0.62)
      ..lineTo(s * 0.62, s * 0.62)
      ..lineTo(s * 0.62, s * 0.76)
      ..lineTo(s * 0.48, s * 0.76)
      ..close();
    canvas.drawPath(bar, blue..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
