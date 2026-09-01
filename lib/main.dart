import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'screens/preview_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CoinVaultApp());
}

class CoinVaultApp extends StatelessWidget {
  const CoinVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CoinVault',
      theme: AppTheme.light,
      home: const CoinVaultPreviewApp(),
    );
  }
}
