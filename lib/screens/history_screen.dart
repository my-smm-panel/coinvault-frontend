import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../services/app_repository.dart';
import 'earn_screen.dart';

/// Earning History - exact kit style: purple header, white pill tabs,
/// Ongoing/Completed/Expired/Rejected sub-tabs, white cards with
/// status pill + progress line + bottom progress bar + logo tile.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _tab = 'Tasks';
  String _sub = 'Ongoing';
  List<dynamic> _withdrawals = [];
  List<dynamic> _spins = [];
  List<dynamic> _tasks = [];
  bool _loading = true;

  static const _bg = Color(0xFF0B0B12);
  static const _red = Color(0xFFF04438);
  static const _blue = Color(0xFF2E90FA);

  static const _logoColors = [
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            _pillTabs(),
            _subTabs(),
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
                      backgroundColor: Colors.white,
                      onRefresh: _load,
                      child: _currentTab(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4A148C), Color(0xFF6A1B9A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
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
          const SizedBox(width: 12),
          const Text('Earning History',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _pillTabs() {
    const tabs = ['Tasks', 'Surveys', 'Games', 'Payouts'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Row(
        children: tabs.map((t) {
          final active = _tab == t;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              onTap: () => setState(() => _tab = t),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 22, vertical: 9),
                decoration: BoxDecoration(
                  color: active ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: active ? Colors.white : Colors.white24),
                ),
                child: Text(t,
                    style: TextStyle(
                        color: active
                            ? const Color(0xFF1A1A22)
                            : Colors.white54,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _subTabs() {
    const subs = ['Ongoing', 'Completed', 'Expired', 'Rejected'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 0),
      child: Row(
        children: subs.map((s) {
          final active = _sub == s;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _sub = s),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(s,
                        style: TextStyle(
                            color: active ? Colors.white : Colors.white60,
                            fontSize: 14,
                            fontWeight: active
                                ? FontWeight.w800
                                : FontWeight.w500)),
                  ),
                  Container(
                    height: 3,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.white
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _currentTab() {
    switch (_tab) {
      case 'Surveys':
        return _surveysList();
      case 'Games':
        return _gamesList();
      case 'Payouts':
        return _payoutsList();
      default:
        return _tasksList();
    }
  }

  // ---------------- DATA ----------------

  /// Normalize any backend item into kit card fields.
  /// Returns null when it does not belong in the active sub-tab.
  Map<String, dynamic>? _kitTask(Map m) {
    final offer = m['offer'];
    final title =
        offer is Map ? (offer['title'] ?? 'Task').toString() : 'Task';
    final status = (m['status'] ?? 'PENDING').toString().toUpperCase();
    final coins = ((m['coinsEarned'] ?? 0) as num).toInt();
    String bucket;
    if (status == 'VERIFIED' ||
        status == 'APPROVED' ||
        status == 'COMPLETED') {
      bucket = 'Completed';
    } else if (status == 'REJECTED') {
      bucket = 'Rejected';
    } else if (status == 'EXPIRED') {
      bucket = 'Expired';
    } else {
      bucket = 'Ongoing';
    }
    if (bucket != _sub) return null;
    final done = bucket == 'Completed';
    return {
      'title': title,
      'pill': done ? 'Coins earned  $coins' : _ongoingLabel(status),
      'pillBlue': done,
      'progress': done ? '100% Completed' : '50% Completed',
      'pct': done ? 1.0 : 0.5,
      'barBlue': done,
      'date': _date(m),
    };
  }

  Map<String, dynamic>? _kitGame(Map m) {
    final reward = ((m['reward'] ?? 0) as num).toInt();
    final won = reward > 0;
    final bucket = won ? 'Completed' : 'Expired';
    if (bucket != _sub) return null;
    return {
      'title': won ? 'Spin Win' : 'Spin Played',
      'pill': won ? 'Coins earned  $reward' : 'No Win',
      'pillBlue': won,
      'progress': won ? '100% Completed' : '0% Completed',
      'pct': won ? 1.0 : 0.0,
      'barBlue': won,
      'date': _date(m),
    };
  }

  Map<String, dynamic>? _kitPayout(Map m) {
    final status = (m['status'] ?? 'PENDING').toString().toUpperCase();
    final amount = (m['amount'] ?? 0).toString();
    final rupees = (m['rupeeAmount'] ?? 0).toString();
    String bucket;
    if (status == 'COMPLETED' || status == 'PAID') {
      bucket = 'Completed';
    } else if (status == 'REJECTED') {
      bucket = 'Rejected';
    } else if (status == 'EXPIRED') {
      bucket = 'Expired';
    } else {
      bucket = 'Ongoing';
    }
    if (bucket != _sub) return null;
    final done = bucket == 'Completed';
    return {
      'title': '$amount coins • ₹$rupees',
      'pill': done ? 'Paid  ₹$rupees' : _ongoingLabel(status),
      'pillBlue': done,
      'progress': done ? '100% Completed' : '50% Completed',
      'pct': done ? 1.0 : 0.5,
      'barBlue': done,
      'date': _date(m),
    };
  }

  String _ongoingLabel(String status) {
    if (status == 'PENDING' || status == 'PROCESSING') return 'Ongoing';
    if (status == 'DISQUALIFIED') return 'Disqualified';
    if (status.isEmpty) return 'Ongoing';
    final s = status[0] + status.substring(1).toLowerCase();
    return s.replaceAll('_', ' ');
  }

  String _date(Map m) {
    final raw = (m['createdAt'] ?? m['date'] ?? m['completedAt'] ?? '')
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
        .map(_kitTask)
        .whereType<Map<String, dynamic>>()
        .toList();
    if (items.isEmpty) return _empty('Nothing here yet');
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      itemCount: items.length,
      itemBuilder: (_, i) => _kitCard(items[i]),
    );
  }

  Widget _gamesList() {
    final items = _spins
        .map((e) => Map<String, dynamic>.from(e as Map))
        .map(_kitGame)
        .whereType<Map<String, dynamic>>()
        .toList();
    if (items.isEmpty) return _empty('Nothing here yet');
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      itemCount: items.length,
      itemBuilder: (_, i) => _kitCard(items[i]),
    );
  }

  Widget _payoutsList() {
    final items = _withdrawals
        .map((e) => Map<String, dynamic>.from(e as Map))
        .map(_kitPayout)
        .whereType<Map<String, dynamic>>()
        .toList();
    if (items.isEmpty) return _empty('Nothing here yet');
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      itemCount: items.length,
      itemBuilder: (_, i) => _kitCard(items[i]),
    );
  }

  Widget _surveysList() {
    // No survey-history endpoint yet: honest kit-styled empty state.
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Text('No surveys completed yet',
                  style: TextStyle(
                      color: Color(0xFF1A1A22),
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text('Complete a survey to see it here',
                  style:
                      TextStyle(color: Color(0xFF667085), fontSize: 13)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const EarnScreen())),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Earn Now',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------- KIT CARD ----------------

  Widget _kitCard(Map<String, dynamic> k) {
    final title = (k['title'] ?? '').toString();
    final pill = (k['pill'] ?? '').toString();
    final pillBlue = k['pillBlue'] as bool;
    final progress = (k['progress'] ?? '').toString();
    final pct = (k['pct'] as num).toDouble().clamp(0.0, 1.0);
    final barBlue = k['barBlue'] as bool;
    final date = (k['date'] ?? '').toString();
    final pillColor = pillBlue ? _blue : _red;
    final logoColor =
        _logoColors[title.hashCode.abs() % _logoColors.length];
    final line = date.isEmpty ? progress : '$progress | $date';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                color: Color(0xFF1A1A22),
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: pillColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(pill,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(height: 6),
                        Text(line,
                            style: TextStyle(
                                color: pillColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: logoColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                          title.isNotEmpty
                              ? title[0].toUpperCase()
                              : 'C',
                          style: TextStyle(
                              color: logoColor,
                              fontSize: 24,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),
            FractionallySizedBox(
              widthFactor: pct <= 0 ? 0.02 : pct,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: barBlue ? _blue : _red,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(2),
                    bottomRight: Radius.circular(2),
                  ),
                ),
              ),
            ),
          ],
        ),
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
