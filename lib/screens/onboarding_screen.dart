import 'package:flutter/material.dart';
import 'auth_screen.dart';
import '../core/app_theme.dart';


/// 3-screen onboarding: Earn Coins → Complete Tasks → Redeem Rewards.
/// Same bear mascot, same design system. Shown before the login screen.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _page = 0;

  static const Color _bg = Color(0xFFFAFAF8);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _border = Color(0xFFE7E7E7);
  static const Color _primaryText = Color(0xFF171717);
  static const Color _secondaryText = Color(0xFF6B7280);
  static const Color _orange = Color(0xFFF59E0B);
  static const Color _orange2 = Color(0xFFF7A928);
  static const Color _brown = Color(0xFF5A3825);

  static const _headings = [
    'Earn Coins',
    'Complete Simple Tasks',
    'Redeem Your Rewards',
  ];
  static const _subtitles = [
    'Turn your free time into rewards.',
    'Answer surveys and finish tasks to earn.',
    'Turn your coins into real rewards.',
  ];

  void _next() {
    if (_page < 2) {
      setState(() => _page++);
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
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
              // skip
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, right: 12),
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const AuthScreen())),
                    child: const Text('Skip',
                        style: TextStyle(
                            color: _secondaryText,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ),

              SizedBox(height: h * 0.03),

              // illustration
              Expanded(child: _illustration(h)),

              SizedBox(height: h * 0.01),

              // heading + subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Text(_headings[_page],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: _primaryText,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2)),
                    const SizedBox(height: 9),
                    Text(_subtitles[_page],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: _secondaryText,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                            height: 1.4)),
                  ],
                ),
              ),

              SizedBox(height: h * 0.028),

              // page indicator
              _indicator(),

              SizedBox(height: h * 0.03),

              // CTA
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: Material(
                    color: _orange,
                    borderRadius: BorderRadius.circular(15),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(15),
                      onTap: _next,
                      child: Center(
                        child: Text(
                          _page < 2 ? 'Next  →' : 'Get Started',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: h * 0.035),
            ],
          ),
        ),
      ),
    );
  }

  Widget _indicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final active = i == _page;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 22 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: active ? _orange : const Color(0xFFD8D8E0),
            borderRadius: BorderRadius.circular(3.5),
          ),
        );
      }),
    );
  }

  /// Per-page illustration: bear + themed extras.
  Widget _illustration(double h) {
    switch (_page) {
      case 1:
        return _TasksIllustration(h: h);
      case 2:
        return _RedeemIllustration(h: h);
      default:
        return _EarnIllustration(h: h);
    }
  }
}

// ───────────────────────── shared mascot export ─────────────────────────
/// Vector bear mascot (shared with the login screen).
class BearMascot extends StatelessWidget {
  final double size;
  const BearMascot({super.key, required this.size});

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
    final cy = h * 0.46;

    final body = Paint()..color = const Color(0xFF8A5A3B);
    final bodyDark = Paint()..color = const Color(0xFF70452F);
    final light = Paint()..color = const Color(0xFFD9B08C);
    final darkAccent = Paint()..color = const Color(0xFF5A3825);
    final white = Paint()..color = Colors.white;
    final orange = Paint()..color = const Color(0xFFF59E0B);
    final gold = Paint()..color = const Color(0xFFFBBF24);

    // ears
    canvas.drawCircle(Offset(cx - w * 0.27, cy - h * 0.30), w * 0.105, body);
    canvas.drawCircle(Offset(cx + w * 0.27, cy - h * 0.30), w * 0.105, body);
    canvas.drawCircle(
        Offset(cx - w * 0.27, cy - h * 0.30), w * 0.052, bodyDark);
    canvas.drawCircle(
        Offset(cx + w * 0.27, cy - h * 0.30), w * 0.052, bodyDark);

    // head
    canvas.drawCircle(Offset(cx, cy), w * 0.30, body);

    // muzzle
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy + h * 0.075),
          width: w * 0.28,
          height: h * 0.20),
      light,
    );
    // nose
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy + h * 0.035),
          width: w * 0.075,
          height: h * 0.05),
      darkAccent,
    );
    // smile
    final mouth = Paint()
      ..color = darkAccent.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.018
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(cx - w * 0.055, cy + h * 0.105)
        ..quadraticBezierTo(cx, cy + h * 0.145, cx + w * 0.055, cy + h * 0.105),
      mouth,
    );
    // eyes
    canvas.drawCircle(
        Offset(cx - w * 0.105, cy - h * 0.035), w * 0.032, darkAccent);
    canvas.drawCircle(
        Offset(cx + w * 0.105, cy - h * 0.035), w * 0.032, darkAccent);
    canvas.drawCircle(Offset(cx - w * 0.095, cy - h * 0.045), w * 0.011, white);
    canvas.drawCircle(Offset(cx + w * 0.115, cy - h * 0.045), w * 0.011, white);

    // cheeks
    final cheek = Paint()..color = const Color(0xFFE8A87C).withAlpha(90);
    canvas.drawCircle(Offset(cx - w * 0.155, cy + h * 0.055), w * 0.045, cheek);
    canvas.drawCircle(Offset(cx + w * 0.155, cy + h * 0.055), w * 0.045, cheek);

    // body
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
          center: Offset(cx, cy + h * 0.335), width: w * 0.26, height: h * 0.20),
      light,
    );

    // gold coin at belly
    canvas.drawCircle(Offset(cx, cy + h * 0.335), w * 0.085, orange);
    canvas.drawCircle(
        Offset(cx, cy + h * 0.335), w * 0.062, gold);
    final tp = TextPainter(
      text: const TextSpan(
          text: '₹',
          style: TextStyle(
              color: Color(0xFFB45309), fontWeight: FontWeight.w800)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas,
        Offset(cx - tp.width / 2, cy + h * 0.335 - tp.height / 2));

    // arms
    canvas.drawCircle(Offset(cx - w * 0.28, cy + h * 0.26), w * 0.058, body);
    canvas.drawCircle(Offset(cx + w * 0.28, cy + h * 0.26), w * 0.058, body);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ───────────────────────── page 1: earn coins ─────────────────────────
class _EarnIllustration extends StatelessWidget {
  final double h;
  const _EarnIllustration({required this.h});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // floating gold coins around the bear
        Positioned(
          top: h * 0.07,
          right: h * 0.06,
          child: _floatingCoin(h * 0.055, 1.0),
        ),
        Positioned(
          top: h * 0.20,
          left: h * 0.05,
          child: _floatingCoin(h * 0.042, 0.85),
        ),
        Positioned(
          top: h * 0.02,
          left: h * 0.17,
          child: _floatingCoin(h * 0.036, 0.7),
        ),
        Positioned(
          bottom: h * 0.06,
          right: h * 0.11,
          child: _floatingCoin(h * 0.04, 0.8),
        ),
        BearMascot(size: h * 0.30),
      ],
    );
  }

  Widget _floatingCoin(double size, double alpha) {
    return Opacity(
      opacity: alpha,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFFBBF24),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFF59E0B), width: size * 0.12),
        ),
        alignment: Alignment.center,
        child: Text('₹',
            style: TextStyle(
              color: const Color(0xFFB45309),
              fontSize: size * 0.5,
              fontWeight: FontWeight.w900,
            )),
      ),
    );
  }
}

// ───────────────────────── page 2: complete tasks ─────────────────────────
class _TasksIllustration extends StatelessWidget {
  final double h;
  const _TasksIllustration({required this.h});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // checklist card behind bear (left)
        Positioned(
          left: 6,
          top: h * 0.10,
          child: _miniCard(
            h * 0.30,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _checkRow('Survey', true),
                _checkRow('Task', true),
                _checkRow('Offer', false),
              ],
            ),
          ),
        ),
        // bear (shifted right a touch)
        Transform.translate(
          offset: Offset(h * 0.05, 0),
          child: BearMascot(size: h * 0.27),
        ),
        // floating coin
        Positioned(
          top: h * 0.05,
          right: h * 0.05,
          child: Container(
            width: h * 0.05,
            height: h * 0.05,
            decoration: BoxDecoration(
              color: const Color(0xFFFBBF24),
              shape: BoxShape.circle,
              border: Border.all(
                  color: const Color(0xFFF59E0B), width: h * 0.006),
            ),
            alignment: Alignment.center,
            child: Text('₹',
                style: TextStyle(
                    color: const Color(0xFFB45309),
                    fontSize: h * 0.026,
                    fontWeight: FontWeight.w900)),
          ),
        ),
      ],
    );
  }

  Widget _miniCard(double size, {required Widget child}) {
    return Container(
      width: size * 1.15,
      height: size * 0.95,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7E7E7)),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: child,
    );
  }

  Widget _checkRow(String label, bool done) {
    return Row(
      children: [
        Icon(done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            color: done ? const Color(0xFF16A34A) : const Color(0xFFC9C9D2),
            size: 18),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                color: Color(0xFF171717),
                fontSize: 12.5,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ───────────────────────── page 3: redeem rewards ─────────────────────────
class _RedeemIllustration extends StatelessWidget {
  final double h;
  const _RedeemIllustration({required this.h});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // reward / withdrawal card
        Positioned(
          bottom: h * 0.02,
          child: Container(
            width: h * 0.42,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE7E7E7)),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 3)),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_rounded,
                        color: Color(0xFFF59E0B), size: 22),
                    const SizedBox(width: 9),
                    const Expanded(
                      child: Text('Available Balance',
                          style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                    Text('2,450',
                        style: const TextStyle(
                            color: Color(0xFF171717),
                            fontSize: 16,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Text('Withdraw',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
        // bear above, slightly smaller
        Positioned(
          top: h * 0.02,
          child: BearMascot(size: h * 0.26),
        ),
        // coins between
        Positioned(
          bottom: h * 0.16,
          right: h * 0.09,
          child: _coin(h * 0.04),
        ),
        Positioned(
          top: h * 0.02,
          left: h * 0.06,
          child: _coin(h * 0.033),
        ),
      ],
    );
  }

  Widget _coin(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFFBBF24),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFF59E0B), width: size * 0.12),
      ),
      alignment: Alignment.center,
      child: Text('₹',
          style: TextStyle(
              color: const Color(0xFFB45309),
              fontSize: size * 0.5,
              fontWeight: FontWeight.w900)),
    );
  }
}
