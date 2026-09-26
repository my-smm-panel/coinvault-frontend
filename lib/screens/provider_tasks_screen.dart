import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/provider_logos.dart';
import '../services/app_repository.dart';
import '../widgets/app_logo.dart';
import '../widgets/state_views.dart';
import 'task_detail_screen.dart';

/// Offers returned for one provider. An offer is shown here only when the
/// backend identifies it with the requested provider; no local starter tasks
/// or reward/instruction defaults are created.
class ProviderTasksScreen extends StatefulWidget {
  final String provider;
  const ProviderTasksScreen({super.key, required this.provider});

  @override
  State<ProviderTasksScreen> createState() => _ProviderTasksScreenState();
}

class _ProviderTasksScreenState extends State<ProviderTasksScreen> {
  List<Map<String, dynamic>> _tasks = [];
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get provider => widget.provider;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    final offers = await AppRepository.instance.fetchOffers();
    if (!mounted) return;
    if (offers == null) {
      setState(() {
        _loading = false;
        _failed = true;
      });
      return;
    }

    final mapped = offers.whereType<Map>().where((raw) {
      final type = (raw['type'] ?? '').toString().toUpperCase();
      final source = (raw['provider'] ?? '').toString().trim();
      return type.startsWith('INSTALL') &&
          source.isNotEmpty &&
          source.toLowerCase() == provider.trim().toLowerCase();
    }).map<Map<String, dynamic>>((raw) {
      final instructions = raw['instructions'];
      final steps = instructions is List
          ? instructions
              .where((e) => e != null && e.toString().trim().isNotEmpty)
              .map((e) => e.toString().trim())
              .toList()
          : <String>[];
      final id = (raw['id'] ?? raw['offerId'] ?? raw['providerOfferId'] ?? '')
          .toString()
          .trim();
      return <String, dynamic>{
        'id': id.isEmpty ? null : id,
        'title': (raw['title'] ?? raw['name'] ?? '').toString().trim(),
        'desc': (raw['shortDesc'] ?? raw['description'] ?? '').toString().trim(),
        'steps': steps,
      };
    }).where((task) => (task['title'] as String).isNotEmpty).toList();

    setState(() {
      _tasks = mapped;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = ProviderLogos.colorFor(provider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _header(color),
            Expanded(
              child: _loading
                  ? const ShimmerCardList(rows: 4)
                  : _failed
                      ? ErrorState(
                          message:
                              'Tasks could not be loaded. Check your connection.',
                          onRetry: _load,
                        )
                      : _tasks.isEmpty
                          ? const EmptyState(
                              icon: Icons.task_outlined,
                              title: 'No tasks right now',
                              subtitle:
                                  'New tasks are added when this provider supplies them.',
                            )
                          : RefreshIndicator(
                              color: AppColors.primary,
                              backgroundColor: AppColors.cardBackground,
                              onRefresh: _load,
                              child: ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                itemCount: _tasks.length,
                                itemBuilder: (_, i) =>
                                    _taskCard(_tasks[i], color),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: AppColors.brandHeader,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: AppLogo(
              provider: provider,
              size: 44,
              radius: 10,
              fallbackIcon: Icons.task_alt_rounded,
              fallbackColor: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(provider,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _taskCard(Map<String, dynamic> task, Color color) {
    final steps = (task['steps'] as List).cast<String>();
    final offerId = task['id'] as String?;
    final title = task['title'] as String;
    final desc = task['desc'] as String;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(desc,
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              height: 1.4),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),

            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TaskDetailScreen(
                    provider: provider,
                    title: title,
                    desc: desc,
                    coins: null,
                    steps: steps.isEmpty ? null : steps,
                    offerId: offerId,
                  ),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color.withOpacity(0.5)),
                foregroundColor: color,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                offerId == null ? 'View Details (start unavailable)' : 'View Details',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
