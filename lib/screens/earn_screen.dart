import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../services/app_repository.dart';
import '../services/offerwall_service.dart';
import '../services/paymentwall_service.dart';
import '../widgets/app_logo.dart';
import 'offerwall_screen.dart';
import 'paymentwall_screen.dart';
import 'surveys_screen.dart';
import 'task_detail_screen.dart';
import 'tracking_screen.dart';

/// API-backed Tasks/Earn tab. Content and reward values are never fabricated.
class EarnScreen extends StatefulWidget {
  const EarnScreen({super.key});

  @override
  State<EarnScreen> createState() => _EarnScreenState();
}

class _EarnScreenState extends State<EarnScreen> {
  List<dynamic> _surveys = [];
  List<dynamic> _offers = [];
  List<OfferwallOffer> _offerwallOffers = [];
  List<PaymentwallOffer> _paymentwallOffers = [];
  bool _surveysFailed = false;
  bool _offersFailed = false;
  bool _offerwallFailed = false;
  bool _paymentwallFailed = false;
  bool _loading = true;
  bool _dailyExpanded = false;
  bool _featuredExpanded = false;
  int _loadRevision = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final revision = ++_loadRevision;
    if (mounted) setState(() => _loading = true);
    final results = await Future.wait<dynamic>([
      AppRepository.instance.fetchSurveys(),
      AppRepository.instance.fetchOffers(),
      OfferwallService.instance.fetchOffers(),
      PaymentwallService.instance.fetchOffers(),
    ]);
    if (!mounted || revision != _loadRevision) return;
    setState(() {
      _surveys = (results[0] as List<dynamic>?) ?? [];
      _offers = (results[1] as List<dynamic>?) ?? [];
      _surveysFailed = results[0] == null;
      _offersFailed = results[1] == null;
      _offerwallOffers = (results[2] as List<OfferwallOffer>?) ?? [];
      _paymentwallOffers = (results[3] as List<PaymentwallOffer>?) ?? [];
      _offerwallFailed = results[2] == null;
      _paymentwallFailed = results[3] == null;
      _loading = false;
    });
  }

  void _push(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  String _title(Map item) =>
      (item['title'] ?? item['name'] ?? '').toString().trim();

  String _description(Map item) =>
      (item['shortDesc'] ?? item['description'] ?? item['provider'] ?? '')
          .toString()
          .trim();

  String _id(Map item) =>
      (item['id'] ?? item['_id'] ?? item['offerId'] ?? item['providerOfferId'] ?? '')
          .toString()
          .trim();

  int? _reward(Map item) {
    final value = item['rewardCoins'] ??
        item['coinReward'] ??
        item['coins'] ??
        item['reward'];
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  String _duration(Map item) {
    final value = item['duration'] ??
        item['estimatedDuration'] ??
        item['durationMinutes'];
    if (value is num) return '${value.toInt()} min';
    return (value ?? '').toString().trim();
  }

  bool _available(Map item) {
    final status = (item['status'] ?? '').toString().toLowerCase().trim();
    if (item['isActive'] == false ||
        item['active'] == false ||
        item['isExpired'] == true ||
        const {'inactive', 'disabled', 'expired'}.contains(status)) {
      return false;
    }
    final now = DateTime.now();
    final start = _date(item['startDate']);
    final end = _date(item['endDate']);
    if (start != null && now.isBefore(start)) return false;
    if (end != null) {
      final rawEnd = item['endDate'];
      final close = rawEnd is String && rawEnd.trim().length <= 10
          ? DateTime(end.year, end.month, end.day, 23, 59, 59, 999)
          : end;
      if (now.isAfter(close)) return false;
    }
    return true;
  }

  DateTime? _date(dynamic value) {
    if (value is num) {
      final millis = value > 1e12 ? value.toInt() : value.toInt() * 1000;
      return DateTime.fromMillisecondsSinceEpoch(millis).toLocal();
    }
    if (value is String) return DateTime.tryParse(value)?.toLocal();
    return null;
  }

  List<Map<String, dynamic>> get _taskOffers => _offers
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .where((item) =>
          _available(item) &&
          _title(item).isNotEmpty &&
          _id(item).isNotEmpty &&
          !((item['type'] ?? item['category'] ?? '')
              .toString()
              .toUpperCase()
              .contains('SURVEY')) &&
          !((item['type'] ?? item['category'] ?? '')
              .toString()
              .toUpperCase()
              .contains('OFFERWALL')) &&
          !((item['type'] ?? item['category'] ?? '')
              .toString()
              .toUpperCase()
              .contains('PAYMENTWALL')))
      .toList();

  bool _isDaily(Map item) {
    final type = (item['type'] ?? item['category'] ?? '')
        .toString()
        .toUpperCase();
    return item['isTaskOfDay'] == true ||
        item['isDaily'] == true ||
        type.contains('TASK_OF_DAY') ||
        type.contains('DAILY');
  }

  bool _isFeatured(Map item) {
    final type = (item['type'] ?? item['category'] ?? '')
        .toString()
        .toUpperCase();
    return item['isFeatured'] == true ||
        item['featured'] == true ||
        type.contains('FEATURED');
  }

  List<Map<String, dynamic>> get _dailyTasks {
    final tagged = _taskOffers.where(_isDaily).toList();
    // If no daily tag is configured, surface real backend offers in this slot.
    return tagged.isNotEmpty ? tagged : _taskOffers.take(6).toList();
  }

  List<Map<String, dynamic>> get _featuredTasks {
    final tagged = _taskOffers.where(_isFeatured).toList();
    if (tagged.isNotEmpty) return tagged;
    final dailyIds = _dailyTasks.map(_id).toSet();
    return _taskOffers.where((item) => !dailyIds.contains(_id(item))).toList();
  }

  void _openTask(Map<String, dynamic> item) {
    final instructions = item['instructions'];
    final steps = instructions is List
        ? instructions
            .where((step) => step != null && step.toString().trim().isNotEmpty)
            .map((step) => step.toString())
            .toList()
        : null;
    _push(TaskDetailScreen(
      provider: (item['provider'] ?? item['providerName'] ?? '').toString(),
      title: _title(item),
      desc: _description(item),
      coins: null,
      steps: steps,
      offerId: _id(item),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 26),
            children: [
              _topBar(),
              const SizedBox(height: 3),
              const Text(
                'Pick an activity and get started',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),
              _sectionHeading(
                'Task of the Day',
                icon: Icons.event_available_rounded,
                action: _dailyExpanded ? 'Show less' : 'See all',
                onAction: () => setState(() => _dailyExpanded = !_dailyExpanded),
              ),
              const SizedBox(height: 10),
              if (_loading)
                _taskSkeleton()
              else
                _dailyTaskContent(),
              const SizedBox(height: 20),
              _sectionHeading(
                'Surveys',
                icon: Icons.poll_rounded,
                action: 'See all',
                onAction: () => _push(const SurveysScreen()),
              ),
              const SizedBox(height: 9),
              if (_loading)
                _surveySkeleton()
              else
                _surveyList(),
              const SizedBox(height: 18),
              _newsBanner(),
              const SizedBox(height: 20),
              _sectionHeading(
                'Featured Tasks',
                icon: Icons.local_fire_department_rounded,
                action: _featuredExpanded ? 'Show less' : 'See all',
                onAction: () => setState(
                    () => _featuredExpanded = !_featuredExpanded),
              ),
              const SizedBox(height: 9),
              if (_loading)
                _rowSkeleton()
              else
                _featuredTaskList(),
              const SizedBox(height: 20),
              _sectionHeading('Task Providers', icon: Icons.apps_rounded),
              const SizedBox(height: 9),
              _sectionHeading('Offerwall.GG'),
              const SizedBox(height: 8),
              if (_loading)
                _rowSkeleton()
              else
                _offerwallList(),
              const SizedBox(height: 14),
              _sectionHeading('Paymentwall'),
              const SizedBox(height: 8),
              if (_loading)
                _rowSkeleton()
              else
                _paymentwallList(),
              if (_offersFailed || _surveysFailed ||
                  _offerwallFailed || _paymentwallFailed) ...[
                const SizedBox(height: 12),
                Center(
                  child: TextButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded, size: 17),
                    label: const Text('Retry loading activities'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() => SizedBox(
        height: 48,
        child: Row(
          children: [
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.bolt_rounded,
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Tasks',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Activity history',
              onPressed: () => _push(const TrackingScreen()),
              icon: const Icon(Icons.history_rounded),
              color: AppColors.primary,
            ),
          ],
        ),
      );

  Widget _sectionHeading(String title,
      {IconData? icon, String? action, VoidCallback? onAction}) {
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 16),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(title,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w900)),
        ),
        if (action != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              minimumSize: const Size(48, 32),
              padding: const EdgeInsets.symmetric(horizontal: 5),
            ),
            child: Text(action,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w800)),
          ),
      ],
    );
  }

  Widget _dailyTaskContent() {
    final tasks = _dailyTasks;
    if (_offersFailed) {
      return _empty('Tasks could not be loaded. Pull down to retry.', retry: true);
    }
    if (tasks.isEmpty) return _empty('No tasks are available right now.');
    if (_dailyExpanded) {
      return LayoutBuilder(builder: (context, constraints) {
        const gap = 8.0;
        final columns = constraints.maxWidth < 360 ? 2 : 3;
        final width =
            (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: tasks
              .map((task) => SizedBox(
                    width: width,
                    height: 148,
                    child: _taskCard(task),
                  ))
              .toList(),
        );
      });
    }
    return SizedBox(
      height: 148,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tasks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) => SizedBox(
          width: 126,
          child: _taskCard(tasks[index]),
        ),
      ),
    );
  }

  Widget _taskCard(Map<String, dynamic> item) {
    final title = _title(item);
    final provider = (item['provider'] ?? item['providerName'] ?? '').toString();
    final reward = _reward(item);
    final detail = _description(item);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _openTask(item),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF1D7C1)),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            children: [
              AppLogo(
                provider: provider,
                title: title,
                size: 35,
                radius: 10,
                fallbackIcon: Icons.task_alt_rounded,
                fallbackColor: AppColors.primary,
              ),
              const SizedBox(height: 6),
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w900)),
              if (detail.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                        height: 1.2)),
              ],
              const Spacer(),
              _rewardBadge(reward),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rewardBadge(int? reward) => Container(
        constraints: const BoxConstraints(minHeight: 24),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4E8),
          border: Border.all(color: const Color(0xFFFFD9B4)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.monetization_on_rounded,
                size: 13, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              reward == null ? 'View task' : _formatNumber(reward),
              style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 10,
                  fontWeight: FontWeight.w900),
            ),
          ],
        ),
      );

  Widget _surveyList() {
    if (_surveysFailed) {
      return _empty('Surveys could not be loaded. Pull down to retry.',
          retry: true);
    }
    final surveys = _surveys
        .whereType<Map>()
        .where((item) => _title(item).isNotEmpty && _available(item))
        .take(8)
        .toList();
    if (surveys.isEmpty) return _empty('No surveys available right now.');
    return Column(
      children: surveys.indexed.map((entry) {
        final index = entry.$1;
        final item = entry.$2;
        final provider = (item['provider'] ?? '').toString().trim();
        final reward = _reward(item);
        final duration = _duration(item);
        final tint = index.isEven
            ? const Color(0xFFFFF8F1)
            : const Color(0xFFFFFCF8);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: tint,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: () => _push(SurveysScreen(
                  initialProvider: provider.isEmpty ? null : provider)),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                constraints: const BoxConstraints(minHeight: 70),
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFF2E6DC)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    AppLogo(
                      provider: provider,
                      title: _title(item),
                      size: 40,
                      radius: 10,
                      fallbackIcon: Icons.poll_rounded,
                      fallbackColor: AppColors.primary,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_title(item),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w900)),
                          const SizedBox(height: 3),
                          Text(_description(item).isEmpty
                              ? 'Survey available'
                              : _description(item),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary)),
                          if (duration.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Row(children: [
                              const Icon(Icons.schedule_rounded,
                                  size: 12, color: AppColors.textTertiary),
                              const SizedBox(width: 3),
                              Text(duration,
                                  style: const TextStyle(
                                      fontSize: 9,
                                      color: AppColors.textSecondary)),
                            ]),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (reward != null) _rewardBadge(reward),
                    const SizedBox(width: 3),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.primary, size: 19),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _newsBanner() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4E8),
          border: Border.all(color: const Color(0xFFF4DDC8)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.campaign_rounded,
                  color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 11),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Latest News',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w900)),
                  SizedBox(height: 3),
                  Text('Announcements will appear here when available.',
                      maxLines: 2,
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                          height: 1.3)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _featuredTaskList() {
    if (_offersFailed) {
      return _empty('Featured tasks could not be loaded. Pull down to retry.',
          retry: true);
    }
    final tasks = _featuredTasks;
    if (tasks.isEmpty) return _empty('No additional tasks available yet.');
    final visible = _featuredExpanded ? tasks : tasks.take(6).toList();
    return Column(
      children: visible.map((item) {
        final provider = (item['provider'] ?? item['providerName'] ?? '').toString();
        final reward = _reward(item);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            child: InkWell(
              onTap: () => _openTask(item),
              borderRadius: BorderRadius.circular(13),
              child: Container(
                constraints: const BoxConstraints(minHeight: 64),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFF0E5DC)),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  children: [
                    AppLogo(
                      provider: provider,
                      title: _title(item),
                      size: 38,
                      radius: 10,
                      fallbackIcon: Icons.task_alt_rounded,
                      fallbackColor: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_title(item),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900)),
                          if (_description(item).isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(_description(item),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 10)),
                          ],
                        ],
                      ),
                    ),
                    if (reward != null) ...[
                      const SizedBox(width: 6),
                      _rewardBadge(reward),
                    ],
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.primary, size: 19),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _offerwallList() {
    if (_offerwallFailed) {
      return _empty('Offers could not be fetched.', retry: true);
    }
    if (_offerwallOffers.isEmpty) return _empty('No provider offers available.');
    return Column(
      children: _offerwallOffers.take(4).map((offer) => _providerItem(
            title: offer.title,
            description: offer.shortRequirement ?? offer.description ?? '',
            action: () => _push(const OfferwallScreen()),
          )).toList(),
    );
  }

  Widget _paymentwallList() {
    if (_paymentwallFailed) {
      return _empty('Offers could not be fetched.', retry: true);
    }
    if (_paymentwallOffers.isEmpty) return _empty('No provider offers available.');
    return Column(
      children: _paymentwallOffers.take(4).map((offer) => _providerItem(
            title: offer.title,
            description: offer.shortRequirement ?? offer.description ?? '',
            action: () => _push(const PaymentwallScreen()),
          )).toList(),
    );
  }

  Widget _providerItem({
    required String title,
    required String description,
    required VoidCallback action,
  }) => _listItem(
        title: title,
        description: description,
        icon: Icons.apps_rounded,
        action: action,
      );

  Widget _listItem({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback action,
  }) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          child: InkWell(
            onTap: action,
            borderRadius: BorderRadius.circular(13),
            child: Container(
              constraints: const BoxConstraints(minHeight: 62),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFF0E5DC)),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w800)),
                      if (description.trim().isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 10)),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.primary, size: 19),
              ]),
            ),
          ),
        ),
      );

  Widget _taskSkeleton() => SizedBox(
        height: 148,
        child: Row(
          children: List.generate(
            3,
            (index) => Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _surveySkeleton() => Column(
        children: List.generate(
          3,
          (_) => Container(
            height: 70,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );

  Widget _rowSkeleton() => Column(
        children: List.generate(
          2,
          (_) => Container(
            height: 62,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(13),
            ),
          ),
        ),
      );

  Widget _empty(String text, {bool retry = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(children: [
          Icon(retry ? Icons.cloud_off_rounded : Icons.inbox_outlined,
              color: AppColors.primary, size: 22),
          const SizedBox(width: 9),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    height: 1.35)),
          ),
          if (retry)
            IconButton(
              tooltip: 'Retry',
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              color: AppColors.primary,
            ),
        ]),
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
