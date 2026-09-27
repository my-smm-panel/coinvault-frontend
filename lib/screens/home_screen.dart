import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../services/app_repository.dart';
import '../services/balance_stream.dart';
import '../widgets/app_logo.dart';
import 'earn_screen.dart';
import 'help_screen.dart';
import 'invite_screen.dart';
import 'leaderboard_screen.dart';
import 'spin_screen.dart';
import 'surveys_screen.dart';
import 'task_detail_screen.dart';
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
  bool _loading = true;
  bool _offersUnavailable = false;
  bool _surveysUnavailable = false;
  int _loadRevision = 0;

  @override
  void initState() {
    super.initState();
    _loadHome();
  }

  Future<void> _loadHome() async {
    final revision = ++_loadRevision;
    // Hide an old account's balance and never display a guessed value while
    // the authenticated, server-authoritative wallet is being refreshed.
    BalanceStream.instance.clear();
    if (mounted) setState(() => _loading = true);
    final results = await Future.wait<dynamic>([
      AppRepository.instance.fetchOffers(),
      AppRepository.instance.fetchSurveys(),
      AppRepository.instance.fetchWalletBalance(),
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
      _loading = false;
    });
  }

  String _offerId(Map<String, dynamic> offer) =>
      (offer['id'] ?? offer['_id'] ?? offer['offerId'] ??
              offer['providerOfferId'] ?? '')
          .toString()
          .trim();

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
      return _isOfferAvailable(offer) &&
          (type.contains('TASK') ||
              type.startsWith('INSTALL') ||
              type.contains('GAME') ||
              type.contains('MULTI') ||
              offer['isTaskOfDay'] == true ||
              offer['isDaily'] == true) &&
          (offer['title'] ?? '').toString().trim().isNotEmpty &&
          _offerId(offer).isNotEmpty;
    }).toList();

    int priority(Map<String, dynamic> task) {
      if (task['isTaskOfDay'] == true || task['isDaily'] == true) return 3;
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
          (offer['title'] ?? '').toString().trim().isNotEmpty;
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
    final multiIds = _multiStepContent().map(_offerId).toSet();
    return _offers.where((offer) {
      final type = (offer['type'] ?? offer['category'] ?? '')
          .toString()
          .toUpperCase();
      return _isOfferAvailable(offer) &&
          (offer['title'] ?? '').toString().trim().isNotEmpty &&
          _offerId(offer).isNotEmpty &&
          !multiIds.contains(_offerId(offer)) &&
          !type.contains('TASK') &&
          !type.contains('SURVEY') &&
          !type.startsWith('INSTALL') &&
          !type.contains('GAME') &&
          !type.contains('MULTI') &&
          offer['isTaskOfDay'] != true &&
          offer['isDaily'] != true;
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
      title: (offer['title'] ?? '').toString(),
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
                    _walletHero(BalanceStream.instance.value),
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
                  ],
                ),
              ),
            ),
          ],
        ),
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
                  const Icon(Icons.monetization_on_rounded,
                      color: Color(0xFFE6A500), size: 17),
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

  Widget _walletHero(int? balance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF226D0D), Color(0xFF154B08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x25236B15),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 285;
          final balanceText = balance == null
              ? (_loading ? 'Checking balance…' : 'Balance unavailable')
              : _formatNumber(balance);
          final balanceColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your Balance',
                  style: TextStyle(
                      color: Color(0xFFC9CDE3),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1)),
              const SizedBox(height: 5),
              if (balance == null)
                Text(balanceText,
                    maxLines: 2,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1.15))
              else
                FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(balanceText,
                      maxLines: 1,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          height: 1.15)),
                ),
              if (balance != null)
                const Text('coins',
                    style: TextStyle(color: Color(0xFFD8C88E), fontSize: 12)),
            ],
          );
          final withdraw = ElevatedButton(
            onPressed: () => _push(const WithdrawScreen()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBEE493),
              foregroundColor: const Color(0xFF174E0C),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 40),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Redeem',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFB82E),
                      border: Border.all(
                          color: const Color(0xFFFFE595), width: 2),
                    ),
                    child: const Icon(Icons.monetization_on_rounded,
                        color: Color(0xFFFFF4C8), size: 29),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: balanceColumn),
                  if (!narrow) ...[
                    const SizedBox(width: 7),
                    withdraw,
                  ],
                ],
              ),
              if (narrow) ...[
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: withdraw),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _quickAccess() {
    final actions = <_QuickAction>[
      _QuickAction('Spin & earn', Icons.stars_rounded, const Color(0xFFFFC344),
          () => _push(const SpinScreen())),
      _QuickAction('Challenge', Icons.emoji_events_rounded,
          const Color(0xFFFFC344), () => _push(const MissionsScreen())),
      _QuickAction('Refer & earn', Icons.person_add_alt_1_rounded,
          const Color(0xFFFFC344), () => _push(const InviteScreen())),
      _QuickAction('Tutorial', Icons.menu_book_rounded,
          const Color(0xFFFFC344), () => _push(const HelpScreen())),
    ];
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
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
                Icon(action.icon, color: action.color, size: 23),
                const SizedBox(height: 4),
                Text(action.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        )).toList(),
      ),
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
                  mainAxisExtent: 124,
                ),
                itemBuilder: (context, index) => _taskTile(tasks[index]),
              );
            }),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
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
    final title = (task['title'] ?? '').toString().trim();
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
            mainAxisExtent: 124,
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
        (survey['title'] ?? '').toString().trim().isNotEmpty &&
        (survey['id'] ?? '').toString().trim().isNotEmpty).take(12).toList();
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
      height: 114,
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
        height: 114,
        child: Row(
          children: List.generate(
            4,
            (index) => Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index == 0 ? 9 : 0),
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
        height: 77,
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
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (context, index) {
          final entry = entries[index];
          return SizedBox(
            width: 100,
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
                  title: (offer['title'] ?? '').toString(),
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
              minimumSize: const Size(44, 40),
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
