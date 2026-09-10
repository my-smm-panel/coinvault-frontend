import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_theme.dart';
import '../core/provider_logos.dart';
import '../services/app_repository.dart';
import '../widgets/state_views.dart';

/// Surveys tab screen - providers strip on top, all real surveys below
/// with company logos. Data comes from GET /api/surveys (Supabase).
/// Tapping a survey opens the provider link (startSurvey registers it).
class SurveysScreen extends StatefulWidget {
  final String? initialProvider;
  const SurveysScreen({super.key, this.initialProvider});

  @override
  State<SurveysScreen> createState() => _SurveysScreenState();
}

class _SurveysScreenState extends State<SurveysScreen> {
  late String _selected;
  List<dynamic> _surveys = [];
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialProvider ?? 'All';
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

  /// Providers derived from real survey data (never hardcoded).
  List<String> get _providers {
    final set = <String>{};
    for (final s in _surveys) {
      final p = ((s as Map)['provider'] ?? '').toString();
      if (p.isNotEmpty) set.add(p);
    }
    return ['All', ...set.toList()..sort()];
  }

  List<dynamic> get _filtered => _selected == 'All'
      ? _surveys
      : _surveys
          .where((s) => ((s as Map)['provider'] ?? '') == _selected)
          .toList();

  Future<void> _openSurvey(Map s) async {
    final id = (s['id'] ?? '').toString();
    // Register the start on the server (IN_PROGRESS completion).
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

  static const _bg = Color(0xFF0B0B12);
  static const _card = Color(0xFF17171F);

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(list.length),
            if (_loading)
              const ShimmerCardList(rows: 4, padding: EdgeInsets.fromLTRB(16, 16, 16, 0))
            else if (_failed)
              Expanded(
                child: ErrorState(
                  message: 'Check your internet connection and try again.',
                  onRetry: _load,
                ),
              )
            else ...[
              _providerStrip(),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text('ALL SURVEYS',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1)),
              ),
              Expanded(
                child: list.isEmpty
                    ? const EmptyState(
                        icon: Icons.assignment_outlined,
                        title: 'No surveys here yet',
                        subtitle: 'New surveys are added daily — check back soon.',
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        backgroundColor: _card,
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          itemCount: list.length,
                          itemBuilder: (_, i) {
                            final s = Map<String, dynamic>.from(list[i] as Map);
                            return _surveyRow(
                              title: (s['title'] ?? 'Survey').toString(),
                              coins: ((s['coins'] ?? 0) as num).toInt(),
                              time: (s['duration'] ?? '').toString(),
                              provider: (s['provider'] ?? '').toString(),
                              onTap: () => _openSurvey(s),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _header(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        gradient: AppColors.brandHeader,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          const Icon(Icons.assignment_rounded, color: Colors.white, size: 24),
          const SizedBox(width: 8),
          const Text('Surveys',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(_loading ? '…' : '$count live',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _providerStrip() {
    final providers = _providers;
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        itemCount: providers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final p = providers[i];
          final active = _selected == p;
          if (p == 'All') {
            return InkWell(
              onTap: () => setState(() => _selected = p),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 72,
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.primary.withOpacity(0.2)
                      : _card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: active ? AppColors.primary : Colors.white10),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.apps_rounded,
                        color: AppColors.primary, size: 26),
                    SizedBox(height: 4),
                    Text('All',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            );
          }
          final color = ProviderLogos.colorFor(p);
          return InkWell(
            onTap: () => setState(() => _selected = p),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 76,
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: active ? color : Colors.white10,
                    width: active ? 2 : 1),
              ),
              child: Center(
                child: ProviderLogo(p, size: 56, radius: 14),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _surveyRow({
    required String title,
    required int coins,
    required String time,
    required String provider,
    required VoidCallback onTap,
  }) {
    final conversion = (coins / 10).toStringAsFixed(2);
    final color = ProviderLogos.colorFor(provider);
    final trending = coins >= 100;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.35)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    ProviderLogo(provider, size: 46),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.monetization_on_rounded,
                                  color: AppColors.gold, size: 16),
                              const SizedBox(width: 4),
                              Text('$coins coins',
                                  style: const TextStyle(
                                      color: AppColors.gold,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(title,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          Text('$provider • ₹$conversion • $time',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 11)),
                        ],
                      ),
                    ),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.chevron_right_rounded,
                          color: Colors.white, size: 26),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (trending)
          Positioned(
            top: -8,
            right: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('HOT',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800)),
            ),
          ),
      ],
    );
  }
}