import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_theme.dart';
import '../services/app_repository.dart';
import '../services/balance_stream.dart';
import '../widgets/cv_header.dart';
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


class BannerSlide {
  final String title;
  final String subtitle;
  final String cta;
  final IconData icon;
  final Color accent;
  final Color accentSoft;
  final String? imageAsset;
  final String reward;
  final VoidCallback onTap;

  const BannerSlide({required this.title, required this.subtitle, required this.cta,
    required this.icon, required this.accent, required this.accentSoft,
    this.imageAsset, required this.reward, required this.onTap});
}

class HomeBannerCarousel extends StatelessWidget {
  final List<BannerSlide> slides;
  const HomeBannerCarousel({super.key, required this.slides});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 148,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: slides.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final slide = slides[index];
          return InkWell(
            onTap: slide.onTap,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Container(
              width: MediaQuery.of(context).size.width - 48,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: slide.accentSoft,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: slide.accent.withOpacity(0.22)),
              ),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(slide.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: slide.accent, fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(slide.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  if (slide.reward.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(slide.reward, style: TextStyle(color: slide.accent, fontSize: 11, fontWeight: FontWeight.w800)),
                  ],
                  const SizedBox(height: 7),
                  Text(slide.cta, style: TextStyle(color: slide.accent, fontSize: 11, fontWeight: FontWeight.w800)),
                ])),
                const SizedBox(width: 8),
                if (slide.imageAsset != null)
                  Image.asset(slide.imageAsset!, width: 62, height: 62, fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(slide.icon, size: 42, color: slide.accent))
                else
                  Icon(slide.icon, size: 42, color: slide.accent),
              ]),
            ),
          );
        },
      ),
    );
  }
}

/// Home — content-rich CoinVault rewards home (light premium design).
///
/// Global header → promo carousel → balance summary → today's earnings →
/// surveys → tasks → available offers → quick earn →
/// recommended → high-paying tasks → daily spin → daily missions →
/// referrals → offers → top earners → how to earn.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _pushScreen(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: _currentIndex == 0
          ? const HomeTab()
          : _currentIndex == 1
              ? const EarnScreen()
              : _currentIndex == 2
                  ? const LeaderboardScreen()
                  : const SurveysScreen(),
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
                          width: 46,
                          height: 46,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentIndex == 2
                                ? AppColors.primaryContainer
                                : AppColors.goldContainer,
                            border: Border.all(
                              color: _currentIndex == 2
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: 1.5,
                            ),
                            boxShadow: _currentIndex == 2
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.18),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            Icons.emoji_events_rounded,
                            color: _currentIndex == 2
                                ? AppColors.primaryDark
                                : AppColors.gold,
                            size: 25,
                          ),
                        ),
                        Text(
                          'Ranks',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _currentIndex == 2
                                ? AppColors.primaryDark
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
  List<dynamic> _offers = [];
  Map<String, dynamic> _leaderboard = {};
  Map<String, dynamic>? _spinStatus;
  bool _loadingHome = true;
  bool _offersUnavailable = false;
  bool _surveysUnavailable = false;
  int? _todayEarnings;

  @override
  void initState() {
    super.initState();
    // Never carry a prior user's balance into a newly opened home screen.
    BalanceStream.instance.clear();
    _loadHomeData();
    _loadActivity();
    _loadLeaderboard();
  }

  Future<void> _loadHomeData() async {
    if (mounted) setState(() => _loadingHome = true);
    final repo = AppRepository.instance;
    final results = await Future.wait<dynamic>([
      repo.fetchSurveys(),
      repo.fetchOffers(),
      repo.spinStatus(),
      repo.fetchWalletBalance(),
    ]);
    if (!mounted) return;
    final surveys = results[0] as List<dynamic>?;
    final offers = results[1] as List<dynamic>?;
    setState(() {
      _surveysUnavailable = surveys == null;
      _offersUnavailable = offers == null;
      _surveys = surveys ?? [];
      _offers = (offers ?? const <dynamic>[])
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
      _spinStatus = results[2] is Map
          ? Map<String, dynamic>.from(results[2] as Map)
          : null;
      _loadingHome = false;
    });
  }

  Future<void> _refreshHome() async {
    await Future.wait<void>([
      _loadHomeData(),
      _loadActivity(),
      _loadLeaderboard(),
    ]);
  }

  Future<void> _loadActivity() async {
    try {
      final list = await AppRepository.instance.fetchActivity();
      if (!mounted) return;
      final now = DateTime.now();
      var earned = 0;
      var hasDatedEarnings = false;
      for (final raw in list ?? const <dynamic>[]) {
        if (raw is! Map) continue;
        final type = (raw['type'] ?? '').toString().toLowerCase();
        if (!{'task', 'survey', 'spin'}.contains(type)) continue;
        final amount = raw['coins'];
        if (amount is! num || amount <= 0) continue;
        final status = (raw['status'] ?? '').toString().toUpperCase();
        if (!{'VERIFIED', 'DONE', 'COMPLETED'}.contains(status)) continue;
        final ts = raw['at'] ?? raw['timestamp'] ?? raw['createdAt'] ?? raw['date'];
        DateTime? dt;
        if (ts is num) {
          dt = DateTime.fromMillisecondsSinceEpoch(
              ts > 1e12 ? ts.toInt() : (ts.toInt() * 1000));
        } else if (ts is String) {
          dt = DateTime.tryParse(ts);
        }
        final localDt = dt?.toLocal();
        if (localDt != null && localDt.year == now.year && localDt.month == now.month && localDt.day == now.day) {
          earned += amount.toInt();
          hasDatedEarnings = true;
        }
      }
      setState(() {
        _todayEarnings = hasDatedEarnings ? earned : null;
      });
    } catch (_) {
      if (mounted) setState(() {
        _todayEarnings = null;
      });
    }
  }

  Future<void> _loadLeaderboard() async {
    try {
      final lb = await AppRepository.instance.fetchLeaderboard('weekly');
      if (mounted) setState(() => _leaderboard = lb ?? <String, dynamic>{});
    } catch (_) {}
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

  int? _todayEarned() => _todayEarnings;

  List<Map<String, dynamic>> _serverTasks() {
    final tasks = _offers
        .whereType<Map>()
        .map((raw) => Map<String, dynamic>.from(raw))
        .where((task) {
          final type = (task['type'] ?? task['category'] ?? '')
              .toString()
              .toUpperCase();
          final id = (task['id'] ??
                  task['_id'] ??
                  task['offerId'] ??
                  task['providerOfferId'] ??
                  '')
              .toString()
              .trim();
          return (type.contains('TASK') || type.startsWith('INSTALL')) &&
              (task['title'] ?? '').toString().trim().isNotEmpty &&
              id.isNotEmpty;
        })
        .toList();

    // If the admin/API marks a daily or featured task, prefer the first such
    // item. Otherwise preserve server ordering and show its first task.
    final featuredIndex = tasks.indexWhere((task) => _taskPriority(task) > 0);
    if (featuredIndex > 0) {
      final featured = tasks.removeAt(featuredIndex);
      tasks.insert(0, featured);
    }
    return tasks;
  }

  int _taskPriority(Map<String, dynamic> task) =>
      task['isTaskOfDay'] == true ||
              task['isDaily'] == true ||
              task['isFeatured'] == true ||
              task['featured'] == true
          ? 1
          : 0;

  List<Map<String, dynamic>> _generalOffers() => _offers
      .whereType<Map>()
      .map((raw) => Map<String, dynamic>.from(raw))
      .where((offer) {
        final type = (offer['type'] ?? offer['category'] ?? '')
            .toString()
            .toUpperCase();
        return (offer['title'] ?? '').toString().trim().isNotEmpty &&
            !type.contains('TASK') &&
            !type.startsWith('INSTALL');
      })
      .toList();

  Widget _taskOfDay(BuildContext context) {
    if (_loadingHome) {
      return Container(
        height: 190,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      );
    }

    final tasks = _serverTasks();
    if (tasks.isEmpty) {
      final message = _offersUnavailable
          ? 'Tasks could not be loaded. Pull down to retry.'
          : 'No tasks have been published yet. Add one in the admin panel, then pull down to refresh.';
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.task_alt_rounded,
                  color: AppColors.primary, size: 25),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Task of the Day',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 5),
                  Text(message,
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                          height: 1.35)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final task = tasks.first;
    final title = (task['title'] ?? '').toString().trim();
    final description = (task['shortDesc'] ?? task['description'] ?? '')
        .toString()
        .trim();
    final provider = (task['provider'] ?? task['cat'] ?? '').toString();
    final rewardRaw = task['coins'] ?? task['rewardCoins'] ?? task['reward'];
    final reward = rewardRaw is num ? rewardRaw.toInt() : null;
    final durationRaw = task['durationMinutes'] ??
        task['duration'] ??
        task['timeEstimate'];
    final duration = durationRaw is num
        ? '${durationRaw.toInt()} min'
        : (durationRaw ?? '').toString().trim();
    final id = (task['id'] ??
            task['_id'] ??
            task['offerId'] ??
            task['providerOfferId'] ??
            '')
        .toString()
        .trim();
    final instructions = (task['instructions'] as List?)
            ?.map((step) => step.toString())
            .toList() ??
        const <String>[];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF8E9), Color(0xFFFFFDF7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.gold.withOpacity(0.38)),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        size: 14, color: AppColors.gold),
                    SizedBox(width: 5),
                    Text('TASK OF THE DAY',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.55)),
                  ],
                ),
              ),
              const Spacer(),
              if (provider.isNotEmpty)
                Text(provider,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 13),
          Text(title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  height: 1.2)),
          const SizedBox(height: 6),
          Text(
            description.isEmpty ? 'Open the task to see its instructions.' : description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12.5, height: 1.4),
          ),
          if (reward != null || duration.isNotEmpty || instructions.isNotEmpty) ...[
            const SizedBox(height: 13),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (reward != null)
                  _taskInfoChip(Icons.monetization_on_rounded,
                      '+${_fmt(reward)} coins'),
                if (duration.isNotEmpty)
                  _taskInfoChip(Icons.schedule_rounded, duration),
                if (instructions.isNotEmpty)
                  _taskInfoChip(Icons.list_alt_rounded,
                      '${instructions.length} steps'),
              ],
            ),
          ],
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () => _push(
                context,
                TaskDetailScreen(
                  provider: provider,
                  title: title,
                  desc: description,
                  coins: reward,
                  steps: instructions,
                  offerId: id,
                ),
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('View task details',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _taskInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: BalanceStream.instance,
      builder: (context, _) {
        final coins = BalanceStream.instance.value;

        return Scaffold(
          backgroundColor: AppColors.surface,
          body: SafeArea(
            child: RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.cardBackground,
              onRefresh: _refreshHome,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 104),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CvHeader(
                      showProfile: true,
                      profileLeft: true,
                      showMoney: coins != null,
                      coins: coins,
                      showWordmark: false,
                    ),
                    const SizedBox(height: 12),
                    _taskOfDay(context),
                    const SizedBox(height: 16),
                    _balanceSummary(context, coins),
                    const SizedBox(height: 20),
                    _sectionTitle('Quick Earn'),
                    const SizedBox(height: 10),
                    _quickEarn(context),
                    if (_loadingHome || _surveys.isNotEmpty || _surveysUnavailable) ...[
                      const SizedBox(height: 22),
                      _sectionTitle(
                        'Surveys',
                        action: 'View all',
                        onAction: () => _push(context, const SurveysScreen()),
                      ),
                      const SizedBox(height: 10),
                      _loadingHome ? _skeletonH() : _surveyRow(context),
                    ],
                    if (_loadingHome || _generalOffers().isNotEmpty || _offersUnavailable) ...[
                      const SizedBox(height: 22),
                      _sectionTitle(
                        'More offers',
                        action: 'View all',
                        onAction: () => _push(context, const EarnScreen()),
                      ),
                      const SizedBox(height: 10),
                      _loadingHome ? _skeletonH() : _limitedOffers(context),
                    ],
                    const SizedBox(height: 22),
                    _dailySpinCard(context),
                    const SizedBox(height: 14),
                    _inviteCard(context),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ───────────────────────── Promo carousel ───────────────────────────────
  // Slides are built from REAL offers fetched from the backend — never
  // hardcoded. If the backend returns no offers, the carousel is hidden.
  Widget _promoCarousel(BuildContext context) {
    final offers = _offers.whereType<Map>().where((m) => (m['title'] ?? '').toString().trim().isNotEmpty).take(5).toList();
    if (offers.isEmpty) return const SizedBox.shrink();

    const accents = [
      Color(0xFFF59E0B), Color(0xFF16A34A), Color(0xFF3B82F6),
      Color(0xFF8B5CF6), Color(0xFFEC4899),
    ];
    const accentSofts = [
      Color(0xFFFFF7E6), Color(0xFFE9F7EE), Color(0xFFEAF1FF),
      Color(0xFFF1ECFE), Color(0xFFFDF0F6),
    ];

    return HomeBannerCarousel(
      slides: [
        for (var i = 0; i < offers.length; i++)
          BannerSlide(
            title: offers[i]['title'].toString(),
            subtitle: (offers[i]['shortDesc'] ?? offers[i]['description'] ?? 'Tap to view offer').toString(),
            cta: 'View Offer',
            icon: Icons.local_offer_rounded,
            accent: accents[i % accents.length],
            accentSoft: accentSofts[i % accentSofts.length],
            imageAsset: i == 0 ? 'assets/bear_earn.png' : null,
            reward: offers[i]['coins'] is num
                ? '+${(offers[i]['coins'] as num).toInt()} Coins'
                : offers[i]['rewardCoins'] is num
                    ? '+${(offers[i]['rewardCoins'] as num).toInt()} Coins'
                    : '',
            onTap: () => _push(context, const EarnScreen()),
          ),
      ],
    );
  }

  // ───────────────────────── Balance summary ───────────────────────────────
  Widget _balanceSummary(BuildContext context, int? coins) {
    final earned = _todayEarned();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_rounded,
                  color: AppColors.primary, size: 19),
              const SizedBox(width: 7),
              const Text('Your wallet',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800)),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _push(context, const WithdrawScreen()),
                icon: const Icon(Icons.north_east_rounded, size: 15),
                label: const Text('Withdraw'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryDark,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Available balance',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 11.5)),
                    const SizedBox(height: 3),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Text(coins == null ? '—' : _fmt(coins),
                              style: GoogleFonts.inter(
                                  color: AppColors.textPrimary,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(width: 5),
                          const Text('coins',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                  width: 1,
                  height: 43,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: AppColors.border),
              Expanded(
                flex: 2,
                child: _miniStat(
                  'Earned today',
                  earned == null ? '—' : '+${_fmt(earned)}',
                  Icons.trending_up_rounded,
                  AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _push(context, const TrackingScreen()),
              icon: const Icon(Icons.history_rounded, size: 15),
              label: const Text('View activity'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryDark,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _cardDec(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text("Today's Earnings", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const Spacer(),
          GestureDetector(
            onTap: () => _push(context, const TrackingScreen()),
            child: Row(children: const [
              Text('View Activity', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
              Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.primary),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Text(earned == null ? '—' : '+${_fmt(earned)}', style: GoogleFonts.inter(
            fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primary, height: 1.1)),
          const SizedBox(width: 5),
          const Text('Coins earned today', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ]),
        const SizedBox(height: 8),
        Text(earned == null ? 'Activity earnings are unavailable.' : 'Based on dated activity records returned by the server.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
      ]),
    );
  }

  // ───────────────────────── Featured surveys ──────────────────────────────
  Widget _surveyRow(BuildContext context) {
    final surveys = _surveys.whereType<Map>().where((m) => (m['title'] ?? '').toString().trim().isNotEmpty).take(6).toList();
    if (surveys.isEmpty) {
      return _emptyRow(_surveysUnavailable
          ? 'Surveys could not be loaded. Pull down to retry.'
          : 'No surveys are available right now.');
    }
    final cards = surveys.map((m) {
      final reward = m['rewardCoins'] is num ? (m['rewardCoins'] as num).toInt() : (m['coins'] is num ? (m['coins'] as num).toInt() : null);
      final duration = m['durationMinutes'] ?? m['duration'];
      return _hCard(
        context: context,
        title: m['title'].toString(),
        sub: (m['provider'] ?? m['shortDesc'] ?? m['description'] ?? '').toString(),
        coins: reward,
        meta: duration is num && duration > 0 ? '${duration.toInt()} min' : '',
        chip: 'Survey',
        icon: Icons.poll_rounded,
        color: const Color(0xFF3B82F6),
        cta: 'Start',
        provider: (m['provider'] ?? '').toString(),
        onTap: () => _push(context, const SurveysScreen()),
      );
    }).toList();
    return SizedBox(height: 168, child: ListView.separated(
      scrollDirection: Axis.horizontal, itemCount: cards.length,
      separatorBuilder: (_, __) => const SizedBox(width: 10), itemBuilder: (_, i) => cards[i]));
  }

  Widget _tasksRow(BuildContext context) {
    final tasks = _offers.whereType<Map>().where((m) {
      final type = (m['type'] ?? '').toString().toUpperCase();
      final id = (m['id'] ?? m['_id'] ?? m['offerId'] ?? m['providerOfferId'] ?? '')
          .toString()
          .trim();
      return (type.startsWith('INSTALL') || type.contains('TASK')) &&
          (m['title'] ?? '').toString().trim().isNotEmpty &&
          id.isNotEmpty;
    }).take(6).toList();
    if (tasks.isEmpty) return _emptyRow('Task data is unavailable.');
    final cards = tasks.map((m) {
      final reward = m['coins'] is num ? (m['coins'] as num).toInt() : (m['rewardCoins'] is num ? (m['rewardCoins'] as num).toInt() : null);
      final duration = m['durationMinutes'] ?? m['duration'];
      return _hCard(
        context: context,
        title: (m['title'] ?? '').toString(),
        sub: (m['shortDesc'] ?? m['description'] ?? m['provider'] ?? '').toString(),
        coins: reward,
        meta: duration is num && duration > 0 ? '${duration.toInt()} min' : '',
        chip: 'Task',
        icon: Icons.task_alt_rounded,
        color: const Color(0xFF16A34A),
        cta: 'View Task',
        provider: (m['provider'] ?? '').toString(),
        onTap: () {
          final id = (m['id'] ?? m['_id'] ?? m['offerId'] ?? m['providerOfferId'] ?? '')
              .toString()
              .trim();
          final instructions = (m['instructions'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
          _push(context, TaskDetailScreen(
            provider: (m['provider'] ?? '').toString(),
            title: (m['title'] ?? '').toString(),
            desc: (m['shortDesc'] ?? m['description'] ?? '').toString(),
            coins: reward,
            steps: instructions,
            offerId: id.isEmpty ? null : id,
          ));
        },
      );
    }).toList();
    return SizedBox(height: 168, child: ListView.separated(
      scrollDirection: Axis.horizontal, itemCount: cards.length,
      separatorBuilder: (_, __) => const SizedBox(width: 10), itemBuilder: (_, i) => cards[i]));
  }

  Widget _hCard({
    required BuildContext context,
    required String title,
    required String sub,
    required int? coins,
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
          if (coins != null || meta.isNotEmpty)
            Row(children: [
              if (coins != null) ...[
                Icon(Icons.monetization_on_rounded, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text('+${_fmt(coins)} Coins', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary)),
              ],
              if (coins != null && meta.isNotEmpty) const SizedBox(width: 8),
              if (meta.isNotEmpty) ...[
                Icon(Icons.access_time_rounded, size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 3),
                Text(meta, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ]),
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
    final offers = _offers.whereType<Map>().where((m) => (m['title'] ?? '').toString().trim().isNotEmpty).toList();
    if (offers.isEmpty) {
      return _emptyRow(_offersUnavailable
          ? 'Offers could not be loaded. Pull down to retry.'
          : 'No offers are available right now.');
    }
    final offer = offers.first;
    final reward = offer['coins'] is num ? (offer['coins'] as num).toInt() : (offer['rewardCoins'] is num ? (offer['rewardCoins'] as num).toInt() : null);
    final steps = (offer['instructions'] as List?)?.take(4).toList() ?? const [];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primary.withOpacity(0.35), width: 1.5),
        boxShadow: AppShadows.card,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(gradient: AppColors.goldGradient, borderRadius: BorderRadius.circular(11)),
            child: const Icon(Icons.local_offer_rounded, color: Colors.white, size: 21)),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(offer['title'].toString(), maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 3),
            Text((offer['shortDesc'] ?? offer['description'] ?? '').toString(), maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
          ])),
          if (reward != null) Padding(padding: const EdgeInsets.only(left: 8), child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            const Text('Reward', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            Text('+${_fmt(reward)}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.primary)),
          ])),
        ]),
        if (steps.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(children: [for (int i = 0; i < steps.length; i++) ...[
            _milestone(i + 1, steps[i].toString(), i == 0 ? AppColors.primary : AppColors.border),
            if (i != steps.length - 1) Expanded(child: Container(height: 2, color: AppColors.border, margin: const EdgeInsets.symmetric(horizontal: 4))),
          ]]),
        ],
        const SizedBox(height: 13),
        SizedBox(width: double.infinity, height: 38, child: ElevatedButton(
          onPressed: () => _push(context, const EarnScreen()),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md))),
          child: const Text('View Offer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
        )),
      ]),
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
      ('Surveys', Icons.poll_rounded, const Color(0xFF3B82F6), () => _push(context, const SurveysScreen())),
      ('Quizzes', Icons.school_rounded, const Color(0xFF10B981), () => _push(context, const QuizScreen())),
      ('Tasks', Icons.task_alt_rounded, const Color(0xFFF59E0B), () => _push(context, const EarnScreen())),
      ('Offers', Icons.local_offer_rounded, const Color(0xFF8B5CF6), () => _push(context, const EarnScreen())),
      ('Scratch', Icons.grid_view_rounded, const Color(0xFFEC4899), () => _push(context, const ScratchScreen())),
      ('Spin', Icons.donut_large_rounded, const Color(0xFF14B8A6), () => _push(context, const SpinScreen())),
    ];
    return GridView.count(
      crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 9, crossAxisSpacing: 9, childAspectRatio: 1.15,
      children: items.map((it) => GestureDetector(
        onTap: it.$4,
        child: Container(padding: const EdgeInsets.all(10), decoration: _cardDec(), child: Column(
          mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 34, height: 34, decoration: BoxDecoration(color: it.$3.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(it.$2, size: 18, color: it.$3)),
            const SizedBox(height: 6),
            Text(it.$1, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ],
        )),
      )).toList(),
    );
  }

  // ───────────────────────── Recommended ───────────────────────────────────
  Widget _recommendedRow(BuildContext context) {
    // Built from REAL backend data — surveys + offers. Never hardcoded.
    final recs = <Map<String, dynamic>>[];
    for (final s in _surveys.whereType<Map>().where((m) => (m['title'] ?? '').toString().trim().isNotEmpty).take(2)) {
      final reward = s['rewardCoins'] ?? s['coins'] ?? s['reward'];
      if (reward is! num) continue;
      recs.add({
        't': s['title'].toString(),
        'c': reward.toInt(),
        'm': 'Survey',
        'i': Icons.poll_rounded,
        'col': const Color(0xFF3B82F6),
        'cta': 'Take Survey',
        'go': () => _push(context, const SurveysScreen()),
      });
    }
    for (final o in _offers.whereType<Map>().where((m) => (m['title'] ?? '').toString().trim().isNotEmpty).take(2)) {
      final reward = o['coins'] ?? o['rewardCoins'];
      if (reward is! num) continue;
      recs.add({
        't': o['title'].toString(),
        'c': reward.toInt(),
        'm': 'Offer',
        'i': Icons.local_offer_rounded,
        'col': AppColors.primary,
        'cta': 'View Offer',
        'go': () => _push(context, const EarnScreen()),
      });
    }
    if (recs.isEmpty) return const SizedBox.shrink();
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
    final high = _offers.whereType<Map>()
        .where((o) => (o['title'] ?? '').toString().trim().isNotEmpty && (o['coins'] is num || o['rewardCoins'] is num))
        .toList()
      ..sort((a, b) {
        final aCoins = a['coins'] is num ? (a['coins'] as num).toInt() : (a['rewardCoins'] as num).toInt();
        final bCoins = b['coins'] is num ? (b['coins'] as num).toInt() : (b['rewardCoins'] as num).toInt();
        return bCoins.compareTo(aCoins);
      });
    final selected = high.take(4).toList();
    if (selected.isEmpty) return const SizedBox.shrink(); // no fake fallback
    return Column(
      children: selected.map((m) {
        final coins = m['coins'] is num ? (m['coins'] as num).toInt() : (m['rewardCoins'] as num).toInt();
        final provider = (m['provider'] ?? m['cat'] ?? '').toString();
        final title = m['title'].toString();
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
                          Text(m['title'].toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text((m['cat'] ?? m['provider'] ?? '').toString(),
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
    final used = _spinStatus?['spinsUsed'];
    final limit = _spinStatus?['dailyLimit'];
    final canSpin = _spinStatus?['canSpin'];
    final String statusLabel = used is num && limit is num && used >= 0 && limit >= 0
        ? '${(limit.toInt() - used.toInt()).clamp(0, limit.toInt())} of ${limit.toInt()} spins available'
        : canSpin == true
            ? 'A spin is available'
            : canSpin == false
                ? 'No spins currently available'
                : 'Spin availability unavailable';
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(gradient: AppColors.goldGradient, borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: const [Icon(Icons.donut_large_rounded, color: Colors.white, size: 19), SizedBox(width: 7),
            Text('Spin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white))]),
          const SizedBox(height: 6),
          Text(statusLabel, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 11),
          GestureDetector(onTap: () => _push(context, const SpinScreen()), child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.full)),
            child: const Text('Open Spin', style: TextStyle(color: AppColors.primaryDark, fontSize: 13, fontWeight: FontWeight.w800)),
          )),
        ])),
        const SizedBox(width: 10),
        Container(width: 78, height: 78, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.18),
          border: Border.all(color: Colors.white.withOpacity(0.55), width: 2)),
          child: ClipOval(child: Image.asset('assets/wheel.png', fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(Icons.donut_large_rounded, color: Colors.white, size: 38))),
        ),
      ]),
    );
  }

  // ───────────────────────── Daily missions ────────────────────────────────
  Widget _missionsRow(BuildContext context) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16), decoration: _cardDec(),
      child: Row(children: [
        const Icon(Icons.flag_rounded, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        const Expanded(child: Text('Mission progress is unavailable.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5))),
        TextButton(onPressed: () => _push(context, const MissionsScreen()), child: const Text('Open')),
      ]),
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
                    Text('Invite Friends',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text('Share your referral link with friends',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
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
    final offers = _generalOffers().take(5).toList();
    if (offers.isEmpty) {
      return _emptyRow(_offersUnavailable
          ? 'Offers could not be loaded. Pull down to retry.'
          : 'No offers are available right now.');
    }
    return SizedBox(height: 150, child: ListView.separated(
      scrollDirection: Axis.horizontal, itemCount: offers.length,
      separatorBuilder: (_, __) => const SizedBox(width: 10),
      itemBuilder: (_, i) {
        final offer = offers[i];
        final reward = offer['coins'] is num ? (offer['coins'] as num).toInt() : (offer['rewardCoins'] is num ? (offer['rewardCoins'] as num).toInt() : null);
        return Container(width: 190, padding: const EdgeInsets.all(13), decoration: _cardDec(), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Container(width: 30, height: 30, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.local_offer_rounded, size: 16, color: AppColors.primary)), const Spacer(),
              const Text('Offer', style: TextStyle(fontSize: 10, color: AppColors.textSecondary))]),
            const SizedBox(height: 9),
            Text(offer['title'].toString(), maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 3),
            Text((offer['shortDesc'] ?? offer['description'] ?? '').toString(), maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const Spacer(),
            Row(children: [
              if (reward != null) Text('+${_fmt(reward)} Coins', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.primary)),
              const Spacer(),
              GestureDetector(onTap: () => _push(context, const EarnScreen()), child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.full)),
                child: const Text('View Offer', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800)),
              )),
            ]),
          ],
        ));
      },
    ));
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
                  if ((top[i] as Map)['coinsEarned'] is num)
                    Text('+${_fmt(((top[i] as Map)['coinsEarned'] as num).truncate())}',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.primary)),
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
