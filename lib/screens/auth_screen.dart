import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'home_screen.dart';

/// Login screen (CoinVault v2 login redesign).
/// Visual: warm radial glow, bear mascot + flipping coin, bottom orange wave,
/// language selector, brand title, 3 feature columns, "Continue with Google".
/// Sign-in is REAL: native Google picker -> Firebase credential -> backend JWT,
/// then routes to HomeScreen.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnim;
  String _selectedLang = 'English';

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _flipAnim = CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    if (_loading) return;
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
    } catch (e) {
      debugPrint('AuthScreen sign-in error: $e');
      final msg = e is Exception ? e.toString() : 'Sign-in failed. Try again.';
      if (mounted) {
        setState(() =>
            _error = msg.replaceFirst(RegExp(r'^Exception: '), ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0D0B),
      body: Stack(
        children: [
          // Warm radial glow background behind the bear
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.45),
                  radius: 0.85,
                  colors: [
                    Color(0xFFFF8A2A),
                    Color(0x33C94A0A),
                    Color(0x000F0D0B),
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // Bottom decorative orange wave
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SizedBox(
              height: size.height * 0.18,
              child: CustomPaint(
                painter: _BottomWavePainter(),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ---- Top status bar (1:28 / 62%) ----
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                  child: Row(
                    children: [
                      const Text(
                        '1:28',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: const [
                          Icon(Icons.signal_cellular_alt,
                              color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Icon(Icons.wifi, color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text(
                            '62%',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ---- Language selector (top right) ----
                Padding(
                  padding: const EdgeInsets.only(right: 20, top: 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        // TODO: wire up language switch
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.public,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              _selectedLang,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.expand_more,
                                color: Colors.white, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ---- Bear mascot + flipping coin ----
                SizedBox(
                  height: size.height * 0.42,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Bear character
                      Positioned(
                        bottom: -10,
                        child: SizedBox(
                          width: size.width * 0.78,
                          height: size.width * 0.78,
                          child: Image.asset(
                            'assets/bear.png',
                            fit: BoxFit.contain,
                            errorBuilder: (c, e, s) => const Icon(
                              Icons.image_not_supported,
                              color: Colors.white24,
                              size: 60,
                            ),
                          ),
                        ),
                      ),

                      // Animated flipping coin positioned over the bear's left hand
                      Positioned(
                        right: size.width * 0.13,
                        top: size.height * 0.05,
                        child: AnimatedBuilder(
                          animation: _flipAnim,
                          builder: (context, _) {
                            // Continuous flip + slight up/down bounce
                            final t = _flipAnim.value;
                            final rotateY = t * 12.566; // multiple full rotations
                            final bounceY =
                                -8 * (1 - (2 * t - 1) * (2 * t - 1).abs());
                            return Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.0015) // perspective
                                ..rotateY(rotateY)
                                ..rotateX((t - 0.5).abs() * 0.3),
                              child: Transform.translate(
                                offset: Offset(0, bounceY),
                                child: Container(
                                  width: 78,
                                  height: 78,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFFB347)
                                            .withOpacity(0.7),
                                        blurRadius: 25,
                                        spreadRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    'assets/coin_zip.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (c, e, s) =>
                                        const Icon(
                                      Icons.monetization_on,
                                      color: Color(0xFFFFC93C),
                                      size: 60,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // ---- Brand title ----
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Coin',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 46,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                      TextSpan(
                        text: 'Vault',
                        style: TextStyle(
                          color: Color(0xFFFF8A2A),
                          fontSize: 46,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // ---- Subtitle ----
                const Text(
                  'Play. Earn. Win Real Rewards.',
                  style: TextStyle(
                    color: Color(0xFFB8B5B0),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),

                const SizedBox(height: 38),

                // ---- Three feature columns ----
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                          child: _FeatureItem(
                        iconBg: const Color(0xFF1A1614),
                        icon: Icons.shield_outlined,
                        title: 'Secure & Safe',
                        subtitle: 'Your data is protected',
                      )),
                      Container(
                          height: 55,
                          width: 1,
                          color: Colors.white.withOpacity(0.12)),
                      Expanded(
                          child: _FeatureItem(
                        iconBg: const Color(0xFF1A1614),
                        icon: Icons.bolt_outlined,
                        title: 'Fast Withdrawals',
                        subtitle: 'Get your rewards quickly',
                      )),
                      Container(
                          height: 55,
                          width: 1,
                          color: Colors.white.withOpacity(0.12)),
                      Expanded(
                          child: _FeatureItem(
                        iconBg: const Color(0xFF1A1614),
                        icon: Icons.card_giftcard_outlined,
                        title: 'Real Rewards',
                        subtitle: 'Play & earn easily',
                      )),
                    ],
                  ),
                ),

                const Spacer(),

                // ---- Error text (if any) ----
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFEF5350),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                // ---- Continue with Google button ----
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(40),
                    onTap: _loading ? null : _signInWithGoogle,
                    child: Container(
                      height: 58,
                      decoration: BoxDecoration(
                        color: _loading
                            ? Colors.white.withOpacity(0.7)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _loading
                          ? const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.6,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFFFF8A2A)),
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Google "G" logo (built-in)
                                _GoogleGLogo(size: 26),
                                const SizedBox(width: 14),
                                const Text(
                                  'Continue with Google',
                                  style: TextStyle(
                                    color: Color(0xFF1F1F1F),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Icon(Icons.arrow_forward,
                                    color: Color(0xFF1F1F1F), size: 20),
                              ],
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // ---- Terms text ----
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    children: [
                      const Text(
                        'By continuing, you agree to our',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF9E9A95),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'Terms of Service',
                              style: TextStyle(
                                color: Color(0xFFFF8A2A),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            TextSpan(
                              text: ' & ',
                              style: TextStyle(
                                color: Color(0xFF9E9A95),
                                fontSize: 12,
                              ),
                            ),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(
                                color: Color(0xFFFF8A2A),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: size.height * 0.05),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Feature item widget ----------
class _FeatureItem extends StatelessWidget {
  final Color iconBg;
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureItem({
    required this.iconBg,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFFF8A2A).withOpacity(0.6),
              width: 1.2,
            ),
          ),
          child: Icon(icon, color: const Color(0xFFFF8A2A), size: 22),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(
              color: Color(0xFF9E9A95),
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------- Google "G" logo (multi-color) ----------
class _GoogleGLogo extends StatelessWidget {
  final double size;
  const _GoogleGLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GLogoPainter()),
    );
  }
}

class _GLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.18;
    final rect = Offset(stroke / 2, stroke / 2) &
        Size(size.width - stroke, size.height - stroke);

    // Ring
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final colors = [
      const Color(0xFF4285F4), // blue (top)
      const Color(0xFF34A853), // green (right/bottom right)
      const Color(0xFFFBBC05), // yellow (bottom)
      const Color(0xFFEA4335), // red (left)
    ];
    final rectBounds = Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height);
    final sweep = 2 * 3.141592653589793;
    for (int i = 0; i < colors.length; i++) {
      ringPaint.color = colors[i];
      canvas.drawArc(rectBounds, -1.5708 + (sweep / 4) * i, sweep / 4, false,
          ringPaint);
    }

    // Blue bar (inside right) — the "G" stem
    final barPaint = Paint()..color = colors[0];
    final barRect = Rect.fromCenter(
      center: Offset(size.width * 0.7, size.height * 0.5),
      width: size.width * 0.42,
      height: size.height * 0.18,
    );
    canvas.drawRRect(
        RRect.fromRectAndRadius(barRect, const Radius.circular(1)), barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------- Bottom orange wave ----------
class _BottomWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFF8A2A), Color(0x33FF8A2A)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final p2 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFF6A0A), Color(0x44FF6A0A)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path1 = Path()
      ..moveTo(0, size.height * 0.9)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.2,
          size.width * 0.55, size.height * 0.55)
      ..quadraticBezierTo(size.width * 0.8, size.height * 0.9,
          size.width, size.height * 0.5)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path1, p1);

    final path2 = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.85)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.4,
          size.width * 0.6, size.height * 0.7)
      ..quadraticBezierTo(size.width * 0.9, size.height * 0.95,
          size.width, size.height * 0.7)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path2, p2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
