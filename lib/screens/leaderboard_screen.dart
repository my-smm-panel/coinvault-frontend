import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../services/app_repository.dart';
import '../services/auth_service.dart';

/// Leaderboard - kit dark style: coin header, CoinVault podium,
/// your rank banner, Daily/Weekly/Monthly pills, letter-avatar rows.
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

  static const _bg = Color(0xFF0B0B12);
  static const _card = Color(0xFF17171F);

  static const _avatarColors = [
    Color(0xFF3B82F6),
    Color(0xFFF66B06),
    Color(0xFF8B5CF6),
    Color(0xFF10B981),
    Color(0xFFEC4899),
    Color(0xFF14B8A6),
  ];

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
    final walletCoins = AuthService().userModel?.coins ?? _myCoins;
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _header(walletCoins),
            _periodRow(),
            if (_myRank != null) _myRankBanner(),
            Expanded(
              child: _loading
                  ? const Center(
                      child: SizedBox(
                        width: 180,
                        child: LinearProgressIndicator(
                          color: AppColors.primary,
                          backgroundColor: Colors.white10,
                        ),
                      ),
                    )
                  : _top.isEmpty
                      ? const Center(
                          child: Text(
                            'No rankings yet. Complete tasks to climb!',
                            style: TextStyle(
                                color: Colors.white54, fontSize: 14),
                          ),
                        )
                      : RefreshIndicator(
                          color: AppColors.primary,
                          backgroundColor: _card,
                          onRefresh: _load,
                          child: ListView(
                            padding:
                                const EdgeInsets.fromLTRB(14, 10, 14, 20),
                            children: [
                              if (_top.length >= 3) _podium(),
                              if (_top.length >= 3)
                                const SizedBox(height: 12),
                              ..._top
                                  .skip(_top.length >= 3 ? 3 : 0)
                                  .map((e) {
                                final m =
                                    Map<String, dynamic>.from(
                                        e as Map);
                                return _row(
                                  m['rank'] as int? ?? 0,
                                  _name(m),
                                  ((m['coinsEarned'] ?? 0) as num)
                                      .toInt(),
                                );
                              }),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  /// Purple header: back + coins pill + COINVAULT LEADERBOARD.
  Widget _header(int walletCoins) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF66B06), Color(0xFFB34700)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.gold.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on_rounded,
                        color: AppColors.gold, size: 18),
                    const SizedBox(width: 6),
                    Text('$walletCoins',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF66B06), Color(0xFFB34700)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('COINVAULT LEADERBOARD',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }

  Widget _periodRow() {
    const periods = ['DAILY', 'WEEKLY', 'MONTHLY'];
    const labels = ['Daily', 'Weekly', 'Monthly'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Row(
        children: List.generate(periods.length, (i) {
          final active = _period == periods[i];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                setState(() => _period = periods[i]);
                _load();
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : _card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: active
                          ? AppColors.primary
                          : Colors.white12),
                ),
                child: Text(labels[i],
                    style: TextStyle(
                        color: active
                            ? Colors.white
                            : Colors.white60,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _myRankBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_rounded,
              color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Your Rank #$_myRank • $_myCoins coins',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _podium() {
    final first = Map<String, dynamic>.from(_top[0] as Map);
    final second = _top.length > 1
        ? Map<String, dynamic>.from(_top[1] as Map)
        : null;
    final third = _top.length > 2
        ? Map<String, dynamic>.from(_top[2] as Map)
        : null;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF66B06), Color(0xFFB34700)],
        ),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.gold.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (second != null)
            _podiumUser(second, 2, Colors.white.withOpacity(0.7)),
          _podiumUser(first, 1, AppColors.gold),
          if (third != null)
            _podiumUser(third, 3, Colors.white.withOpacity(0.5)),
        ],
      ),
    );
  }

  Widget _podiumUser(Map m, int rank, Color ring) {
    final name = _name(m);
    final coins = ((m['coinsEarned'] ?? 0) as num).toInt();
    return Column(
      children: [
        if (rank == 1)
          const Icon(Icons.emoji_events_rounded,
              color: AppColors.gold, size: 26),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(3),
          decoration:
              BoxDecoration(shape: BoxShape.circle, color: ring),
          child: CircleAvatar(
            radius: rank == 1 ? 30 : 25,
            backgroundColor: const Color(0xFF1A1A26),
            child: Text(
              name.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 22),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('#$rank',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12)),
        ),
        const SizedBox(height: 2),
        SizedBox(
          width: 90,
          child: Text(name,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: Colors.white, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.monetization_on_rounded,
                size: 13, color: AppColors.gold),
            const SizedBox(width: 2),
            Text('$coins',
                style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w800,
                    fontSize: 13)),
          ],
        ),
      ],
    );
  }

  Widget _row(int rank, String name, int coins) {
    final color = _avatarColors[rank % _avatarColors.length];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text('#$rank',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14)),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(0.2),
            child: Text(
              name.isEmpty ? 'U' : name.substring(0, 1).toUpperCase(),
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text('$coins coins',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.monetization_on_rounded,
              size: 16, color: AppColors.gold),
          const SizedBox(width: 4),
          Text('$coins',
              style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w800,
                  fontSize: 14)),
        ],
      ),
    );
  }
}
