import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/app_models.dart';
import '../services/app_repository.dart';
import '../services/auth_service.dart';
import '../services/balance_stream.dart';
import '../widgets/state_views.dart';
import 'earn_screen.dart';
import 'help_screen.dart';
import 'history_screen.dart';
import 'invite_screen.dart';
import 'leaderboard_screen.dart';
import 'notifications_screen.dart';
import 'withdraw_screen.dart';

/// Profile — CoinVault light premium design (global header, readable text).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  bool _loading = true;

  static const _bg = Color(0xFFFAFAF8);
  static const _card = Color(0xFFFFFFFF);
  static const _border = Color(0xFFE7E7E7);
  static const _textPrimary = Color(0xFF171717);
  static const _textSecondary = Color(0xFF6B7280);

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
      // Wallet balance must come from a fresh authenticated response.
      await AppRepository.instance.fetchWalletBalance();
      if (mounted) setState(() {});
    } else {
      setState(() => _loading = false);
    }
    // Refresh server-authoritative remaining spins so the "Spins left"
    // tile matches what the spin screen enforces.
    try {
      final status = await AppRepository.instance.spinStatus();
      final limit = status?['dailyLimit'];
      final used = status?['spinsUsed'];
      if (!mounted || limit is! num || used is! num) return;
      setState(() => _spinsLeft = (limit.toInt() - used.toInt()).clamp(0, limit.toInt()).toInt());
    } catch (_) {}
  }

  int? _spinsLeft;

  Future<void> _signOut() async {
    await AuthService().signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  /// Confirm before logging out — prevents accidental taps from losing the
  /// session while a withdrawal is pending.
  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Logout?'),
        content: const Text(
            'You will be signed out of CoinVault. Your coins and progress stay safe.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (ok == true) await _signOut();
  }

  void _push(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  static String _fmt(int n) {
    final s = StringBuffer();
    final str = n.abs().toString();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count != 0 && count % 3 == 0) s.write(',');
      s.write(str[i]);
      count++;
    }
    final rev = s.toString().split('').reversed.join();
    return n < 0 ? '-$rev' : rev;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _bg,
        body: ShimmerCardList(rows: 6, padding: EdgeInsets.all(20)),
      );
    }
    if (_user == null) {
      return Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: _bg,
          foregroundColor: _textPrimary,
          elevation: 0,
        ),
        body: const Center(
          child: Text('Please sign in',
              style: TextStyle(color: _textSecondary, fontSize: 14)),
        ),
      );
    }

    final user = _user!;
    final balance = BalanceStream.instance.value;
    final spinsLeft = _spinsLeft?.toString() ?? '—';
    final name = user.displayName.isEmpty ? 'User' : user.displayName;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Title ──
              const Text(
                'My Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Manage your account & rewards',
                style: TextStyle(fontSize: 13, color: _textSecondary),
              ),
              const SizedBox(height: 18),

              // ── Profile card ──
              _profileCard(user, name, balance),
              const SizedBox(height: 14),

              // ── Stats grid ──
              _statsGrid(balance, spinsLeft),
              const SizedBox(height: 14),

              // ── Payout details ──
              if ((user.upiId ?? '').isNotEmpty ||
                  (user.bankDetails ?? '').isNotEmpty) ...[
                _payoutCard(user),
                const SizedBox(height: 14),
              ],

              // ── Menu ──
              const Text(
                'Account',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              _menuList(),
              const SizedBox(height: 22),

              // ── Logout ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _confirmLogout,
                  icon: const Icon(Icons.logout_rounded, size: 19),
                  label: const Text('Logout',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error.withOpacity(0.5), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Center(
                child: const Text('CoinVault v1.0.0',
                    style:
                        TextStyle(color: Color(0xFFB9BDC4), fontSize: 11)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileCard(UserModel user, String name, int? balance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/bear_avatar.png',
                fit: BoxFit.cover,
                width: 56,
                height: 56,
                errorBuilder: (_, __, ___) => Container(
                  width: 56,
                  height: 56,
                  color: const Color(0xFFFFF7E6),
                  child: const Icon(Icons.person_rounded, size: 28),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                if (user.email != null && user.email!.isNotEmpty)
                  Text(
                    user.email!,
                    style: const TextStyle(
                        color: _textSecondary, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.monetization_on_rounded,
                        color: AppColors.primary, size: 16),
                    const SizedBox(width: 5),
                    Text(
                      balance == null ? 'Balance unavailable' : '${_fmt(balance)} Coins',
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsGrid(int? balance, String spinsLeft) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.3,
      children: [
        _stat('Balance', balance == null ? '—' : _fmt(balance), Icons.payments_rounded,
            AppColors.primary),
        _stat('Spins Left', spinsLeft, Icons.donut_large_rounded,
            const Color(0xFFF59E0B)),
        _stat('Wallet status', balance == null ? 'Unknown' : 'Fresh', Icons.account_balance_wallet_rounded,
            const Color(0xFF16A34A)),
        _stat('Payouts', 'View', Icons.currency_rupee_rounded,
            const Color(0xFF3B82F6)),
      ],
    );
  }

  Widget _stat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(label,
                    style: const TextStyle(
                        color: _textSecondary, fontSize: 10.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuList() {
    final items = [
      ['History', 'View all tasks & payouts', Icons.history_rounded,
          const Color(0xFF14B8A6), const HistoryScreen()],
      ['Payouts', 'Withdrawal transactions', Icons.payments_rounded,
          AppColors.primary, const HistoryScreen(initialTab: 'Payouts')],
      ['Ranks', 'Leaderboard standings', Icons.emoji_events_rounded,
          const Color(0xFFF59E0B), const LeaderboardScreen()],
      ['Refer & Earn', 'Referral code and activity', Icons.group_add_rounded,
          const Color(0xFFEC4899), const InviteScreen()],
      ['Earn More', 'Tasks & offers', Icons.task_alt_rounded,
          const Color(0xFF3B82F6), const EarnScreen()],
      ['Withdraw', 'Request payout', Icons.account_balance_wallet_rounded,
          AppColors.primary, const WithdrawScreen()],
      ['Notifications', 'Alerts & updates', Icons.notifications_rounded,
          const Color(0xFFF59E0B), const NotificationsScreen()],
      ['Help & Support', 'FAQs and contact', Icons.help_outline_rounded,
          const Color(0xFF8B5CF6), const HelpScreen()],
    ];
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _row(
              items[i][0] as String,
              items[i][1] as String,
              items[i][2] as IconData,
              items[i][3] as Color,
              () => _push(items[i][4] as Widget),
            ),
            if (i != items.length - 1)
              const Divider(height: 1, color: _border),
          ],
        ],
      ),
    );
  }

  Widget _row(String title, String sub, IconData icon, Color color,
      VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(sub,
                      style: const TextStyle(
                          color: _textSecondary, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFFB9BDC4)),
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
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.account_balance_wallet_rounded,
                  size: 17, color: AppColors.primary),
              SizedBox(width: 7),
              Text('Payout Details',
                  style: TextStyle(
                      color: _textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          if ((user.upiId ?? '').isNotEmpty)
            Text('UPI: ${user.upiId}',
                style: const TextStyle(
                    color: _textSecondary, fontSize: 12.5)),
          if ((user.bankDetails ?? '').isNotEmpty)
            Text('Bank: ${user.bankDetails}',
                style: const TextStyle(
                    color: _textSecondary, fontSize: 12.5),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _push(const WithdrawScreen()),
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: const Text('Update Payout Details'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
