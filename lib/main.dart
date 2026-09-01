import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'core/api_config.dart';
import 'screens/preview_app.dart';
import 'services/app_repository.dart';

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
      title: ApiConfig.appName,
      theme: AppTheme.light,
      home: const CoinVaultPreviewApp(),
    );
  }
}

/// Fetches real data from the backend and hands it to the UI.
/// UI falls back to mock data when the API is unreachable.
class HomeDataLoader extends StatefulWidget {
  const HomeDataLoader({super.key, required this.builder});

  final Widget Function(Map<String, dynamic> data) builder;

  @override
  State<HomeDataLoader> createState() => _HomeDataLoaderState();
}

class _HomeDataLoaderState extends State<HomeDataLoader> {
  Map<String, dynamic> _data = {};
  bool _loading = true;
  bool _connected = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = AppRepository.instance;
    final connected = await repo.checkHealth();
    final data = await repo.fetchHomeData();
    if (mounted) {
      setState(() {
        _connected = connected;
        _data = data;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return widget.builder(_data);
  }
}
