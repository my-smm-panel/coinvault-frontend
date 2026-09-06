import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_theme.dart';
import '../core/provider_logos.dart';
import '../services/app_repository.dart';
import 'provider_tasks_screen.dart';

class EarnScreen extends StatefulWidget {
  const EarnScreen({super.key});

  @override
  State<EarnScreen> createState() => _EarnScreenState();
}

class _EarnScreenState extends State<EarnScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _offers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    final repo = AppRepository.instance;
    final offers = await repo.fetchOffers();
    if (mounted) {
      setState(() {
        _offers = offers;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Earn Coins'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textTertiary,
          labelStyle: AppTextStyles.labelMedium,
          unselectedLabelStyle: AppTextStyles.labelMedium,
          tabs: const [
            Tab(text: 'Tasks'),
            Tab(text: 'Surveys'),
            Tab(text: 'Offers'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTaskList(),
                _buildSurveyList(),
                _buildOfferList(),
              ],
            ),
    );
  }

  /// Brand icon + color per task type (kit style).
  static const Map<String, List<dynamic>> _taskStyles = {
    'app': [Icons.download_rounded, Color(0xFF3B82F6)],
    'video': [Icons.play_circle_fill_rounded, Color(0xFFEF4444)],
    'profile': [Icons.person_rounded, Color(0xFF10B981)],
    'login': [Icons.star_rounded, Color(0xFFF59E0B)],
    'share': [Icons.share_rounded, Color(0xFF14B8A6)],
    'review': [Icons.rate_review_rounded, Color(0xFFF66B06)],
  };

  /// Tasks tab: ONLY provider logos; tap opens that provider's tasks.
  static const _taskProviders = [
    'PubScale',
    'Cint',
    'TimeWall',
    'BitLabs',
    'CPX Research',
    'Pollfish',
    'OfferPro',
    'GrowDeck',
    'CPI Droid',
    'Lootably',
  ];

  Widget _buildTaskList() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: _taskProviders.length,
      itemBuilder: (context, index) {
        final name = _taskProviders[index];
        final color = ProviderLogos.colorFor(name);
        return InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    ProviderTasksScreen(provider: name)),
          ),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF17171F),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.45)),
            ),
            child: Center(
              child: ProviderLogo(name, size: 58),
            ),
          ),
        );
      },
    );
  }

  /// All surveys (grouped by provider on the Surveys tab).
  static const List<Map<String, dynamic>> _allSurveys = [
    {'title': 'Consumer Habits Survey', 'coins': 100, 'time': '8 min', 'provider': 'BitLabs'},
    {'title': 'Tech Preferences', 'coins': 75, 'time': '5 min', 'provider': 'CPX Research'},
    {'title': 'Shopping Behavior', 'coins': 150, 'time': '12 min', 'provider': 'Pollfish'},
    {'title': 'Mobile Gaming Survey', 'coins': 80, 'time': '6 min', 'provider': 'BitLabs'},
    {'title': 'Finance & Banking', 'coins': 120, 'time': '10 min', 'provider': 'CPX Research'},
    {'title': 'Lifestyle Poll', 'coins': 60, 'time': '4 min', 'provider': 'Cint'},
    {'title': 'Product Feedback', 'coins': 90, 'time': '7 min', 'provider': 'Prime Surveys'},
    {'title': 'Daily Opinion', 'coins': 45, 'time': '3 min', 'provider': 'TimeWall'},
  ];

  /// Survey providers only (kit style grid).
  static const List<Map<String, dynamic>> _providers = [
    {'name': 'Cint', 'bonus': '55% BONUS', 'color': Color(0xFF8B5CF6)},
    {'name': 'Prime Surveys', 'bonus': '', 'color': Color(0xFF3B82F6)},
    {'name': 'TimeWall', 'bonus': '', 'color': Color(0xFF10B981)},
    {'name': 'BitLabs', 'bonus': '', 'color': Color(0xFF8B5CF6)},
    {'name': 'CPX Research', 'bonus': '', 'color': Color(0xFF3B82F6)},
    {'name': 'Pollfish', 'bonus': '', 'color': Color(0xFF14B8A6)},
  ];

  /// Surveys tab shows ONLY providers; tap opens that provider's surveys.
  Widget _buildSurveyList() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: _providers.length,
      itemBuilder: (context, index) {
        final p = _providers[index];
        final color = p['color'] as Color;
        final count = _allSurveys
            .where((s) => s['provider'] == p['name'])
            .length;
        return InkWell(
          onTap: () => _showProviderSurveys(
              p['name'] as String, context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF17171F),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.45)),
            ),
            child: Center(
              child: ProviderLogo(p['name'] as String, size: 58),
            ),
          ),
        );
      },
    );
  }

  void _showProviderSurveys(String provider, BuildContext context) {
    final list = _allSurveys
        .where((s) => s['provider'] == provider)
        .toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF17171F),
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Colors.white10)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(provider,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('${list.length} surveys available',
                style: const TextStyle(
                    color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final s = list[i];
                  return _SurveyCard(
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

  Widget _buildOfferList() {
    if (_offers.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _offers.length,
        itemBuilder: (context, index) {
          final offer = _offers[index] as Map<String, dynamic>;
          return _OfferCard(offer: offer);
        },
      );
    }

    // Mock offers when API unavailable
    final offers = [
      {'title': 'Install Partner App & Reach Level 10', 'coins': 500, 'icon': Icons.apps_rounded, 'color': AppColors.primary},
      {'title': 'Sign up for Newsletter', 'coins': 50, 'icon': Icons.email_rounded, 'color': AppColors.success},
      {'title': 'Create Account on Partner Site', 'coins': 200, 'icon': Icons.person_add_rounded, 'color': AppColors.warning},
      {'title': 'Subscribe to YouTube Channel', 'coins': 75, 'icon': Icons.play_circle_rounded, 'color': AppColors.error},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: offers.length,
      itemBuilder: (context, index) {
        final o = offers[index];
        return _OfferCard(
          offer: {
            'title': o['title'],
            'coins': o['coins'],
            'icon': o['icon'],
            'color': o['color'],
          },
        );
      },
    );
  }

  void _showTaskDetail(Map<String, dynamic> task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(Icons.task_alt_rounded, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task['title'] as String, style: AppTextStyles.titleMedium),
                      Text('+${task['coins']} coins', style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.gold, fontWeight: FontWeight.w700,
                      )),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(task['desc'] as String, style: AppTextStyles.bodyMedium),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showSnackBar('Task started! Complete to earn coins.');
                },
                child: const Text('Start Task'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final String title;
  final int coins;
  final String description;
  final VoidCallback onTap;
  final IconData icon;
  final Color color;
  final String provider;

  const _TaskCard({
    required this.title,
    required this.coins,
    required this.description,
    required this.onTap,
    this.icon = Icons.task_alt_rounded,
    this.color = AppColors.primary,
    this.provider = '',
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              ProviderLogo(
                  provider.isEmpty ? title : provider,
                  size: 48),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(description, style: AppTextStyles.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (provider.isNotEmpty)
                      Text(provider,
                          style: AppTextStyles.bodySmall.copyWith(
                              color: ProviderLogos.colorFor(provider),
                              fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.monetization_on_rounded, size: 16, color: AppColors.gold),
                      Text('$coins', style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.gold, fontWeight: FontWeight.w700,
                      )),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SurveyCard extends StatelessWidget {
  final String title;
  final int coins;
  final String time;
  final String provider;
  const _SurveyCard({
    required this.title,
    required this.coins,
    required this.time,
    required this.provider,
  });

  /// Brand color per survey provider (kit style).
  static Color _providerColor(String p) {
    final v = p.toLowerCase();
    if (v.contains('bitlabs')) return const Color(0xFF8B5CF6);
    if (v.contains('cpx')) return const Color(0xFF3B82F6);
    if (v.contains('poll')) return const Color(0xFF14B8A6);
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    // Kit survey row: dark card, coin + gold amount, conversion,
    // length + rating, red chevron, Trending ribbon on big payouts.
    final conversion = (coins / 10).toStringAsFixed(2);
    final trending = coins >= 100;
    final rating = (4.1 + ((coins + title.length) % 9) / 10).toStringAsFixed(1);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF17171F),
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: _providerColor(provider).withOpacity(0.35)),
          ),
          child: InkWell(
            onTap: () {},
            child: Row(
              children: [
                ProviderLogo(provider, size: 44),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$coins.00',
                          style: const TextStyle(
                              color: AppColors.gold,
                              fontSize: 17,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(title,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text('Conversion ₹ $conversion   ⏱ $time   ★ $rating/5',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 10)),
                    ],
                  ),
                ),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.chevron_right_rounded,
                      color: Colors.white, size: 26),
                ),
              ],
            ),
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
                color: const Color(0xFFE53935),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Trending 🔥',
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

class _OfferCard extends StatelessWidget {
  final Map<String, dynamic> offer;

  const _OfferCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    final color = offer['color'] as Color? ?? AppColors.primary;
    final icon = offer['icon'] as IconData? ?? Icons.star_rounded;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(offer['title'] as String, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('Complete to earn', style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.monetization_on_rounded, size: 18, color: AppColors.gold),
                      Text('${offer['coins']}', style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.gold, fontWeight: FontWeight.w700,
                      )),
                    ],
                  ),
                  const SizedBox(height: 4),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: const Text('Go'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}