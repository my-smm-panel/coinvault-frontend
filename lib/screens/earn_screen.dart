import 'package:flutter/material.dart';


import '../core/provider_logos.dart';
import '../widgets/app_logo.dart';
import '../services/app_repository.dart';
import '../services/offerwall_service.dart';
import '../services/auth_service.dart';
import '../widgets/cv_header.dart';
import '../widgets/state_views.dart';
import 'quiz_screen.dart';
import 'surveys_screen.dart';
import 'task_detail_screen.dart';
import 'offerwall_screen.dart';
import 'tracking_screen.dart';

/// CoinVault — Earn tab (light design sheet).
///
/// Global header (wordmark + bell + bear avatar) → page title + balance pill
/// → search → category tabs → earn-more-today summary → featured carousel →
/// surveys → tasks → offers → quizzes → quick earn → high reward → new today
/// → recommended → earning tips. Vertically scrollable, content-rich.
class EarnScreen extends StatefulWidget {
  const EarnScreen({super.key});

  @override
  State<EarnScreen> createState() => _EarnScreenState();
}

class _EarnScreenState extends State<EarnScreen> {
  // ── palette (exact design tokens) ──────────────────────────────────────
  static const Color _bg = Color(0xFFFAFAF8);
  static const Color _card = Color(0xFFFFFFFF);
  static const Color _border = Color(0xFFE7E7E7);
  static const Color _primary = Color(0xFFF59E0B);


  static const Color _text = Color(0xFF171717);
  static const Color _sub = Color(0xFF6B7280);
  static const Color _success = Color(0xFF16A34A);
  static const Color _warn = Color(0xFFD97706);

  // ── data ────────────────────────────────────────────────────────────────
  List<dynamic> _surveys = [];
  List<dynamic> _offers = [];
  List<OfferwallOffer> _offerwallOffers = [];
  bool _loading = true;
  bool _failed = false;
  int _today = 0;
  int _pending = 0;
  int _completed = 0;
  String _category = 'All';

  static const List<String> _cats = [
    'All', 'Surveys', 'Tasks', 'Offers', 'Quizzes', 'Quick Earn',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    final repo = AppRepository.instance;
    final results = await Future.wait([
      repo.fetchSurveys(),
      repo.fetchOffers(),
      repo.fetchActivity(),
    ]);
    // Offerwall.GG — best-effort, may fail gracefully
    final offerwallResult = await OfferwallService.instance.fetchOffers();
    if (!mounted) return;

    final surveys = results[0];
    final offers = results[1];
    final activity = results[2] as List;

    // fetchSurveys returns null on network failure => show error state
    final failed = surveys == null || offers == null;

    int today = 0;
    final now = DateTime.now();
    for (final raw in activity) {
      final m = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
      final coins = (m['coins'] as num?)?.toInt() ?? 0;
      if (coins > 0) {
        final ts = m['timestamp'] ?? m['createdAt'] ?? m['date'];
        DateTime? dt;
        if (ts is num) {
          dt = DateTime.fromMillisecondsSinceEpoch(ts > 1e12 ? ts.toInt() : ts.toInt() * 1000);
        } else if (ts is String) {
          dt = DateTime.tryParse(ts);
        }
        if (dt != null && now.difference(dt).inHours < 24) today += coins;
      }
    }

    setState(() {
      _surveys = surveys ?? <dynamic>[];
      _offers = offers ?? <dynamic>[];
      _offerwallOffers = offerwallResult ?? <OfferwallOffer>[];
      _failed = failed;
      _today = today;
      _pending = offers
          ?.where((o) => ((o as Map)['status'] ?? '').toString() == 'PENDING')
          .fold<int>(0, (s, o) => s + (((o['coins'] ?? 0) as num).toInt())) ??
          0;
      _completed = activity
          .where((raw) => raw is Map && (raw['status'] ?? '') == 'COMPLETED')
          .length;
      _loading = false;
    });
  }

  String _fmt(int n) {
    final s = n.abs().toString();
    final sb = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) sb.write(',');
      sb.write(s[i]);
    }
    return n.isNegative ? '-$sb' : sb.toString();
  }

  void _push(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final coins = AuthService().userModel?.coins ?? 0;
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: _primary,
          backgroundColor: _card,
          onRefresh: _load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: CvHeader()),

              // title (no balance pill, no search bar — per spec)
              SliverToBoxAdapter(child: _titleRow()),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),

              // category tabs
              SliverToBoxAdapter(child: _categoryTabs()),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // earn-more-today
              if (_loading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: ShimmerCardList(
                        rows: 3, padding: EdgeInsets.zero),
                  ),
                )
              else if (_failed)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorState(
                    message: 'Unable to load activities',
                    onRetry: _load,
                  ),
                )
              else ...[
                SliverToBoxAdapter(child: _summaryCard(coins)),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // surveys
                _section('Surveys',
                    action: 'View All',
                    onAction: () => _push(const SurveysScreen())),
                SliverToBoxAdapter(child: _surveysSection()),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // tasks
                _section('Tasks'),
                SliverToBoxAdapter(child: _tasksCarousel()),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // offers
                _section('Offers'),
                SliverToBoxAdapter(child: _offersSection()),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // offerwall
                _section('Offerwall',
                    action: 'View All',
                    onAction: () => _push(const OfferwallScreen())),
                SliverToBoxAdapter(child: _offerwallSection()),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // high reward
                _section('High Reward Opportunities'),
                SliverToBoxAdapter(child: _highRewardSection()),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // new today
                _section('New Today'),
                SliverToBoxAdapter(child: _newTodayCarousel()),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // recommended
                _section('Recommended for You'),
                SliverToBoxAdapter(child: _recommendedSection()),
                const SliverToBoxAdapter(child: SizedBox(height: 28)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────── title + balance ─────────────────────────────
  Widget _titleRow() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Earn Coins',
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w800, color: _text)),
            SizedBox(height: 2),
            Text('Choose an activity and start earning',
                style: TextStyle(fontSize: 13, color: _sub)),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── category tabs ────────────────────────────────
  Widget _categoryTabs() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = _cats[i];
          final on = _category == c;
          return GestureDetector(
            onTap: () => setState(() => _category = c),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? _primary : _card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: on ? _primary : _border),
              ),
              child: Text(c,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: on ? Colors.white : _sub)),
            ),
          );
        },
      ),
    );
  }

  // ───────────────────────── summary card ─────────────────────────────────
  Widget _summaryCard(int coins) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        decoration: _cardDec(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Earn More Today',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _text)),
                const Spacer(),
                GestureDetector(
                  onTap: () => _push(const TrackingScreen()),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('View Activity',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700, color: _primary)),
                      Icon(Icons.arrow_forward_rounded, size: 14, color: _primary),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _stat('Today', '$_today', 'Coins')),
                Container(width: 1, height: 34, color: _border),
                Expanded(child: _stat('Pending', _fmt(_pending), 'Coins')),
                Container(width: 1, height: 34, color: _border),
                Expanded(child: _stat('Completed', '$_completed', 'Tasks')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, String unit) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: _sub)),
        const SizedBox(height: 3),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _text),
            children: [
              TextSpan(text: value),
              TextSpan(text: ' $unit', style: const TextStyle(fontSize: 10, color: _sub, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  // ───────────────────────── featured carousel ────────────────────────────
  Widget _featuredCarousel() {
    return const SizedBox(height: 0);
  }

  Widget _badge(String text) {
    Color c = _primary;
    if (text == 'New') c = _success;
    if (text == 'High Reward') c = _warn;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withOpacity(0.35)),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: c)),
    );
  }

  // ───────────────────────── surveys ──────────────────────────────────────
  Widget _surveysSection() {
    if (_loading) return _skeletonH(170);
    final list = _filteredSurveys();
    if (list.isEmpty) return _emptyStrip('No surveys available right now');
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: list.length > 4 ? 4 : list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _surveyCard(list[i] as Map),
    );
  }

  List<dynamic> _filteredSurveys() {
    // Filter by real provider identifier (not visual hiding).
    if (_category == 'Surveys') return List.of(_surveys);
    if (_category == 'Tasks' || _category == 'Offers' || _category == 'Quick Earn') {
      return _surveys
          .where((raw) => (raw as Map)['type']?.toString() == _category.toUpperCase())
          .toList();
    }
    return _surveys;
  }

  Widget _surveyCard(Map raw) {
    final s = Map<String, dynamic>.from(raw);
    final provider = (s['provider'] ?? 'Survey').toString();
    final coins = ((s['rewardCoins'] ?? s['coins'] ?? 0) as num).toInt();
    final min = int.tryParse((s['durationMinutes'] ?? s['duration'] ?? 5).toString()) ?? 5;
    final color = ProviderLogos.colorFor(provider);
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: _cardDec(),
      child: Row(
        children: [
                    // ONE resolver: provider logo → app logo from title → icon
                    AppLogo(
                      provider: provider,
                      title: (s['title'] ?? '').toString(),
                      size: 44,
                      radius: 12,
                      fallbackIcon: Icons.poll_rounded,
                      fallbackColor: color,
                    ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(provider,
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: color),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text((s['title'] ?? 'Survey').toString(),
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _text),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 11, color: _sub),
                    const SizedBox(width: 3),
                    Text('$min min', style: const TextStyle(fontSize: 10.5, color: _sub)),
                    const SizedBox(width: 8),
                    Icon(Icons.signal_cellular_alt_rounded, size: 11, color: _sub),
                    const SizedBox(width: 3),
                    Text(_difficulty(min), style: const TextStyle(fontSize: 10.5, color: _sub)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('+$coins',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _primary)),
              const Text('Coins', style: TextStyle(fontSize: 9, color: _sub, fontWeight: FontWeight.w600)),
              const SizedBox(height: 5),
              GestureDetector(
                onTap: () => _push(SurveysScreen(initialProvider: provider)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Start',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                      Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _difficulty(int min) => min <= 5 ? 'Easy' : (min <= 12 ? 'Medium' : 'High');

  // ───────────────────────── tasks carousel ───────────────────────────────
  Widget _tasksCarousel() {
    final tasks = <Map<String, dynamic>>[
      ..._offers
          .where((o) => ((o as Map)['type'] ?? '').toString().startsWith('INSTALL'))
          .take(3)
          .map((o) => <String, dynamic>{
                'title': (o['title'] ?? 'Task').toString(),
                'coins': ((o['coins'] ?? 0) as num).toInt(),
                'min': (((o['coins'] ?? 0) as num).toInt() ~/ 20).clamp(3, 30),
                'req': 'Install + complete',
                'icon': Icons.download_rounded,
                'color': ProviderLogos.colorFor((o['provider'] ?? '').toString()),
              }),
    ];
    if (tasks.isEmpty) return _emptyStrip('No tasks right now');
    return SizedBox(
      height: 176,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: tasks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final t = tasks[i];
          return Container(
            width: 200,
            padding: const EdgeInsets.all(13),
            decoration: _cardDec(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppLogo(
                      title: t['title'] as String,
                      provider: (t['provider'] as String?) ?? '',
                      size: 36,
                      radius: 10,
                      fallbackIcon: t['icon'] as IconData,
                      fallbackColor: t['color'] as Color,
                    ),
                    const Spacer(),
                    Text('+${t['coins']}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: _primary)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(t['title'] as String,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: _text),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(t['req'] as String,
                    style: const TextStyle(fontSize: 11, color: _sub),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const Spacer(),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 11, color: _sub),
                    const SizedBox(width: 3),
                    Text('~${t['min']} min', style: const TextStyle(fontSize: 10.5, color: _sub)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _push(TaskDetailScreen(
                        provider: 'CoinVault Partner',
                        title: t['title'] as String,
                        desc: t['req'] as String,
                        coins: t['coins'] as int,
                        steps: const ['Open the offer', 'Follow instructions', 'Complete activity', 'Coins credited'],
                      )),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                        decoration: BoxDecoration(
                          color: _primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('View Task',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
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

  // ───────────────────────── offerwall ────────────────────────────────────
  Widget _offerwallSection() {
    final offerwallOffers = <Map<String, dynamic>>[
      ..._offerwallOffers.map((o) => <String, dynamic>{
            'title': o.title,
            'provider': o.provider.isEmpty ? 'Offerwall.GG' : o.provider,
            'coins': o.coinReward,
            'offerId': o.id,
            'color': ProviderLogos.colorFor(o.provider),
          }),
    ];
    if (offerwallOffers.isEmpty) {
      // Show a placeholder card for Offerwall.GG when no offers loaded yet
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GestureDetector(
          onTap: () => _push(const OfferwallScreen()),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDec(),
            child: Row(
              children: [
                AppLogo(
                  provider: 'gg',
                  title: 'Offerwall',
                  size: 46,
                  radius: 12,
                  fallbackIcon: Icons.local_offer_rounded,
                  fallbackColor: ProviderLogos.colorFor('gg'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Offerwall.GG',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w800, color: _text)),
                      SizedBox(height: 3),
                      Text('Complete tasks, surveys & installs to earn coins',
                          style: TextStyle(fontSize: 11.5, color: _sub)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Open',
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                      Icon(Icons.arrow_forward_rounded, size: 13, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: offerwallOffers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final o = offerwallOffers[i];
        final coins = o['coins'] as int;
        final color = o['color'] as Color;
        return GestureDetector(
          onTap: () => _push(OfferDetailScreen(
            offerId: o['offerId'] as String,
            provider: o['provider'] as String,
            title: o['title'] as String,
            coins: coins,
          )),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: _cardDec(),
            child: Row(
              children: [
                AppLogo(
                  provider: (o['provider'] as String).trim(),
                  title: o['title'] as String,
                  size: 44,
                  radius: 12,
                  fallbackIcon: Icons.local_offer_rounded,
                  fallbackColor: color,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(o['title'] as String,
                          style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: _text),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('+${_fmt(coins)} Coins',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: _primary)),
                          const SizedBox(width: 4),
                          Text('≈ ₹${(coins / 10).toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 10.5, color: _sub)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _push(OfferDetailScreen(
                    offerId: o['offerId'] as String,
                    provider: o['provider'] as String,
                    title: o['title'] as String,
                    coins: coins,
                  )),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Start',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                        Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ───────────────────────── offers ───────────────────────────────────────
  Widget _offersSection() {
    final offers = <Map<String, dynamic>>[
      ..._offers
          .where((o) => ((o as Map)['coins'] ?? 0) as num >= 1000)
          .take(2)
          .map((o) => <String, dynamic>{
                'title': (o['title'] ?? 'Offer').toString(),
                'provider': (o['provider'] ?? 'Partner').toString(),
                'coins': ((o['coins'] ?? 0) as num).toInt(),
                'min': 25,
                'milestones': 4,
                'done': 0,
              }),
    ];
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: offers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final o = offers[i];
        final steps = ['Install', 'Register', 'Complete Activity', 'Final Reward'];
        final done = (o['done'] as int).clamp(0, 4);
        final total = (o['milestones'] as int).clamp(1, 4);
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDec(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(o['title'] as String,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _text),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  Text('Up to +${o['coins']}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: _primary)),
                ],
              ),
              const SizedBox(height: 4),
              Text('Complete $total milestones  •  ~${o['min']} min  •  ${o['provider']}',
                  style: const TextStyle(fontSize: 11.5, color: _sub)),
              const SizedBox(height: 12),
              // progress
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : done / total,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFEFEFEF),
                  color: _primary,
                ),
              ),
              const SizedBox(height: 6),
              Text('$done/$total completed',
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: _sub)),
              const SizedBox(height: 12),
              // milestone preview
              Row(
                children: List.generate(total, (mi) {
                  final reached = mi < done;
                  return Expanded(
                    child: Row(
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: reached ? _primary : _card,
                                border: Border.all(
                                    color: reached ? _primary : _border, width: 1.5),
                              ),
                              child: reached
                                  ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                                  : const SizedBox(),
                            ),
                            const SizedBox(height: 4),
                            Text(steps[mi],
                                style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: reached ? FontWeight.w800 : FontWeight.w600,
                                    color: reached ? _primary : _sub)),
                          ],
                        ),
                        if (mi != total - 1)
                          Expanded(
                            child: Container(
                              height: 1.5,
                              color: mi < done ? _primary : _border,
                              margin: const EdgeInsets.only(bottom: 16),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 12, color: _sub),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text('Coins credited after verification',
                        style: const TextStyle(fontSize: 10.5, color: _sub)),
                  ),
                  GestureDetector(
                    onTap: () => _push(TaskDetailScreen(
                      provider: o['provider'] as String,
                      title: o['title'] as String,
                      desc: 'Complete ${o['milestones']} milestones to earn up to ${o['coins']} coins.',
                      coins: o['coins'] as int,
                      steps: steps,
                    )),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                      decoration: BoxDecoration(
                        color: _primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('View Offer',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Colors.white)),
                          Icon(Icons.arrow_forward_rounded, size: 13, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ───────────────────────── quizzes ──────────────────────────────────────
  Widget _quizzesCarousel() {
    return const SizedBox(height: 0);
  }

  // ───────────────────────── quick earn grid ──────────────────────────────
  Widget _quickEarnGrid() {
    return const SizedBox(height: 0);
  }

  // ───────────────────────── high reward ──────────────────────────────────
  Widget _highRewardSection() {
    final high = <Map<String, dynamic>>[
      ..._offers
          .where((o) => ((o as Map)['coins'] ?? 0) as num >= 800)
          .take(3)
          .map((o) => <String, dynamic>{
                'title': (o['title'] ?? 'Offer').toString(),
                'provider': (o['provider'] ?? 'Partner').toString(),
                'coins': ((o['coins'] ?? 0) as num).toInt(),
                'min': (((o['coins'] ?? 0) as num).toInt() ~/ 40).clamp(5, 40),
                'badge': 'High Reward',
              }),
    ];
    if (high.isEmpty) return const SizedBox.shrink();
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: high.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final h = high[i];
        final color = ProviderLogos.colorFor((h['provider'] as String).trim());
        return Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _primary.withOpacity(0.25), width: 1.2),
            boxShadow: const [
              BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 3)),
            ],
          ),
          child: Row(
            children: [
              AppLogo(
                provider: (h['provider'] as String).trim(),
                title: h['title'] as String,
                size: 46,
                radius: 12,
                fallbackIcon: Icons.local_fire_department_rounded,
                fallbackColor: color,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _badge(h['badge'] as String),
                    const SizedBox(height: 4),
                    Text(h['title'] as String,
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: _text),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text('${h['provider']}  •  ~${h['min']} min',
                        style: const TextStyle(fontSize: 10.5, color: _sub),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('+${h['coins']}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _primary)),
                  const Text('Coins', style: TextStyle(fontSize: 9, color: _sub, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 5),
                  GestureDetector(
                    onTap: () => _push(TaskDetailScreen(
                      provider: h['provider'] as String,
                      title: h['title'] as String,
                      desc: 'High reward opportunity. Complete all requirements to earn ${h['coins']} coins.',
                      coins: h['coins'] as int,
                      steps: const ['Open the offer', 'Follow instructions', 'Complete activity', 'Coins credited'],
                    )),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('View Details',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _primary)),
                        Icon(Icons.arrow_forward_rounded, size: 12, color: _primary),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ───────────────────────── new today ────────────────────────────────────
  Widget _newTodayCarousel() {
    final fresh = <Map<String, dynamic>>[
      ..._surveys.take(2).map((s) => <String, dynamic>{
            'title': (s['provider'] as String?) ?? 'Survey',
            'sub': (s['title'] ?? '').toString(),
            'coins': ((s['rewardCoins'] ?? s['coins'] ?? 0) as num).toInt(),
            'min': int.tryParse((s['durationMinutes'] ?? 5).toString()) ?? 5,
          }),
    ];
    if (fresh.isEmpty) return _emptyStrip('Nothing new today');
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: fresh.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final n = fresh[i];
          return Container(
            width: 210,
            padding: const EdgeInsets.all(12),
            decoration: _cardDec(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _badge('New'),
                    const Spacer(),
                    Text('+${n['coins']}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: _primary)),
                  ],
                ),
                const SizedBox(height: 7),
                Text(n['title'] as String,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: _text),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text((n['sub'] as String?) ?? '',
                    style: const TextStyle(fontSize: 10.5, color: _sub),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const Spacer(),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 11, color: _sub),
                    const SizedBox(width: 3),
                    Text('${n['min']} min', style: const TextStyle(fontSize: 10.5, color: _sub)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _push(const SurveysScreen()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Start',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white)),
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

  // ───────────────────────── recommended ──────────────────────────────────
  Widget _recommendedSection() {
    // Built from REAL offers — no hardcoded rewards or tasks.
    final rec = <Map<String, dynamic>>[];
    for (final o in _offers.take(4)) {
      final coins = ((o['coins'] ?? 0) as num).toInt();
      rec.add({
        'title': (o['title'] ?? 'Offer').toString(),
        'coins': coins,
        'min': (coins ~/ 40).clamp(3, 40),
        'icon': Icons.local_offer_rounded,
        'color': _primary,
        'page': TaskDetailScreen(
          provider: (o['provider'] ?? 'Partner').toString(),
          title: (o['title'] ?? 'Offer').toString(),
          desc: (o['shortDesc'] ?? o['description'] ?? 'Complete this offer to earn coins.').toString(),
          coins: coins,
          steps: ((o['instructions'] ?? []) as List).map((e) => e.toString()).toList(),
        ),
      });
    }
    if (rec.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: rec.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final r = rec[i];
          return GestureDetector(
            onTap: () => _push(r['page'] as Widget),
            child: Container(
              width: 176,
              padding: const EdgeInsets.all(13),
              decoration: _cardDec(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (r['color'] as Color).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(r['icon'] as IconData, size: 18, color: r['color'] as Color),
                  ),
                  const SizedBox(height: 9),
                  Text(r['title'] as String,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _text),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text('+${r['coins']} coins  •  ${r['min']} min',
                      style: const TextStyle(fontSize: 10.5, color: _sub)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      color: _primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Start',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ───────────────────────── tips ─────────────────────────────────────────
  Widget _tipsSection() {
    return const SizedBox(height: 0);
  }

  // ───────────────────────── shared bits ──────────────────────────────────
  BoxDecoration _cardDec() => BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 1),
        boxShadow: const [
          BoxShadow(color: Color(0x10000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      );

  Widget _section(String title, {String? action, VoidCallback? onAction}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Row(
          children: [
            Text(title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _text)),
            const Spacer(),
            if (action != null && onAction != null)
              GestureDetector(
                onTap: onAction,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(action,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700, color: _primary)),
                    const Icon(Icons.arrow_forward_rounded, size: 14, color: _primary),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _skeletonH(double h) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: const ShimmerCardList(rows: 3),
    );
  }

  Widget _emptyStrip(String msg) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: _cardDec(),
      child: Row(
        children: [
          Image.asset('assets/bear_avatar.png',
              width: 40, height: 40, errorBuilder: (_, __, ___) => const Icon(Icons.task_alt_rounded, color: _primary, size: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(msg,
                style: const TextStyle(fontSize: 12.5, color: _sub, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
