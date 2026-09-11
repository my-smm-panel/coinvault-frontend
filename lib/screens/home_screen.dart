import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/provider_logos.dart';
import '../services/auth_service.dart';
import '../services/app_repository.dart';
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
      const LeaderboardScreen(),
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
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _currentIndex = 2),
                    borderRadius: BorderRadius.circular(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          margin:
                              const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: _currentIndex == 2
                                    ? AppColors.gold
                                    : AppColors.primary,
                                width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary
                                    .withOpacity(0.5),
                                blurRadius: 14,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/app_icon.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(
                                      Icons
                                          .emoji_events_rounded,
                                      color: AppColors.gold,
                                      size: 28),
                            ),
                          ),
                        ),
                        Text(
                          'Ranks',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _currentIndex == 2
                                ? AppColors.gold
                                : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
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

/// Home Tab - Main dashboard.
/// Surveys + tasks come from the REAL backend (GET /api/surveys, /api/offers).
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<dynamic> _surveys = [];
  List<dynamic> _tasks = [];
  List<dynamic> _topEarners = [];
  bool _loadingHome = true;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
    _loadTopEarners();
  }

  Future<void> _loadTopEarners() async {
    final data =
        await AppRepository.instance.fetchLeaderboard('WEEKLY');
    final top = data['top'];
    if (!mounted) return;
    if (top is List && top.isNotEmpty) {
      setState(() => _topEarners = top.take(3).toList());
    }
  }

  Future<void> _loadHomeData() async {
    final repo = AppRepository.instance;
    final results = await Future.wait([
      repo.fetchSurveys(),
      repo.fetchOffers(),
    ]);
    if (!mounted) return;
    setState(() {
      _surveys = results[0] ?? [];
      // Tasks row = install-type offers from the real backend,
      // mapped to the shape the task cards expect.
      _tasks = (results[1] ?? [])
          .where((o) => ((o as Map)['type'] ?? '').toString().startsWith('INSTALL'))
          .take(6)
          .map((o) {
        final m = o as Map;
        return <String, dynamic>{
          'title': (m['title'] ?? '').toString(),
          'sub': (m['shortDesc'] ?? '').toString(),
          'coins': ((m['coins'] ?? 0) as num).toInt(),
          'provider':
              _categoryLabel((m['category'] ?? 'OTHER').toString()),
          'steps': ((m['instructions'] ?? []) as List)
              .map((e) => e.toString())
              .toList(),
        };
      }).toList();
      _loadingHome = false;
    });
  }

  static String _categoryLabel(String c) {
    switch (c) {
      case 'GAME':
        return 'Games';
      case 'APP':
        return 'Apps';
      case 'FINANCE':
        return 'Finance';
      case 'SHOPPING':
        return 'Shopping';
      case 'ENTERTAINMENT':
        return 'Fun';
      case 'SURVEY':
        return 'Surveys';
      default:
        return 'Tasks';
    }
  }

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
              const SizedBox(height: 14),
              // Wallet hero: own orange card with coins + ₹ value + withdraw
              _buildBalanceCard(context, user),
              const SizedBox(height: 16),
              // Daily bonus strip
              _dailyBonusBanner(context),
              const SizedBox(height: 16),
              // Promo trio (compact — Lucky/Invite/Top Earners)
              _proPromoRow(context),
              const SizedBox(height: 18),
              // Featured Surveys — comes right after promos
              _proSectionTitle('FEATURED SURVEYS',
                  action: 'See more',
                  onAction: () => _proPush(
                      context, const SurveysScreen())),
              const SizedBox(height: 10),
              _loadingHome
                  ? _skeletonHorizontal()
                  : _proSurveyRow(context),
              const SizedBox(height: 18),
              _proSectionTitle('TASKS OF THE DAY',
                  action: 'See more',
                  onAction: () => _proPush(
                      context, const EarnScreen())),
              const SizedBox(height: 10),
              _loadingHome
                  ? _skeletonHorizontal()
                  : _proTasksList(context),
              const SizedBox(height: 18),
              // Top earners preview (real leaderboard data)
              _proSectionTitle('TOP EARNERS',
                  action: 'Ranks',
                  onAction: () => _proPush(
                      context, const LeaderboardScreen())),
              const SizedBox(height: 10),
              _loadingHome
                  ? _skeletonList()
                  : _proTopEarners(context),
              const SizedBox(height: 18),
              // Play & Earn — compact, tucked lower on the page
              _proSectionTitle('PLAY & EARN'),
              const SizedBox(height: 10),
              _proQuickPlay(context, remainingSpins),
              const SizedBox(height: 18),
              _proMegaBanner(context),
              const SizedBox(height: 18),
              // How to earn — fills the page, own style
              _howToEarn(context),
              const SizedBox(height: 20),
              // Small footer so the page feels finished, not clipped
              Center(
                child: Text(
                  'CoinVault • Earn coins daily',
                  style: TextStyle(
                      color: Colors.white24, fontSize: 11),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
        );
      },
    );
  }

  /// Skeleton: horizontal cards (surveys / tasks placeholder).
  Widget _skeletonHorizontal() {
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, __) => Container(
          width: 150,
          decoration: BoxDecoration(
            color: const Color(0xFF17171F),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _skeletonBox(36, 36, radius: 10),
                const Spacer(),
                _skeletonBox(70, 14),
                const SizedBox(height: 8),
                _skeletonBox(100, 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Skeleton: list rows (top earners placeholder).
  Widget _skeletonList() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF17171F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: List.generate(3, (i) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            children: [
              _skeletonBox(28, 28, radius: 14),
              const SizedBox(width: 10),
              _skeletonBox(28, 28, radius: 14),
              const SizedBox(width: 10),
              _skeletonBox(120, 12),
              const Spacer(),
              _skeletonBox(50, 12),
            ],
          ),
        )),
      ),
    );
  }

  /// Single gray shimmer block.
  Widget _skeletonBox(double w, double h,
      {double radius = 6}) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  void _proPush(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  /// Pro top bar: bear logo + CoinVault + wallet pill (tap = Withdraw) + icons.
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
        InkWell(
          onTap: () => _proPush(context, const WithdrawScreen()),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.primary.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on_rounded,
                    color: AppColors.gold, size: 16),
                const SizedBox(width: 4),
                Text('${user?.coins ?? 0}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Own bell: soft orange bubble, unread dot, NO text label
        // (killed the ProRewards-style labeled icon circles).
        InkWell(
          onTap: () => _proPush(context, const NotificationsScreen()),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.14),
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.primary.withOpacity(0.35)),
            ),
            child: const Icon(Icons.notifications_none_rounded,
                color: AppColors.primaryLight, size: 21),
          ),
        ),
      ],
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


  /// Own promo cards (NOT copy): Lucky Spin / Invite & Earn / Top Earners.
  Widget _proPromoRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _proPromoCard(
            context,
            'Lucky Spin',
            '2 FREE DAILY',
            Icons.donut_large_rounded,
            const [Color(0xFFF66B06), Color(0xFFB34700)],
            badge: 'FREE',
            image: 'assets/wheel.png',
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
            image: 'assets/app_icon.jpg',
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
      {String? badge, String? image, required VoidCallback onTap}) {
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
                if (image != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(image,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                            icon,
                            color:
                                Colors.white.withOpacity(0.85),
                            size: 26)),
                  )
                else
                  Icon(icon,
                      color: Colors.white.withOpacity(0.85),
                      size: 26),
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

  /// Daily bonus strip: login bonus claim + next reset.
  Widget _dailyBonusBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.gold.withOpacity(0.18), const Color(0xFF17171F)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_fire_department_rounded,
                color: AppColors.gold, size: 20),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily Bonus',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800)),
                Text('Log in daily, get free coins!',
                    style: TextStyle(color: Colors.white54, fontSize: 10)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('CLAIM',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }

  /// How to earn — 3 simple steps card (own, fills the page).
  Widget _howToEarn(BuildContext context) {
    final steps = [
      ('Do Tasks', Icons.task_alt_rounded,
          'Complete app installs & surveys'),
      ('Spin Daily', Icons.donut_large_rounded,
          '2 free spins every day, win coins'),
      ('Withdraw', Icons.currency_rupee_rounded,
          '100 coins = ₹10 via UPI/Bank'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF17171F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('HOW TO EARN',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1)),
          const SizedBox(height: 12),
          ...steps.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(s.$2, color: AppColors.primary, size: 17),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.$1,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                          Text(s.$3,
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  /// Top earners preview — 3 rows with rank + name + coins.
  /// Real data from GET /api/leaderboard/WEEKLY.
  Widget _proTopEarners(BuildContext context) {
    final earners = _topEarners;
    if (earners.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF17171F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: const Row(
          children: [
            Icon(Icons.emoji_events_rounded,
                color: AppColors.gold, size: 20),
            SizedBox(width: 10),
            Text('Rankings update — complete tasks to climb!',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF17171F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: List.generate(earners.length, (i) {
          final m = earners[i] as Map;
          final u = m['user'];
          String name = 'User';
          if (u is Map) {
            final n = (u['name'] ?? '').toString();
            name = n.isNotEmpty ? n : 'User';
          }
          final coins = ((m['coins'] ?? 0) as num).toInt();
          final rankColors = [
            AppColors.gold,
            const Color(0xFFB0B0B0),
            const Color(0xFFB45309),
          ];
          final rc = rankColors[i % rankColors.length];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: rc.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('${i + 1}',
                        style: TextStyle(
                            color: rc,
                            fontWeight: FontWeight.w800,
                            fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.white10,
                  backgroundImage: (u is Map &&
                          u['photoUrl'] != null &&
                          (u['photoUrl'] as String).isNotEmpty)
                      ? NetworkImage(u['photoUrl'] as String)
                      : null,
                  child: (u is Map &&
                          u['photoUrl'] != null &&
                          (u['photoUrl'] as String).isNotEmpty)
                      ? null
                      : const Icon(Icons.person_rounded,
                          color: Colors.white38, size: 15),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
                const Icon(Icons.monetization_on_rounded,
                    color: AppColors.gold, size: 14),
                const SizedBox(width: 3),
                Text('$coins',
                    style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 13,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          );
        }),
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

  /// Featured Surveys - own style: provider logo cards with coins.
  /// Data comes from the live backend (GET /api/surveys).
  Widget _proSurveyRow(BuildContext context) {
    final cards = _surveys.take(5).map((s) {
      final m = s as Map;
      return [
        (m['provider'] ?? 'Survey').toString(),
        ((m['coins'] ?? 0) as num).toInt(),
        (m['duration'] ?? '').toString(),
      ];
    }).toList();
    if (cards.isEmpty) {
      return Container(
        height: 132,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF17171F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: const Text('New surveys coming soon',
            style: TextStyle(color: Colors.white38, fontSize: 13)),
      );
    }
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final provider = cards[i][0] as String;
          final coins = cards[i][1] as int;
          final time = cards[i][2] as String;
          final color = ProviderLogos.colorFor(provider);
          return InkWell(
            onTap: () => _proPush(
                context,
                SurveysScreen(initialProvider: provider)),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 150,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF17171F),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: color.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      ProviderLogo(provider,
                          size: 38, radius: 10),
                      const Spacer(),
                      const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white38,
                          size: 20),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                          Icons.monetization_on_rounded,
                          color: AppColors.gold,
                          size: 15),
                      const SizedBox(width: 3),
                      Text('$coins coins',
                          style: const TextStyle(
                              color: AppColors.gold,
                              fontSize: 15,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                  Text('$provider • $time',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Tasks of the day: rich app-install / game-play cards
  /// with provider logo, direct tap = full steps.
  Widget _proTasksList(BuildContext context) {
    final tasks = _tasks;
    return SizedBox(
      height: 148,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tasks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final t = tasks[i];
          final provider = t['provider'] as String;
          final color = ProviderLogos.colorFor(provider);
          return InkWell(
            onTap: () => _showHomeTaskDetail(context, t, color),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 168,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF17171F),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.45)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ProviderLogo(provider, size: 40),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: AppColors.goldGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                            '+${t['coins']}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(t['title'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                  Text(t['sub'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11)),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.verified_rounded,
                          color: AppColors.gold, size: 12),
                      const SizedBox(width: 3),
                      Text(provider,
                          style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  void _showHomeTaskDetail(
      BuildContext context, Map<String, dynamic> t, Color color) {
    final provider = t['provider'] as String;
    final steps = (t['steps'] as List).cast<String>();
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ProviderLogo(provider, size: 56),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t['title'] as String,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800)),
                      Text(provider,
                          style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('+${t['coins']} coins',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text('How to earn',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...steps.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text('${e.key + 1}',
                              style: TextStyle(
                                  color: color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(e.value,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Task started! Complete steps to earn coins.')));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Start Task',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// QUICK PLAY: compact tiles with real asset images (own style).
  Widget _proQuickPlay(BuildContext context, int remainingSpins) {
    final tiles = [
      {
        'label': 'Spin',
        'sub': '$remainingSpins left',
        'image': 'assets/wheel.png',
        'color': AppColors.primary,
        'onTap': () => _proPush(context, const SpinScreen()),
      },
      {
        'label': 'Scratch',
        'sub': 'Win coins',
        'image': 'assets/scratch.png',
        'color': AppColors.gold,
        'onTap': () => _showScratchDialog(context),
      },
      {
        'label': 'Challenges',
        'sub': 'Bonus',
        'image': 'assets/trophy.png',
        'color': const Color(0xFF10B981),
        'onTap': () => _showChallenges(context, remainingSpins),
      },
      {
        'label': 'Refer',
        'sub': 'Invite',
        'image': 'assets/app_icon.jpg',
        'color': const Color(0xFF3B82F6),
        'onTap': () => _proPush(context, const ReferScreen()),
      },
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF17171F),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: tiles.map((t) {
          final color = t['color'] as Color;
          return Expanded(
            child: InkWell(
              onTap: t['onTap'] as VoidCallback,
              borderRadius: BorderRadius.circular(14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: color.withOpacity(0.3)),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        t['image'] as String,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                            Icons.star_rounded,
                            color: color,
                            size: 22),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(t['label'] as String,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                  Text(t['sub'] as String,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 9)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Daily challenges sheet with live spin progress.
  void _showChallenges(BuildContext context, int remainingSpins) {
    final used = (2 - remainingSpins).clamp(0, 2);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF17171F),
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24)),
          border:
              Border(top: BorderSide(color: Colors.white10)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Today's Challenges",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Complete goals, earn bonus coins',
                style: TextStyle(
                    color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 12),
            _challengeRow(
                context,
                'Spin the wheel 2 times',
                '$used/2 done',
                used / 2,
                '+20 coins',
                () => _proPush(context, const SpinScreen())),
            _challengeRow(
                context,
                'Complete 3 tasks',
                'Earn Screen',
                0,
                '+50 coins',
                () => _proPush(context, const EarnScreen())),
            _challengeRow(
                context,
                'Invite 1 friend',
                'Refer & Earn',
                0,
                '+100 coins',
                () => _proPush(context, const ReferScreen())),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _challengeRow(
      BuildContext context,
      String title,
      String sub,
      double progress,
      String reward,
      VoidCallback onTap) {
    final done = progress >= 1;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0B0B12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: done
                  ? const Color(0xFF10B981).withOpacity(0.5)
                  : Colors.white10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  Text('$sub • $reward',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: Colors.white10,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(
                              Color(0xFF10B981)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onTap();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: done
                    ? const Color(0xFF10B981)
                    : AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(done ? 'Done' : 'Go',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800)),
            ),
          ],
        ),
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
        'icon': Icons.donut_large_rounded,
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

  /// Real scratch card: finger-erase to reveal (no coins minted here -
  /// rewards only come from the server spin wheel).
  void _showScratchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF17171F),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: AppColors.gold.withOpacity(0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Scratch Card',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Scratch with your finger!',
                  style: TextStyle(
                      color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 14),
              const _ScratchCard(),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SpinScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadius.full),
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
                      const Icon(Icons.donut_large_rounded, color: Colors.white, size: 16),
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
                Icons.donut_large_rounded,
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
/// True scratch-off card: drag finger to erase the gold cover
/// and reveal the luck message underneath.
/// True scratch-off card (finger erase).
class _ScratchCard extends StatefulWidget {
  const _ScratchCard();

  @override
  State<_ScratchCard> createState() => _ScratchCardState();
}

class _ScratchCardState extends State<_ScratchCard> {
  final List<Offset> _points = [];
  bool _revealed = false;

  void _onPan(DragUpdateDetails d, BuildContext ctx) {
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;
    final p = box.globalToLocal(d.globalPosition);
    setState(() {
      _points.add(p);
      if (_points.length > 140) _revealed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (ctx) {
      return GestureDetector(
        onPanUpdate: (d) => _onPan(d, ctx),
        onPanEnd: (_) {
          if (_points.length > 60) {
            setState(() => _revealed = true);
          }
        },
        child: Container(
          width: double.infinity,
          height: 170,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.gold.withOpacity(0.5)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Prize underneath
                Container(
                  color: const Color(0xFF0B0B12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/coin.png',
                          width: 52,
                          height: 52,
                          errorBuilder: (_, __, ___) =>
                              const Icon(
                                  Icons.monetization_on_rounded,
                                  color: AppColors.gold,
                                  size: 44)),
                      const SizedBox(height: 6),
                      const Text("YOU'RE LUCKY!",
                          style: TextStyle(
                              color: AppColors.gold,
                              fontSize: 20,
                              fontWeight: FontWeight.w900)),
                      const Text('Spin the wheel to claim',
                          style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12)),
                    ],
                  ),
                ),
                // Scratch cover
                if (!_revealed)
                  CustomPaint(
                    painter: _ScratchCoverPainter(_points),
                    child: Container(),
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _ScratchCoverPainter extends CustomPainter {
  final List<Offset> points;
  _ScratchCoverPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint());
    // gold cover
    final cover = Paint()..color = const Color(0xFFC98A1B);
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), cover);
    // diagonal shine lines
    final shine = Paint()
      ..color = const Color(0xFFE8B93E)
      ..strokeWidth = 10;
    for (var i = -size.height;
        i < size.width + size.height;
        i += 34) {
      canvas.drawLine(Offset(i.toDouble(), 0),
          Offset(i + size.height, size.height), shine);
    }
    // erase where finger passed
    final clear = Paint()..blendMode = BlendMode.clear;
    for (final p in points) {
      canvas.drawCircle(p, 22, clear);
    }
    canvas.restore();
    // hint text on cover
    if (points.isEmpty) {
      final tp = TextPainter(
        text: const TextSpan(
            text: 'SCRATCH HERE',
            style: TextStyle(
                color: Color(0xFF7A4d00),
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 2)),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(
          canvas,
          Offset((size.width - tp.width) / 2,
              (size.height - tp.height) / 2));
    }
  }

  @override
  bool shouldRepaint(_ScratchCoverPainter old) => true;
}
