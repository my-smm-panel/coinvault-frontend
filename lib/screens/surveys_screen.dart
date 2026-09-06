import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/provider_logos.dart';

/// Surveys tab screen - ONLY surveys: providers strip on top,
/// all surveys below with company logos (own CoinVault style).
class SurveysScreen extends StatefulWidget {
  const SurveysScreen({super.key});

  @override
  State<SurveysScreen> createState() => _SurveysScreenState();
}

class _SurveysScreenState extends State<SurveysScreen> {
  String _selected = 'All';

  static const _bg = Color(0xFF0B0B12);
  static const _card = Color(0xFF17171F);

  static const _surveys = [
    {'title': 'Consumer Habits Survey', 'coins': 100, 'time': '8 min', 'provider': 'BitLabs'},
    {'title': 'Tech Preferences', 'coins': 75, 'time': '5 min', 'provider': 'CPX Research'},
    {'title': 'Shopping Behavior', 'coins': 150, 'time': '12 min', 'provider': 'Pollfish'},
    {'title': 'Mobile Gaming Survey', 'coins': 80, 'time': '6 min', 'provider': 'BitLabs'},
    {'title': 'Finance & Banking', 'coins': 120, 'time': '10 min', 'provider': 'CPX Research'},
    {'title': 'Lifestyle Poll', 'coins': 60, 'time': '4 min', 'provider': 'Cint'},
    {'title': 'Product Feedback', 'coins': 90, 'time': '7 min', 'provider': 'Prime Surveys'},
    {'title': 'Daily Opinion', 'coins': 45, 'time': '3 min', 'provider': 'TimeWall'},
  ];

  static const _providers = [
    'All',
    'Cint',
    'Prime Surveys',
    'TimeWall',
    'BitLabs',
    'CPX Research',
    'Pollfish',
  ];

  @override
  Widget build(BuildContext context) {
    final list = _selected == 'All'
        ? _surveys
        : _surveys
            .where((s) => s['provider'] == _selected)
            .toList();
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(list.length),
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
                  ? const Center(
                      child: Text('No surveys here yet',
                          style: TextStyle(
                              color: Colors.white54,
                              fontSize: 14)),
                    )
                  : ListView.builder(
                      padding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final s = list[i];
                        return _surveyRow(
                          title: s['title'] as String,
                          coins: s['coins'] as int,
                          time: s['time'] as String,
                          provider: s['provider'] as String,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(int count) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        gradient: AppColors.brandHeader,
        borderRadius:
            BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          const Icon(Icons.assignment_rounded,
              color: Colors.white, size: 24),
          const SizedBox(width: 8),
          const Text('Surveys',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('$count live',
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
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        itemCount: _providers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final p = _providers[i];
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
                      color: active
                          ? AppColors.primary
                          : Colors.white10),
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
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 72,
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: active ? color : Colors.white10,
                    width: active ? 2 : 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ProviderLogo(p, size: 36, radius: 18),
                  const SizedBox(height: 4),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(p,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
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
  }) {
    final conversion = (coins / 10).toStringAsFixed(2);
    final color = ProviderLogos.colorFor(provider);
    final trending = coins >= 100;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: color.withOpacity(0.35)),
          ),
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
                        const Icon(
                            Icons.monetization_on_rounded,
                            color: AppColors.gold,
                            size: 16),
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
                    Text(
                        '$provider • ₹$conversion • $time',
                        style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11)),
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
                child: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                    size: 26),
              ),
            ],
          ),
        ),
        if (trending)
          Positioned(
            top: -8,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 3),
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
