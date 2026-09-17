import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/provider_logos.dart';
import '../services/app_repository.dart';
import '../widgets/state_views.dart';
import '../widgets/cv_header.dart';

/// Surveys screen — light/white premium design.
/// Header (title + subtitle + bell + avatar) → compact balance → search →
/// filter chips → "Available Surveys" section → vertical survey cards
/// (provider logo, verified, reward, meta row, divider, Start Survey button),
/// one card carries a "+20% Boost" badge with a countdown.
/// Data from GET /api/surveys (Supabase); start via startSurvey().
class SurveysScreen extends StatefulWidget {
  final String? initialProvider;
  const SurveysScreen({super.key, this.initialProvider});

  @override
  State<SurveysScreen> createState() => _SurveysScreenState();
}

class _SurveysScreenState extends State<SurveysScreen> {
  String _filter = 'All';
  List<dynamic> _surveys = [];
  bool _loading = true;
  bool _failed = false;

  static const Color _bg = Color(0xFFFAFAF8);
  static const Color _card = Color(0xFFFFFFFF);
  static const Color _border = Color(0xFFE7E7E7);
  static const Color _primaryText = Color(0xFF171717);
  static const Color _secondaryText = Color(0xFF6B7280);
  static const Color _orange = Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    if (widget.initialProvider != null) {
      _filter = widget.initialProvider!;
    }
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    final data = await AppRepository.instance.fetchSurveys();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (data == null) {
        _failed = true;
      } else {
        _surveys = data;
      }
    });
  }

  /// Providers available in the fetched data (dynamic, never hardcoded).
  List<String> get _providers => _surveys
      .map((s) => (s['provider'] ?? '').toString())
      .where((p) => p.isNotEmpty)
      .toSet()
      .toList();

  /// Filter by the ACTUAL provider identifier field, not visual hiding.
  List<dynamic> get _filtered {
    var list = _surveys;
    if (_filter != 'All') {
      list = list.where((raw) {
        final s = raw as Map;
        if (_providers.contains(_filter)) {
          return (s['provider'] ?? '').toString() == _filter;
        }
        // heuristic chips
        final coins = ((s['coins'] ?? 0) as num).toInt();
        final dur = (s['duration'] ?? '').toString();
        final mins = int.tryParse(
                RegExp(r'(\d+)').firstMatch(dur)?.group(1) ?? '') ??
            99;
        switch (_filter) {
          case 'Quick':
            return mins <= 5;
          case 'High Reward':
            return coins >= 200;
          case 'Short':
            return mins <= 8;
          case 'New':
            return coins >= 100;
          default:
            return true;
        }
      }).toList();
    }
    return list;
  }

  Future<void> _openSurvey(Map s) async {
    final id = (s['id'] ?? '').toString();
    if (id.isNotEmpty) {
      await AppRepository.instance.startSurvey(id);
    }
    final url = (s['externalUrl'] ?? s['iframeUrl'] ?? '').toString();
    if (url.isEmpty || !mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This survey opens inside the app soon')),
      );
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open survey link')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: _orange,
          backgroundColor: _card,
          onRefresh: _load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: CvHeader()),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(child: _filterChips()),
              const SliverToBoxAdapter(child: SizedBox(height: 6)),
              SliverToBoxAdapter(child: _sectionTitle()),
              if (_loading)
                const SliverToBoxAdapter(
                    child: ShimmerCardList(
                        rows: 4, padding: EdgeInsets.fromLTRB(16, 12, 16, 0)))
              else if (_failed)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorState(
                    message:
                        'Check your internet connection and try again.',
                    onRetry: _load,
                  ),
                )
              else if (list.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.assignment_outlined,
                    title: _filter != 'All'
                        ? 'No surveys available'
                        : 'No surveys here yet',
                    subtitle: _filter != 'All'
                        ? 'For ${_filter} right now.'
                        : 'New surveys are added daily — check back soon.',
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final s =
                          Map<String, dynamic>.from(list[i] as Map);
                      return _surveyCard(
                        s,
                        boosted: i == 0, // boost on the first listing
                      );
                    },
                    childCount: list.length,
                    addAutomaticKeepAlives: false,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────── SURVEY CARD ───────────────────────────

  // ─────────────────────────── FILTERS ───────────────────────────
  Widget _filterChips() {
    // Real providers first (dynamic from data), then heuristic chips.
    final chips = <String>[
      'All',
      ..._providers,
      if (_providers.isEmpty) ...['Quick', 'High Reward', 'Short', 'New'],
    ];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = chips[i];
          final active = _filter == c;
          return GestureDetector(
            onTap: () => setState(() => _filter = c),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? _orange : _card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: active ? _orange : _border, width: 1),
              ),
              child: Text(c,
                  style: TextStyle(
                    color: active ? Colors.white : _primaryText,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  )),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────── SECTION TITLE ───────────────────────────
  Widget _sectionTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Available Surveys',
              style: TextStyle(
                  color: _primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
          SizedBox(height: 2),
          Text('Earn coins by completing surveys',
              style: TextStyle(color: _secondaryText, fontSize: 12)),
        ],
      ),
    );
  }

  // ─────────────────────────── SURVEY CARD ───────────────────────────
  Widget _surveyCard(Map s, {bool boosted = false}) {
    final title = (s['title'] ?? 'Survey').toString();
    final coins = ((s['coins'] ?? 0) as num).toInt();
    final duration = (s['duration'] ?? '').toString();
    final provider = (s['provider'] ?? '').toString();
    final category = (s['category'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12, top: 4),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: provider + verified + reward
                Row(
                  children: [
                    ProviderLogo(provider, size: 36),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(provider.isEmpty ? 'CoinVault' : provider,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: _primaryText,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded,
                              color: Color(0xFF16A34A), size: 14),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text('+${_fmt(coins)} Coins',
                        style: const TextStyle(
                            color: Color(0xFF5A3825),
                            fontSize: 14,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 10),
                // Title
                Text(title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: _primaryText,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        height: 1.25)),
                const SizedBox(height: 7),
                // Meta row
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        color: _secondaryText, size: 14),
                    const SizedBox(width: 4),
                    Text(duration.isEmpty ? '5 min' : duration,
                        style: const TextStyle(
                            color: _secondaryText, fontSize: 12)),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9F7EE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Easy',
                          style: TextStyle(
                              color: Color(0xFF16A34A),
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ),
                    if (category.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: _secondaryText, fontSize: 11.5)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, thickness: 1, color: _border),
                const SizedBox(height: 10),
                // Bottom row: coins + Start button
                Row(
                  children: [
                    const Icon(Icons.monetization_on_rounded,
                        color: _orange, size: 16),
                    const SizedBox(width: 5),
                    Text('${_fmt(coins)} Coins',
                        style: const TextStyle(
                            color: _primaryText,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                    const Spacer(),
                    SizedBox(
                      height: 34,
                      child: ElevatedButton(
                        onPressed: () => _openSurvey(s),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _orange,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                        ),
                        child: const Text('Start Survey',
                            style: TextStyle(
                                fontSize: 12.5, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Boost badge
          if (boosted)
            Positioned(
              top: -9,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _orange,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x33F59E0B), blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text('+20% Boost',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800)),
                    SizedBox(width: 5),
                    Icon(Icons.timer_rounded, color: Colors.white, size: 11),
                    SizedBox(width: 2),
                    Text('23:14 left',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _fmt(int n) {
    final str = n.abs().toString();
    final sb = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) sb.write(',');
      sb.write(str[i]);
    }
    return n.isNegative ? '-$sb' : sb.toString();
  }
}
