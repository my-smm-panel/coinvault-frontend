import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_theme.dart';
import '../core/provider_logos.dart';
import '../services/auth_service.dart';
import '../models/app_models.dart';
import 'earn_screen.dart';
import 'spin_screen.dart';
import 'surveys_screen.dart';
import 'withdraw_screen.dart';
import 'profile_screen.dart';
import 'leaderboard_screen.dart';
import 'history_screen.dart';
import 'notifications_screen.dart';
import 'refer_screen.dart';
import 'help_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  UserModel? _user;
  bool _loading = true;

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _loadUser();
    _screens.addAll([
      const HomeTab(),
      const EarnScreen(),
      const SpinScreen(),
      const SurveysScreen(),
      const ProfileScreen(),
    ]);
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isActive: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _NavItem(
                  icon: Icons.task_alt_rounded,
                  label: 'Earn',
                  isActive: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _NavItem(
                  icon: Icons.casino_rounded,
                  label: 'Spin',
                  isActive: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                  badge: _user?.remainingSpins() ?? 2,
                ),
                _NavItem(
                  icon: Icons.assignment_rounded,
                  label: 'Surveys',
                  isActive: _currentIndex == 3,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
                _NavItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  isActive: _currentIndex == 4,
                  onTap: () => setState(() => _currentIndex = 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final int? badge;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primary.withOpacity(0.12)
                          : Colors.transparent,
                      borderRadius:
                          BorderRadius.circular(AppRadius.full),
                    ),
                    child: Icon(
                      icon,
                      size: 24,
                      color: isActive
                          ? AppColors.primary
                          : AppColors.textTertiary,
                    ),
                  ),
                  if (badge != null && badge! > 0 && !isActive)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          badge.toString(),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isActive ? AppColors.primary : AppColors.textTertiary,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Home Tab - Main dashboard
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuilds instantly whenever AuthService coins/user change (no restart).
    return ListenableBuilder(
      listenable: AuthService(),
      builder: (context, _) {
        final auth = AuthService();
        final user = auth.userModel;
        final remainingSpins = auth.getRemainingSpins();

        return Scaffold(
      backgroundColor: const Color(0xFF0E0E13),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _proTopBar(context, user),
              const SizedBox(height: 12),
              _proWalletBar(context, user, remainingSpins),
              const SizedBox(height: 12),
              _proTicker(),
              const SizedBox(height: 12),
              _proPromoRow(context),
              const SizedBox(height: 18),
              _proSectionTitle('FEATURED SURVEYS'),
              const SizedBox(height: 10),
              _proSurveyRow(context),
              const SizedBox(height: 18),
              _proSectionTitle('TASKS OF THE DAY',
                  action: 'History',
                  onAction: () => _proPush(
                      context, const HistoryScreen())),
              const SizedBox(height: 10),
              _proTasksList(context),
              const SizedBox(height: 18),
              _proSectionTitle('EARNING PARTNERS',
                  action: 'Earn',
                  onAction: () =>
                      _proPush(context, const EarnScreen())),
              const SizedBox(height: 10),
              _proProvidersRow(context),
              const SizedBox(height: 18),
              _proMegaBanner(context),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
        );
      },
    );
  }

  void _proPush(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  /// Pro top bar: bear logo + CoinVault + Tutorials / Notification / Profile.
  Widget _proTopBar(BuildContext context, UserModel? user) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/app_icon_name.png',
            width: 42,
            height: 42,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.account_balance_wallet_rounded,
              color: AppColors.gold,
              size: 36,
            ),
          ),
        ),
        const SizedBox(width: 8),
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            children: [
              TextSpan(
                  text: 'Coin',
                  style: TextStyle(color: AppColors.gold)),
              TextSpan(
                  text: 'Vault', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        const Spacer(),
        _proTopIcon(context, Icons.play_arrow_rounded,
            const Color(0xFFE53935), 'Tutorials', const HelpScreen()),
        _proTopIcon(context, Icons.notifications_rounded,
            AppColors.primary, 'Notification', const NotificationsScreen()),
        _proTopIcon(context, Icons.person_rounded,
            AppColors.primary, 'Profile', const ProfileScreen()),
      ],
    );
  }

  Widget _proTopIcon(BuildContext context, IconData icon, Color color,
      String label, Widget page) {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: InkWell(
        onTap: () => _proPush(context, page),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 9)),
          ],
        ),
      ),
    );
  }

  /// Pro wallet bar: balance + orange Withdraw button (kit "Shop Now").
  Widget _proWalletBar(
      BuildContext context, UserModel? user, int remainingSpins) {
    final coins = user?.coins ?? 0;
    final rupees = (coins / 10).toStringAsFixed(2);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF17171F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(Icons.monetization_on_rounded,
              color: AppColors.gold, size: 28),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$coins',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                Text('≈ ₹$rupees • $remainingSpins spins left',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _proPush(context, const WithdrawScreen()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Withdraw',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  /// Winner ticker (kit): horizontal pills of recent earners.
  Widget _proTicker() {
    const winners = [
      ['Aarav', '+250'],
      ['Priya', '+120'],
      ['Rohan', '+500'],
      ['Sneha', '+80'],
      ['Amit', '+1000'],
      ['Neha', '+60'],
    ];
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: winners.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF17171F),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                const Icon(Icons.person_rounded,
                    size: 14, color: AppColors.gold),
                const SizedBox(width: 4),
                Text(winners[i][0],
                    style:
                        const TextStyle(color: Colors.white, fontSize: 12)),
                const SizedBox(width: 6),
                Text(winners[i][1],
                    style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Own promo cards (NOT copy): Lucky Spin / Invite & Earn / Top Earners.
  Widget _proPromoRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _proPromoCard(
            context,
            'Lucky Spin',
            '2 FREE DAILY',
            Icons.casino_rounded,
            const [Color(0xFFF66B06), Color(0xFFB34700)],
            badge: 'FREE',
            onTap: () => _proPush(context, const SpinScreen()),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _proPromoCard(
            context,
            'Invite & Earn',
            'BONUS COINS',
            Icons.group_add_rounded,
            const [Color(0xFFF59E0B), Color(0xFFB45309)],
            onTap: () => _proPush(context, const ReferScreen()),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _proPromoCard(
            context,
            'Top Earners',
            'WEEKLY RANKS',
            Icons.emoji_events_rounded,
            const [Color(0xFF10B981), Color(0xFF047857)],
            onTap: () =>
                _proPush(context, const LeaderboardScreen()),
          ),
        ),
      ],
    );
  }

  Widget _proPromoCard(BuildContext context, String title, String sub,
      IconData icon, List<Color> gradient,
      {String? badge, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 128,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(icon, color: Colors.white.withOpacity(0.85), size: 26),
                const SizedBox(height: 6),
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14)),
                Text(sub,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8), fontSize: 9)),
              ],
            ),
            if (badge != null)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(badge,
                      style: const TextStyle(
                          color: Color(0xFFB71C1C),
                          fontSize: 9,
                          fontWeight: FontWeight.w800)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _proSectionTitle(String title,
      {String? action, VoidCallback? onAction}) {
    return Row(
      children: [
        const Icon(Icons.grid_view_rounded,
            size: 14, color: Colors.white54),
        const SizedBox(width: 6),
        Text(title,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1)),
        const Spacer(),
        if (action != null)
          InkWell(
            onTap: onAction,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF17171F),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Text(action,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 11)),
            ),
          ),
      ],
    );
  }

  /// Featured surveys: horizontal coin cards (kit).
  Widget _proSurveyRow(BuildContext context) {
    const cards = [
      ['1050', '1.3k earned'],
      ['1233', '2.4k earned'],
      ['1050', '787 earned'],
    ];
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          return InkWell(
            onTap: () => _proPush(context, const EarnScreen()),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 108,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF17171F),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.gold.withOpacity(0.4)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('EARN',
                      style: TextStyle(
                          color: Colors.white54, fontSize: 9)),
                  Text(cards[i][0],
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                  const Text('COINS',
                      style: TextStyle(
                          color: Colors.white54, fontSize: 9)),
                  const SizedBox(height: 2),
                  Text(cards[i][1],
                      style: const TextStyle(
                          color: AppColors.gold, fontSize: 10)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Tasks of the day (kit rows with brand tiles).
  Widget _proTasksList(BuildContext context) {
    const tasks = [
      ['Install Game & Play', 'Reach level 5 • 500 coins', 'PubScale'],
      ['Shopping Survey', '10 min • 150 coins', 'Cint'],
      ['Daily Check-in', 'Streak bonus • 25 coins', 'TimeWall'],
    ];
    return Column(
      children: tasks.map((t) {
        final provider = t[2];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: () => _proPush(context, const EarnScreen()),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF17171F),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  ProviderLogo(provider, size: 46),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t[0],
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                        Text(t[1],
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 11)),
                        Text(provider,
                            style: TextStyle(
                                color: ProviderLogos.colorFor(
                                    provider),
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: Colors.white38),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// All earning providers on Home (horizontal scroll, real logos).
  Widget _proProvidersRow(BuildContext context) {
    const providers = [
      'Cint',
      'Prime Surveys',
      'TimeWall',
      'BitLabs',
      'CPX Research',
      'Pollfish',
      'PubScale',
      'OfferPro',
      'GrowDeck',
      'CPI Droid',
    ];
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: providers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final name = providers[i];
          final color = ProviderLogos.colorFor(name);
          return InkWell(
            onTap: () => _proPush(context, const EarnScreen()),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 96,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF17171F),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: color.withOpacity(0.45)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ProviderLogo(name, size: 40, radius: 20),
                  const SizedBox(height: 6),
                  Text(name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Mega Task banner + bottom sheet (kit "Limited Time / Swipe Up").
  Widget _proMegaBanner(BuildContext context) {
    return InkWell(
      onTap: () => _proMegaSheet(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF66B06), Color(0xFFB34700)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gold.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('LIMITED',
                      style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w800)),
                ),
                const Icon(Icons.bolt_rounded,
                    color: AppColors.gold, size: 22),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('TIME',
                      style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text('MEGA TASK',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1)),
            const Text('— TASK OF THE DAY —',
                style: TextStyle(color: Colors.white70, fontSize: 11)),
            const SizedBox(height: 6),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('SWIPE UP',
                    style: TextStyle(
                        color: Color(0xFFFF8A80),
                        fontWeight: FontWeight.w800,
                        fontSize: 13)),
                Icon(Icons.keyboard_double_arrow_up_rounded,
                    color: Color(0xFFFF8A80), size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _proMegaSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF17171F),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Colors.white10)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/app_icon_name.png',
                height: 110,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Mega Task of the Day',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text(
              'Spin the wheel now — every spin today counts double luck!',
              style: TextStyle(color: Colors.white60, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _proPush(context, const SpinScreen());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Spin Now',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Kit balance card: total coins + rupee value + withdraw button.
  Widget _buildBalanceCard(BuildContext context, UserModel? user) {
    final coins = user?.coins ?? 0;
    final rupees = (coins / 10).toStringAsFixed(2);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Balance',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$coins',
                  style: AppTextStyles.displayLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '≈ ₹$rupees',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Image.asset(
              'assets/app_icon_name.png',
              width: 84,
              height: 84,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.account_balance_wallet_rounded,
                size: 60,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Kit category row: Spin / Scratch / Surveys / Wallet.
  Widget _buildCategories(BuildContext context) {
    final items = [
      {
        'label': 'Spin',
        'icon': Icons.casino_rounded,
        'color': AppColors.primary,
        'onTap': () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const SpinScreen())),
      },
      {
        'label': 'Scratch',
        'icon': Icons.card_giftcard_rounded,
        'color': const Color(0xFF8B5CF6),
        'onTap': () => _showScratchDialog(context),
      },
      {
        'label': 'Surveys',
        'icon': Icons.assignment_rounded,
        'color': const Color(0xFF3B82F6),
        'onTap': () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const EarnScreen())),
      },
      {
        'label': 'Wallet',
        'icon': Icons.account_balance_wallet_rounded,
        'color': AppColors.success,
        'onTap': () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const WithdrawScreen())),
      },
      {
        'label': 'Board',
        'icon': Icons.emoji_events_rounded,
        'color': AppColors.gold,
        'onTap': () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
      },
      {
        'label': 'Refer',
        'icon': Icons.group_add_rounded,
        'color': const Color(0xFFEC4899),
        'onTap': () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ReferScreen())),
      },
      {
        'label': 'History',
        'icon': Icons.history_rounded,
        'color': const Color(0xFF14B8A6),
        'onTap': () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const HistoryScreen())),
      },
      {
        'label': 'Notices',
        'icon': Icons.notifications_rounded,
        'color': const Color(0xFFF43F5E),
        'onTap': () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen())),
      },
    ];
    return Wrap(
      alignment: WrapAlignment.spaceEvenly,
      spacing: 2,
      runSpacing: 8,
      children: items.map((item) {
        final color = item['color'] as Color;
        return InkWell(
          onTap: item['onTap'] as VoidCallback,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Icon(item['icon'] as IconData, color: color, size: 28),
                ),
                const SizedBox(height: 6),
                Text(
                  item['label'] as String,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Scratch teaser (kit): reveals today's luck, leads to Spin Wheel.
  /// No coins granted here - rewards only come from the server.
  void _showScratchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Image.asset(
                  'assets/app_icon_name.png',
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.card_giftcard_rounded,
                    size: 80,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Today\'s Luck Card', style: AppTextStyles.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Feeling lucky? Your spins are waiting on the wheel.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SpinScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                  ),
                  child: const Text('Go to Spin Wheel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel? user, int remainingSpins) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppRadius.xxl)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    backgroundImage: user?.photoUrl != null
                        ? NetworkImage(user!.photoUrl!)
                        : const AssetImage('assets/app_icon_name.png')
                            as ImageProvider,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi, ${user?.displayName?.split(' ').first ?? 'User'}!',
                          style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
                        ),
                        Text(
                          'Balance: ${user?.coins ?? 0} coins',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Coins display
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.monetization_on_rounded, color: AppColors.gold, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          '${user?.coins ?? 0}',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // Spins indicator
              if (remainingSpins > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.casino_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '$remainingSpins free spin${remainingSpins > 1 ? 's' : ''} left today',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    'No spins left today',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(UserModel? user) {
    final coins = user?.coins ?? 0;
    final rupees = (coins / 10).toStringAsFixed(1);

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Total Coins',
            value: '$coins',
            icon: Icons.monetization_on_rounded,
            color: AppColors.gold,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatCard(
            title: 'Value (₹)',
            value: rupees,
            icon: Icons.currency_rupee_rounded,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildSpinCard(BuildContext context, int remainingSpins) {
    return GestureDetector(
      onTap: remainingSpins > 0 
          ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SpinScreen()))
          : null,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: remainingSpins > 0 ? AppColors.goldGradient : null,
          color: remainingSpins > 0 ? null : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: remainingSpins > 0 ? AppShadows.elevated : null,
          border: remainingSpins > 0 ? null : Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: remainingSpins > 0 
                    ? Colors.white.withOpacity(0.2) 
                    : AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.casino_rounded,
                size: 36,
                color: remainingSpins > 0 ? AppColors.gold : AppColors.textTertiary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Spin Wheel',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: remainingSpins > 0 ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    remainingSpins > 0
                        ? 'Tap to spin! Win 10, 2, or 3 coins'
                        : 'Come back tomorrow for 2 free spins',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: remainingSpins > 0 
                          ? Colors.white.withOpacity(0.9) 
                          : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (remainingSpins > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  'SPIN',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurveyOffers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Survey Bonus Offers', style: AppTextStyles.titleMedium),
            Text('View All', style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            )),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final offers = [
                {'title': 'Quick Survey', 'coins': 50, 'time': '5 min', 'color': AppColors.primary},
                {'title': 'Product Review', 'coins': 75, 'time': '8 min', 'color': AppColors.success},
                {'title': 'Brand Feedback', 'coins': 100, 'time': '10 min', 'color': AppColors.warning},
                {'title': 'Market Research', 'coins': 150, 'time': '15 min', 'color': AppColors.error},
              ];
              final o = offers[index];
              return Container(
                width: 180,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.divider),
                  boxShadow: AppShadows.card,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (o['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        o['time'] as String,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: o['color'] as Color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      o['title'] as String,
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        const Icon(Icons.monetization_on_rounded, size: 16, color: AppColors.gold),
                        const SizedBox(width: 4),
                        Text(
                          '+${o['coins']} coins',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text('Start'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.1,
          children: [
            _ActionCard(
              icon: Icons.credit_card_rounded,
              title: 'Scratch Cards',
              subtitle: 'Instant rewards',
              color: AppColors.primary,
              onTap: () {},
            ),
            _ActionCard(
              icon: Icons.check_circle_rounded,
              title: 'Daily Check-in',
              subtitle: 'Login bonus',
              color: AppColors.success,
              onTap: () {},
            ),
            _ActionCard(
              icon: Icons.leaderboard_rounded,
              title: 'Leaderboard',
              subtitle: 'Top earners',
              color: AppColors.warning,
              onTap: () {},
            ),
            _ActionCard(
              icon: Icons.share_rounded,
              title: 'Refer & Earn',
              subtitle: 'Invite friends',
              color: AppColors.error,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.divider),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const Spacer(),
            ],
          ),
          const Spacer(),
          Text(value, style: AppTextStyles.headlineLarge.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(title, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.divider),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const Spacer(),
            Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(subtitle, style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }
}