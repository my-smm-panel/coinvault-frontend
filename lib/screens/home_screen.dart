import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_theme.dart';
import '../services/auth_service.dart';
import '../models/app_models.dart';
import 'earn_screen.dart';
import 'spin_screen.dart';
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
      const SpinScreen(),
      const WithdrawScreen(),
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
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Withdraw',
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
                  Icon(
                    icon,
                    size: 24,
                    color: isActive ? AppColors.primary : AppColors.textTertiary,
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
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar / Header
          SliverAppBar(
            automaticallyImplyLeading: false,
            pinned: false,
            floating: true,
            backgroundColor: AppColors.background,
            expandedHeight: 180,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(context, user, remainingSpins),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Kit balance card + categories
                _buildBalanceCard(context, user),
                const SizedBox(height: AppSpacing.lg),
                _buildCategories(context),
                const SizedBox(height: AppSpacing.lg),
                // Quick Stats
                _buildStatsRow(user),
                const SizedBox(height: AppSpacing.lg),
                
                // Spin Wheel Card
                _buildSpinCard(context, remainingSpins),
                const SizedBox(height: AppSpacing.lg),
                
                // Survey Bonus Offers
                _buildSurveyOffers(),
                const SizedBox(height: AppSpacing.lg),
                
                // Quick Actions
                _buildQuickActions(context),
                const SizedBox(height: AppSpacing.xl),
              ]),
            ),
          ),
        ],
          ),
        );
      },
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