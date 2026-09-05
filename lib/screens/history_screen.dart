import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../services/app_repository.dart';
import 'earn_screen.dart';

/// History in ProRewards dark style: purple header, filter chips,
/// neon-bordered dark cards. Tabs: Tasks / Surveys / Games / Payouts.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<dynamic> _withdrawals = [];
  List<dynamic> _spins = [];
  List<dynamic> _tasks = [];
  bool _loading = true;
  String _filter = 'All';

  static const _bg = Color(0xFF0E0E13);
  static const _card = Color(0xFF17171F);

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final repo = AppRepository.instance;
    final w = await repo.fetchWithdrawalHistory('');
    final s = await repo.spinHistoryList();
    final t = await repo.taskHistoryList();
    if (!mounted) return;
    setState(() {
      _withdrawals = w;
      _spins = s;
      _tasks = t;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            _filterRow(),
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
                  : RefreshIndicator(
                      color: AppColors.primary,
                      backgroundColor: _card,
                      onRefresh: _load,
                      child: TabBarView(
                        controller: _tab,
                        children: [
                          _tasksTab(),
                          _surveysTab(),
                          _gamesTab(),
                          _payoutsTab(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Purple gradient header: back + History + total badge (kit style).
  Widget _header() {
    final total = _withdrawals.length + _spins.length + _tasks.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4A148C), Color(0xFF7B1FA2)],
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
              const SizedBox(width: 10),
              const Text('History',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$total records',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tab,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              tabs: const [
                Tab(text: 'Tasks'),
                Tab(text: 'Surveys'),
                Tab(text: 'Games'),
                Tab(text: 'Payouts'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Filter chips like kit Guaranteed/Quick/Medium row.
  Widget _filterRow() {
    const filters = ['All', 'Completed', 'Pending'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: filters.map((f) {
          final active = _filter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _filter = f),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : _card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: active
                          ? AppColors.primary
                          : Colors.white12),
                ),
                child: Text(f,
                    style: TextStyle(
                        color: active ? Colors.white : Colors.white60,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  bool _passFilter(String status) {
    if (_filter == 'All') return true;
    final s = status.toUpperCase();
    if (_filter == 'Completed') {
      return s == 'COMPLETED' ||
          s == 'VERIFIED' ||
          s == 'APPROVED' ||
          s == 'PAID';
    }
    return !(s == 'COMPLETED' ||
        s == 'VERIFIED' ||
        s == 'APPROVED' ||
        s == 'PAID');
  }

  // ---------------- TABS ----------------

  Widget _tasksTab() {
    final items = _tasks
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where((m) => _passFilter((m['status'] ?? '').toString()))
        .toList();
    if (items.isEmpty) return _empty('No task history yet', Icons.task_alt_rounded);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) => _taskTile(items[i]),
    );
  }

  Widget _surveysTab() {
    // No survey-history endpoint yet: honest empty state + Earn CTA.
    return _empty('No surveys completed yet', Icons.assignment_rounded,
        actionLabel: 'Earn Now',
        onAction: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const EarnScreen())));
  }

  Widget _gamesTab() {
    final items = _spins
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where((m) {
          final reward = ((m['reward'] ?? 0) as num).toInt();
          return _passFilter(reward > 0 ? 'COMPLETED' : 'PENDING');
        })
        .toList();
    if (items.isEmpty) return _empty('No games played yet', Icons.casino_rounded);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) => _gameTile(items[i], i),
    );
  }

  Widget _payoutsTab() {
    final items = _withdrawals
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where((m) => _passFilter((m['status'] ?? 'PENDING').toString()))
        .toList();
    if (items.isEmpty) return _empty('No payouts yet', Icons.account_balance_wallet_rounded);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) => _payoutTile(items[i]),
    );
  }

  // ---------------- TILES ----------------

  Widget _taskTile(Map m) {
    final offer = m['offer'];
    final title =
        offer is Map ? (offer['title'] ?? 'Task').toString() : 'Task';
    final status = (m['status'] ?? '').toString();
    final ok = status == 'VERIFIED' || status == 'APPROVED';
    final coins = ((m['coinsEarned'] ?? 0) as num).toInt();
    final tileColor = ok ? const Color(0xFF10B981) : AppColors.primary;
    return _darkCard(
      border: tileColor,
      child: Row(
        children: [
          _brandTile(title.isNotEmpty ? title[0].toUpperCase() : 'T',
              tileColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Text('Earned By You • +$coins coins',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          _statusPill(status.isEmpty ? 'PENDING' : status, ok),
        ],
      ),
    );
  }

  Widget _gameTile(Map m, int index) {
    final reward = ((m['reward'] ?? 0) as num).toInt();
    final won = reward > 0;
    const tileColor = AppColors.gold;
    const borders = [
      Color(0xFF10B981),
      Color(0xFF3B82F6),
      Color(0xFFF66B06),
      Color(0xFF8B5CF6),
    ];
    return _darkCard(
      border: borders[index % borders.length],
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: tileColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.casino_rounded,
                color: tileColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(won ? 'Spin Win' : 'Spin Played',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Text((m['rewardType'] ?? 'SPIN').toString(),
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Icon(Icons.monetization_on_rounded,
                      color: AppColors.gold, size: 14),
                  const SizedBox(width: 2),
                  Text(won ? '+$reward' : '0',
                      style: const TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                ],
              ),
              Text(won ? 'coins' : 'no win',
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _payoutTile(Map m) {
    final status = (m['status'] ?? 'PENDING').toString();
    final color = status == 'COMPLETED' || status == 'PAID'
        ? const Color(0xFF10B981)
        : status == 'REJECTED'
            ? const Color(0xFFEF4444)
            : AppColors.primary;
    final method =
        (m['method'] ?? '').toString().replaceAll('_', ' ');
    return _darkCard(
      border: color,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.account_balance_wallet_rounded,
                color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${m['amount'] ?? 0} coins • ₹${m['rupeeAmount'] ?? 0}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Text(method.isEmpty ? 'Withdrawal' : method,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          _statusPill(status, color == const Color(0xFF10B981)),
        ],
      ),
    );
  }

  // ---------------- PIECES ----------------

  Widget _darkCard({required Color border, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border.withOpacity(0.45)),
      ),
      child: child,
    );
  }

  Widget _brandTile(String letter, Color color) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(letter,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w800, fontSize: 20)),
      ),
    );
  }

  Widget _statusPill(String status, bool ok) {
    final color = ok ? const Color(0xFF10B981) : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 10)),
    );
  }

  Widget _empty(String msg, IconData icon,
      {String? actionLabel, VoidCallback? onAction}) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 40),
        Icon(icon, color: Colors.white24, size: 64),
        const SizedBox(height: 12),
        Text(msg,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 14)),
        if (actionLabel != null) ...[
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(actionLabel,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ],
    );
  }
}
