import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_theme.dart';
import '../core/provider_logos.dart';
import '../services/app_repository.dart';
import '../services/balance_stream.dart';
import '../services/auth_service.dart';
import '../widgets/cv_header.dart';
import 'earn_screen.dart';
import 'help_screen.dart';
import 'offerwall_screen.dart';
import 'provider_tasks_screen.dart';
import 'task_detail_screen.dart';
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

/// Home tab matching the COINIVO-style mockup:
/// header → green balance hero → Task of the Day grid → Earn More bar →
/// horizontal Surveys → Task Providers → Ludo double-coins banner.
/// All data stays server-authoritative (BalanceStream + AppRepository).
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<dynamic> _surveys = [];
  List<dynamic> _tasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = AppRepository.instance;
    final results = await Future.wait<dynamic>([
      repo.fetchSurveys(),
      repo.fetchOffers(),
    ]);
    if (!mounted) return;
    setState(() {
      _surveys = (results[0] as List<dynamic>?) ?? [];
      _tasks = ((results[1] as List<dynamic>?) ?? [])
          .where((o) =>
              ((o['type'] ?? '').toString().toUpperCase().startsWith('INSTALL')) ||
              ((o['type'] ?? '').toString().toUpperCase().startsWith('TASK')) ||
              ((o['coins'] ?? 0) as num) > 0)
          .take(6)
          .toList();
      _loading = false;
    });
  }

  void _push(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  String _reward(num coins) {
    final c = coins.toInt();
    if (c >= 1000) {
      final k = c / 1000.0;
      return '+ ${k == k.roundToDouble() ? k.toInt() : k.toStringAsFixed(1)}k';
    }
    final s = c.toString();
    return '+ ${s.length > 3 ? '${s.substring(0, s.length - 1)}.${s.substring(s.length - 1)}' : s}';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AuthService(), BalanceStream.instance]),
      builder: (context, _) {
        final user = AuthService().userModel;
        final coins = BalanceStream.instance.value ?? user?.coins ?? 0;

        return Scaffold(
          backgroundColor: const Color(0xFFFAFAF8),
          body: SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
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
                    _balanceHero(coins),
                    const SizedBox(height: 18),
                    _sectionHeader('Task of the Day', 'See all',
                        () => _push(const EarnScreen())),
                    const SizedBox(height: 12),
                    _loading ? _gridSkeleton() : _tasksGrid(),
                    const SizedBox(height: 18),
                    _earnMoreBar(),
                    const SizedBox(height: 18),
                    _sectionHeader('Surveys', 'View All',
                        () => _push(const SurveysScreen())),
                    const SizedBox(height: 12),
                    _surveysRow(),
                    const SizedBox(height: 18),
                    _sectionHeader('Task Providers', 'View All',
                        () => _push(const OfferwallScreen())),
                    const SizedBox(height: 12),
                    _providersRow(),
                    const SizedBox(height: 14),
                    _ludoBanner(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sectionHeader(String title, String action, VoidCallback onTap) {
    return Row(
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF171717))),
        const Spacer(),
        GestureDetector(
          onTap: onTap,
          child: Text('$action →',
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8B5CF6))),
        ),
      ],
    );
  }

  // ─── Green balance hero (mockup) ────────────────────────────────────────
  Widget _balanceHero(int coins) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF22A06B), Color(0xFF0E7C4A)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF22A06B).withOpacity(0.30),
              blurRadius: 18,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: Color(0xFFF59E0B)),
            child: const Center(
              child: Text('C',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your Balance',
                    style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                const SizedBox(height: 2),
                Text('$coins',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        height: 1.0)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _push(const WithdrawScreen()),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.card_giftcard_rounded,
                      size: 16, color: Color(0xFF0E7C4A)),
                  SizedBox(width: 6),
                  Text('Redeem',
                      style: TextStyle(
                          color: Color(0xFF0E7C4A),
                          fontSize: 13,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Task of the Day grid (real offers) ─────────────────────────────────
  Widget _tasksGrid() {
    if (_tasks.isEmpty) {
      return _emptyNote('No tasks live right now. Pull to refresh.');
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _tasks.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.78,
      ),
      itemBuilder: (context, i) {
        final t = _tasks[i] as Map;
        final title = (t['title'] ?? 'Task').toString();
        final sub = (t['shortDesc'] ?? t['description'] ?? '').toString();
        final coins = (t['coins'] ?? 0) as num;
        return GestureDetector(
          onTap: () => _push(TaskDetailScreen(
            provider: 'CoinVault Partner',
            title: title,
            desc: sub,
            coins: coins.toInt(),
            steps: ((t['instructions'] ?? []) as List)
                .map((e) => e.toString())
                .toList(),
          )),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE7E7E7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProviderLogo(title, size: 38, radius: 10),
                const SizedBox(height: 8),
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF171717))),
                const SizedBox(height: 2),
                Expanded(
                  child: Text(sub,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 10.5,
                          height: 1.25,
                          color: Color(0xFF6B7280))),
                ),
                const SizedBox(height: 6),
                _rewardChip(_reward(coins)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _gridSkeleton() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.78,
      children: List.generate(
          6,
          (_) => Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFEFEFEC),
                  borderRadius: BorderRadius.circular(14),
                ),
              )),
    );
  }

  Widget _rewardChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3D6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle, size: 10, color: Color(0xFFF59E0B)),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFB45309))),
        ],
      ),
    );
  }

  // ─── Earn More bar ──────────────────────────────────────────────────────
  Widget _earnMoreBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Earn More..',
            style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF171717))),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1B1B1F),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _earnItem(Icons.monetization_on_rounded, 'Spin & earn',
                  () => _push(const SpinScreen())),
              _earnItem(Icons.emoji_events_rounded, 'Challenge',
                  () => _push(const MissionsScreen())),
              _earnItem(Icons.group_add_rounded, 'Refer & earn',
                  () => _push(const InviteScreen())),
              _earnItem(Icons.menu_book_rounded, 'Tutorial',
                  () => _push(const HelpScreen())),
            ],
          ),
        ),
      ],
    );
  }

  Widget _earnItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 26),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ─── Surveys row (real surveys) ─────────────────────────────────────────
  Widget _surveysRow() {
    if (_loading) return _rowSkeleton();
    if (_surveys.isEmpty) return _emptyNote('No surveys live right now.');
    return SizedBox(
      height: 128,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _surveys.length > 6 ? 6 : _surveys.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final s = _surveys[i] as Map;
          final title = (s['title'] ?? 'Survey').toString();
          final coins = ((s['coins'] ?? 0) as num).toInt();
          final mins = ((s['minutes'] ?? s['duration'] ?? 0) as num).toInt();
          return GestureDetector(
            onTap: () => _push(const SurveysScreen()),
            child: Container(
              width: 130,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE7E7E7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF1FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.assignment_rounded,
                        size: 18, color: Color(0xFF3B82F6)),
                  ),
                  const SizedBox(height: 8),
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF171717))),
                  const SizedBox(height: 4),
                  _rewardChip('+ $coins'),
                  const Spacer(),
                  if (mins > 0)
                    Text('$mins mins',
                        style: const TextStyle(
                            fontSize: 10.5, color: Color(0xFF6B7280))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Task providers row ─────────────────────────────────────────────────
  Widget _providersRow() {
    const providers = [
      ('CPX Research', '+ 30 - 300'),
      ('BitLabs', '+ 50 - 400'),
      ('Pollfish', '+ 10 - 250'),
      ('AdScend', '+ 20 - 200'),
      ('Lootably', '+ 5 - 150'),
    ];
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: providers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final (name, range) = providers[i];
          return GestureDetector(
            onTap: () => _push(ProviderTasksScreen(provider: name)),
            child: Container(
              width: 118,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE7E7E7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProviderLogo(name, size: 34, radius: 10),
                  const SizedBox(height: 8),
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF171717))),
                  const SizedBox(height: 4),
                  Text(range,
                      style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF59E0B))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Ludo double-coins banner ───────────────────────────────────────────
  Widget _ludoBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.celebration_rounded,
              color: Colors.white, size: 30),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Play Ludo & Double Coins',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800)),
                SizedBox(height: 2),
                Text('Earn up to 500 coins',
                    style: TextStyle(color: Colors.white70, fontSize: 11.5)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _push(const EarnScreen()),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text('Double Up',
                  style: TextStyle(
                      color: Color(0xFF6D28D9),
                      fontSize: 12,
                      fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowSkeleton() {
    return SizedBox(
      height: 128,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, __) => Container(
          width: 130,
          decoration: BoxDecoration(
            color: const Color(0xFFEFEFEC),
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _emptyNote(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7E7E7)),
      ),
      child: Text(msg,
          style:
              const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
    );
  }
}
