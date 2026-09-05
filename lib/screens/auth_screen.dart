import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
      setState(() {
        _error = 'Sign-in error: $e';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'account-exists-with-different-credential':
        return 'Account exists with different sign-in method.';
      case 'invalid-credential':
        return 'Invalid credentials. Please try again.';
      case 'operation-not-allowed':
        return 'Google sign-in is not enabled. Contact support.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return 'Sign-in failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              
              // Logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: AppShadows.elevated,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              
              // Title
              Text(
                'Welcome to CoinVault',
                style: AppTextStyles.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Sign in to start earning coins\nvia tasks, spin wheel & surveys',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              
              // Error message
              if (_error != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Text(
                    _error!,
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              
              // Google Sign-In Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _signInWithGoogle,
                  icon: _loading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.textOnPrimary),
                          ),
                        )
                      : Image.asset(
                          'assets/google_logo.png',
                          width: 22,
                          height: 22,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.g_mobiledata,
                            size: 22,
                            color: Colors.white,
                          ),
                        ),
                  label: Text(_loading ? 'Signing in...' : 'Continue with Google'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.textPrimary,
                    elevation: 0,
                    side: const BorderSide(color: AppColors.divider),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    textStyle: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary),
                  ),
                ),
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Terms
              Text(
                'By continuing, you agree to our\nTerms of Service & Privacy Policy',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.md),

              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}