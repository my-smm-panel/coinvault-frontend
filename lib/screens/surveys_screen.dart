import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/coin_format.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/provider_logos.dart';
import '../widgets/app_logo.dart';
import '../services/app_repository.dart';
import '../widgets/state_views.dart';
import '../widgets/cv_header.dart';

/// Surveys screen — light/white premium design.
/// Shared header, provider filters and server-backed survey cards. Cards show
/// instructions/metadata rather than speculative rewards or balances.
/// Data from GET /api/surveys; start via the authenticated startSurvey endpoint.
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

  static const Color _bg = AppColors.background;
  static const Color _card = AppColors.surface;
  static const Color _border = AppColors.border;
  static const Color _primaryText = AppColors.textPrimary;
  static const Color _secondaryText = AppColors.textSecondary;
  static const Color _orange = AppColors.primary;

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
        if (_filter != 'All' && !_providers.contains(_filter)) _filter = 'All';
      }
    });
  }

  /// Providers available in the fetched data (dynamic, never hardcoded).
  List<String> get _providers => _surveys
      .whereType<Map>()
      .map((s) => (s['provider'] ?? '').toString().trim())
      .where((p) => p.isNotEmpty)
      .toSet()
      .toList();

  /// Filter by the ACTUAL provider identifier field, not visual hiding.
  List<dynamic> get _filtered {
    var list = _surveys.where((s) =>
        s is Map && (s['title'] ?? '').toString().trim().isNotEmpty).toList();
    if (_filter != 'All') {
      list = list.where((raw) {
        final s = raw as Map;
        if (_providers.contains(_filter)) {
          return (s['provider'] ?? '').toString() == _filter;
        }
        return false;
      }).toList();
    }
    return list;
  }

  Future<void> _openSurvey(Map<String, dynamic> survey) async {
    final id = (survey['id'] ?? '').toString().trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This survey is unavailable right now')),
      );
      return;
    }

    final started = await AppRepository.instance.startSurvey(id);
    if (!mounted) return;
    if (started == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not start this survey')),
      );
      return;
    }

    // The start response is authoritative for the tracking destination.
    final url = (started['externalUrl'] ??
            started['trackingUrl'] ??
            started['iframeUrl'] ??
            '')
        .toString()
        .trim();
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Survey started, but no valid link was provided')),
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
              SliverToBoxAdapter(child: CvHeader(showBack: Navigator.of(context).canPop())),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(child: _filterChips()),
              const SliverToBoxAdapter(child: SizedBox(height: 6)),
              SliverToBoxAdapter(child: _dailyProgressCard()),
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
                        : 'No surveys are available right now',
                    subtitle: _filter != 'All'
                        ? 'No server-listed surveys for ${_filter}.'
                        : 'Please check again later.',
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final s =
                          Map<String, dynamic>.from(list[i] as Map);
                      return _surveyCard(s);
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
    // Only show categories that exist in the current server response.
    final chips = <String>['All', ..._providers];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = chips[i];
          final active = _filter == c;
          return ChoiceChip(
            label: Text(c),
            selected: active,
            showCheckmark: false,
            onSelected: (_) => setState(() => _filter = c),
            selectedColor: _orange,
            backgroundColor: _card,
            side: BorderSide(color: active ? _orange : _border),
            labelStyle: TextStyle(color: active ? Colors.white : _primaryText,
              fontSize: 12.5, fontWeight: FontWeight.w700),
          );
        },
      ),
    );
  }

  // ─────────────────────────── DAILY PROGRESS ───────────────────────────
  Widget _dailyProgressCard() {
    final total = _filtered.where((s) => (s as Map)['status']?.toString().toLowerCase() == 'completed').length;
    final done = total;
    final remaining = (3 - done).clamp(0, 3);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.track_changes_rounded,
                    color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Daily Poll Target',
                    style: const TextStyle(
                        color: _primaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w800)),
              ),
              Text('$done of 3 Finished',
                  style: const TextStyle(
                      color: _secondaryText, fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: done / 3,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.monetization_on_rounded,
                  color: AppColors.gold, size: 13),
              const SizedBox(width: 4),
              Text('Finish $remaining more to unlock a 250 streak bonus',
                  style: const TextStyle(
                      color: _secondaryText, fontSize: 10.5)),
            ],
          ),
        ],
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
          Text('Choose a survey currently listed by the server',
              style: TextStyle(color: _secondaryText, fontSize: 12)),
        ],
      ),
    );
  }

  // ─────────────────────────── SURVEY CARD ───────────────────────────
  Widget _surveyCard(Map s) {
    final title = (s['title'] ?? '').toString().trim();
    final duration = (s['duration'] ?? '').toString().trim();
    final provider = (s['provider'] ?? '').toString().trim();
    final category = (s['category'] ?? '').toString().trim();
    final difficulty = (s['difficulty'] ?? '').toString().trim();
    final detail = (s['shortDesc'] ?? s['description'] ?? '').toString().trim();
    final survey = Map<String, dynamic>.from(s);
    final hasId = (survey['id'] ?? '').toString().trim().isNotEmpty;
    final status = (survey['status'] ?? '').toString().trim().toLowerCase();
    final reward = survey['rewardCoins'] ?? survey['coins'] ?? survey['coinReward'];
    final rewardInt = reward is num ? reward.toInt() : (reward is String ? int.tryParse(reward.trim()) : null);
    final image = (survey['image'] ?? survey['icon'] ?? '').toString().trim();
    final isNew = status == 'new' || status == 'active';
    final isCompleted = status == 'completed' || status == 'done';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: hasId && !isCompleted ? () => _openSurvey(survey) : null,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Big provider image / avatar
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: image.isNotEmpty
                      ? Image.network(image, width: 56, height: 56, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _surveyAvatar(provider, title))
                      : _surveyAvatar(provider, title),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isNew)
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE7F6F1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('NEW',
                              style: TextStyle(color: Color(0xFF159D76), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                        ),
                      Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: _primaryText, fontSize: 14, fontWeight: FontWeight.w800)),
                      if (detail.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(detail,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: _secondaryText, fontSize: 11, height: 1.25)),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (duration.isNotEmpty) ...[
                            const Icon(Icons.access_time_rounded, color: _secondaryText, size: 13),
                            const SizedBox(width: 3),
                            Text(duration, style: const TextStyle(color: _secondaryText, fontSize: 10.5)),
                            const SizedBox(width: 10),
                          ],
                          if (rewardInt != null) ...[
                            const Icon(Icons.monetization_on_rounded, color: AppColors.gold, size: 13),
                            const SizedBox(width: 3),
                            Text('+${formatCoins(rewardInt)}',
                                style: const TextStyle(color: _primaryText, fontSize: 11, fontWeight: FontWeight.w800)),
                          ],
                          if (difficulty.isNotEmpty) ...[
                            const SizedBox(width: 10),
                            Text(difficulty, style: const TextStyle(color: _secondaryText, fontSize: 10.5)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Completed',
                        style: TextStyle(color: _secondaryText, fontSize: 11, fontWeight: FontWeight.w700)),
                  )
                else
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Text('Start',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _surveyAvatar(String provider, String title) {
    final letter = (provider.isNotEmpty ? provider : title).trim().isNotEmpty
        ? (provider.isNotEmpty ? provider : title).trim()[0].toUpperCase()
        : 'S';
    final colors = [
      const Color(0xFF159D76),
      const Color(0xFFDC8A1C),
      const Color(0xFF7C3AED),
      const Color(0xFF3B82F6),
      const Color(0xFF8B5A2B),
    ];
    final color = colors[letter.codeUnitAt(0) % colors.length];
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(letter,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
      ),
    );
  }

}