import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_theme.dart';
import '../services/app_repository.dart';
import '../services/auth_service.dart';
import '../widgets/cv_header.dart';
import '../widgets/home_banner_carousel.dart';
import 'earn_screen.dart';
import 'task_detail_screen.dart';
import '../widgets/app_logo.dart';
import 'invite_screen.dart';
import 'leaderboard_screen.dart';
import 'missions_screen.dart';
import 'quiz_screen.dart';
import 'scratch_screen.dart';
import 'spin_screen.dart';
import 'surveys_screen.dart';
import 'tracking_screen.dart';
import 'withdraw_screen.dart';

/// Home — content-rich CoinVault rewards home (light premium design).
///
/// Global header → promo carousel → balance summary → today's earnings →
/// featured surveys → tasks of the day → offer of the day → quick earn →
/// recommended → high-paying tasks → daily spin → daily missions →
/// invite & earn → limited-time offers → top earners → how to earn.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeTab(),
    const EarnScreen(),
    const LeaderboardScreen(),
    const SurveysScreen(),
  ];

  void _pushScreen(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
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
                          width: 52,
                          height: 52,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.goldContainer,
                            border: Border.all(
                                color: _currentIndex == 2 ? AppColors.gold : AppColors.border,
                                width: 2.5),
                            boxShadow: _currentIndex == 2
                                ? [BoxShadow(color: AppColors.gold.withOpacity(0.28), blurRadius: 12)]
                                : null,
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/app_icon.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                  Icons.emoji_events_rounded, color: AppColors.gold, size: 26),
                            ),
                          ),
                        ),
                        Text(
                          'Ranks',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _currentIndex == 2 ? AppColors.gold : AppColors.textTertiary,
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
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Withdraw',
                  isActive: false,
                  onTap: () => _pushScreen(const WithdrawScreen()),
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primaryContainer : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Icon(
                      icon,
                      size: 24,
                      color: isActive ? AppColors.primary : AppColors.textTertiary,
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

/// Content-rich light-theme home dashboard (design sheet):
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<dynamic> _surveys = [];
  List<dynamic> _tasks = [];
  List<dynamic> _offers = [];
  List<dynamic> _activity = [];
  Map<String, dynamic> _leaderboard = {};
  bool _loadingHome = true;
  int _spinsUsedToday = 0; // server-authoritative; set in _loadHomeData

  static const int _dailyGoal = 500;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
    _loadActivity();
    _loadLeaderboard();
  }

  Future<void> _loadHomeData() async {
    final repo = AppRepository.instance;
    final results = await Future.wait<dynamic>([
      repo.fetchSurveys(),
      repo.fetchOffers(),
      repo.spinsRemainingToday(), // 2 — server-authoritative spin count
    ]);
    if (!mounted) return;
    setState(() {
      _surveys = (results[0] as List<dynamic>?) ?? [];
      final allOffers =
          ((results[1] as List<dynamic>?) ?? []).cast<Map>();
      _offers = allOffers;
      _tasks = allOffers
          .where((o) => ((o['type'] ?? '').toString().startsWith('INSTALL')))
          .take(6)
          .map((m) => <String, dynamic>{
                'title': (m['title'] ?? '').toString(),
                'sub': (m['shortDesc'] ?? '').toString(),
                'coins': ((m['coins'] ?? 0) as num).toInt(),
                'provider': _categoryLabel((m['category'] ?? 'OTHER').toString()),
                'steps': ((m['instructions'] ?? []) as List)
                    .map((e) => e.toString())
                    .toList(),
              })
          .toList();
      // Spins used today (server truth) — clamped 0..2.
      final remaining = results[2] as int?;
      _spinsUsedToday =
          remaining == null ? 0 : (2 - remaining).clamp(0, 2);
      _loadingHome = false;
    });
  }

  Future<void> _loadActivity() async {
    try {
      final list = await AppRepository.instance.fetchActivity();
      if (!mounted) return;
      final now = DateTime.now();
      int earned = 0;
      for (final raw in list) {
        final m = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
        final coins = (m['coins'] as num?)?.toInt() ?? 0;
        if (coins <= 0) continue;
        final ts = m['timestamp'] ?? m['createdAt'] ?? m['date'];
        DateTime? dt;
        if (ts is num) {
          dt = DateTime.fromMillisecondsSinceEpoch(
              ts > 1e12 ? ts.toInt() : (ts.toInt() * 1000));
        } else if (ts is String) {
          dt = DateTime.tryParse(ts);
        }
        if (dt == null || now.difference(dt).inHours < 24) {
          earned += coins;
        }
      }
      setState(() => _activity = [
            {'earned': earned},
          ]);
    } catch (_) {
      if (mounted) setState(() => _activity = []);
    }
  }

  Future<void> _loadLeaderboard() async {
    try {
      final lb = await AppRepository.instance.fetchLeaderboard('weekly');
      if (mounted) setState(() => _leaderboard = lb);
    } catch (_) {}
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

  void _push(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  String _fmt(int n) {
    final str = n.abs().toString();
    final sb = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        sb.write(',');
      }
      sb.write(str[i]);
    }
    return n.isNegative ? '-$sb' : sb.toString();
  }

  int _todayEarned() {
    if (_activity.isEmpty) return 0;
    return ((_activity.first as Map)['earned'] as num?)?.toInt() ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService(),
      builder: (context, _) {
        final auth = AuthService();
        final user = auth.userModel;
        final coins = user?.coins ?? 0;

        return Scaffold(
          backgroundColor: AppColors.surface,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CvHeader(
                    showProfile: true,
                    profileLeft: true,
                    showMoney: true,
                    coins: coins,
                    showWordmark: false,
                  ),
                  const SizedBox(height: 12),
                  _promoCarousel(context),
                  const SizedBox(height: 18),
                  _balanceSummary(context, coins),
                  const SizedBox(height: 18),
                  _todayEarningsCard(context),
                  const SizedBox(height: 20),
                  _sectionTitle('Tasks of the Day',
                      action: 'View All',
                      onAction: () => _push(context, const EarnScreen())),
                  const SizedBox(height: 10),
                  _loadingHome ? _skeletonH() : _tasksRow(context),
                  const SizedBox(height: 20),
                  _sectionTitle('Featured Surveys',
                      action: 'View All',
                      onAction: () => _push(context, const SurveysScreen())),
                  const SizedBox(height: 10),
                  _loadingHome ? _skeletonH() : _surveyRow(context),
                  const SizedBox(height: 20),
                  _sectionTitle('Quick Earn'),
                  const SizedBox(height: 10),
                  _quickEarn(context),
                  const SizedBox(height: 20),
                  _sectionTitle('High-Paying Tasks',
                      action: 'View All',
                      onAction: () => _push(context, const EarnScreen())),
                  const SizedBox(height: 10),
                  _highPayingList(context),
                  const SizedBox(height: 20),
                  _sectionTitle('Limited-Time Offers'),
                  const SizedBox(height: 10),
                  _limitedOffers(context),
                  const SizedBox(height: 20),
                  _sectionTitle('Offer of the Day'),
                  const SizedBox(height: 10),
                  _offerOfDay(context),
                  const SizedBox(height: 20),
                  _sectionTitle('Quick Earn'),
                  const SizedBox(height: 10),
                  _quickEarn(context),
                  const SizedBox(height: 20),
                  _sectionTitle('Recommended for You'),
                  const SizedBox(height: 10),
                  _recommendedRow(context),
                  const SizedBox(height: 20),
                  _sectionTitle('High-Paying Tasks',
                      action: 'View All',
                      onAction: () => _push(context, const EarnScreen())),
                  const SizedBox(height: 10),
                  _highPayingList(context),
                  const SizedBox(height: 20),
                  _dailySpinCard(context),
                  const SizedBox(height: 18),
                  _sectionTitle('Daily Missions',
                      action: 'View All',
                      onAction: () => _push(context, const MissionsScreen())),
                  const SizedBox(height: 10),
                  _missionsRow(context),
                  const SizedBox(height: 20),
                  _inviteCard(context),
                  const SizedBox(height: 20),
                  _sectionTitle('Top Earners',
                      action: 'View Full Rankings',
                      onAction: () =>
                          _push(context, const LeaderboardScreen())),
                  const SizedBox(height: 10),
                  _topEarners(context),
                  const SizedBox(height: 20),
                  _sectionTitle('How to Earn'),
                  const SizedBox(height: 10),
                  _howToEarn(context),
                  const SizedBox(height: 18),
                  Center(
                    child: Text(
                      'CoinVault • Earn coins daily',
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ───────────────────────── Promo carousel ────────────────────────────────
  Widget _promoCarousel(BuildContext context) {
    return HomeBannerCarousel(
      slides: [
        BannerSlide(
          title: 'Offer of the Day',
          subtitle: "Complete today's featured offer",
          cta: 'View Offer',
          icon: Icons.local_fire_department_rounded,
          accent: const Color(0xFFF59E0B),
          accentSoft: const Color(0xFFFFF7E6),
          reward: '+1,500 Coins',
          onTap: () => _push(context, const EarnScreen()),
        ),
        BannerSlide(
          title: 'Task of the Day',
          subtitle: 'Finish this task and earn extra coins',
          cta: 'Start Task',
          icon: Icons.task_alt_rounded,
          accent: const Color(0xFF16A34A),
          accentSoft: const Color(0xFFE9F7EE),
          reward: '+750 Coins',
          onTap: () => _push(context, const EarnScreen()),
        ),
        BannerSlide(
          title: 'Featured Survey',
          subtitle: 'Your opinion can earn you coins',
          cta: 'Take Survey',
          icon: Icons.poll_rounded,
          accent: const Color(0xFF3B82F6),
          accentSoft: const Color(0xFFEAF1FF),
          reward: 'Up to 500 Coins',
          onTap: () => _push(context, const SurveysScreen()),
        ),
        BannerSlide(
          title: 'Limited Time',
          subtitle: 'Extra rewards available today',
          cta: 'Explore',
          icon: Icons.bolt_rounded,
          accent: const Color(0xFF8B5CF6),
          accentSoft: const Color(0xFFF1ECFE),
          reward: 'Earn More',
          onTap: () => _push(context, const EarnScreen()),
        ),
        BannerSlide(
          title: 'Mega Offer',
          subtitle: 'Complete multiple milestones',
          cta: 'View Offer',
          icon: Icons.emoji_events_rounded,
          accent: const Color(0xFFEC4899),
          accentSoft: const Color(0xFFFDF0F6),
          reward: 'Up to 3,000 Coins',
          onTap: () => _push(context, const EarnScreen()),
        ),
      ],
    );
  }

  // ───────────────────────── Balance summary ───────────────────────────────
  Widget _balanceSummary(BuildContext context, int coins) {
    final earned = _todayEarned();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: _cardDec(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Flexible(
                      child: Text('Your Balance',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600)),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _push(context, const WithdrawScreen()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 11, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: const Text('Withdraw',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Balance value — wraps naturally, never clips or overlaps.
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 5,
                  runSpacing: 4,
                  children: [
                    const Icon(Icons.monetization_on_rounded,
                        color: AppColors.primary, size: 22),
                    Text(_fmt(coins),
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          height: 1.1,
                        )),
                    const Text('Coins',
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('≈ ₹${(coins / 10).toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11.5)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: _cardDec(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _miniStat('Today', '+${_fmt(earned)}',
                    Icons.trending_up_rounded, AppColors.success),
                const SizedBox(height: 8),
                _miniStat('Total Earned', _fmt(coins),
                    Icons.emoji_events_rounded, AppColors.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _miniStat(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 7),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 10.5)),
            Text(value,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800)),
          ],
        ),
      ],
    );
  }

  // ───────────────────────── Today's earnings ──────────────────────────────
  Widget _todayEarningsCard(BuildContext context) {
    final earned = _todayEarned();
    final progress = (earned / _dailyGoal).clamp(0.0, 1.0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _cardDec(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text("Today's Earnings",
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              const Spacer(),
              GestureDetector(
                onTap: () => _push(context, const TrackingScreen()),
                child: Row(
                  children: const [
                    Text('View Activity',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 12, color: AppColors.primary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('+${_fmt(earned)}',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    height: 1.1,
                  )),
              const SizedBox(width: 5),
              const Text('Coins earned today',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
              const Spacer(),
              Text('${_fmt(earned)}/${_fmt(_dailyGoal)}',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Keep earning to reach your daily goal',
              style:
                  TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
        ],
      ),
    );
  }

  // ───────────────────────── Featured surveys ──────────────────────────────
  Widget _surveyRow(BuildContext context) {
    if (_surveys.isEmpty) return _emptyRow('No surveys yet — check back soon');
    final cards = _surveys.take(6).map((s) {
      final m = s as Map;
      return _hCard(
        context: context,
        title: (m['title'] ?? 'Survey').toString(),
        sub: (m['provider'] ?? 'CPX Research').toString(),
        coins: ((m['rewardCoins'] ?? m['coins'] ?? 0) as num).toInt(),
        meta: '${(m['durationMinutes'] ?? m['duration'] ?? 5)} min',
        chip: 'Survey',
        icon: Icons.poll_rounded,
        color: const Color(0xFF3B82F6),
        cta: 'Start',
        provider: (m['provider'] ?? '').toString(),
        onTap: () => _push(context, const SurveysScreen()),
      );
    }).toList();
    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => cards[i],
      ),
    );
  }

  // ───────────────────────── Tasks of the day ──────────────────────────────
  Widget _tasksRow(BuildContext context) {
    if (_tasks.isEmpty) return _emptyRow('No tasks yet — check back soon');
    final cards = _tasks.take(6).map((t) {
      final m = t as Map;
      return _hCard(
        context: context,
        title: (m['title'] ?? 'Task').toString(),
        sub: (m['provider'] ?? 'Offer').toString(),
        coins: ((m['coins'] ?? 0) as num).toInt(),
        meta: '~10 min',
        chip: 'Task',
        icon: Icons.task_alt_rounded,
        color: const Color(0xFF16A34A),
        cta: 'Start Task',
        provider: (m['provider'] ?? '').toString(),
        onTap: () => _push(
              context,
              TaskDetailScreen(
                provider: (m['provider'] ?? 'CoinVault').toString(),
                title: (m['title'] ?? 'Task').toString(),
                desc: (m['sub'] ?? '').toString(),
                coins: ((m['coins'] ?? 0) as num).toInt(),
                steps: (m['steps'] as List?)?.cast<String>() ??
                    const ['Tap Start', 'Complete the task', 'Coins credited'],
              ),
            ),
      );
    }).toList();
    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => cards[i],
      ),
    );
  }

  Widget _hCard({
    required BuildContext context,
    required String title,
    required String sub,
    required int coins,
    required String meta,
    required String chip,
    required IconData icon,
    required Color color,
    required String cta,
    required VoidCallback onTap,
    String? provider,
    double width = 200,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(13),
      decoration: _cardDec(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // ONE resolver: real provider logo → app logo from title →
              // clean activity icon. Never a dummy brand logo.
              AppLogo(
                provider: provider,
                title: title,
                size: 36,
                radius: 9,
                fallbackIcon: icon,
                fallbackColor: color,
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(chip,
                    style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: color)),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 3),
          Text(sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 7),
          Row(
            children: [
              Icon(Icons.monetization_on_rounded,
                  size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Text('+${_fmt(coins)} Coins',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary)),
              const SizedBox(width: 8),
              Icon(Icons.access_time_rounded,
                  size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 3),
              Text(meta,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: Text(cta,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Offer of the day ──────────────────────────────
  Widget _offerOfDay(BuildContext context) {
    if (_offers.isEmpty) return _emptyRow('No featured offer today');
    final offer = _offers.first as Map;
    final coins = ((offer['coins'] ?? 0) as num).toInt();
    final steps = (offer['instructions'] as List?)?.take(4) ?? const [];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primary.withOpacity(0.35), width: 1.5),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.local_fire_department_rounded,
                    color: Colors.white, size: 21),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text((offer['title'] ?? 'Offer of the Day').toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 3),
                    Text((offer['shortDesc'] ?? '').toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11.5, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Reward',
                      style: TextStyle(
                          fontSize: 10, color: AppColors.textSecondary)),
                  Text('+${_fmt(coins)}',
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (int i = 0; i < steps.length; i++) ...[
                _milestone(i + 1, steps.elementAt(i).toString(),
                    i == 0 ? AppColors.primary : AppColors.border),
                if (i != steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: AppColors.border,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 13),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton(
              onPressed: () => _push(context, const EarnScreen()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: const Text('View Offer',
                  style:
                      TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _milestone(int n, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text('$n',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 58,
          child: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 9, color: AppColors.textSecondary)),
        ),
      ],
    );
  }

  // ───────────────────────── Quick earn ────────────────────────────────────
  Widget _quickEarn(BuildContext context) {
    final items = [
      ('Surveys', Icons.poll_rounded, const Color(0xFF3B82F6), '+450',
          () => _push(context, const SurveysScreen())),
      ('Quizzes', Icons.school_rounded, const Color(0xFF10B981), '+300',
          () => _push(context, const QuizScreen())),
      ('Tasks', Icons.task_alt_rounded, const Color(0xFFF59E0B), '+600',
          () => _push(context, const EarnScreen())),
      ('Offers', Icons.local_offer_rounded, const Color(0xFF8B5CF6), '+1,500',
          () => _push(context, const EarnScreen())),
      ('Scratch', Icons.grid_view_rounded, const Color(0xFFEC4899), '+200',
          () => _push(context, const ScratchScreen())),
      ('Spin', Icons.donut_large_rounded, const Color(0xFF14B8A6), '+10',
          () => _push(context, const SpinScreen())),
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 9,
      crossAxisSpacing: 9,
      childAspectRatio: 1.15,
      children: items.map((it) {
        return GestureDetector(
          onTap: it.$5,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: _cardDec(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: it.$3.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(it.$2, size: 18, color: it.$3),
                ),
                const SizedBox(height: 6),
                Text(it.$1,
                    style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(it.$4,
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ───────────────────────── Recommended ───────────────────────────────────
  Widget _recommendedRow(BuildContext context) {
    final recs = <Map<String, dynamic>>[
      {'t': 'Short Survey', 'c': 120, 'm': '3 min', 'i': Icons.poll_rounded,
       'col': const Color(0xFF3B82F6), 'cta': 'Take Survey',
       'go': () => _push(context, const SurveysScreen())},
      {'t': 'Quick Task', 'c': 250, 'm': '5 min', 'i': Icons.bolt_rounded,
       'col': const Color(0xFF16A34A), 'cta': 'Start',
       'go': () => _push(context, const EarnScreen())},
      {'t': 'High Reward Offer', 'c': 1500, 'm': '~15 min',
       'i': Icons.emoji_events_rounded, 'col': AppColors.primary,
       'cta': 'View Offer', 'go': () => _push(context, const EarnScreen())},
      {'t': 'New Survey', 'c': 320, 'm': '6 min', 'i': Icons.fiber_new_rounded,
       'col': const Color(0xFFEC4899), 'cta': 'Start',
       'go': () => _push(context, const SurveysScreen())},
    ];
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: recs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final r = recs[i];
          return Container(
            width: 176,
            padding: const EdgeInsets.all(12),
            decoration: _cardDec(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: (r['col'] as Color).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(r['i'] as IconData,
                          size: 16, color: r['col'] as Color),
                    ),
                    const Spacer(),
                    Text('+${_fmt(r['c'] as int)}',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(r['t'] as String,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 3),
                    Text(r['m'] as String,
                        style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.textSecondary)),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 30,
                  child: ElevatedButton(
                    onPressed: r['go'] as VoidCallback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: Text(r['cta'] as String,
                        style: const TextStyle(
                            fontSize: 11.5, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ───────────────────────── High-paying tasks ─────────────────────────────
  Widget _highPayingList(BuildContext context) {
    final high = <Map>[
      if (_offers.isNotEmpty)
        ..._offers
            .cast<Map>()
            .where((o) => ((o['coins'] ?? 0) as num).toInt() >= 500)
            .take(4)
    ];
    if (high.isEmpty) return const SizedBox.shrink(); // no fake fallback
    return Column(
      children: high.map((m) {
        final coins = ((m['coins'] ?? 0) as num).toInt();
        final provider = (m['provider'] ?? m['cat'] ?? '').toString();
        final title = (m['title'] ?? 'Task').toString();
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: _cardDec(),
            child: Row(
              children: [
                AppLogo(
                  provider: provider,
                  title: title,
                  size: 44,
                  fallbackIcon: Icons.local_fire_department_rounded,
                  fallbackColor: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text((m['title'] ?? 'Task').toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary)),
                          const SizedBox(width: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.12),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                            ),
                            child: const Text('New',
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.success)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text((m['cat'] ?? m['provider'] ?? 'Offer').toString(),
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('+${_fmt(coins)}',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary)),
                    const Text('Coins',
                        style: TextStyle(
                            fontSize: 10, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _push(context, const EarnScreen()),
                  child: const Icon(Icons.arrow_forward_ios_rounded,
                      size: 15, color: AppColors.primary),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ───────────────────────── Daily spin ────────────────────────────────────
  Widget _dailySpinCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.donut_large_rounded,
                        color: Colors.white, size: 19),
                    SizedBox(width: 7),
                    Text('Daily Spin',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text('Your free spin is ready!',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                const Text('Win bonus coins every day',
                    style: TextStyle(color: Colors.white70, fontSize: 11.5)),
                const SizedBox(height: 11),
                GestureDetector(
                  onTap: () => _push(context, const SpinScreen()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: const Text('Spin Now',
                        style: TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 13,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // simple wheel visual (no casino look)
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.18),
              border: Border.all(color: Colors.white.withOpacity(0.5), width: 3),
            ),
            child: const Icon(Icons.donut_large_rounded,
                color: Colors.white, size: 38),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Daily missions ────────────────────────────────
  Widget _missionsRow(BuildContext context) {
    final spinsUsed = _spinsUsedToday;
    final missions = [
      {'t': 'Complete 3 Surveys', 'cur': 2, 'target': 3, 'r': 100,
       'i': Icons.poll_rounded, 'col': const Color(0xFF3B82F6)},
      {'t': 'Complete 2 Tasks', 'cur': 1, 'target': 2, 'r': 150,
       'i': Icons.task_alt_rounded, 'col': const Color(0xFF16A34A)},
      {'t': 'Use 2 Free Spins', 'cur': spinsUsed, 'target': 2, 'r': 20,
       'i': Icons.donut_large_rounded, 'col': const Color(0xFFF59E0B)},
    ];
    return Column(
      children: missions.map((m) {
        final cur = (m['cur'] as num).toInt();
        final target = (m['target'] as num).toInt();
        final progress = (cur / target).clamp(0.0, 1.0);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: _cardDec(),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: (m['col'] as Color).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(m['i'] as IconData,
                      size: 19, color: m['col'] as Color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m['t'] as String,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: AppColors.border,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              m['col'] as Color),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('$cur/$target completed',
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text('+${m['r']}',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ───────────────────────── Invite & earn ─────────────────────────────────
  Widget _inviteCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: _cardDec(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.card_giftcard_rounded,
                        color: AppColors.primary, size: 19),
                    SizedBox(width: 7),
                    Text('Invite & Earn',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text('Invite friends and earn bonus coins',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                const Text('+100 Coins per friend who joins',
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
                const SizedBox(height: 11),
                GestureDetector(
                  onTap: () => _push(context, const InviteScreen()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 9),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: const Text('Invite Now',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ClipOval(
            child: Image.asset(
              'assets/bear_redeem.png',
              width: 76,
              height: 76,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 76,
                height: 76,
                color: const Color(0xFFFFF7E6),
                child: const Icon(Icons.card_giftcard_rounded, size: 32),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Limited-time offers ───────────────────────────
  Widget _limitedOffers(BuildContext context) {
    final now = DateTime.now();
    final offers = <Map<String, dynamic>>[
      {'t': 'Flash Survey', 'c': 500, 'h': 4, 'i': Icons.poll_rounded,
       'col': const Color(0xFF3B82F6), 'req': 'Complete 1 survey'},
      {'t': 'Task Marathon', 'c': 900, 'h': 9, 'i': Icons.task_alt_rounded,
       'col': const Color(0xFF16A34A), 'req': 'Finish 3 tasks'},
      {'t': 'Spin Bonus', 'c': 150, 'h': 2, 'i': Icons.donut_large_rounded,
       'col': const Color(0xFFF59E0B), 'req': 'Use daily spins'},
    ];
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: offers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final o = offers[i];
          final ends = now.add(Duration(hours: o['h'] as int));
          final hh = ends.hour.toString().padLeft(2, '0');
          final mm = ends.minute.toString().padLeft(2, '0');
          return Container(
            width: 190,
            padding: const EdgeInsets.all(13),
            decoration: _cardDec(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: (o['col'] as Color).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(o['i'] as IconData,
                          size: 16, color: o['col'] as Color),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer_outlined,
                              size: 11, color: AppColors.error),
                          const SizedBox(width: 3),
                          Text('Ends $hh:$mm',
                              style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Text(o['t'] as String,
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 3),
                Text(o['req'] as String,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                const Spacer(),
                Row(
                  children: [
                    Text('+${_fmt(o['c'] as int)} Coins',
                        style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _push(context, const EarnScreen()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 13, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: const Text('View Offer',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ───────────────────────── Top earners ───────────────────────────────────
  Widget _topEarners(BuildContext context) {
    final top = (_leaderboard['top'] as List?)?.take(3).toList() ?? [];
    if (top.isEmpty) {
      return _emptyRow('Leaderboard updates soon');
    }
    final medals = [AppColors.primary, const Color(0xFF9CA3AF), const Color(0xFFB45309)];
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: _cardDec(),
      child: Column(
        children: [
          for (int i = 0; i < top.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: medals[i].withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text('${i + 1}',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: medals[i])),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      (((top[i] as Map)['user'] ?? {}) as Map)['name'] ??
                          'User',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text('+${_fmt((((top[i] as Map)['coinsEarned'] ?? 0) as num).truncate())}',
                      style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary)),
                ],
              ),
            ),
            if (i != top.length - 1)
              const Divider(height: 1, color: AppColors.border),
          ],
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _push(context, const LeaderboardScreen()),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text('View Full Rankings',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700)),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 12, color: AppColors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── How to earn ───────────────────────────────────
  Widget _howToEarn(BuildContext context) {
    final steps = [
      ('Find a survey/task', Icons.search_rounded),
      ('Complete it', Icons.check_circle_rounded),
      ('Earn coins', Icons.monetization_on_rounded),
      ('Redeem rewards', Icons.redeem_rounded),
    ];
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: _cardDec(),
      child: Row(
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            Expanded(
              child: Column(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(steps[i].$2,
                        size: 19, color: AppColors.primary),
                  ),
                  const SizedBox(height: 6),
                  Text(steps[i].$1,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (i != steps.length - 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 22),
                child: Icon(Icons.arrow_forward_ios_rounded,
                    size: 12, color: AppColors.textTertiary),
              ),
          ],
        ],
      ),
    );
  }

  // ───────────────────────── Shared bits ───────────────────────────────────
  BoxDecoration _cardDec() {
    return BoxDecoration(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: AppColors.border),
      boxShadow: AppShadows.card,
    );
  }

  Widget _sectionTitle(String title,
      {String? action, VoidCallback? onAction}) {
    return Row(
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary)),
        const Spacer(),
        if (action != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Row(
              children: [
                Text(action,
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 11, color: AppColors.primary),
              ],
            ),
          ),
      ],
    );
  }

  Widget _emptyRow(String text) {
    return Container(
      width: double.infinity,
      height: 90,
      alignment: Alignment.center,
      decoration: _cardDec(),
      child: Text(text,
          style: const TextStyle(
              fontSize: 12.5, color: AppColors.textSecondary)),
    );
  }

  Widget _skeletonH() {
    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, __) => Container(
          width: 200,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
      ),
    );
  }
}
