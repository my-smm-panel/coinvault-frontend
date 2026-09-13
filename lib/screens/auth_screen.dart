import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

/// Login screen — matches reference video exactly:
///   1. Top-right: "English" language pill
///   2. Center: bear mascot + $ coin with warm amber spotlight glow
///   3. Below: "CoinVault" wordmark (white "Coin" + orange "Vault")
///   4. Bottom: full-width white "Continue with Google" pill button
/// Sign-in is REAL: native Google picker -> Firebase credential -> backend JWT.
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
    _flipAnim = CurvedAnimation(parent: _flipController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    if (_loading) return;
    setState(() { _loading = true; _error = null; });
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
        setState(() => _error = msg.replaceFirst(RegExp(r'^Exception: '), ''));
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
          // Warm radial amber spotlight glow centered behind bear
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.5, -0.3),
                  radius: 0.7,
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
          SafeArea(
            child: Column(
              children: [
                // Top-right language pill
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20, top: 12),
                    child: GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.public, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(_selectedLang, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                            const SizedBox(width: 4),
                            const Icon(Icons.expand_more, color: Colors.white, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Bear mascot + flipping coin (center of screen)
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        child: SizedBox(
                          width: size.width * 0.7,
                          height: size.width * 0.7,
                          child: Image.asset('assets/bear.png', fit: BoxFit.contain),
                        ),
                      ),
                      Positioned(
                        right: size.width * 0.12,
                        top: size.height * 0.05,
                        child: AnimatedBuilder(
                          animation: _flipAnim,
                          builder: (context, _) {
                            final t = _flipAnim.value;
                            final rotateY = t * 12.566;
                            final bounceY = -8 * (1 - (2 * t - 1) * (2 * t - 1).abs());
                            return Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.0015)
                                ..rotateY(rotateY)
                                ..rotateX((t - 0.5).abs() * 0.3),
                              child: Transform.translate(
                                offset: Offset(0, bounceY),
                                child: Container(
                                  width: 64, height: 64,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(color: Color(0xFFFFB347), blurRadius: 25, spreadRadius: 4),
                                    ],
                                  ),
                                  child: Image.asset('assets/coin_zip.png', fit: BoxFit.contain),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Brand wordmark
                const Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'Coin', style: TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w800, letterSpacing: -1)),
                      TextSpan(text: 'Vault', style: TextStyle(color: Color(0xFFFF8A2A), fontSize: 44, fontWeight: FontWeight.w800, letterSpacing: -1)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // Continue with Google button (full width, white pill)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(40),
                    onTap: _loading ? null : _signInWithGoogle,
                    child: Container(
                      height: 56,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _loading ? Colors.white.withOpacity(0.7) : Colors.white,
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: _loading
                          ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.6, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF8A2A)))))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _GoogleGLogo(size: 24),
                                const SizedBox(width: 12),
                                const Text('Continue with Google', style: TextStyle(color: Color(0xFF1F1F1F), fontSize: 16, fontWeight: FontWeight.w600)),
                                const SizedBox(width: 10),
                                const Icon(Icons.arrow_forward, color: Color(0xFF1F1F1F), size: 20),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Google "G" logo ----------
class _GoogleGLogo extends StatelessWidget {
  final double size;
  const _GoogleGLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: size, height: size, child: CustomPaint(painter: _GLogoPainter()));
  }
}

class _GLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.18;
    final rect = Offset(stroke / 2, stroke / 2) & Size(size.width - stroke, size.height - stroke);
    final ringPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = stroke;
    final colors = [const Color(0xFF4285F4), const Color(0xFF34A853), const Color(0xFFFBBC05), const Color(0xFFEA4335)];
    final sweep = 2 * 3.141592653589793;
    for (int i = 0; i < colors.length; i++) {
      ringPaint.color = colors[i];
      canvas.drawArc(Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height), -1.5708 + (sweep / 4) * i, sweep / 4, false, ringPaint);
    }
    final barPaint = Paint()..color = colors[0];
    final barRect = Rect.fromCenter(center: Offset(size.width * 0.7, size.height * 0.5), width: size.width * 0.42, height: size.height * 0.18);
    canvas.drawRRect(RRect.fromRectAndRadius(barRect, const Radius.circular(1)), barPaint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
