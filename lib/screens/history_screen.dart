import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../services/app_repository.dart';

/// History: Withdrawals / Spins / Tasks (all from backend).
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

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('History'),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textTertiary,
          tabs: const [
            Tab(text: 'Withdrawals'),
            Tab(text: 'Spins'),
            Tab(text: 'Tasks'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _load,
              child: TabBarView(
                controller: _tab,
                children: [
                  _list(_withdrawals, _withdrawTile, 'No withdrawals yet'),
                  _list(_spins, _spinTile, 'No spins yet'),
                  _list(_tasks, _taskTile, 'No tasks yet'),
                ],
              ),
            ),
    );
  }

  Widget _list(List<dynamic> items, Widget Function(Map) tile, String empty) {
    if (items.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Center(
            child: Text(empty,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textTertiary)),
          ),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) => tile(Map<String, dynamic>.from(items[i] as Map)),
    );
  }

  Widget _card(Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.divider),
      ),
      child: child,
    );
  }

  Widget _withdrawTile(Map m) {
    final status = (m['status'] ?? 'PENDING').toString();
    final color = status == 'COMPLETED'
        ? AppColors.success
        : status == 'REJECTED'
            ? AppColors.error
            : AppColors.warning;
    return _card(Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: const Icon(Icons.account_balance_wallet_rounded,
              color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${m['amount'] ?? 0} coins • ₹${m['rupeeAmount'] ?? 0}',
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w700)),
              Text((m['method'] ?? '').toString().replaceAll('_', ' '),
                  style: AppTextStyles.bodySmall),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(status,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 11)),
        ),
      ],
    ));
  }

  Widget _spinTile(Map m) {
    final reward = ((m['reward'] ?? 0) as num).toInt();
    return _card(Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.goldContainer,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: const Icon(Icons.casino_rounded, color: AppColors.gold),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(reward > 0 ? '+$reward coins' : 'No win',
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w700)),
        ),
        Text((m['rewardType'] ?? '').toString(),
            style: AppTextStyles.bodySmall),
      ],
    ));
  }

  Widget _taskTile(Map m) {
    final offer = m['offer'];
    final title = offer is Map ? (offer['title'] ?? 'Task').toString() : 'Task';
    final status = (m['status'] ?? '').toString();
    final color =
        status == 'VERIFIED' ? AppColors.success : AppColors.warning;
    return _card(Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child:
              const Icon(Icons.task_alt_rounded, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600)),
              Text('+${((m['coinsEarned'] ?? 0) as num).toInt()} coins',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.gold)),
            ],
          ),
        ),
        Text(status,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: 11)),
      ],
    ));
  }
}
