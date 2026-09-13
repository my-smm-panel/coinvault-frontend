import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'screens/auth_screen.dart';
import 'screens/spin_screen.dart';

/// Screenshot harness entry — runs AuthScreen / SpinScreen directly
/// (no Firebase, no backend) so we can capture and compare with the
/// reference images. Not shipped in the APK.
void main() {
  runApp(const ScreenshotApp());
}

class ScreenshotApp extends StatelessWidget {
  const ScreenshotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CoinVault Screenshot',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.black,
      ),
      // Args: 'spin' -> SpinScreen, anything else -> AuthScreen
      home: _home(),
    );
  }

  Widget _home() {
    // no easy args on web; use a switch via const from environment later.
    return const AuthScreen();
  }
}
