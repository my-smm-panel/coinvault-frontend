import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import 'home_screen.dart';

/// Login screen — exact replica of the reference screenshot.
/// Spec (572x1280 reference, % of screen W/H):
///  - bg #0D0D0F solid
///  - logo circle 42% W, top at 12% H (below status bar), orange ring
///    + dark gap ring + orange fill with bear asset, orange glow 15-25%
///  - title 4.3% below circle, 8% W font, Coin white + Vault orange + 🐻
///  - subtitle 2.2% below title, gray #B3B3B8, 4% W font
///  - chips 5% below subtitle: left-aligned, 1px orange 35% border pills,
///    transparent fill, 3rd chip clipped right edge
///  - Google button 4.4% below chips: white full pill, no border/shadow,
///    height 15% W, G logo 44% of button height, text #1A1A1A semibold
///  - lock hint 2.5% below button, gray #9E9E9E
///  - terms pinned bottom ~3.5% H margin, link-colored spans
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
        setState(() => _error = 'Sign-in cancelled. Please try again.');
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthScreen Firebase error: ${e.code} ${e.message}');
      setState(() =>
          _error = 'Sign-in failed (${e.code}): ${e.message ?? "Please try again."}');
    } catch (e) {
      debugPrint('AuthScreen error: $e');
      setState(() => _error = 'Sign-in error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _googleLogo({double size = 24}) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleGPainter(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final logoD = size.width * 0.42; // 42% of screen width
    final sidePad = size.width * 0.087; // ~50px on 572px reference

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: sidePad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: size.height * 0.12),

                    // ===== Logo circle: orange ring + dark gap + orange fill =====
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            // warm orange glow halo
                            BoxShadow(
                              color:
                                  const Color(0xFFFF7A00).withOpacity(0.22),
                              blurRadius: 60,
                              spreadRadius: 14,
                            ),
                          ],
                        ),
                        child: Container(
                          width: logoD,
                          height: logoD,
                          padding: const EdgeInsets.all(6), // dark gap ring
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF0D0D0F),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFFF8C1A),
                                width: 3.5,
                              ),
                            ),
                            child: const ClipOval(
                              child: _LogoFill(),
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: size.height * 0.043),

                    // ===== Title =====
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Coin',
                            style: GoogleFonts.inter(
                              fontSize: size.width * 0.080,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.05,
                            ),
                          ),
                          Text(
                            'Vault',
                            style: GoogleFonts.inter(
                              fontSize: size.width * 0.080,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFFF8C00),
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('🐻',
                              style: TextStyle(fontSize: size.width * 0.042)),
                        ],
                      ),
                    ),

                    SizedBox(height: size.height * 0.022),

                    // ===== Subtitle =====
                    Center(
                      child: Text(
                        'Earn coins. Cash out real money.',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFB3B3B8),
                          fontSize: size.width * 0.040,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    SizedBox(height: size.height * 0.05),

                    // ===== Chips: left-aligned, overflow right edge =====
                    SizedBox(
                      height: size.width * 0.082,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _benefitChip(
                              context, Icons.autorenew_rounded, 'Spin & Win'),
                          const SizedBox(width: 8),
                          _benefitChip(context,
                              Icons.check_circle_outline_rounded, 'Easy Tasks'),
                          const SizedBox(width: 8),
                          _benefitChip(context,
                              Icons.account_balance_wallet_outlined, 'UPI Cashout'),
                        ],
                      ),
                    ),

                    SizedBox(height: size.height * 0.044),

                    // ===== Error banner =====
                    if (_error != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color:
                                  const Color(0xFFEF4444).withOpacity(0.35)),
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

                    // ===== Google button: white full pill, flat =====
                    SizedBox(
                      width: double.infinity,
                      height: size.width * 0.150,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _signInWithGoogle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1A1A1A),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                size.width * 0.075),
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
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                              const Color(0xFFFF7A00)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Signing you in...',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF1A1A1A),
                                      fontWeight: FontWeight.w700,
                                      fontSize: size.width * 0.037,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _googleLogo(size: size.width * 0.063),
                                  const SizedBox(width: 14),
                                  Text(
                                    'Continue with Google',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF1A1A1A),
                                      fontWeight: FontWeight.w600,
                                      fontSize: size.width * 0.037,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    SizedBox(height: size.height * 0.025),

                    // ===== Lock hint =====
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_rounded,
                              size: size.width * 0.023,
                              color: const Color(0xFF9E9E9E)),
                          const SizedBox(width: 5),
                          Text(
                            '100% secure sign-in via Google',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF9E9E9E),
                              fontSize: size.width * 0.021,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ===== Terms pinned at bottom =====
            Padding(
              padding: EdgeInsets.only(
                left: sidePad,
                right: sidePad,
                bottom: size.height * 0.035,
              ),
              child: Center(
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _benefitChip(BuildContext context, IconData icon, String label) {
    final size = MediaQuery.of(context).size;
    return Container(
      height: size.width * 0.082,
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.035),
      decoration: ShapeDecoration(
        shape: StadiumBorder(
          side: BorderSide(
            color: const Color(0xFFFF9800).withOpacity(0.35),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: size.width * 0.030, color: const Color(0xFFFF9800)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: size.width * 0.026,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

/// Orange-filled circle with the bear + coin + wordmark asset inside.
/// Falls back to a drawn bear-ish placeholder if the asset is missing.
class _LogoFill extends StatelessWidget {
  const _LogoFill();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo_circle.png',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFFFF8C1A),
        child: Center(
          child: Icon(
            Icons.savings_rounded,
            size: 64,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
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
    final Rect arcRect =
        Rect.fromLTWH(s * 0.04, s * 0.04, s * 0.92, s * 0.92);

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
