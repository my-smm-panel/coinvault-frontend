import 'package:flutter/material.dart';

import '../core/app_theme.dart';
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
    final survey = Map<String, dynamic>.from(s);
    final hasId = (survey['id'] ?? '').toString().trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
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
                // Provider identity from the survey catalogue.
                Row(
                  children: [
                    AppLogo(
                      provider: provider,
                      title: title,
                      size: 40,
                      fallbackIcon: Icons.poll_rounded,
                      fallbackColor: const Color(0xFF3B82F6),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: provider.isEmpty
                          ? const SizedBox.shrink()
                          : Text(provider,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: _primaryText,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 10),
                // Title
                if (title.isNotEmpty)
                  Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: _primaryText,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          height: 1.25)),
                if (title.isNotEmpty && (duration.isNotEmpty ||
                    difficulty.isNotEmpty || category.isNotEmpty))
                  const SizedBox(height: 7),
                // Meta row contains only fields supplied by the server.
                if (duration.isNotEmpty || difficulty.isNotEmpty || category.isNotEmpty)
                  Row(
                    children: [
                      if (duration.isNotEmpty) ...[
                        const Icon(Icons.access_time_rounded,
                            color: _secondaryText, size: 14),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(duration,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: _secondaryText, fontSize: 12)),
                        ),
                      ],
                      if (difficulty.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(difficulty,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: _secondaryText, fontSize: 11.5)),
                        ),
                      ],
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
                // Only the start action is shown; the server owns any outcome.
                Row(
                  children: [

                    const Spacer(),
                    SizedBox(
                      height: 42,
                      child: ElevatedButton(
                        onPressed: hasId ? () => _openSurvey(survey) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hasId ? _orange : AppColors.surfaceVariant,
                          foregroundColor: hasId ? Colors.white : _secondaryText,
                          disabledBackgroundColor: AppColors.surfaceVariant,
                          disabledForegroundColor: _secondaryText,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                        ),
                        child: Text(hasId ? 'Start Survey' : 'Unavailable',
                            style: const TextStyle(
                                fontSize: 12.5, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }

}
