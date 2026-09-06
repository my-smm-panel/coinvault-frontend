import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../services/auth_service.dart';
import '../models/app_models.dart';
import 'earn_screen.dart';
import 'leaderboard_screen.dart';
import 'history_screen.dart';
import 'notifications_screen.dart';
import 'refer_screen.dart';
import 'withdraw_screen.dart';
import 'help_screen.dart';

/// Profile - own CoinVault style: centered bear avatar overlapping
/// an orange header, gold balance pill, 2x2 stats grid, grid menu.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  bool _loading = true;

  static const _bg = Color(0xFF0B0B12);
  static const _card = Color(0xFF17171F);

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final auth = AuthService();
    if (auth.isLoggedIn) {
      setState(() {
        _user = auth.userModel;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    await AuthService().signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  void _push(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(
            child:
                CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (_user == null) {
      return Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(
          child: Text('Please sign in',
              style: TextStyle(color: Colors.white70)),
        ),
      );
    }
    final user = _user!;
    final spinsLeft =
        (2 - user.dailySpinsUsed).clamp(0, 2).toString();
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _header(user),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    _balanceCard(user),
                    const SizedBox(height: 12),
                    _statsGrid(user, spinsLeft),
                    const SizedBox(height: 16),
                    _gridMenu(),
                    const SizedBox(height: 8),
                    if ((user.upiId ?? '').isNotEmpty ||
                        (user.bankDetails ?? '').isNotEmpty)
                      _payoutCard(user),
                    const SizedBox(height: 8),
                    const Text('CoinVault v1.0.0',
                        style: TextStyle(
                            color: Colors.white38, fontSize: 11)),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Orange header with centered avatar overlapping the bottom edge.
  Widget _header(UserModel user) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.fromLTRB(16, 12, 16, 56),
          decoration: const BoxDecoration(
            gradient: AppColors.brandHeader,
            borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(28)),
          ),
          child: Row(
            children: [
              const Text('My Profile',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              const Spacer(),
              InkWell(
                onTap: () => _push(const HelpScreen()),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.settings_rounded,
                          color: Colors.white, size: 15),
                      SizedBox(width: 4),
                      Text('Help',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: -44,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _bg,
                border: Border.all(
                    color: AppColors.gold, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 42,
                backgroundColor: Colors.white10,
                backgroundImage: user.photoUrl != null
                    ? NetworkImage(user.photoUrl!)
                    : const AssetImage('assets/app_icon.jpg')
                        as ImageProvider,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _balanceCard(UserModel user) {
    return Container(
      margin: const EdgeInsets.only(top: 56),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: AppColors.gold.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Text(
            user.displayName.isEmpty ? 'User' : user.displayName,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (user.email != null && user.email!.isNotEmpty)
            Text(user.email!,
                style: const TextStyle(
                    color: Colors.white54, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 6),
                Text('${user.coins} coins',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Text('≈ ₹${(user.coins / 10).toStringAsFixed(2)}',
              style: const TextStyle(
                  color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _statsGrid(UserModel user, String spinsLeft) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.1,
      children: [
        _stat('Withdrawable', '${user.coins}',
            Icons.payments_rounded, AppColors.primary),
        _stat('Spins Left', spinsLeft, Icons.casino_rounded,
            AppColors.gold),
        _stat('Total Earned', '${user.coins}',
            Icons.emoji_events_rounded, const Color(0xFF10B981)),
        _stat('Rate', '100 = ₹10', Icons.currency_rupee_rounded,
            const Color(0xFF3B82F6)),
      ],
    );
  }

  Widget _stat(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(label,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 2-column grid menu (own style, not rows).
  Widget _gridMenu() {
    final items = [
      ['History', Icons.history_rounded, const Color(0xFF14B8A6),
        const HistoryScreen()],
      ['Payouts', Icons.payments_rounded, AppColors.primary,
        const HistoryScreen(initialTab: 'Payouts')],
      ['Ranks', Icons.emoji_events_rounded, AppColors.gold,
        const LeaderboardScreen()],
      ['Refer', Icons.group_add_rounded, const Color(0xFFEC4899),
        const ReferScreen()],
      ['Earn', Icons.task_alt_rounded, const Color(0xFF3B82F6),
        const EarnScreen()],
      ['Withdraw', Icons.account_balance_wallet_rounded,
        AppColors.primary, const WithdrawScreen()],
      ['Alerts', Icons.notifications_rounded, const Color(0xFFF59E0B),
        const NotificationsScreen()],
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.05,
      children: [
        ...items.map((e) => _tile(e[0] as String, e[1] as IconData,
            e[2] as Color, () => _push(e[3] as Widget))),
        _tile('Logout', Icons.logout_rounded,
            const Color(0xFFEF4444), _signOut),
      ],
    );
  }

  Widget _tile(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _payoutCard(UserModel user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payout Details',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          if ((user.upiId ?? '').isNotEmpty)
            Text('UPI: ${user.upiId}',
                style: const TextStyle(
                    color: Colors.white54, fontSize: 12)),
          if ((user.bankDetails ?? '').isNotEmpty)
            Text('Bank: ${user.bankDetails}',
                style: const TextStyle(
                    color: Colors.white54, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
