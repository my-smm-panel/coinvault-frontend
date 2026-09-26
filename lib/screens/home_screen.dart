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

/// Main user app shell.
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

/// Home dashboard: server-published daily task first, then wallet, surveys,
/// multi-step content, and compact shortcuts. Nothing here invents rewards.
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

  @override
  void initState() {
    super.initState();
    // Do not show a previous account's in-memory balance while refreshing.
    BalanceStream.instance.clear();
    _loadHome();
  }

  Future<void> _loadHome() async {
    if (mounted) setState(() => _loading = true);
    final results = await Future.wait<dynamic>([
      AppRepository.instance.fetchOffers(),
      AppRepository.instance.fetchSurveys(),
      AppRepository.instance.spinStatus(),
      AppRepository.instance.fetchWalletBalance(),
    ]);
    if (!mounted) return;

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

  Future<void> _refreshHome() => _loadHome();

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
      // Date-only server values remain available through their stated day.
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
          (type.contains('TASK') || type.startsWith('INSTALL') ||
              type.contains('GAME') || type.contains('MULTI')) &&
          (offer['title'] ?? '').toString().trim().isNotEmpty &&
          _offerId(offer).isNotEmpty;
    }).toList();

    int priority(Map<String, dynamic> task) {
      if (task['isTaskOfDay'] == true || task['isDaily'] == true) return 3;
      final type = (task['type'] ?? task['category'] ?? '').toString().toUpperCase();
      if (type.contains('TASK')) return 2;
      if (type.contains('GAME') || type.contains('MULTI')) return 1;
      return 0;
    }
    tasks.sort((a, b) => priority(b).compareTo(priority(a)));
    return tasks;
  }

  List<Map<String, dynamic>> _multiStepContent() {
    final tasks = _serverTasks();
    final highlightedId = tasks.isEmpty ? '' : _offerId(tasks.first);
    return _offers.where((offer) {
      final type = (offer['type'] ?? offer['category'] ?? '')
          .toString()
          .toUpperCase();
      final steps = offer['instructions'];
      final hasSeveralSteps = steps is List && steps.length > 1;
      final id = _offerId(offer);
      return _isOfferAvailable(offer) &&
          id != highlightedId &&
          (type.contains('GAME') || type.contains('MULTI') || hasSeveralSteps) &&
          (offer['title'] ?? '').toString().trim().isNotEmpty &&
          id.isNotEmpty;
    }).toList();
  }

  List<Map<String, dynamic>> _otherOffers() {
    return _offers.where((offer) {
      final type = (offer['type'] ?? offer['category'] ?? '')
          .toString()
          .toUpperCase();
      return _isOfferAvailable(offer) &&
          (offer['title'] ?? '').toString().trim().isNotEmpty &&
          _offerId(offer).isNotEmpty &&
          !type.contains('TASK') &&
          !type.contains('SURVEY') &&
          !type.startsWith('INSTALL') &&
          !type.contains('GAME') &&
          !type.contains('MULTI');
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
      // Keep earned/reward amounts off the home task cards.
      coins: null,
      steps: steps,
      offerId: _offerId(offer),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: BalanceStream.instance,
      builder: (context, _) {
        final balance = BalanceStream.instance.value;
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              const CvHeader(
                showProfile: true,
                profileLeft: true,
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  onRefresh: _refreshHome,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
                    children: [
                      _sectionHeader('Task of the Day',
                          subtitle: 'A task currently available to you'),
                      const SizedBox(height: 10),
                      _taskOfDay(),
                      const SizedBox(height: 14),
                      _walletSummary(balance),
                      const SizedBox(height: 24),
                      _sectionHeader('Surveys',
                          subtitle: 'Available survey opportunities',
                          action: 'View all',
                          onAction: () => _push(const SurveysScreen())),
                      const SizedBox(height: 10),
                      _surveyList(),
                      if (_loading || _multiStepContent().isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _sectionHeader('Games & multi-step tasks',
                            subtitle: 'Activities with more to explore',
                            action: 'View all',
                            onAction: () => _push(const EarnScreen())),
                        const SizedBox(height: 10),
                        _multiStepList(),
                      ],
                      if (_loading || _remainingTasks().isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _sectionHeader('More tasks',
                            subtitle: 'Explore available activities',
                            action: 'View all',
                            onAction: () => _push(const EarnScreen())),
                        const SizedBox(height: 10),
                        _otherTaskList(),
                      ],
                      if (_otherOffers().isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _sectionHeader('More offers',
                            action: 'View all',
                            onAction: () => _push(const EarnScreen())),
                        const SizedBox(height: 10),
                        _otherOfferList(),
                      ],
                      const SizedBox(height: 24),
                      _sectionHeader('Quick access'),
                      const SizedBox(height: 10),
                      _quickAccess(),
                      const SizedBox(height: 18),
                      _dailySpinCard(),
                      const SizedBox(height: 12),
                      _inviteCard(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _taskOfDay() {
    if (_loading) return _taskSkeleton();
    final tasks = _serverTasks();
    if (tasks.isEmpty) {
      return _emptyCard(
        icon: Icons.task_alt_rounded,
        title: _offersUnavailable ? 'Tasks could not load' : 'No tasks posted yet',
        message: _offersUnavailable
            ? 'Pull down to retry.'
            : 'Tasks added in the admin panel will appear here.',
        actionLabel: _offersUnavailable ? 'Retry' : 'Browse tasks',
        onAction: _offersUnavailable ? _refreshHome : () => _push(const EarnScreen()),
      );
    }

    final task = tasks.first;
    final provider = (task['provider'] ?? task['providerName'] ?? task['cat'] ?? '')
        .toString()
        .trim();
    final title = (task['title'] ?? '').toString().trim();
    final description = (task['shortDesc'] ?? task['description'] ?? '')
        .toString()
        .trim();
    final instructions = task['instructions'];
    final durationValue = task['durationMinutes'] ?? task['duration'];
    final duration = durationValue is num && durationValue > 0
        ? '${durationValue.toInt()} min'
        : '';
    final isFeatured = task['isTaskOfDay'] == true ||
        task['isDaily'] == true ||
        task['isFeatured'] == true ||
        task['featured'] == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.gold.withOpacity(.42)),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: AppLogo(
                  provider: provider,
                  title: title,
                  size: 42,
                  radius: 13,
                  fallbackIcon: Icons.task_alt_rounded,
                  fallbackColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        isFeatured ? 'FEATURED TASK' : 'AVAILABLE TASK',
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .6,
                        ),
                      ),
                    ),
                    if (provider.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(provider,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 11)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w800, height: 1.2)),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary, height: 1.4)),
          ],
          if ((instructions is List && instructions.isNotEmpty) || duration.isNotEmpty) ...[
            const SizedBox(height: 11),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (instructions is List && instructions.isNotEmpty)
                  _infoChip(Icons.list_alt_rounded, '${instructions.length} steps'),
                if (duration.isNotEmpty) _infoChip(Icons.schedule_rounded, duration),
              ],
            ),
          ],
          const SizedBox(height: 13),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () => _openOffer(task),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('View task details'),
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

  Widget _walletSummary(int? balance) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 13, 12, 13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.account_balance_wallet_rounded,
                color: AppColors.primaryDark, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Available balance',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
                const SizedBox(height: 2),
                Text(balance == null ? 'Balance unavailable' : '${_formatNumber(balance)} coins',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => _push(const WithdrawScreen()),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryDark,
              side: const BorderSide(color: AppColors.primary),
              minimumSize: const Size(86, 42),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
  }

  Widget _surveyList() {
    if (_loading) return _listSkeleton();
    final surveys = _surveys.whereType<Map>().where((survey) {
      return (survey['title'] ?? '').toString().trim().isNotEmpty;
    }).take(5).toList();
    if (surveys.isEmpty) {
      return _emptyCard(
        icon: Icons.poll_rounded,
        title: _surveysUnavailable ? 'Surveys could not load' : 'No surveys available',
        message: _surveysUnavailable
            ? 'Pull down to try again.'
            : 'New survey opportunities will appear here when available.',
      );
    }
    return Column(
      children: surveys.map((survey) {
        final provider = (survey['provider'] ?? '').toString();
        final description = (survey['shortDesc'] ?? survey['description'] ?? '')
            .toString()
            .trim();
        return Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: _activityRow(
            icon: Icons.poll_rounded,
            title: (survey['title'] ?? '').toString(),
            detail: description.isEmpty ? provider : description,
            label: 'Open',
            color: const Color(0xFF3B82F6),
            onTap: () => _push(const SurveysScreen()),
          ),
        );
      }).toList(),
    );
  }

  Widget _multiStepList() {
    if (_loading) return _listSkeleton();
    final items = _multiStepContent().take(6).toList();
    if (items.isEmpty) {
      return _emptyCard(
        icon: Icons.sports_esports_rounded,
        title: _offersUnavailable ? 'Activities could not load' : 'No games or multi-step tasks yet',
        message: _offersUnavailable
            ? 'Pull down to try again.'
            : 'Activities added by the team will appear here.',
      );
    }
    return Column(
      children: items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: _activityRow(
          icon: Icons.sports_esports_rounded,
          title: (item['title'] ?? '').toString(),
          detail: (item['shortDesc'] ?? item['description'] ?? item['provider'] ?? '')
              .toString(),
          label: 'Details',
          color: const Color(0xFF7056C9),
          onTap: () => _openOffer(item),
        ),
      )).toList(),
    );
  }

  List<Map<String, dynamic>> _remainingTasks() {
    final all = _serverTasks();
    final highlightedId = all.isEmpty ? '' : _offerId(all.first);
    final multiStepIds = _multiStepContent().map(_offerId).toSet();
    return all.where((task) => _offerId(task) != highlightedId &&
        !multiStepIds.contains(_offerId(task))).toList();
  }

  Widget _otherTaskList() {
    if (_loading) return _listSkeleton();
    final remaining = _remainingTasks().take(8).toList();
    if (remaining.isEmpty) {
      return _emptyCard(
        icon: Icons.checklist_rounded,
        title: _offersUnavailable ? 'Tasks could not load' : 'You’re all caught up',
        message: _offersUnavailable
            ? 'Pull down to retry.'
            : 'See the featured task above, or browse the full task list.',
        actionLabel: 'Browse tasks',
        onAction: () => _push(const EarnScreen()),
      );
    }
    return Column(
      children: remaining.map((task) => Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: _activityRow(
          icon: Icons.task_alt_rounded,
          title: (task['title'] ?? '').toString(),
          detail: (task['shortDesc'] ?? task['description'] ?? task['provider'] ?? '')
              .toString(),
          label: 'Details',
          color: AppColors.success,
          onTap: () => _openOffer(task),
        ),
      )).toList(),
    );
  }

  Widget _otherOfferList() {
    final offers = _otherOffers().take(3).toList();
    if (offers.isEmpty) return const SizedBox.shrink();
    return Column(
      children: offers.map((offer) => Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: _activityRow(
          icon: Icons.local_offer_rounded,
          title: (offer['title'] ?? '').toString(),
          detail: (offer['shortDesc'] ?? offer['description'] ?? offer['provider'] ?? '')
              .toString(),
          label: 'Details',
          color: AppColors.primaryDark,
          onTap: () => _openOffer(offer),
        ),
      )).toList(),
    );
  }

  Widget _activityRow({
    required IconData icon,
    required String title,
    required String detail,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(.11),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
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
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    if (detail.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(detail,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary, height: 1.35)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                  Icon(Icons.chevron_right_rounded, color: color, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickAccess() {
    final actions = <_QuickAction>[
      _QuickAction('Spin', Icons.casino_outlined, const Color(0xFF9A6C00),
          () => _push(const SpinScreen())),
      _QuickAction('Quiz', Icons.quiz_outlined, const Color(0xFF21805A),
          () => _push(const QuizScreen())),
      _QuickAction('Scratch', Icons.grid_view_rounded, const Color(0xFFB44778),
          () => _push(const ScratchScreen())),
      _QuickAction('Invite', Icons.group_add_outlined, const Color(0xFF3B6CCB),
          () => _push(const InviteScreen())),
    ];
    return Wrap(
      spacing: 9,
      runSpacing: 9,
      children: actions.map((action) => SizedBox(
        width: (MediaQuery.of(context).size.width - 41) / 2,
        child: OutlinedButton.icon(
          onPressed: action.onTap,
          icon: Icon(action.icon, size: 18),
          label: Text(action.label),
          style: OutlinedButton.styleFrom(
            foregroundColor: action.color,
            backgroundColor: AppColors.surface,
            side: BorderSide(color: action.color.withOpacity(.24)),
            alignment: Alignment.centerLeft,
            minimumSize: const Size(0, 46),
          ),
        ),
      )).toList(),
    );
  }

  Widget _dailySpinCard() {
    final used = _spinStatus?['spinsUsed'];
    final limit = _spinStatus?['dailyLimit'];
    final canSpin = _spinStatus?['canSpin'];
    final status = used is num && limit is num
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
      label: 'Open',
      color: AppColors.primaryDark,
      onTap: () => _push(const SpinScreen()),
    );
  }

  Widget _inviteCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF5FF),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: const Color(0xFFD9E6FF)),
      ),
      child: Row(
        children: [
          const Icon(Icons.group_add_rounded, color: Color(0xFF3B6CCB), size: 22),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Invite friends',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800)),
                SizedBox(height: 3),
                Text('Share your referral link',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _push(const InviteScreen()),
            child: const Text('Invite'),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title,
      {String? subtitle, String? action, VoidCallback? onAction}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800)),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary)),
              ],
            ],
          ),
        ),
        if (action != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
                minimumSize: const Size(44, 40),
                padding: const EdgeInsets.symmetric(horizontal: 8)),
            child: Text(action),
          ),
      ],
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: AppColors.primaryDark, size: 14),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10.5,
                fontWeight: FontWeight.w700)),
      ]),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.textSecondary, size: 20),
          ),
          const SizedBox(width: 11),
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
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 6),
            IconButton(
              tooltip: actionLabel,
              onPressed: onAction,
              icon: const Icon(Icons.arrow_forward_rounded),
              color: AppColors.primaryDark,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            ),
          ],
        ],
      ),
    );
  }

  Widget _taskSkeleton() => Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      );

  Widget _listSkeleton() => Column(
        children: List.generate(
          2,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Container(
              height: 68,
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
