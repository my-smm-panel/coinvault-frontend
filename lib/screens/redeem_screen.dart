import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../services/app_repository.dart';
import '../services/auth_service.dart';

/// Gift card redeem screen — shows brand grid (Amazon, OLA, PhonePe, Paytm,
/// Flipkart, Google Play, Myntra, Ajio, Swiggy, Zomato, Netflix, Spotify).
/// Tap a brand → redeem dialog.
class RedeemScreen extends StatefulWidget {
  const RedeemScreen({super.key});

  @override
  State<RedeemScreen> createState() => _RedeemScreenState();
}

class _RedeemScreenState extends State<RedeemScreen> {
  static const _bg = Color(0xFFF7F8FA);

  // Brand list is loaded from the backend on init — never hardcoded.
  List<Map<String, dynamic>> _brands = [];
  bool _loading = true;
  bool _failed = false;

  // Fallback brand assets exist for known names; unknown names get a generic icon.
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

  static const _brandColors = {
    'Amazon Pay': Color(0xFFFF9900),
    'PhonePe': Color(0xFF5F259F),
    'Paytm': Color(0xFF00B9F1),
    'Flipkart': Color(0xFF2874F0),
    'Google Play': Color(0xFF34A853),
    'Myntra': Color(0xFFFF4466),
    'Ajio': Color(0xFF2BB1E4),
    'Swiggy': Color(0xFFFF5200),
    'Zomato': Color(0xFFE23744),
    'Netflix': Color(0xFFE50914),
    'Spotify': Color(0xFF1DB954),
    'OLA': Color(0xFF00C853),
  };

  static String _brandImg(String name) =>
      _brandAssets[name] ?? 'assets/brands/amazon.png';

  static Color _brandColor(String name) =>
      _brandColors[name] ?? AppColors.primary;

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
          .map((e) => <String, dynamic>{'name': (e['name'] ?? e['brand'] ?? 'Gift Card').toString()})
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Gift Cards',
            style: TextStyle(
                color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
        centerTitle: false,
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_failed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.textSecondary),
            const SizedBox(height: 10),
            const Text('Could not load gift cards',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_brands.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.card_giftcard_rounded, size: 40, color: AppColors.textSecondary),
            SizedBox(height: 10),
            Text('No gift cards available yet',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _brands.length,
      itemBuilder: (_, i) => _brandCard(_brands[i]),
    );
  }

  Widget _brandCard(Map<String, dynamic> brand) {
    final name = brand['name'] as String;
    final color = _brandColor(name);
    final img = _brandImg(name);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showRedeemDialog(name, color),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    img,
                    width: 30,
                    height: 30,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                        Icons.card_giftcard_rounded,
                        color: color, size: 24),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showRedeemDialog(String brand, Color brandColor) {
    final user = AuthService().userModel;
    final balance = user?.coins ?? 0;
    final ctrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final amount = int.tryParse(ctrl.text) ?? 0;
          final coinsNeeded = (amount * 100).clamp(0, 999999999);
          final valid = amount >= 10 && coinsNeeded <= balance;

          return AlertDialog(
            backgroundColor: const Color(0xFFFFFFFF),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: brandColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      _brandImg(brand),
                      width: 22,
                      height: 22,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                          Icons.card_giftcard_rounded,
                          color: brandColor, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(brand, style: TextStyle(color: brandColor, fontSize: 18)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Enter amount (₹)',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
                  decoration: InputDecoration(
                    hintText: 'e.g. 50',
                    hintStyle: const TextStyle(color: AppColors.textTertiary),
                    prefixText: '₹ ',
                    prefixStyle: TextStyle(color: brandColor, fontSize: 18),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: brandColor, width: 1.5),
                    ),
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
                const SizedBox(height: 12),
                if (ctrl.text.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Coins needed',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      Text('$coinsNeeded coins',
                          style: TextStyle(color: brandColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Your balance',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      Text('$balance coins',
                         style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                    ],
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                onPressed: valid
                    ? () {
                        Navigator.pop(ctx);
                        _redeem(brand, amount, coinsNeeded);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: brandColor.withOpacity(0.25),
                  disabledForegroundColor: AppColors.textSecondary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: const Text('Redeem',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _redeem(String brand, int amount, int coins) async {
    final user = AuthService().userModel;
    if (user == null) return;

    // Front-end guard: clear message before server round-trip
    if (user.coins < coins) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Not enough coins. Need $coins, have ${user.coins}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    final repo = AppRepository.instance;
    try {
      await repo.submitWithdrawal(
        uid: user.uid,
        coins: coins,
        method: 'voucher',
        details: '$brand|₹$amount',
      );
      // Deduct coins instantly (local first)
      await AuthService().deductCoins(coins);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $brand ₹$amount redeem request submitted!'),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.pop(context); // close dialog
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $msg'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}