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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // ===== Hero: bear mascot in glowing orange ring =====
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.45),
                          blurRadius: 45,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.background,
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/app_icon_name.png',
                          width: 128,
                          height: 128,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 128,
                            height: 128,
                            color: AppColors.surfaceVariant,
                            child: const Icon(
                              Icons.savings_rounded,
                              size: 56,
                              color: AppColors.primaryLight,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ===== Brand =====
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('Coin',
                          style: GoogleFonts.inter(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.1,
                          )),
                      Text(
                        'Vault',
                        style: GoogleFonts.inter(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFF5821F),
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('🐻', style: TextStyle(fontSize: 26)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Earn coins. Cash out real money.',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFA3A6AD),
                      fontSize: 15.5,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ===== Benefit chips =====
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _benefitChip(Icons.donut_large_rounded, 'Spin & Win'),
                      _benefitChip(Icons.task_alt_rounded, 'Easy Tasks'),
                      _benefitChip(Icons.account_balance_wallet_rounded, 'UPI Cashout'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ===== Error banner =====
                  if (_error != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.error.withOpacity(0.35)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: AppColors.error, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              _error!,
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // ===== Google Sign-In (white card button) =====
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _signInWithGoogle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1F1F1F),
                        elevation: 3,
                        shadowColor: Colors.black.withOpacity(0.35),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.full),
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
                                        AppColors.primary),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Text('Signing you in...',
                                    style: AppTextStyles.labelLarge.copyWith(
                                        color: const Color(0xFF1F1F1F))),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _googleLogo(size: 24),
                                const SizedBox(width: 12),
                                Text(
                                  'Continue with Google',
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: const Color(0xFF1F1F1F),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ===== Trust hint =====
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_rounded,
                          size: 13, color: Color(0xFF8A8D93)),
                      const SizedBox(width: 5),
                      Text(
                        '100% secure sign-in via Google',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF8A8D93),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(flex: 3),

                  // ===== Terms =====
                  Text.rich(
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
                          text: '\n& ',
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
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _benefitChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF16161A),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: const Color(0xFF5A3A1E)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFF5821F)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: const Color(0xFFE5E7EB),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Official multi-color Google "G" painted in code — always renders,
/// no missing-asset fallback issues.
class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width;
    final Paint blue = Paint()..color = const Color(0xFF4285F4);
    final Paint green = Paint()..color = const Color(0xFF34A853);
    final Paint yellow = Paint()..color = const Color(0xFFFBBC05);
    final Paint red = Paint()..color = const Color(0xFFEA4335);

    final double stroke = s * 0.115;

    // Blue arc (top-left half of ring, 225deg..405deg)
    final Rect arcRect = Rect.fromLTWH(s * 0.04, s * 0.04, s * 0.92, s * 0.92);
    canvas.drawArc(
      arcRect,
      -math.pi * 0.25, // start
      math.pi * 1.0, // sweep
      false,
      blue..style = PaintingStyle.stroke..strokeWidth = stroke..strokeCap = StrokeCap.butt,
    );

    // Green arc (bottom-left, 90deg sweep ending at right)
    canvas.drawArc(
      arcRect,
      math.pi * 0.75,
      math.pi * 0.5,
      false,
      green..style = PaintingStyle.stroke..strokeWidth = stroke..strokeCap = StrokeCap.butt,
    );

    // Yellow arc (left, 45deg)
    canvas.drawArc(
      arcRect,
      math.pi * 0.25,
      math.pi * 0.5,
      false,
      yellow..style = PaintingStyle.stroke..strokeWidth = stroke..strokeCap = StrokeCap.butt,
    );

    // Red arc (top-right to left joint, 90deg)
    canvas.drawArc(
      arcRect,
      math.pi * 1.75,
      math.pi * 0.5,
      false,
      red..style = PaintingStyle.stroke..strokeWidth = stroke..strokeCap = StrokeCap.butt,
    );

    // Blue horizontal bar of the G
    final Path bar = Path()
      ..moveTo(s * 0.48, s * 0.47)
      ..lineTo(s, s * 0.47)
      ..lineTo(s, s * 0.62)
      ..lineTo(s * 0.62, s * 0.62)
      ..lineTo(s * 0.62, s * 0.76)
      ..lineTo(s * 0.48, s * 0.76)
      ..close();
    canvas.drawPath(
      bar,
      blue..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
