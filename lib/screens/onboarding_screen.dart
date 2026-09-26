import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import 'auth_screen.dart';

/// 3-screen onboarding: Earn Coins → Complete Tasks → Redeem Rewards.
/// Uses the real bear mascot illustrations cropped from the user's design
/// sheet (assets/bear_*.png). Same design system across all three.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _page = 0;

  static const Color _bg = AppColors.background;
  static const Color _primaryText = AppColors.textPrimary;
  static const Color _secondaryText = AppColors.textSecondary;
  static const Color _orange = AppColors.gold;

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
  static const _images = [
    'assets/bear_earn.png',
    'assets/bear_tasks.png',
    'assets/bear_redeem.png',
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
                  padding: const EdgeInsets.only(top: 6, right: 10),
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

              // illustration (real bear asset, per page)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Image.asset(
                    _images[_page],
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                  ),
                ),
              ),

              const SizedBox(height: 10),

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

              const SizedBox(height: 20),

              // page indicator
              _indicator(),

              const SizedBox(height: 18),

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

              const SizedBox(height: 24),
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
}
