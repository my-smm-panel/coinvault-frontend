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
  static const _bg = Color(0xFF0B0B12);

  // 12 famous Indian / global gift card brands
  static const _brands = [
    {'name': 'Amazon Pay',    'color': Color(0xFFFF9900), 'icon': Icons.shopping_cart_rounded},
    {'name': 'PhonePe',       'color': Color(0xFF5F259F), 'icon': Icons.phone_android_rounded},
    {'name': 'Paytm',         'color': Color(0xFF00B9F1), 'icon': Icons.account_balance_wallet_rounded},
    {'name': 'Flipkart',      'color': Color(0xFF2874F0), 'icon': Icons.shopping_bag_rounded},
    {'name': 'Google Play',   'color': Color(0xFF34A853), 'icon': Icons.play_circle_fill_rounded},
    {'name': 'Myntra',        'color': Color(0xFFFF4466), 'icon': Icons.checkroom_rounded},
    {'name': 'Ajio',          'color': Color(0xFF2BB1E4), 'icon': Icons.shopping_basket_rounded},
    {'name': 'Swiggy',        'color': Color(0xFFFF5200), 'icon': Icons.restaurant_rounded},
    {'name': 'Zomato',        'color': Color(0xFFE23744), 'icon': Icons.restaurant_menu_rounded},
    {'name': 'Netflix',       'color': Color(0xFFE50914), 'icon': Icons.movie_rounded},
    {'name': 'Spotify',       'color': Color(0xFF1DB954), 'icon': Icons.music_note_rounded},
    {'name': 'OLA',           'color': Color(0xFF00C853), 'icon': Icons.directions_car_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Gift Cards',
            style: TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
        centerTitle: false,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _brands.length,
        itemBuilder: (_, i) => _brandCard(_brands[i]),
      ),
    );
  }

  Widget _brandCard(Map<String, dynamic> brand) {
    final name = brand['name'] as String;
    final color = brand['color'] as Color;
    final icon = brand['icon'] as IconData;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showRedeemDialog(name, color),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF17171F),
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
                child: Icon(icon,
                    color: color, size: 26),
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
            backgroundColor: const Color(0xFF17171F),
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
                  child: Icon(
                      _brands.firstWhere((b) => b['name'] == brand)['icon']
                          as IconData,
                      color: brandColor, size: 20),
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
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  decoration: InputDecoration(
                    hintText: 'e.g. 50',
                    hintStyle: const TextStyle(color: Colors.white24),
                    prefixText: '₹ ',
                    prefixStyle: TextStyle(color: brandColor, fontSize: 18),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.07),
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
                          style: TextStyle(color: Colors.white54, fontSize: 12)),
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
                          style: TextStyle(color: Colors.white54, fontSize: 12)),
                      Text('$balance coins',
                          style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel',
                    style: TextStyle(color: Colors.white54)),
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
                  disabledForegroundColor: Colors.white38,
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