import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../services/app_repository.dart';
import '../services/auth_service.dart';
import '../widgets/cv_header.dart';

/// Ranks / Leaderboard — light premium design.
/// Header, segmented period control, top-3 podium, My Rank card,
/// ranked list (current user highlighted), Your Stats.
/// Data from GET /api/leaderboard/:period (real, server-computed).
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _period = 'daily';
  List<Map<String, dynamic>> _top = [];
  Map<String, dynamic> _mine = {};
  bool _loading = true;
  bool _failed = false;

  static const Color _bg = Color(0xFFFAFAF8);
  static const Color _card = Color(0xFFFFFFFF);
  static const Color _border = Color(0xFFE7E7E7);
  static const Color _primaryText = Color(0xFF171717);
  static const Color _secondaryText = Color(0xFF6B7280);
  static const Color _orange = Color(0xFFF59E0B);
  static const Color _orange2 = Color(0xFFF7A928);
  static const Color _brown = Color(0xFF5A3825);

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
    final data = await AppRepository.instance.fetchLeaderboard(_period);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _failed = data == null;
      final top = data?['top'];
      _top = top is List
          ? top.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : [];
      _mine = (data?['my'] is Map)
          ? Map<String, dynamic>.from(data!['my'] as Map)
          : {};
    });
  }

  String _periodLabel() {
    switch (_period) {
      case 'weekly':
        return 'this week';
      case 'monthly':
        return 'this month';
      default:
        return 'today';
    }
  }

  String _name(Map e) {
    final u = e['user'];
    if (u is Map) {
      final n = (u['name'] ?? '').toString().trim();
      if (n.isNotEmpty) return n;
      final p = (u['phone'] ?? '').toString().trim();
      if (p.length >= 10) return 'User ${p.substring(p.length - 4)}';
    }
    return 'User';
  }

  String? _avatar(Map e) {
    final u = e['user'];
    return (u is Map) ? u['avatar']?.toString() : null;
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().userModel?.uid;
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CvHeader(),
            _segmented(),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: _orange, strokeWidth: 2.5))
                  : _failed
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Leaderboard could not be loaded.'),
                              const SizedBox(height: 8),
                              TextButton(onPressed: _load, child: const Text('Retry')),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                      color: _orange,
                      backgroundColor: _card,
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                        children: [
                          if (_top.isNotEmpty) ...[
                            _podium(),
                            const SizedBox(height: 16),
                            _myRankCard(),
                            const SizedBox(height: 18),
                          ],
                          _listTitle(),
                          const SizedBox(height: 8),
                          ..._rankRows(uid),
                          if (_top.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _statsSection(),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── HEADER ───────────────────────────

  // ─────────────────────────── SEGMENTED CONTROL ───────────────────────────
  Widget _segmented() {
    const tabs = ['daily', 'weekly', 'monthly'];
    const labels = ['Daily', 'Weekly', 'Monthly'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F1F4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: List.generate(3, (i) {
            final active = _period == tabs[i];
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  if (!active) {
                    setState(() => _period = tabs[i]);
                    _load();
                  }
                },
                child: Container(
                  margin: const EdgeInsets.all(3),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active ? _orange : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(labels[i],
                      style: TextStyle(
                        color: active ? Colors.white : _secondaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      )),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ─────────────────────────── PODIUM (top 3) ───────────────────────────
  Widget _podium() {
    // order: #2 left, #1 center (elevated), #3 right
    final first = _top[0];
    final second = _top.length > 1 ? _top[1] : null;
    final third = _top.length > 2 ? _top[2] : null;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _podiumSlot(second, 2, false, height: 96),
          _podiumSlot(first, 1, true, height: 116),
          _podiumSlot(third, 3, false, height: 96),
        ],
      ),
    );
  }

  Widget _podiumSlot(Map? e, int rank, bool gold, {required double height}) {
    final name = e != null ? _name(e) : '—';
    final rawCoins = e?['coinsEarned'];
    final coins = rawCoins is num ? rawCoins.toInt() : null;
    final avatar = e != null ? _avatar(e) : null;
    final d = 52.0 + (gold ? 12 : 0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // crown for #1
        if (gold)
          const Icon(Icons.emoji_events_rounded,
              color: _orange, size: 22)
        else
          const SizedBox(height: 22),
        const SizedBox(height: 4),
        Container(
          width: d,
          height: d,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: gold ? const Color(0xFFFFF7E6) : const Color(0xFFF1F1F4),
            border: Border.all(
                color: gold ? _orange : _border, width: gold ? 2.2 : 1),
          ),
          child: avatar != null && avatar.isNotEmpty
              ? ClipOval(
                  child: Image.network(avatar, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _initials(name, gold)))
              : _initials(name, gold),
        ),
        const SizedBox(height: 7),
        Text(name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: _primaryText, fontSize: 12.5, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(coins == null ? 'Coins unavailable' : '${_fmt(coins)} Coins',
            style: TextStyle(
                color: gold ? _brown : _secondaryText,
                fontSize: 11.5,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        // pedestal
        Container(
          height: height * 0.26,
          width: 64,
          decoration: BoxDecoration(
            color: gold
                ? const Color(0xFFFDEBC8)
                : const Color(0xFFF1F1F4),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text('#$rank',
              style: TextStyle(
                  color: gold ? _brown : _secondaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }

  Widget _initials(String name, bool gold) {
    final parts = name.trim().split(' ');
    final ini = parts.isNotEmpty && parts.first.isNotEmpty
        ? parts.first[0].toUpperCase()
        : '?';
    return Center(
      child: Text(ini,
          style: TextStyle(
            color: gold ? _brown : _secondaryText,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          )),
    );
  }

  // ─────────────────────────── MY RANK CARD ───────────────────────────
  Widget _myRankCard() {
    final rank = (_mine['rank'] as num?)?.toInt();
    final rawCoins = _mine['coinsEarned'];
    final coins = rawCoins is num ? rawCoins.toInt() : null;
    final periodCoins = coins == null
        ? 'Coins unavailable'
        : '${_fmt(coins)} Coins';
    if (rank == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7E6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF3E3C2)),
        ),
        child: const Text(
            'Complete a task to enter the leaderboard.',
            style: TextStyle(color: _secondaryText, fontSize: 13)),
      );
    }
    // progress to next rank: rough position indicator (rank vs 100)
    final pct = (100 - rank).clamp(0, 100) / 100;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3E3C2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('My Rank',
                  style: TextStyle(
                      color: _secondaryText,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('#$rank',
                  style: const TextStyle(
                      color: _brown,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 6),
          Text('$periodCoins ${_periodLabel()}',
              style: const TextStyle(
                  color: _primaryText, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: const Color(0xFFEFE4CD),
              color: _orange,
            ),
          ),
          const SizedBox(height: 5),
          Text('Climbing the ranks — keep earning!',
              style: TextStyle(color: _secondaryText, fontSize: 11)),
        ],
      ),
    );
  }

  // ─────────────────────────── LIST ───────────────────────────
  Widget _listTitle() {
    return const Text('Leaderboard',
        style: TextStyle(
            color: _primaryText, fontSize: 16, fontWeight: FontWeight.w800));
  }

  List<Widget> _rankRows(String? uid) {
    if (_top.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.only(top: 40),
          child: Center(
            child: Text('No rankings yet for this period.',
                style: TextStyle(color: _secondaryText, fontSize: 13)),
          ),
        ),
      ];
    }
    // Start from rank 4 (podium shows 1-3); malformed server rows are omitted.
    final rest = _top.where((e) {
      final rank = e['rank'];
      return rank is num && rank.toInt() >= 4;
    }).toList();
    return rest.map((e) {
      final rankValue = e['rank'];
      if (rankValue is! num) return const SizedBox.shrink();
      final rank = rankValue.toInt();
      final rawCoins = e['coinsEarned'];
      final coins = rawCoins is num ? rawCoins.toInt() : null;
      final name = _name(e);
      final avatar = _avatar(e);
      final isMe = e['userId']?.toString() == uid;
      return _rankRow(
        rank: rank,
        name: name,
        coins: coins,
        avatar: avatar,
        isMe: isMe,
      );
    }).toList();
  }

  Widget _rankRow({
    required int rank,
    required String name,
    required int? coins,
    String? avatar,
    bool isMe = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8, top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFFFF7E6) : _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isMe ? const Color(0xFFF3D9A8) : _border, width: 1),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text('#$rank',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: isMe ? _brown : _secondaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 10),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F1F4),
              shape: BoxShape.circle,
            ),
            child: avatar != null && avatar.isNotEmpty
                ? ClipOval(
                    child: Image.network(avatar, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _initials(name, false)))
                : _initials(name, false),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: _primaryText,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600)),
                ),
                if (isMe) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: _orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('You',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800)),
                  ),
                ],
              ],
            ),
          ),
          Text(coins == null ? '—' : _fmt(coins),
              style: const TextStyle(
                  color: _brown, fontSize: 13.5, fontWeight: FontWeight.w800)),
          const SizedBox(width: 4),
          const Icon(Icons.monetization_on_rounded,
              color: _orange, size: 15),
        ],
      ),
    );
  }

  // ─────────────────────────── YOUR STATS ───────────────────────────
  Widget _statsSection() {
    final uid = AuthService().userModel?.uid;
    final mineRows = _top.where((e) => e['userId']?.toString() == uid).toList();
    final mineRow = mineRows.isEmpty ? null : mineRows.first;
    final rawTasks = _mine['tasksCompleted'] ?? mineRow?['tasksCompleted'];
    final myTasks = rawTasks is num ? rawTasks.toInt() : null;
    final rawCoins = _mine['coinsEarned'] ?? mineRow?['coinsEarned'];
    final coins = rawCoins is num ? rawCoins.toInt() : null;
    final rawSurveys = _mine['surveysCompleted'] ?? mineRow?['surveysCompleted'];
    final surveys = rawSurveys is num ? rawSurveys.toInt() : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your Stats',
            style: TextStyle(
                color: _primaryText, fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Row(
          children: [
            _statCard('Coins Earned', coins == null ? '—' : _fmt(coins), Icons.savings_rounded,
                const Color(0xFFF59E0B)),
            const SizedBox(width: 10),
            _statCard('Tasks Completed', myTasks?.toString() ?? '—', Icons.task_alt_rounded,
                const Color(0xFF16A34A)),
            const SizedBox(width: 10),
            _statCard('Surveys', surveys?.toString() ?? '—', Icons.poll_rounded,
                const Color(0xFF3B82F6)),
          ],
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0F000000), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(height: 9),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: _primaryText,
                    fontSize: 17,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: _secondaryText, fontSize: 10.5)),
          ],
        ),
      ),
    );
  }

  String _fmt(int n) {
    final str = n.abs().toString();
    final sb = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) sb.write(',');
      sb.write(str[i]);
    }
    return n.isNegative ? '-$sb' : sb.toString();
  }
}
