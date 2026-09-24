import 'package:flutter/material.dart';
import 'package:coinvault_admin/services/api_service.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final loginResponse = await ApiService.post('/api/admin-v2/auth/login', {
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
    });

    if (!mounted) return;

    if (loginResponse == null || !loginResponse.containsKey('success')) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Login failed. Check credentials.';
      });
      return;
    }

    final success = loginResponse['success'] as bool;
    if (!success) {
      setState(() {
        _isLoading = false;
        _errorMessage = loginResponse['error'] ?? 'Login failed';
      });
      return;
    }

    // Check if OTP is required
    final data = loginResponse['data'] as Map<String, dynamic>?;
    if (data != null && data['requiresOtp'] == true) {
      // Navigate to OTP verification
      setState(() => _isLoading = false);
      _showOtpDialog();
      return;
    }

    setState(() => _isLoading = false);
    _showError('OTP verification required');
  }

  Future<void> _showOtpDialog() async {
    final email = _emailController.text.trim();
    final otpController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter OTP'),
        content: Form(
          key: GlobalKey<FormState>(),
          child: TextFormField(
            controller: otpController,
            decoration: const InputDecoration(
              labelText: 'OTP Code',
              hintText: 'Check your email',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.length < 4) {
                return 'Enter valid OTP';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, {'otp': otpController.text}),
            child: const Text('Verify'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (result != null) {
      await _verifyOtp(email, result['otp'] as String);
    }
  }

  Future<void> _verifyOtp(String email, String otp) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await ApiService.post('/api/admin-v2/auth/verify', {
      'email': email,
      'otp': otp,
    });

    if (!mounted) return;

    if (response == null || !response.containsKey('success')) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'OTP verification failed';
      });
      return;
    }

    final success = response['success'] as bool;
    if (!success) {
      setState(() {
        _isLoading = false;
        _errorMessage = response['error'] ?? 'OTP failed';
      });
      return;
    }

    final data = response['data'] as Map<String, dynamic>?;
    if (data != null) {
      final token = data['token'] as String?;
      final refreshToken = data['refreshToken'] as String?;

      if (token != null && refreshToken != null) {
        await ApiService.setToken(token, refreshToken);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
        return;
      }
    }

    setState(() {
      _isLoading = false;
      _errorMessage = 'No token received';
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'CoinVault Admin',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign in to manage your platform',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter email';
                      }
                      if (!value.contains('@')) {
                        return 'Enter valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter password';
                      }
                      return null;
                    },
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sign In'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
