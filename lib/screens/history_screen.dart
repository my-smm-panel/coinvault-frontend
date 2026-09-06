import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../services/app_repository.dart';

/// History - own CoinVault style (NOT ProRewards):
/// orange header, orange segment control, filter chips,
/// dark cards with gold coin figures and status dots.
class HistoryScreen extends StatefulWidget {
  final String initialTab; // 'Tasks' or 'Payouts'
  const HistoryScreen({super.key, this.initialTab = 'Tasks'});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late String _tab;
  String _filter = 'All';
  List<dynamic> _withdrawals = [];
  List<dynamic> _tasks = [];
  bool _loading = true;

  static const _bg = Color(0xFF0B0B12);
  static const _card = Color(0xFF17171F);

  static const _tileColors = [
    Color(0xFFF66B06),
    Color(0xFFF59E0B),
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFFEC4899),
    Color(0xFF14B8A6),
  ];

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab == 'Payouts' ? 'Payouts' : 'Tasks';
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final repo = AppRepository.instance;
    final w = await repo.fetchWithdrawalHistory('');
    final t = await repo.taskHistoryList();
    if (!mounted) return;
    setState(() {
      _withdrawals = w;
      _tasks = t;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = _withdrawals.length + _tasks.length;
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _header(total),
            _segment(),
            _filters(),
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
                      child: _tab == 'Payouts'
                          ? _payoutsList()
                          : _tasksList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(int total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        gradient: AppColors.brandHeader,
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
              color: Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on_rounded,
                    color: AppColors.goldLight, size: 16),
                const SizedBox(width: 4),
                Text('$total',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Orange segment control (own style, not pill tabs).
  Widget _segment() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: ['Tasks', 'Payouts'].map((t) {
            final active = _tab == t;
            return Expanded(
              child: InkWell(
                onTap: () => setState(() => _tab = t),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    gradient: active
                        ? AppColors.primaryGradient
                        : null,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                          t == 'Tasks'
                              ? Icons.task_alt_rounded
                              : Icons.payments_rounded,
                          size: 16,
                          color: active
                              ? Colors.white
                              : Colors.white54),
                      const SizedBox(width: 6),
                      Text(t,
                          style: TextStyle(
                              color: active
                                  ? Colors.white
                                  : Colors.white54,
                              fontSize: 14,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _filters() {
    const fs = ['All', 'Ongoing', 'Completed', 'Expired', 'Rejected'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 2),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: fs.map((f) {
            final active = _filter == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => setState(() => _filter = f),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.primary.withOpacity(0.18)
                        : _card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: active
                            ? AppColors.primary
                            : Colors.white10),
                  ),
                  child: Text(f,
                      style: TextStyle(
                          color: active
                              ? AppColors.primaryLight
                              : Colors.white60,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ---------------- FILTER ----------------

  bool _pass(String bucket) => _filter == 'All' || bucket == _filter;

  String _taskBucket(String status) {
    final s = status.toUpperCase();
    if (s == 'VERIFIED' || s == 'APPROVED' || s == 'COMPLETED') {
      return 'Completed';
    } else if (s == 'REJECTED') {
      return 'Rejected';
    } else if (s == 'EXPIRED') {
      return 'Expired';
    }
    return 'Ongoing';
  }

  String _payoutBucket(String status) {
    final s = status.toUpperCase();
    if (s == 'COMPLETED' || s == 'PAID') return 'Completed';
    if (s == 'REJECTED') return 'Rejected';
    if (s == 'EXPIRED') return 'Expired';
    return 'Ongoing';
  }

  String _date(Map m) {
    final raw =
        (m['createdAt'] ?? m['date'] ?? m['completedAt'] ?? '')
            .toString();
    if (raw.isEmpty) return '';
    try {
      final d = DateTime.parse(raw).toLocal();
      const mon = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${d.day} ${mon[d.month - 1]} ${d.year}';
    } catch (_) {
      return raw.length > 10 ? raw.substring(0, 10) : raw;
    }
  }

  // ---------------- LISTS ----------------

  Widget _tasksList() {
    final items = _tasks
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where((m) => _pass(_taskBucket(
            (m['status'] ?? '').toString())))
        .toList();
    if (items.isEmpty) return _empty('No tasks here yet');
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final m = items[i];
        final offer = m['offer'];
        final title = offer is Map
            ? (offer['title'] ?? 'Task').toString()
            : 'Task';
        final status = (m['status'] ?? '').toString();
        final bucket = _taskBucket(status);
        final coins = ((m['coinsEarned'] ?? 0) as num).toInt();
        final date = _date(m);
        return _darkTile(
          title: title,
          sub: date.isEmpty ? bucket : '$bucket • $date',
          coinsText: '+$coins',
          bucket: bucket,
          icon: Icons.task_alt_rounded,
          color: _tileColors[title.hashCode.abs() % _tileColors.length],
        );
      },
    );
  }

  Widget _payoutsList() {
    final items = _withdrawals
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where((m) => _pass(_payoutBucket(
            (m['status'] ?? 'PENDING').toString())))
        .toList();
    if (items.isEmpty) return _empty('No payouts here yet');
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final m = items[i];
        final status =
            (m['status'] ?? 'PENDING').toString();
        final bucket = _payoutBucket(status);
        final amount = (m['amount'] ?? 0).toString();
        final rupees = (m['rupeeAmount'] ?? 0).toString();
        final method =
            (m['method'] ?? '').toString().replaceAll('_', ' ');
        final date = _date(m);
        final sub =
            '${method.isEmpty ? 'Withdrawal' : method}${date.isEmpty ? '' : ' • $date'}';
        return _darkTile(
          title: '$amount coins  →  ₹$rupees',
          sub: '$bucket • $sub',
          coinsText: '₹$rupees',
          bucket: bucket,
          icon: Icons.payments_rounded,
          color: AppColors.primary,
        );
      },
    );
  }

  // ---------------- OWN DARK TILE ----------------

  Widget _darkTile({
    required String title,
    required String sub,
    required String coinsText,
    required String bucket,
    required IconData icon,
    required Color color,
  }) {
    final ok = bucket == 'Completed';
    final dot = ok
        ? const Color(0xFF10B981)
        : bucket == 'Ongoing'
            ? AppColors.primary
            : const Color(0xFFEF4444);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.55)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                          color: dot, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(sub,
                          style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
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
                      color: AppColors.gold, size: 15),
                  const SizedBox(width: 3),
                  Text(coinsText,
                      style: const TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w800,
                          fontSize: 14)),
                ],
              ),
              Text(bucket,
                  style: TextStyle(
                      color: dot,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _empty(String msg) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 60),
        const Icon(Icons.inbox_rounded,
            color: Colors.white24, size: 56),
        const SizedBox(height: 12),
        Text(msg,
            textAlign: TextAlign.center,
            style:
                const TextStyle(color: Colors.white54, fontSize: 14)),
      ],
    );
  }
}
