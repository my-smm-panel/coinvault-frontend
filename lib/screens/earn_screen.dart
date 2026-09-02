import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_theme.dart';
import '../services/app_repository.dart';

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

  Widget _buildTaskList() {
    final tasks = [
      {'title': 'Download & Open App', 'coins': 50, 'desc': 'Install and open for 30 seconds', 'type': 'app'},
      {'title': 'Watch Video Ad', 'coins': 10, 'desc': 'Watch 30-second video', 'type': 'video'},
      {'title': 'Complete Profile', 'coins': 25, 'desc': 'Fill all profile fields', 'type': 'profile'},
      {'title': 'Daily Login', 'coins': 5, 'desc': 'Open app today', 'type': 'login'},
      {'title': 'Share on WhatsApp', 'coins': 15, 'desc': 'Share referral link', 'type': 'share'},
      {'title': 'Rate App on Play Store', 'coins': 30, 'desc': 'Leave 5-star review', 'type': 'review'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _TaskCard(
          title: task['title'] as String,
          coins: task['coins'] as int,
          description: task['desc'] as String,
          onTap: () => _showTaskDetail(task),
        );
      },
    );
  }

  Widget _buildSurveyList() {
    final surveys = [
      {'title': 'Consumer Habits Survey', 'coins': 100, 'time': '8 min', 'provider': 'BitLabs'},
      {'title': 'Tech Preferences', 'coins': 75, 'time': '5 min', 'provider': 'CPX Research'},
      {'title': 'Shopping Behavior', 'coins': 150, 'time': '12 min', 'provider': 'Pollfish'},
      {'title': 'Mobile Gaming Survey', 'coins': 80, 'time': '6 min', 'provider': 'BitLabs'},
      {'title': 'Finance & Banking', 'coins': 120, 'time': '10 min', 'provider': 'CPX Research'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: surveys.length,
      itemBuilder: (context, index) {
        final s = surveys[index];
        return _SurveyCard(
          title: s['title'] as String,
          coins: s['coins'] as int,
          time: s['time'] as String,
          provider: s['provider'] as String,
        );
      },
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
      {'title': 'Install Game & Reach Level 10', 'coins': 500, 'icon': Icons.games_rounded, 'color': AppColors.primary},
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

  const _TaskCard({
    required this.title,
    required this.coins,
    required this.description,
    required this.onTap,
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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.task_alt_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(description, style: AppTextStyles.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(provider, style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w600,
                    )),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.goldContainer,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time_rounded, size: 12, color: AppColors.gold),
                        const SizedBox(width: 4),
                        Text(time, style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.gold, fontWeight: FontWeight.w600,
                        )),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  const Icon(Icons.monetization_on_rounded, size: 20, color: AppColors.gold),
                  const SizedBox(width: 6),
                  Text('+$coins coins', style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.gold, fontWeight: FontWeight.w700,
                  )),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Start'),
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