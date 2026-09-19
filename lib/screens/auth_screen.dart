import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

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
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    // Login can complete via the authStateChanges listener (not just the
    // direct return value), so listen too — otherwise the button unlocks and
    // the screen just sits there after a successful sign-in.
    AuthService().addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    AuthService().removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (!_navigated && AuthService().isLoggedIn && mounted) {
      _navigated = true;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

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
      final model = await AuthService().signInWithGoogle();
      if (model == null && mounted && !_navigated) {
        // Picker dismissed without an account — unlock the button, no error.
        setState(() => _loading = false);
        return;
      }
      // Success: the listener (or this) routes to Home.
      _onAuthChanged();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted && !_navigated) setState(() => _loading = false);
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
              Image.asset('assets/bear_earn.png', height: h * 0.26, fit: BoxFit.contain),

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
                                  Image.asset('assets/google_g.png', width: 20, height: 20),
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
