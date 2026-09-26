import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../services/app_repository.dart';
import '../services/balance_stream.dart';
import '../widgets/app_logo.dart';
import '../widgets/cv_header.dart';
import 'earn_screen.dart';
import 'invite_screen.dart';
import 'leaderboard_screen.dart';
import 'quiz_screen.dart';
import 'scratch_screen.dart';
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
  Map<String, dynamic>? _spinStatus;
  bool _loading = true;
  bool _offersUnavailable = false;
  bool _surveysUnavailable = false;
  int _loadRevision = 0;

  static const _surveyGradients = <List<Color>>[
    [Color(0xFF10AAC5), Color(0xFF0875B9)],
    [Color(0xFFF5A315), Color(0xFFE86A19)],
    [Color(0xFFEF5570), Color(0xFFBE267A)],
  ];

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
      AppRepository.instance.spinStatus(),
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
      _spinStatus = results[2] is Map
          ? Map<String, dynamic>.from(results[2] as Map)
          : null;
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
            const CvHeader(showProfile: true, profileLeft: true),
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
                    _quickAccess(),
                    const SizedBox(height: 20),
                    _taskSection(),
                    const SizedBox(height: 22),
                    _sectionHeader(
                      'Available surveys',
                      subtitle: 'Explore currently listed surveys',
                      icon: Icons.auto_awesome_rounded,
                      action: 'View all',
                      onAction: () => _push(const SurveysScreen()),
                    ),
                    const SizedBox(height: 12),
                    _surveyList(),
                    if (_loading || _multiStepContent().isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _sectionHeader(
                        'Games & multi-step tasks',
                        subtitle: 'More activities from the catalogue',
                        icon: Icons.sports_esports_rounded,
                        action: 'View all',
                        onAction: () => _push(const EarnScreen()),
                      ),
                      const SizedBox(height: 10),
                      _offerRows(_multiStepContent().take(4).toList(),
                          Icons.sports_esports_rounded,
                          const Color(0xFF6853B9)),
                    ],
                    if (_remainingTasks().isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _sectionHeader('More tasks',
                          icon: Icons.task_alt_rounded,
                          action: 'View all',
                          onAction: () => _push(const EarnScreen())),
                      const SizedBox(height: 10),
                      _offerRows(_remainingTasks().take(4).toList(),
                          Icons.task_alt_rounded, AppColors.success),
                    ],
                    if (_otherOffers().isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _sectionHeader('More offers',
                          icon: Icons.local_offer_rounded,
                          action: 'View all',
                          onAction: () => _push(const EarnScreen())),
                      const SizedBox(height: 10),
                      _offerRows(_otherOffers().take(3).toList(),
                          Icons.local_offer_rounded, AppColors.primaryDark),
                    ],
                    if (_spinStatus != null) ...[
                      const SizedBox(height: 22),
                      _dailySpinCard(),
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

  Widget _walletHero(int? balance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF171D3B), Color(0xFF302872)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x291B2355),
            blurRadius: 14,
            offset: Offset(0, 6),
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
              const Text('AVAILABLE BALANCE',
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
              backgroundColor: const Color(0xFFEEE6FF),
              foregroundColor: const Color(0xFF302366),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 40),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Withdraw',
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
                      color: Colors.white.withOpacity(.11),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(.13)),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded,
                        color: Color(0xFFFFD56D), size: 22),
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
      _QuickAction('Spin', Icons.casino_rounded, const Color(0xFFB16B08),
          () => _push(const SpinScreen())),
      _QuickAction('Quiz', Icons.quiz_rounded, const Color(0xFF21805A),
          () => _push(const QuizScreen())),
      _QuickAction('Scratch', Icons.grid_view_rounded,
          const Color(0xFFB44778), () => _push(const ScratchScreen())),
      _QuickAction('Invite', Icons.group_add_rounded,
          const Color(0xFF3B6CCB), () => _push(const InviteScreen())),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 300 ? 4 : 2;
      final itemWidth = (constraints.maxWidth - (columns - 1) * 8) / columns;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: actions.map((action) {
          return SizedBox(
            width: itemWidth,
            child: Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(15),
              child: InkWell(
                onTap: action.onTap,
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  height: 82,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: action.color.withOpacity(.12),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(action.icon,
                            color: action.color.withOpacity(.9), size: 20),
                      ),
                      const SizedBox(height: 6),
                      Text(action.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _taskSection() {
    final tasks = _taskGridItems();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHeader('Task of the Day',
              subtitle: 'Available tasks from the catalogue',
              icon: Icons.checklist_rounded),
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
                  mainAxisExtent: 158,
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

  Widget _taskTile(Map<String, dynamic> task) {
    final title = (task['title'] ?? '').toString().trim();
    final provider =
        (task['provider'] ?? task['providerName'] ?? '').toString().trim();
    return Material(
      color: const Color(0xFFFCFDFE),
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: () => _openOffer(task),
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppLogo(
                provider: provider,
                title: title,
                size: 40,
                radius: 11,
                fallbackIcon: Icons.task_alt_rounded,
              ),
              const SizedBox(height: 7),
              Text(title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      height: 1.2)),
              if (provider.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(provider,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 10)),
              ],
              const Spacer(),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Details',
                      style: TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                  SizedBox(width: 2),
                  Icon(Icons.arrow_forward_rounded,
                      size: 12, color: AppColors.primaryDark),
                ],
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
            mainAxisExtent: 158,
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
    final surveys = _surveys.whereType<Map>().where((survey) =>
        (survey['title'] ?? '').toString().trim().isNotEmpty &&
        (survey['id'] ?? '').toString().trim().isNotEmpty).take(5).toList();
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
      height: 172,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: surveys.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final survey = surveys[index];
          final title = (survey['title'] ?? '').toString().trim();
          final provider = (survey['provider'] ?? '').toString().trim();
          final duration = (survey['duration'] ?? '').toString().trim();
          final colors = _surveyGradients[index % _surveyGradients.length];
          return SizedBox(
            width: 188,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: () => _push(SurveysScreen(
                      initialProvider: provider.isEmpty ? null : provider)),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AppLogo(
                              provider: provider,
                              title: title,
                              size: 34,
                              radius: 9,
                              fallbackIcon: Icons.poll_rounded,
                              fallbackColor: Colors.white,
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(provider.isEmpty ? 'SURVEY' : provider,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 11),
                        Expanded(
                          child: Text(title,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2)),
                        ),
                        Row(
                          children: [
                            const Text('Browse surveys',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700)),
                            const Icon(Icons.chevron_right_rounded,
                                size: 16, color: Colors.white),
                            if (duration.isNotEmpty) ...[
                              const Spacer(),
                              Flexible(
                                child: Text(duration,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10)),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _surveySkeleton() => SizedBox(
        height: 172,
        child: Row(
          children: List.generate(
            2,
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

  Widget _dailySpinCard() {
    final used = _spinStatus?['spinsUsed'];
    final limit = _spinStatus?['dailyLimit'];
    final canSpin = _spinStatus?['canSpin'];
    final status = used is num && limit is num && limit >= 0 && used >= 0
        ? '${(limit.toInt() - used.toInt()).clamp(0, limit.toInt())} of ${limit.toInt()} spins available'
        : canSpin == true
            ? 'A spin is available'
            : canSpin == false
                ? 'No spins available right now'
                : 'Spin availability unavailable';
    return _activityRow(
      icon: Icons.casino_rounded,
      title: 'Daily spin',
      detail: status,
      color: AppColors.primaryDark,
      onTap: () => _push(const SpinScreen()),
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
