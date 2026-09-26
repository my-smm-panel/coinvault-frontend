import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../services/app_repository.dart';

/// Gift-card catalogue and server-authoritative redemption.
class RedeemScreen extends StatefulWidget {
  const RedeemScreen({super.key});

  @override
  State<RedeemScreen> createState() => _RedeemScreenState();
}

class _RedeemScreenState extends State<RedeemScreen> {
  List<Map<String, dynamic>> _brands = [];
  bool _loading = true;
  bool _failed = false;
  bool _confirming = false;
  bool _redeeming = false;

  static const _brandAssets = {
    'Amazon Pay': 'assets/brands/amazon.png',
    'PhonePe': 'assets/brands/phonepe.png',
    'Paytm': 'assets/brands/paytm.png',
    'Flipkart': 'assets/brands/flipkart.png',
    'Google Play': 'assets/brands/googleplay.png',
    'Myntra': 'assets/brands/myntra.png',
    'Ajio': 'assets/brands/ajio.png',
    'Swiggy': 'assets/brands/swiggy.png',
    'Zomato': 'assets/brands/zomato.png',
    'Netflix': 'assets/brands/netflix.png',
    'Spotify': 'assets/brands/spotify.png',
    'OLA': 'assets/brands/ola.png',
  };

  static String _brandImg(String name) =>
      _brandAssets[name] ?? 'assets/brands/amazon.png';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    final list = await AppRepository.instance.fetchGiftCards();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _failed = list == null;
      _brands = (list ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((e) => (e['name'] ?? e['brand'] ?? '').toString().trim().isNotEmpty)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Gift Cards', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_failed) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.textSecondary),
          const SizedBox(height: 10),
          const Text('Could not load gift cards', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 12),
          TextButton(onPressed: _load, child: const Text('Retry')),
        ]),
      );
    }
    if (_brands.isEmpty) {
      return const Center(child: Text('No gift cards available yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)));
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final columns = width >= 760 ? 5 : width >= 560 ? 4 : width >= 340 ? 3 : 2;
          return GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              childAspectRatio: 0.96,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _brands.length,
            itemBuilder: (_, i) => _brandCard(_brands[i]),
          );
        },
      ),
    );
  }

  Widget _brandCard(Map<String, dynamic> brand) {
    final name = (brand['name'] ?? brand['brand'] ?? '').toString();
    final image = (brand['image'] ?? '').toString();
    final value = brand['valueInr'];
    final cost = brand['coinCost'];
    final stock = brand['stock'];
    final outOfStock = stock is num && stock <= 0;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: (_confirming || _redeeming) ? null : () => _showInfo(brand),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: image.isNotEmpty
                    ? Image.network(image, width: 30, height: 30, fit: BoxFit.contain, errorBuilder: (_, __, ___) => _assetOrIcon(name))
                    : _assetOrIcon(name),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w700), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          if (value is num || cost is num)
            Text([if (value is num) '₹${value.toString()}', if (cost is num) '${cost.toString()} coins'].join(' • '), style: const TextStyle(color: AppColors.textSecondary, fontSize: 9), maxLines: 1, overflow: TextOverflow.ellipsis),
          if (outOfStock)
            const Text('Out of stock', style: TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }

  Widget _assetOrIcon(String name) {
    return Image.asset(_brandImg(name), width: 30, height: 30, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.card_giftcard_rounded, color: AppColors.primary, size: 24));
  }

  Future<void> _showInfo(Map<String, dynamic> brand) async {
    if (_confirming || _redeeming) return;
    final id = (brand['id'] ?? '').toString().trim();
    final name = (brand['name'] ?? brand['brand'] ?? 'Gift card').toString();
    final value = brand['valueInr'];
    final cost = brand['coinCost'];
    final stock = brand['stock'];
    final outOfStock = stock is num && stock <= 0;
    if (outOfStock) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(name),
          content: const Text('This gift card is currently out of stock.'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
        ),
      );
      return;
    }
    if (id.isEmpty) {
      _showMessage('This gift card cannot be redeemed right now.');
      return;
    }
    setState(() => _confirming = true);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Redeem $name?'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (value is num) Text('Value: ₹${value.toString()}'),
          if (cost is num) Text('Cost: ${cost.toString()} coins'),
          const SizedBox(height: 12),
          const Text('The server will check availability and your balance before redeeming.'),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Redeem')),
        ],
      ),
    );
    if (mounted) setState(() => _confirming = false);
    if (confirmed == true && mounted) await _redeem(id, name);
  }

  Future<void> _redeem(String id, String name) async {
    if (_redeeming) return;
    setState(() => _redeeming = true);
    try {
      final result = await AppRepository.instance.redeemGiftCard(id);
      if (!mounted) return;
      final redemption = result['redemption'] is Map
          ? Map<String, dynamic>.from(result['redemption'] as Map)
          : <String, dynamic>{};
      await _showRedemption(name, redemption);
      if (mounted) _load();
    } catch (error) {
      if (mounted) {
        final message = error.toString().replaceFirst(RegExp(r'^Exception: '), '');
        _showMessage(message.isEmpty ? 'Gift card redemption failed.' : message);
      }
    } finally {
      if (mounted) setState(() => _redeeming = false);
    }
  }

  Future<void> _showRedemption(String name, Map<String, dynamic> redemption) async {
    final code = redemption['code']?.toString();
    final pin = redemption['pin']?.toString();
    final expiresAt = redemption['expiresAt']?.toString();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text('$name redeemed'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (code != null && code.isNotEmpty) Text('Code: $code'),
          if (pin != null && pin.isNotEmpty) Text('PIN: $pin'),
          if (expiresAt != null && expiresAt.isNotEmpty) Text('Expires: $expiresAt'),
          if ((code == null || code.isEmpty) && (pin == null || pin.isEmpty) && (expiresAt == null || expiresAt.isEmpty))
            const Text('Your gift card redemption was completed.'),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done'))],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}
