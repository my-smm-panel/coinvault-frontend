import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/provider_logos.dart';
import '../services/app_repository.dart';
import '../widgets/state_views.dart';

/// One provider's available tasks on its own page.
/// Header shows the company logo big; below, only its tasks.
/// Tasks come from the real backend (GET /api/offers) — starter
/// tasks are shown per provider until the backend exposes per-provider
/// task listings (the offer schema has no provider field yet).
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
    final mapped = offers
        .where((o) =>
            ((o as Map)['type'] ?? '').toString().startsWith('INSTALL'))
        .take(6)
        .map((o) {
      final m = o as Map;
      final steps = (m['instructions'] is List)
          ? (m['instructions'] as List).map((e) => e.toString()).toList()
          : <String>[];
      return <String, dynamic>{
        'title': (m['title'] ?? '').toString(),
        'desc': (m['shortDesc'] ?? '').toString(),
        'coins': ((m['coins'] ?? 0) as num).toInt(),
        'steps': steps.isEmpty
            ? <String>['Tap Start', 'Complete the task', 'Coins credited']
            : steps,
      };
    }).toList();
    setState(() {
      _tasks = mapped;
      _loading = false;
    });
  }

  String get provider => widget.provider;

  @override
  Widget build(BuildContext context) {
    final color = ProviderLogos.colorFor(provider);
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B12),
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
                                  'New tasks are added daily — check back soon.',
                            )
                          : RefreshIndicator(
                              color: AppColors.primary,
                              backgroundColor: const Color(0xFF17171F),
                              onRefresh: _load,
                              child: ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 4, 16, 20),
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
              padding: const EdgeInsets.all(8),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ProviderLogo(provider, size: 44, radius: 8),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(provider,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text('Official partner tasks',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.85), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _taskCard(Map<String, dynamic> t, Color color) {
    final coins = t['coins'] as int;
    final steps = (t['steps'] as List).cast<String>();
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF17171F),
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
                    Text(t['title'] as String,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(t['desc'] as String,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('+$coins',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...steps.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('${e.key + 1}',
                            style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(e.value,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Task started! Complete the steps to earn coins.')),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Start Task',
                  style:
                      TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}