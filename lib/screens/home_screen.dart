import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../services/app_repository.dart';
import '../services/balance_stream.dart';
import '../widgets/app_logo.dart';
import 'earn_screen.dart';
import 'help_screen.dart';
import 'invite_screen.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart';
import 'quiz_screen.dart';
import 'spin_screen.dart';
import 'surveys_screen.dart';
import 'task_detail_screen.dart';
import 'tracking_screen.dart';
import 'withdraw_screen.dart';

/// Main user app shell. The existing tab destinations are unchanged.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  Widget _currentPage() => switch (_currentIndex) {
        0 => const HomeTab(),
        1 => const EarnScreen(),
        2 => const LeaderboardScreen(),
        3 => const SurveysScreen(),
        _ => const WithdrawScreen(),
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _currentPage(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        height: 72,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.bolt_outlined),
            selectedIcon: Icon(Icons.bolt_rounded),
            label: 'Earn',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events_rounded),
            label: 'Ranks',
          ),
          NavigationDestination(
            icon: Icon(Icons.poll_outlined),
            selectedIcon: Icon(Icons.poll_rounded),
            label: 'Surveys',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Wallet',
          ),
        ],
      ),
    );
  }
}

/// API-backed home dashboard. The reference image informs spacing and hierarchy,
/// never the offers, survey names, amounts, badges, or promotional copy.
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<Map<String, dynamic>> _offers = [];
  List<dynamic> _surveys = [];
  List<dynamic> _activity = [];
  bool _loading = true;
  bool _offersUnavailable = false;
  bool _surveysUnavailable = false;
  int _loadRevision = 0;
  final PageController _carouselController = PageController();
  Timer? _carouselTimer;
  int _carouselIndex = 0;

  static const _carouselImages = <String>[
    'assets/bear_tasks.png',
    'assets/bear_earn.png',
    'assets/wheel.png',
    'assets/trophy.png',
    'assets/bear_redeem.png',
  ];
  static const _carouselTitles = <String>[
    'Find your next task',
    'Explore surveys',
    'Try the daily spin',
    'Check the rankings',
    'Redeem your coins',
  ];
  static const _carouselSubtitles = <String>[
    'Browse activities available to you',
    'See surveys currently listed',
    'Check today’s spin availability',
    'See how you rank this week',
    'View the withdrawal options',
  ];
  static const _carouselCtas = <String>[
    'Browse tasks',
    'View surveys',
    'Open spin',
    'See rankings',
    'Open wallet',
  ];
  static const _carouselColors = <List<Color>>[
    [Color(0xFF164C18), Color(0xFF2B7A24)],
    [Color(0xFF075E68), Color(0xFF168A88)],
    [Color(0xFF4C2B9D), Color(0xFF8052D5)],
    [Color(0xFF9A4F16), Color(0xFFDC8A1C)],
    [Color(0xFF173F7A), Color(0xFF2872B0)],
  ];

  @override
  void initState() {
    super.initState();
    _loadHome();
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_carouselController.hasClients) return;
      final next = (_carouselIndex + 1) % _carouselImages.length;
      _carouselController.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _carouselController.dispose();
    super.dispose();
  }

  Future<void> _loadHome() async {
    final revision = ++_loadRevision;
    // Hide an old account's balance and never display a guessed value while
    // the authenticated, server-authoritative wallet is being refreshed.
    BalanceStream.instance.clear();
    if (mounted) {
      setState(() {
        _loading = true;
        _activity = [];
      });
    }
    final results = await Future.wait<dynamic>([
      AppRepository.instance.fetchOffers(),
      AppRepository.instance.fetchSurveys(),
      AppRepository.instance.fetchWalletBalance(),
      AppRepository.instance.fetchActivity(),
    ]);
    if (!mounted || revision != _loadRevision) return;

    final rawOffers = results[0] as List<dynamic>?;
    final rawSurveys = results[1] as List<dynamic>?;
    setState(() {
      _offersUnavailable = rawOffers == null;
      _surveysUnavailable = rawSurveys == null;
      _offers = (rawOffers ?? const <dynamic>[])
          .whereType<Map>()
          .map((offer) => Map<String, dynamic>.from(offer))
          .toList();
      _surveys = rawSurveys ?? [];
      _activity = (results[3] as List<dynamic>?) ?? [];
      _loading = false;
    });
  }

  String _offerId(Map<String, dynamic> offer) =>
      (offer['id'] ?? offer['_id'] ?? offer['offerId'] ??
              offer['providerOfferId'] ?? '')
          .toString()
          .trim();

  String _offerTitle(Map<String, dynamic> offer) =>
      (offer['title'] ?? offer['name'] ?? '').toString().trim();

  DateTime? _dateValue(dynamic value) {
    if (value is num) {
      final millis = value > 1e12 ? value.toInt() : value.toInt() * 1000;
      return DateTime.fromMillisecondsSinceEpoch(millis).toLocal();
    }
    if (value is String) return DateTime.tryParse(value)?.toLocal();
    return null;
  }

  bool _isOfferAvailable(Map<String, dynamic> offer) {
    final status = (offer['status'] ?? '').toString().trim().toLowerCase();
    if (offer['isActive'] == false ||
        offer['active'] == false ||
        offer['isExpired'] == true ||
        status == 'inactive' ||
        status == 'expired' ||
        status == 'disabled') {
      return false;
    }
    final now = DateTime.now();
    final start = _dateValue(offer['startDate']);
    final end = _dateValue(offer['endDate']);
    if (start != null && now.isBefore(start)) return false;
    if (end != null) {
      final rawEnd = offer['endDate'];
      final effectiveEnd = rawEnd is String && rawEnd.trim().length <= 10
          ? DateTime(end.year, end.month, end.day, 23, 59, 59, 999)
          : end;
      if (now.isAfter(effectiveEnd)) return false;
    }
    return true;
  }

  List<Map<String, dynamic>> _serverTasks() {
    final tasks = _offers.where((offer) {
      final type = (offer['type'] ?? offer['category'] ?? '')
          .toString()
          .toUpperCase();
      final taskTagged = type.contains('TASK') ||
          type.startsWith('INSTALL') ||
          type.contains('GAME') ||
          type.contains('MULTI') ||
          offer['isTaskOfDay'] == true ||
          offer['isDaily'] == true ||
          offer['isFeatured'] == true;
      final genericOffer = type.isEmpty ||
          (!type.contains('SURVEY') &&
              !type.contains('OFFERWALL') &&
              !type.contains('PAYMENTWALL'));
      return _isOfferAvailable(offer) &&
          (taskTagged || genericOffer) &&
          _offerTitle(offer).isNotEmpty &&
          _offerId(offer).isNotEmpty;
    }).toList();

    int priority(Map<String, dynamic> task) {
      if (task['isTaskOfDay'] == true ||
          task['isDaily'] == true ||
          task['isFeatured'] == true) return 3;
      final type =
          (task['type'] ?? task['category'] ?? '').toString().toUpperCase();
      if (type.contains('TASK')) return 2;
      if (type.contains('GAME') || type.contains('MULTI')) return 1;
      return 0;
    }

    tasks.sort((a, b) => priority(b).compareTo(priority(a)));
    return tasks;
  }

  List<Map<String, dynamic>> _taskGridItems() =>
      _serverTasks().take(6).toList();

  List<Map<String, dynamic>> _multiStepContent() {
    final shownIds = _taskGridItems().map(_offerId).toSet();
    return _offers.where((offer) {
      final type = (offer['type'] ?? offer['category'] ?? '')
          .toString()
          .toUpperCase();
      final steps = offer['instructions'];
      final id = _offerId(offer);
      return _isOfferAvailable(offer) &&
          id.isNotEmpty &&
          !shownIds.contains(id) &&
          (type.contains('GAME') ||
              type.contains('MULTI') ||
              (steps is List && steps.length > 1)) &&
          _offerTitle(offer).isNotEmpty;
    }).toList();
  }

  List<Map<String, dynamic>> _remainingTasks() {
    final shownIds = _taskGridItems().map(_offerId).toSet();
    final multiIds = _multiStepContent().map(_offerId).toSet();
    return _serverTasks()
        .where((task) =>
            !shownIds.contains(_offerId(task)) &&
            !multiIds.contains(_offerId(task)))
        .toList();
  }

  List<Map<String, dynamic>> _otherOffers() {
    final taskIds = _serverTasks().map(_offerId).toSet();
    return _offers.where((offer) {
      final type = (offer['type'] ?? offer['category'] ?? '')
          .toString()
          .toUpperCase();
      return _isOfferAvailable(offer) &&
          _offerTitle(offer).isNotEmpty &&
          _offerId(offer).isNotEmpty &&
          !taskIds.contains(_offerId(offer)) &&
          (type.contains('OFFERWALL') || type.contains('PAYMENTWALL'));
    }).toList();
  }

  void _push(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  void _openOffer(Map<String, dynamic> offer) {
    final instructions = offer['instructions'];
    final steps = instructions is List
        ? instructions
            .where((step) => step != null && step.toString().trim().isNotEmpty)
            .map((step) => step.toString())
            .toList()
        : const <String>[];
    _push(TaskDetailScreen(
      provider: (offer['provider'] ?? offer['providerName'] ?? '').toString(),
      title: _offerTitle(offer),
      desc: (offer['shortDesc'] ?? offer['description'] ?? '').toString(),
      coins: null,
      steps: steps,
      offerId: _offerId(offer),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: BalanceStream.instance,
      builder: (context, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _homeTopBar(BalanceStream.instance.value),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.surface,
                onRefresh: _loadHome,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  children: [
                    _homeCarousel(),
                    const SizedBox(height: 12),
                    _taskSection(),
                    const SizedBox(height: 18),
                    _quickAccess(),
                    const SizedBox(height: 20),
                    _sectionHeader(
                      'Surveys',
                      action: 'View All',
                      onAction: () => _push(const SurveysScreen()),
                    ),
                    const SizedBox(height: 9),
                    _surveyList(),
                    const SizedBox(height: 20),
                    _sectionHeader(
                      'Task Providers',
                      action: 'View All',
                      onAction: () => _push(const EarnScreen()),
                    ),
                    const SizedBox(height: 9),
                    _providerStrip(),
                    if (_loading || _multiStepContent().isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _sectionHeader(
                        'Games & multi-step tasks',
                        action: 'View All',
                        onAction: () => _push(const EarnScreen()),
                      ),
                      const SizedBox(height: 9),
                      _offerRows(_multiStepContent().take(4).toList(),
                          Icons.sports_esports_rounded,
                          const Color(0xFF6853B9)),
                    ],
                    if (_remainingTasks().isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _sectionHeader('More tasks',
                          icon: Icons.task_alt_rounded,
                          action: 'View All',
                          onAction: () => _push(const EarnScreen())),
                      const SizedBox(height: 9),
                      _offerRows(_remainingTasks().take(4).toList(),
                          Icons.task_alt_rounded, AppColors.success),
                    ],
                    if (_otherOffers().isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _sectionHeader('More offers',
                          icon: Icons.local_offer_rounded,
                          action: 'View All',
                          onAction: () => _push(const EarnScreen())),
                      const SizedBox(height: 9),
                      _offerRows(_otherOffers().take(3).toList(),
                          Icons.local_offer_rounded, AppColors.primaryDark),
                    ],
                    if (_recentActivities().isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _sectionHeader('Recent activity',
                          icon: Icons.history_rounded,
                          action: 'View All',
                          onAction: () => _push(const TrackingScreen())),
                      const SizedBox(height: 9),
                      ..._recentActivities().map(_recentActivityRow),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _recentActivities() => _activity
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .where((item) =>
          (item['type'] ?? item['action'] ?? item['title'] ??
                  item['category'] ?? item['transactionType'] ?? '')
              .toString()
              .trim()
              .isNotEmpty)
      .take(3)
      .toList();

  Widget _recentActivityRow(Map<String, dynamic> item) {
    final title = (item['type'] ?? item['action'] ?? item['title'] ??
            item['category'] ?? item['transactionType'] ?? '')
        .toString()
        .trim();
    final status = (item['status'] ?? item['state'] ?? '').toString().trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _activityRow(
        icon: Icons.history_rounded,
        title: title,
        detail: status,
        color: AppColors.primary,
        onTap: () => _push(const TrackingScreen()),
      ),
    );
  }

  Widget _homeTopBar(int? balance) {
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 19),
          child: Row(
            children: [
              InkWell(
                onTap: () => _push(const ProfileScreen()),
                borderRadius: BorderRadius.circular(20),
                child: ClipOval(
                  child: Image.asset(
                    'assets/bear_avatar.png',
                    width: 34,
                    height: 34,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const CircleAvatar(
                      radius: 17,
                      child: Icon(Icons.person_rounded),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF7047F7), Color(0xFF9A55FF)],
                  ),
                ),
                child: const Icon(Icons.bolt_rounded,
                    color: Colors.white, size: 21),
              ),
              const SizedBox(width: 7),
              const Text('COINVAULT',
                  style: TextStyle(
                      color: Color(0xFF6642E8),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .4)),
              const Spacer(),
              Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0D8),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 25,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF25282B),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded,
                        color: Color(0xFFFFC43D), size: 15),
                  ),
                  const SizedBox(width: 5),
                  Text(balance == null ? '—' : _formatNumber(balance),
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800)),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _homeCarousel() {
    return SizedBox(
      height: 132,
      child: Stack(
        children: [
          PageView.builder(
            controller: _carouselController,
            itemCount: _carouselImages.length,
            onPageChanged: (index) => setState(() => _carouselIndex = index),
            itemBuilder: (context, index) {
              final colors = _carouselColors[index];
              return ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: colors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 15,
                        top: 14,
                        bottom: 22,
                        right: 118,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_carouselTitles[index],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    height: 1.1)),
                            const SizedBox(height: 5),
                            Text(_carouselSubtitles[index],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(.86),
                                    fontSize: 10,
                                    height: 1.2)),
                            const Spacer(),
                            InkWell(
                              onTap: () => _openCarouselSlide(index),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(_carouselCtas[index],
                                        style: TextStyle(
                                            color: colors.last,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800)),
                                    const SizedBox(width: 3),
                                    Icon(Icons.arrow_forward_rounded,
                                        color: colors.last, size: 12),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 4,
                        bottom: 4,
                        right: 5,
                        width: 120,
                        child: Image.asset(
                          _carouselImages[index],
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.auto_awesome_rounded,
                              color: Colors.white,
                              size: 48),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Positioned(
            bottom: 6,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_carouselImages.length, (index) {
                final active = index == _carouselIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: active ? 12 : 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(active ? .95 : .48),
                    borderRadius: BorderRadius.circular(5),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  void _openCarouselSlide(int index) {
    switch (index) {
      case 0:
        _push(const EarnScreen());
        break;
      case 1:
        _push(const SurveysScreen());
        break;
      case 2:
        _push(const SpinScreen());
        break;
      case 3:
        _push(const LeaderboardScreen());
        break;
      default:
        _push(const WithdrawScreen());
    }
  }

  Widget _quickAccess() {
    final actions = <_QuickAction>[
      _QuickAction('Spin & earn', Icons.stars_rounded, const Color(0xFFFFC344),
          () => _push(const SpinScreen())),
      _QuickAction('Challenge', Icons.emoji_events_rounded,
          const Color(0xFFFFC344), () => _push(const QuizScreen())),
      _QuickAction('Refer & earn', Icons.person_add_alt_1_rounded,
          const Color(0xFFFFC344), () => _push(const InviteScreen())),
      _QuickAction('Tutorial', Icons.menu_book_rounded,
          const Color(0xFFFFC344), () => _push(const HelpScreen())),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 1, bottom: 6),
          child: Text('Earn More..',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800)),
        ),
        Container(
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF171D22),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            children: actions.map((action) => Expanded(
              child: InkWell(
                onTap: action.onTap,
                borderRadius: BorderRadius.circular(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(action.icon, color: action.color, size: 21),
                    const SizedBox(height: 3),
                    Text(action.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _taskSection() {
    final tasks = _taskGridItems();
    return Container(
      padding: EdgeInsets.zero,
      decoration: const BoxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHeader('Task of the Day'),
          const SizedBox(height: 13),
          if (_loading)
            _taskGridSkeleton()
          else if (tasks.isEmpty)
            _emptyCard(
              icon: Icons.task_alt_rounded,
              title: _offersUnavailable
                  ? 'Tasks could not load'
                  : 'No tasks posted yet',
              message: _offersUnavailable
                  ? 'Pull down to retry.'
                  : 'New tasks will appear here when available.',
              actionLabel: _offersUnavailable ? 'Retry' : null,
              onAction: _offersUnavailable ? _loadHome : null,
            )
          else
            LayoutBuilder(builder: (context, constraints) {
              final columns = constraints.maxWidth >= 300 ? 3 : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tasks.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  mainAxisExtent: 106,
                ),
                itemBuilder: (context, index) => _taskTile(tasks[index]),
              );
            }),
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
            child: TextButton(
              onPressed: () => _push(const EarnScreen()),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.surfaceVariant,
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('See all tasks'),
                  SizedBox(width: 5),
                  Icon(Icons.arrow_forward_rounded, size: 17),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  int? _taskReward(Map<String, dynamic> task) {
    final value = task['rewardCoins'] ?? task['coins'] ?? task['coinReward'];
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  Widget _taskTile(Map<String, dynamic> task) {
    final title = _offerTitle(task);
    final provider =
        (task['provider'] ?? task['providerName'] ?? '').toString().trim();
    final detail = (task['shortDesc'] ?? task['description'] ?? provider)
        .toString()
        .trim();
    final reward = _taskReward(task);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: () => _openOffer(task),
        borderRadius: BorderRadius.circular(11),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFDDE2FA)),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppLogo(
                provider: provider,
                title: title,
                size: 32,
                radius: 9,
                fallbackIcon: Icons.task_alt_rounded,
              ),
              const SizedBox(height: 4),
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800)),
              if (detail.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 8)),
              ],
              const Spacer(),
              Container(
                constraints: const BoxConstraints(minHeight: 22),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBE8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFE77A)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (reward != null) ...[
                    const Icon(Icons.monetization_on_rounded,
                        color: Color(0xFFFFB300), size: 13),
                    const SizedBox(width: 3),
                    Text(_formatNumber(reward),
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w800)),
                  ] else
                    const Text('View task',
                        style: TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 9,
                            fontWeight: FontWeight.w700)),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _taskGridSkeleton() => LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth >= 300 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: columns * 2,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            mainAxisExtent: 106,
          ),
          itemBuilder: (_, __) => Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(13),
            ),
          ),
        );
      });

  Widget _surveyList() {
    if (_loading) return _surveySkeleton();
    final surveys = _surveys.whereType<Map>().map((item) =>
        Map<String, dynamic>.from(item)).where((survey) =>
        _isOfferAvailable(survey) &&
        _offerTitle(survey).isNotEmpty &&
        (survey['id'] ?? survey['_id'] ?? survey['surveyId'] ?? '')
            .toString()
            .trim()
            .isNotEmpty).take(12).toList();
    if (surveys.isEmpty) {
      return _emptyCard(
        icon: Icons.poll_rounded,
        title: _surveysUnavailable
            ? 'Surveys could not load'
            : 'No surveys available',
        message: _surveysUnavailable
            ? 'Pull down to try again.'
            : 'New surveys will appear here when available.',
        actionLabel: _surveysUnavailable ? 'Retry' : null,
        onAction: _surveysUnavailable ? _loadHome : null,
      );
    }
    return SizedBox(
      height: 100,
      child: LayoutBuilder(builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - 18) / 4;
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: surveys.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (context, index) {
            final survey = surveys[index];
            final title = (survey['title'] ?? '').toString().trim();
            final provider = (survey['provider'] ?? '').toString().trim();
            final reward = _taskReward(survey);
            final rawDuration = survey['duration'] ??
                survey['estimatedDuration'] ?? survey['durationMinutes'];
            final duration = rawDuration is num
                ? '${rawDuration.toInt()} min'
                : (rawDuration ?? '').toString().trim();
            return SizedBox(
              width: tileWidth,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () => _push(SurveysScreen(
                      initialProvider: provider.isEmpty ? null : provider)),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFD6EBDD)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppLogo(
                          provider: provider,
                          title: title,
                          size: 27,
                          radius: 7,
                          fallbackIcon: Icons.poll_rounded,
                          fallbackColor: const Color(0xFF159D76),
                        ),
                        const SizedBox(height: 4),
                        Text(title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                height: 1.1)),
                        if (reward != null) ...[
                          const SizedBox(height: 3),
                          Row(mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                            const Icon(Icons.monetization_on_rounded,
                                color: Color(0xFFFFB300), size: 11),
                            const SizedBox(width: 2),
                            Flexible(child: Text(_formatNumber(reward),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800))),
                          ]),
                        ],
                        if (duration.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(duration,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 7)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _surveySkeleton() => SizedBox(
        height: 100,
        child: Row(
          children: List.generate(
            4,
            (index) => Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index == 3 ? 0 : 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      );

  Map<String, int> _providerCounts() {
    final counts = <String, int>{};
    final labels = <String, String>{};
    void add(dynamic value) {
      final name = (value ?? '').toString().trim();
      if (name.isEmpty) return;
      final key = name.toLowerCase();
      labels.putIfAbsent(key, () => name);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    for (final offer in _offers.where(_isOfferAvailable)) {
      add(offer['provider'] ?? offer['providerName']);
    }
    for (final item in _surveys.whereType<Map>()) {
      add(item['provider']);
    }
    return {
      for (final key in counts.keys) labels[key]!: counts[key]!,
    };
  }

  Widget _providerStrip() {
    if (_loading) {
      return SizedBox(
        height: 64,
        child: Row(children: List.generate(3, (index) => Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index == 2 ? 0 : 7),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(11),
            ),
          ),
        ))),
      );
    }
    final counts = _providerCounts();
    if (counts.isEmpty) {
      return _emptyCard(
        icon: Icons.apps_rounded,
        title: 'No providers available',
        message: 'Providers will appear when activities are available.',
      );
    }
    final entries = counts.entries.toList();
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (context, index) {
          final entry = entries[index];
          return SizedBox(
            width: 90,
            child: Material(
              color: const Color(0xFFF5FBFF),
              borderRadius: BorderRadius.circular(11),
              child: InkWell(
                onTap: () => _push(const EarnScreen()),
                borderRadius: BorderRadius.circular(11),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFD6EBF7)),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Row(children: [
                    AppLogo(
                      provider: entry.key,
                      size: 29,
                      radius: 8,
                      fallbackIcon: Icons.apps_rounded,
                      fallbackColor: const Color(0xFF1685C5),
                    ),
                    const SizedBox(width: 6),
                    Expanded(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.key,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                height: 1.1)),
                        const SizedBox(height: 3),
                        Text('${entry.value} available',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 8)),
                      ],
                    )),
                  ]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _offerRows(
      List<Map<String, dynamic>> offers, IconData icon, Color color) {
    if (_loading) return _listSkeleton();
    return Column(
      children: offers
          .map((offer) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _activityRow(
                  icon: icon,
                  title: _offerTitle(offer),
                  provider: (offer['provider'] ?? offer['providerName'] ?? '')
                      .toString(),
                  detail: (offer['shortDesc'] ?? offer['description'] ?? '')
                      .toString(),
                  color: color,
                  onTap: () => _openOffer(offer),
                ),
              ))
          .toList(),
    );
  }

  Widget _activityRow({
    required IconData icon,
    required String title,
    required String detail,
    required Color color,
    required VoidCallback onTap,
    String provider = '',
  }) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              AppLogo(
                provider: provider,
                title: title,
                size: 40,
                fallbackIcon: icon,
                fallbackColor: color,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleMedium.copyWith(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                    if (detail.trim().isNotEmpty || provider.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(detail.trim().isEmpty ? provider : detail,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary, height: 1.3)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Icon(Icons.chevron_right_rounded, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title,
      {String? subtitle, IconData? icon, String? action, VoidCallback? onAction}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: AppColors.primaryDark, size: 17),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleLarge.copyWith(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary, fontSize: 11)),
              ],
            ],
          ),
        ),
        if (action != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryDark,
              minimumSize: const Size(44, 30),
              padding: const EdgeInsets.symmetric(horizontal: 5),
            ),
            child: Text(action,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }

  Widget _emptyCard({
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: AppColors.textSecondary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(message,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        height: 1.35)),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            IconButton(
              tooltip: actionLabel,
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded),
              color: AppColors.primaryDark,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            ),
        ],
      ),
    );
  }

  Widget _listSkeleton() => Column(
        children: List.generate(
          2,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
          ),
        ),
      );

  String _formatNumber(int number) {
    final digits = number.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return number < 0 ? '-$buffer' : buffer.toString();
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(this.label, this.icon, this.color, this.onTap);
}
