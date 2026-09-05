import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../services/app_repository.dart';

/// Leaderboard with podium top-3 + period tabs (kit screen 19).
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _period = 'WEEKLY';
  bool _loading = true;
  List<dynamic> _top = [];
  int? _myRank;
  int _myCoins = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await AppRepository.instance.fetchLeaderboard(_period);
    if (!mounted) return;
    final top = data['top'];
    setState(() {
      _top = top is List ? top : [];
      _myRank = (data['myRank'] ?? data['my_rank']) as int?;
      _myCoins = ((data['myCoins'] ?? data['my_coins'] ?? 0) as num).toInt();
      _loading = false;
    });
  }

  String _name(Map m) {
    final u = m['user'];
    if (u is Map) {
      final n = (u['name'] ?? '').toString();
      if (n.isNotEmpty) return n;
      final p = (u['phone'] ?? '').toString();
      if (p.length >= 4) return 'User ${p.substring(p.length - 4)}';
    }
    return 'User';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Leaderboard')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: ['DAILY', 'WEEKLY', 'MONTHLY', 'ALL_TIME'].map((p) {
                final active = _period == p;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: ChoiceChip(
                      label: Text(
                        p == 'ALL_TIME' ? 'All' : p[0] + p.substring(1).toLowerCase(),
                        style: TextStyle(
                          fontSize: 11,
                          color: active ? Colors.white : AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      selected: active,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surfaceVariant,
                      onSelected: (_) {
                        setState(() => _period = p);
                        _load();
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          if (_myRank != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your rank #$_myRank • $_myCoins coins',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _top.isEmpty
                    ? Center(
                        child: Text(
                          'No rankings yet. Complete tasks to climb!',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textTertiary),
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _load,
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            if (_top.length >= 3) _podium(),
                            const SizedBox(height: 8),
                            ..._top.skip(_top.length >= 3 ? 3 : 0).map((e) {
                              final m = Map<String, dynamic>.from(e as Map);
                              return _row(
                                m['rank'] as int? ?? 0,
                                _name(m),
                                ((m['coinsEarned'] ?? 0) as num).toInt(),
                              );
                            }),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _podium() {
    final first = Map<String, dynamic>.from(_top[0] as Map);
    final second = _top.length > 1 ? Map<String, dynamic>.from(_top[1] as Map) : null;
    final third = _top.length > 2 ? Map<String, dynamic>.from(_top[2] as Map) : null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (second != null)
            _podiumUser(second, 2, 70, Colors.white.withOpacity(0.85)),
          _podiumUser(first, 1, 92, AppColors.gold),
          if (third != null)
            _podiumUser(third, 3, 70, Colors.white.withOpacity(0.7)),
        ],
      ),
    );
  }

  Widget _podiumUser(Map m, int rank, double h, Color ring) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(shape: BoxShape.circle, color: ring),
          child: CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white,
            child: Text(
              _name(m).substring(0, 1).toUpperCase(),
              style: AppTextStyles.headlineMedium.copyWith(color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: h,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '#$rank',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _name(m),
                style: const TextStyle(color: Colors.white, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${((m['coinsEarned'] ?? 0) as num).toInt()}',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(int rank, String name, int coins) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '#$rank',
              style:
                  AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primaryContainer,
            child: Text(
              name.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(name,
                style: AppTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600)),
          ),
          const Icon(Icons.monetization_on_rounded,
              size: 16, color: AppColors.gold),
          const SizedBox(width: 4),
          Text('$coins',
              style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.gold, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
