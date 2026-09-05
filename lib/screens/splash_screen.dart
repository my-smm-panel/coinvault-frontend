import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/app_theme.dart';
import '../services/auth_service.dart';
import 'auth_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    // Fullscreen splash: hide status bar (battery/time) + nav bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 1.0, curve: Curves.easeOut)),
    );
    
    _controller.forward();
    
    // Navigate after animation: persisted Firebase users go straight Home
    Future.delayed(const Duration(milliseconds: 2000), () async {
      if (!mounted) return;
      // Restore system UI before leaving splash
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      Widget next = const AuthScreen();
      try {
        if (FirebaseAuth.instance.currentUser != null) {
          final model = await AuthService().ensureUserLoaded();
          if (model != null && mounted) next = const HomeScreen();
        }
      } catch (_) {}
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => next),
        );
      }
    });
  }

  @override
  void dispose() {
    // Safety: always restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF66B06),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Bear loading screen: whole image always visible.
          // Image bg is solid orange = same as scaffold, so it blends
          // seamlessly on any screen size (no crop, no stretch).
          FadeTransition(
            opacity: _fadeAnim,
            child: Center(
              child: Image.asset(
                'assets/app_icon.jpg',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: const Center(
              child: SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}