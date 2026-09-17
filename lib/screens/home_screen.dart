import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_theme.dart';
import '../core/provider_logos.dart';
import '../services/auth_service.dart';
import '../services/app_repository.dart';
import '../models/app_models.dart';
import 'earn_screen.dart';
import 'spin_screen.dart';
import '../widgets/home_banner_carousel.dart';
import '../widgets/cv_header.dart';
import 'scratch_screen.dart';
import 'quiz_screen.dart';
import 'surveys_screen.dart';
import 'withdraw_screen.dart';
import 'missions_screen.dart';
import 'invite_screen.dart';
import 'tracking_screen.dart';
import 'redeem_screen.dart';
import 'leaderboard_screen.dart';
import 'notifications_screen.dart';
import 'refer_screen.dart';

/// Light-theme home shell: bottom nav only (Home/Earn/Ranks/Surveys/Withdraw).
/// The dark-theme left side-drawer was replaced by this sheet's top bar.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
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
    ]);
  }

  Future<void> _loadUser() async {
    final auth = AuthService();
    if (auth.isLoggedIn) {
      setState(() {
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  void _pushScreen(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
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
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.xs),
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
                                color: _currentIndex == 2
                                    ? AppColors.gold
                                    : AppColors.border,
                                width: 2.5),
                            boxShadow: _currentIndex == 2
                                ? [
                                    BoxShadow(
                                      color: AppColors.gold.withOpacity(0.28),
                                      blurRadius: 12,
                                    ),
                                  ]
                                : null,
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/app_icon.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                  Icons.emoji_events_rounded,
                                  color: AppColors.gold,
                                  size: 26),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primaryContainer
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
                        constraints: const BoxConstraints(
                            minWidth: 16, minHeight: 16),
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

/// Home tab — light-theme dashboard (design sheet):
/// top bar (wordmark + coin pill + bell), Total Balance card, earnings &
/// daily-goal bars, Featured Surveys, quick actions, footer.
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<dynamic> _surveys = [];
  List<dynamic> _tasks = [];
  List<dynamic> _activity = [];
  bool _loadingHome = true;

  /// Daily goal (design sheet: 240/500 style). Live-derived from today's
  /// credited activity; falls back to a safe 0/500 until the API answers.
  static const int _dailyGoal = 500;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
    _loadActivity();
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
          .where((o) =>
              ((o as Map)['type'] ?? '').toString().startsWith('INSTALL'))
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

  /// Today's earnings = coins credited in the last 24h (real /api/user/activity).
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

  /// Formats with thousands separators (design sheet: "2,450").
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

  @override
  Widget build(BuildContext context) {
    // Rebuilds instantly whenever AuthService coins/user change (no restart).
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CvHeader(showProfile: false),
                  const SizedBox(height: 10),
                  _walletCard(context, coins),
                  const SizedBox(height: 12),
                  HomeBannerCarousel(
                    slides: [
                      BannerSlide(
                        title: 'Daily Bonus',
                        subtitle:
                            "Complete today's activities and earn extra coins.",
                        cta: 'Earn Now',
                        icon: Icons.calendar_today_rounded,
                        accent: const Color(0xFFFF8C42),
                        accentSoft: const Color(0xFFFFF0E5),
                        onTap: () => _push(context, const EarnScreen()),
                      ),
                      BannerSlide(
                        title: 'Earn With Surveys',
                        subtitle: 'Share your opinion and earn coins.',
                        cta: 'View Surveys',
                        icon: Icons.poll_rounded,
                        accent: const Color(0xFF3B82F6),
                        accentSoft: const Color(0xFFEAF1FF),
                        onTap: () => _push(context, const SurveysScreen()),
                      ),
                      BannerSlide(
                        title: 'New Tasks Available',
                        subtitle: 'Complete simple tasks and collect rewards.',
                        cta: 'View Tasks',
                        icon: Icons.task_alt_rounded,
                        accent: const Color(0xFF16A34A),
                        accentSoft: const Color(0xFFE9F7EE),
                        onTap: () => _push(context, const EarnScreen()),
                      ),
                      BannerSlide(
                        title: 'Spin & Win Coins',
                        subtitle: 'Use your daily free spin for extra rewards.',
                        cta: 'Spin Now',
                        icon: Icons.casino_rounded,
                        accent: const Color(0xFF8B5CF6),
                        accentSoft: const Color(0xFFF1ECFE),
                        onTap: () => _push(context, const SpinScreen()),
                      ),
                      BannerSlide(
                        title: 'Redeem Your Coins',
                        subtitle: 'Turn your coins into exciting rewards.',
                        cta: 'Withdraw',
                        icon: Icons.account_balance_wallet_rounded,
                        accent: const Color(0xFFF59E0B),
                        accentSoft: const Color(0xFFFFF7E6),
                        onTap: () => _push(context, const WithdrawScreen()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _earningsRow(context),
                  const SizedBox(height: 16),
                  _sectionTitle('Featured Surveys',
                      action: 'View All',
                      onAction: () => _push(context, const SurveysScreen())),
                  const SizedBox(height: 10),
                  _loadingHome
                      ? _skeletonHorizontal()
                      : _surveyList(context),
                  const SizedBox(height: 18),
                  _sectionTitle('Tasks of the Day',
                      action: 'View All',
                      onAction: () => _push(context, const EarnScreen())),
                  const SizedBox(height: 10),
                  _loadingHome
                      ? _skeletonHorizontal()
                      : _tasksList(context),
                  const SizedBox(height: 18),
                  _quickActions(context),
                  const SizedBox(height: 18),
                  _referralBanner(context),
                  const SizedBox(height: 16),
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

  // ───────────────────────────── Top bar ─────────────────────────────
  // CoinVault wordmark + coin balance pill + notification bell.

  // ─────────────── Today's Earnings + Daily Goal progress ─────────────
  Widget _earningsRow(BuildContext context) {
    final earned = _todayEarned();
    final progress = (earned / _dailyGoal).clamp(0.0, 1.0);
    return Row(
      children: [
        // Today's Earnings
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Today's Earnings",
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('+${_fmt(earned)}',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          height: 1.15,
                        )),
                    const SizedBox(width: 4),
                    const Text('Coins',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Daily Goal + progress bar
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Daily Goal',
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600)),
                    Text('${_fmt(earned)}/${_fmt(_dailyGoal)}',
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 8),
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
              ],
            ),
          ),
        ),
      ],
    );
  }

  int _todayEarned() {
    if (_activity.isEmpty) return 0;
    return ((_activity.first as Map)['earned'] as num?)?.toInt() ?? 0;
  }

  // ─────────────────────────── Section title ──────────────────────────
  Widget _sectionTitle(String title,
      {String? action, VoidCallback? onAction}) {
    return Row(
      children: [
        Text(title,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        const Spacer(),
        if (action != null)
          InkWell(
            onTap: onAction,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(action,
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700)),
            ),
          ),
      ],
    );
  }

  // ─────────────────────── Featured Surveys cards ─────────────────────
  /// Data comes from the live backend (GET /api/surveys).
  Widget _surveyList(BuildContext context) {
    final cards = _surveys.take(5).map((s) {
      final m = s as Map;
      return {
        'provider': (m['provider'] ?? 'Survey').toString(),
        'coins': ((m['coins'] ?? 0) as num).toInt(),
        'duration': (m['duration'] ?? '').toString(),
      };
    }).toList();
    if (cards.isEmpty) {
      return Container(
        height: 96,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Text('New surveys coming soon', style: AppTextStyles.bodyMedium),
      );
    }
    return Column(
      children: cards.map((c) {
        final provider = c['provider'] as String;
        final coins = c['coins'] as int;
        final time = c['duration'] as String;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _SurveyCard(
            provider: provider,
            coins: coins,
            time: time,
            onTap: () => _push(context,
                SurveysScreen(initialProvider: provider)),
          ),
        );
      }).toList(),
    );
  }

  // ─────────────────────── Tasks of the Day cards ─────────────────────
  Widget _tasksList(BuildContext context) {
    final tasks = _tasks;
    if (tasks.isEmpty) {
      return Container(
        height: 96,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Text('No tasks available right now',
            style: AppTextStyles.bodyMedium),
      );
    }
    return Column(
      children: tasks.map((t) {
        final provider = t['provider'] as String;
        final color = ProviderLogos.colorFor(provider);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _TaskCard(
            title: t['title'] as String,
            sub: t['sub'] as String,
            coins: t['coins'] as int,
            provider: provider,
            color: color,
            onTap: () => _showTaskDetail(context, t, color),
          ),
        );
      }).toList(),
    );
  }

  void _showTaskDetail(
      BuildContext context, Map<String, dynamic> t, Color color) {
    final provider = t['provider'] as String;
    final steps = (t['steps'] as List).cast<String>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ProviderLogo(provider, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(t['title'] as String,
                      style: AppTextStyles.titleLarge),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('+${t['coins']} coins • $provider',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
            const Divider(height: 24, color: AppColors.divider),
            ...steps.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: AppColors.success, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(s, style: AppTextStyles.bodyMedium)),
                    ],
                  ),
                )),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: const Text('Got it',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────── Quick actions (play & earn) ──────────────────
  Widget _quickActions(BuildContext context) {
    final tiles = <(String, IconData, Color, VoidCallback)>[
      ('Spin', Icons.donut_large_rounded, AppColors.primary,
          () => _push(context, const SpinScreen())),
      ('Scratch', Icons.grid_view_rounded, AppColors.gold,
          () => _push(context, const ScratchScreen())),
      ('Quiz', Icons.school_rounded, const Color(0xFF10B981),
          () => _push(context, const QuizScreen())),
      ('Ranks', Icons.emoji_events_rounded, const Color(0xFF8B5CF6),
          () => _push(context, const LeaderboardScreen())),
      ('Tasks', Icons.task_alt_rounded, const Color(0xFF3B82F6),
          () => _push(context, const MissionsScreen())),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: tiles.map((t) {
          final label = t.$1;
          final icon = t.$2;
          final color = t.$3;
          return Expanded(
            child: InkWell(
              onTap: t.$4,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(height: 6),
                  Text(label,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // WALLET — top of Home. Orange gradient, real balance, Withdraw + History.
  // ─────────────────────────────────────────────────────────────────────
  Widget _walletCard(BuildContext context, int coins) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF59E0B), Color(0xFFE8842A)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 7),
                    const Text(
                      'Wallet Balance',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _fmt(coins),
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('Coins',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
                const SizedBox(height: 3),
                const Text(
                  'Redeemable rewards in your vault',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              InkWell(
                onTap: () => _push(context, const WithdrawScreen()),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Withdraw',
                    style: TextStyle(
                      color: Color(0xFFB45309),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _push(context, const TrackingScreen()),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'History',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Referral / invite banner ─────────────────────
  Widget _referralBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Invite & Earn',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800)),
                Text('Get bonus coins for every friend who joins',
                    style: TextStyle(
                        color: const Color(0xFF3D2E00).withOpacity(0.75),
                        fontSize: 11)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _push(context, const InviteScreen()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.gold,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
            child: const Text('Invite',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────── Skeletons ─────────────────────────────
  Widget _skeletonHorizontal() {
    return Column(
      children: List.generate(
          2,
          (i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.border),
                  ),
                ),
              )),
    );
  }
}

/// Light-theme survey card: icon tile, title, reward + meta, orange Start pill.
class _SurveyCard extends StatelessWidget {
  final String provider;
  final int coins;
  final String time;
  final VoidCallback onTap;

  const _SurveyCard({
    required this.provider,
    required this.coins,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: ProviderLogo(provider, size: 44, radius: 12),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(provider,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.monetization_on_rounded,
                          color: AppColors.gold, size: 13),
                      const SizedBox(width: 3),
                      Text('+$coins',
                          style: const TextStyle(
                              color: AppColors.gold,
                              fontSize: 12,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(width: 8),
                      Icon(Icons.access_time_rounded,
                          color: AppColors.textTertiary, size: 13),
                      const SizedBox(width: 3),
                      Text(time.isEmpty ? '2 min' : time,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 11.5)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Orange Start pill (design sheet)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: const Text('Start',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Light-theme task card: provider logo, title, sub, reward, chevron.
class _TaskCard extends StatelessWidget {
  final String title;
  final String sub;
  final int coins;
  final String provider;
  final Color color;
  final VoidCallback onTap;

  const _TaskCard({
    required this.title,
    required this.sub,
    required this.coins,
    required this.provider,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: ProviderLogo(provider, size: 46, radius: 12),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11.5)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.goldContainer,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(color: AppColors.border),
              ),
              child: Text('+$coins',
                  style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}
