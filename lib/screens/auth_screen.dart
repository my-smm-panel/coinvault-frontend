import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

/// Login screen — uses the exact CoinVault design image (pixel-perfect).
/// The image already contains the bear, glow, wordmark, tagline and the
/// "Continue with Google" pill. A transparent tap-zone sits over that pill so
/// Google sign-in still works.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _loading = false;
  String? _error;

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
    // Show loading toast if present.
    Widget? note;
    if (_error != null) {
      note = Positioned(
        top: 60,
        left: 24,
        right: 24,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xE6291111),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0D0B),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // The exact design image, letterboxed invisibly on the dark bg.
          Image.asset('assets/login_screen.png', fit: BoxFit.contain),

          // Transparent tap-zone over the baked-in "Continue with Google" pill.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: MediaQuery.of(context).size.height * 0.2,
            child: Align(
              alignment: Alignment.topCenter,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _loading ? null : _signInWithGoogle,
                child: _loading
                    ? const Center(
                        child: SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF8A2A)),
                          ),
                        ),
                      )
                    : SizedBox.expand(), // fills the zone -> tappable
              ),
            ),
          ),

          if (note != null) note,
        ],
      ),
    );
  }
}
