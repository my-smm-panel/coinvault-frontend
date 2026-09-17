import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../widgets/cv_header.dart';
import '../core/provider_logos.dart';
import '../services/app_repository.dart';
import '../services/auth_service.dart';
import '../widgets/state_views.dart';
import 'provider_tasks_screen.dart';
import 'task_detail_screen.dart';
import 'redeem_screen.dart';

class EarnScreen extends StatefulWidget {
  const EarnScreen({super.key});

  @override
  State<EarnScreen> createState() => _EarnScreenState();
}

class _EarnScreenState extends State<EarnScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _offers = [];
  bool _loading = true;
  bool _offersFailed = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    setState(() {
      _loading = true;
      _offersFailed = false;
    });
    final repo = AppRepository.instance;
    final offers = await repo.fetchOffers();
    if (mounted) {
      setState(() {
        _offers = offers ?? [];
        _offersFailed = offers == null;
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
    final user = AuthService().userModel;
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: CvHeader(),
      ),
      backgroundColor: AppColors.background,
      
      body: _loading
          ? const ShimmerCardList(rows: 6)
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTaskList(),
                _buildSurveyList(),
                _buildOfferList(),
                _buildGiftCardList(),
              ],
            ),
    );
  }

  /// Brand icon + color per task type (kit style).


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
    // Top: big square provider logos — tightly packed (little gap, thin line keeps rows)
    final quickTasks = [
      {'title': 'Ludo Supreme — Play 5 games', 'coins': 500, 'provider': 'PubScale'},
      {'title': 'MPL — Install & Play', 'coins': 350, 'provider': 'CPI Droid'},
      {'title': 'Rummy Circle — 3 rounds', 'coins': 300, 'provider': 'PubScale'},
      {'title': 'Watch & Earn — 3 videos', 'coins': 30, 'provider': 'Lootably'},
      {'title': 'Daily Check-in', 'coins': 25, 'provider': 'TimeWall'},
      {'title': 'Rate App on Play Store', 'coins': 30, 'provider': 'OfferPro'},
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1,
            ),
            itemCount: _taskProviders.length,
            itemBuilder: (context, index) {
              final name = _taskProviders[index];
              return InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProviderTasksScreen(provider: name),
                  ),
                ),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.textPrimary.withOpacity(0.06), width: 1),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ProviderLogo(name, size: 60),
                      const SizedBox(height: 6),
                      Text(name,
                          style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                              fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text('Popular Tasks', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 10),
          ...quickTasks.map((t) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.textPrimary.withOpacity(0.06)),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TaskDetailScreen(
                            provider: t['provider'] as String,
                            title: t['title'] as String,
                            desc: 'Complete this offer from our partner ${t['provider']} to earn coins.',
                            coins: t['coins'] as int,
                            steps: const [
                              'Open the offer',
                              'Follow the instructions',
                              'Complete the activity',
                              'Coins credited after verification',
                            ],
                          ),
                        )),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: AppColors.textPrimary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(6),
                            child: ProviderLogo(t['provider'] as String, size: 42),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t['title'] as String, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: ProviderLogos.colorFor(t['provider'] as String).withOpacity(0.18), borderRadius: BorderRadius.circular(6)),
                                      child: Text(t['provider'] as String, style: TextStyle(color: ProviderLogos.colorFor(t['provider'] as String), fontSize: 10, fontWeight: FontWeight.w700)),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.schedule_rounded, size: 12, color: Colors.white38),
                                    const SizedBox(width: 2),
                                    Text('${(t['coins'] as int) ~/ 20} min',
                                        style: const TextStyle(
                                            color: Colors.white38,
                                            fontSize: 10)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      gradient: AppColors.goldGradient,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text('+${t['coins']}',
                                        style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: AppColors.primary.withOpacity(0.4)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('GO',
                                        style: TextStyle(
                                            color: AppColors.primaryLight,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800)),
                                    SizedBox(width: 2),
                                    Icon(Icons.arrow_forward_rounded,
                                        color: AppColors.primaryLight,
                                        size: 12),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }


  /// Survey providers only (kit style grid).
  static const List<Map<String, dynamic>> _providers = [
    {'name': 'Cint', 'bonus': '55% BONUS', 'color': Color(0xFF8B5CF6)},
    {'name': 'Prime Surveys', 'bonus': '', 'color': Color(0xFF3B82F6)},
    {'name': 'TimeWall', 'bonus': '', 'color': Color(0xFF16A34A)},
    {'name': 'BitLabs', 'bonus': '', 'color': Color(0xFF8B5CF6)},
    {'name': 'CPX Research', 'bonus': '', 'color': Color(0xFF3B82F6)},
    {'name': 'Pollfish', 'bonus': '', 'color': Color(0xFF14B8A6)},
  ];

  /// Surveys tab shows ONLY providers; tap opens that provider's surveys.
  Widget _buildSurveyList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 14, 12, 4),
          child: Text('SURVEY PROVIDERS',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1)),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1,
            ),
            itemCount: _providers.length,
            itemBuilder: (context, index) {
              final p = _providers[index];
              return InkWell(
                onTap: () => _showProviderSurveys(
                    p['name'] as String, context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.textPrimary.withOpacity(0.06), width: 1),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ProviderLogo(p['name'] as String, size: 60),
                      const SizedBox(height: 6),
                      Text(p['name'] as String,
                          style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                              fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showProviderSurveys(String provider, BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => FutureBuilder<List<dynamic>?>(
        future: AppRepository.instance.fetchSurveys(),
        builder: (context, snap) {
          final all = snap.data ?? [];
          final list = all
              .where((s) => ((s as Map)['provider'] ?? '') == provider)
              .toList();
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFFFFFFF),
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
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                    snap.connectionState == ConnectionState.waiting
                        ? 'Loading surveys…'
                        : snap.data == null
                            ? 'Could not load surveys'
                            : '${list.length} surveys available',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 12),
                Flexible(
                  child: list.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text('No surveys from this provider yet',
                                style: TextStyle(
                                    color: Colors.white38, fontSize: 13)),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: list.length,
                          itemBuilder: (_, i) {
                            final s =
                                Map<String, dynamic>.from(list[i] as Map);
                            return _SurveyCard(
                              title: (s['title'] ?? '').toString(),
                              coins: ((s['coins'] ?? 0) as num).toInt(),
                              time: (s['duration'] ?? '').toString(),
                              provider: (s['provider'] ?? '').toString(),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOfferList() {
    if (_offersFailed) {
      return ErrorState(
        message: 'Offers could not be loaded.',
        onRetry: _loadOffers,
      );
    }
    if (_offers.isEmpty) {
      return const EmptyState(
        icon: Icons.local_offer_outlined,
        title: 'No offers yet',
        subtitle: 'New offers added daily.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      itemCount: _offers.length,
      itemBuilder: (context, index) {
        final offer = Map<String, dynamic>.from(_offers[index] as Map);
        return _OfferCard(offer: offer);
      },
    );
  }

  Widget _buildGiftCardList() {
    // Navigate to full RedeemScreen
    return const RedeemScreen();
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
            color: const Color(0xFFFFFFFF),
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
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textPrimary, size: 26),
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
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Trending 🔥',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 9,
                      fontWeight: FontWeight.w800)),
            ),
          ),
      ],
    );
  }
}

/// Production offer card: renders real backend offer fields
/// (title/shortDesc/coins/timeEstimate/isHot/isNew) with HOT/NEW badges.
class _OfferCard extends StatelessWidget {
  final Map<String, dynamic> offer;

  const _OfferCard({required this.offer});

  IconData get _typeIcon {
    switch ((offer['type'] ?? '').toString()) {
      case 'INSTALL':
      case 'INSTALL_AND_USE':
      case 'INSTALL_AND_REACH_LEVEL':
      case 'INSTALL_AND_DEPOSIT':
      case 'INSTALL_AND_KYC':
        return Icons.download_rounded;
      case 'VIDEO':
        return Icons.play_circle_fill_rounded;
      case 'SURVEY':
        return Icons.assignment_rounded;
      case 'SIGNUP':
        return Icons.person_add_rounded;
      case 'SHARE':
        return Icons.share_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHot = offer['isHot'] == true;
    final isNew = offer['isNew'] == true;
    final coins = ((offer['coins'] ?? 0) as num).toInt();
    final title = (offer['title'] ?? '').toString();
    final sub = (offer['shortDesc'] ?? 'Complete to earn').toString();
    final time = (offer['timeEstimate'] ?? '').toString();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.divider),
          ),
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(_typeIcon, color: AppColors.primary, size: 26),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: AppTextStyles.bodyMedium
                                .copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(sub,
                            style: AppTextStyles.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        if (time.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.schedule_rounded,
                                  size: 12, color: AppColors.textTertiary),
                              const SizedBox(width: 3),
                              Text(time, style: AppTextStyles.bodySmall),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.monetization_on_rounded,
                              size: 16, color: AppColors.gold),
                          const SizedBox(width: 2),
                          Text('$coins',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.gold,
                                fontWeight: FontWeight.w800,
                              )),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Text('GO',
                            style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isHot || isNew)
          Positioned(
            top: -7,
            right: 14,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isHot ? AppColors.error : AppColors.success,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(isHot ? 'HOT' : 'NEW',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 9,
                      fontWeight: FontWeight.w800)),
            ),
          ),
      ],
    );
  }
}