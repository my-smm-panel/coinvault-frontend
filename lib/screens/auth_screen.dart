import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../services/auth_service.dart';

/// Premium light login screen: brand wordmark, big bear mascot (vector),
/// welcome line, single "Continue with Google" button, terms footer.
/// No email/password, no extra methods.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _loading = false;
  String? _error;

  static const Color _bg = Color(0xFFFAFAF8);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _border = Color(0xFFE7E7E7);
  static const Color _primaryText = Color(0xFF171717);
  static const Color _secondaryText = Color(0xFF6B7280);
  static const Color _orange = Color(0xFFF59E0B);
  static const Color _brown = Color(0xFF5A3825);

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService().signInWithGoogle();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              SizedBox(height: h * 0.045),

              // ── Brand wordmark ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on_rounded,
                      color: _orange, size: 26),
                  const SizedBox(width: 7),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                      children: [
                        TextSpan(
                            text: 'Coin',
                            style: TextStyle(color: _brown)),
                        TextSpan(
                            text: 'Vault',
                            style: TextStyle(color: _orange)),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: h * 0.02),

              // ── Bear mascot (vector, large) ──
              _BearMascot(size: h * 0.26),

              SizedBox(height: h * 0.035),

              // ── Welcome ──
              const Text('Welcome to CoinVault',
                  style: TextStyle(
                      color: _primaryText,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2)),
              const SizedBox(height: 8),
              const Text('Earn coins. Complete tasks. Redeem rewards.',
                  style: TextStyle(
                      color: _secondaryText,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500)),

              // error (if any)
              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE9EC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Color(0xFFB3261E), fontSize: 12)),
                ),
              ],

              const Spacer(),

              // ── Google sign-in ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: Material(
                    color: _surface,
                    borderRadius: BorderRadius.circular(15),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(15),
                      onTap: _loading ? null : _signInWithGoogle,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: _border, width: 1),
                        ),
                        child: _loading
                            ? const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        _orange),
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Google G
                                  _GoogleG(size: 20),
                                  const SizedBox(width: 11),
                                  const Text('Continue with Google',
                                      style: TextStyle(
                                        color: _primaryText,
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w600,
                                      )),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: h * 0.03),

              // ── Terms footer ──
              const Text('By continuing, you agree to our Terms & Privacy Policy.',
                  style: TextStyle(
                      color: Color(0xFF9AA0A6),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500)),

              SizedBox(height: h * 0.02),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Google G logo (multi-color) ─────────────────────────
class _GoogleG extends StatelessWidget {
  final double size;
  const _GoogleG({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleGPainter(),
        size: Size(size, size),
      ),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = s * 0.09;

    // Blue arc (top-right → bottom-right)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(s / 2, s / 2), radius: s * 0.42),
      -1.9, 2.4, false, paint,
    );
    // Red arc (top-left → top-right)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(s / 2, s / 2), radius: s * 0.42),
      -3.1, 1.2, false, paint,
    );
    // Yellow arc (bottom-left → top-left)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(s / 2, s / 2), radius: s * 0.42),
      0.5, 1.9, false, paint,
    );
    // Green arc (bottom-right → bottom-left)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(s / 2, s / 2), radius: s * 0.42),
      2.4, 1.2, false, paint,
    );
    // G bar
    paint.style = PaintingStyle.fill;
    paint.color = const Color(0xFF4285F4);
    final r = s * 0.42;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * 0.5 - r * 0.28, s * 0.5 - s * 0.085, r * 0.9,
            s * 0.17),
        Radius.circular(s * 0.08),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ───────────────────────── Bear mascot (vector) ─────────────────────────
class _BearMascot extends StatelessWidget {
  final double size;
  const _BearMascot({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BearPainter(),
        size: Size(size, size),
      ),
    );
  }
}

class _BearPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h * 0.54;

    final body = Paint()..color = const Color(0xFF8A5A3B);
    final bodyDark = Paint()..color = const Color(0xFF70452F);
    final light = Paint()..color = const Color(0xFFD9B08C);
    final darkAccent = Paint()..color = const Color(0xFF5A3825);
    final white = Paint()..color = Colors.white;
    final orange = Paint()..color = const Color(0xFFF59E0B);

    // ears (behind head)
    canvas.drawCircle(Offset(cx - w * 0.27, cy - h * 0.30), w * 0.105, body);
    canvas.drawCircle(Offset(cx + w * 0.27, cy - h * 0.30), w * 0.105, body);
    canvas.drawCircle(Offset(cx - w * 0.27, cy - h * 0.30), w * 0.052, bodyDark);
    canvas.drawCircle(Offset(cx + w * 0.27, cy - h * 0.30), w * 0.052, bodyDark);

    // head
    canvas.drawCircle(Offset(cx, cy), w * 0.30, body);

    // muzzle
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy + h * 0.075), width: w * 0.28, height: h * 0.20),
      light,
    );
    // nose
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy + h * 0.035), width: w * 0.075, height: h * 0.05),
      darkAccent,
    );
    // mouth (smile)
    final mouth = Paint()
      ..color = darkAccent.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.018
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(cx - w * 0.055, cy + h * 0.105)
        ..quadraticBezierTo(
            cx, cy + h * 0.145, cx + w * 0.055, cy + h * 0.105),
      mouth,
    );
    // eyes
    canvas.drawCircle(Offset(cx - w * 0.105, cy - h * 0.035), w * 0.032, darkAccent);
    canvas.drawCircle(Offset(cx + w * 0.105, cy - h * 0.035), w * 0.032, darkAccent);
    canvas.drawCircle(
        Offset(cx - w * 0.095, cy - h * 0.045), w * 0.011, white);
    canvas.drawCircle(
        Offset(cx + w * 0.115, cy - h * 0.045), w * 0.011, white);

    // cheeks (subtle)
    final cheek = Paint()..color = const Color(0xFFE8A87C).withAlpha(90);
    canvas.drawCircle(Offset(cx - w * 0.155, cy + h * 0.055), w * 0.045, cheek);
    canvas.drawCircle(Offset(cx + w * 0.155, cy + h * 0.055), w * 0.045, cheek);

    // body (rounded) below head
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - w * 0.24, cy + h * 0.18, w * 0.48, h * 0.30),
        Radius.circular(w * 0.16),
      ),
      body,
    );
    // belly
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy + h * 0.335),
          width: w * 0.26,
          height: h * 0.20),
      light,
    );

    // gold coin held at belly
    canvas.drawCircle(Offset(cx, cy + h * 0.335), w * 0.085, orange);
    canvas.drawCircle(Offset(cx, cy + h * 0.335), w * 0.062, Paint()..color = const Color(0xFFFBBF24));
    final tp = TextPainter(
      text: const TextSpan(
          text: '₹',
          style: TextStyle(
              color: Color(0xFFB45309), fontWeight: FontWeight.w800)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy + h * 0.335 - tp.height / 2));

    // arms
    canvas.drawCircle(Offset(cx - w * 0.28, cy + h * 0.26), w * 0.058, body);
    canvas.drawCircle(Offset(cx + w * 0.28, cy + h * 0.26), w * 0.058, body);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
