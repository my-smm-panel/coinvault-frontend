import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_theme.dart';
import '../services/app_repository.dart';

/// Tracking — CoinVault light theme (per design sheet).
/// Keeps the 3 tabs (Activity / Withdrawals / Referrals) and all data logic.
class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen>
    with SingleTickerProviderStateMixin {
  static const _bg = AppColors.background;

  late final TabController _tabs = TabController(length: 3, vsync: this);
  bool _loading = true;
  String? _error;
  bool _activityFailed = false;
  bool _withdrawalsFailed = false;
  bool _referralsFailed = false;

  // Activity
  List<Map<String, dynamic>> _activity = [];

  // Withdrawals
  List<Map<String, dynamic>> _withdrawals = [];

  // Referrals
  String _referralCode = '';
  String _referralLink = '';
  int? _totalReferrals;
  int? _activeReferrals;
  int? _referralCoins;
  List<Map<String, dynamic>> _referralList = [];

  // Stats
  int? _coins;
  int? _spins;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = AppRepository.instance;
      final results = await Future.wait<dynamic>([
        repo.fetchActivity(), // 0
        repo.fetchWithdrawalHistory(''), // 1 (the endpoint is authenticated)
        repo.referralInfo(), // 2
        repo.fetchWalletBalance(), // 3 — fresh server wallet
        repo.spinStatus(), // 4 — server-authoritative spin status
      ]);
      _activityFailed = results[0] == null;
      _withdrawalsFailed = results[1] == null;
      _referralsFailed = results[2] == null;

      // activity
      final act = results[0];
      _activity = act is List
          ? act.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : [];

      // withdrawals
      final wRaw = results[1];
      List<dynamic> wList = [];
      if (wRaw is List) {
        wList = wRaw;
      } else if (wRaw is Map) {
        final d = wRaw['data'];
        final items = (d is Map) ? (d['items'] ?? d['withdrawals']) : null;
        wList = items is List ? items : (d is List ? d : []);
      }
      _withdrawals = wList.whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      // referrals
      final r = results[2];
      if (r is Map) {
        final d = r['data'] is Map ? r['data'] as Map : r;
        _referralCode = d['referralCode']?.toString() ?? '';
        _referralLink = d['referralLink']?.toString() ?? '';
        final total = d['totalReferrals'];
        final active = d['activeReferrals'];
        final referralCoins = d['totalCoinsEarned'];
        _totalReferrals = total is num ? total.toInt() : null;
        _activeReferrals = active is num ? active.toInt() : null;
        _referralCoins = referralCoins is num ? referralCoins.toInt() : null;
        final rl = d['referrals'];
        _referralList = rl is List
            ? rl.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
            : [];
      }

      // Wallet and spin usage are server-only. Do not fall back to the
      // cached profile or a local/default daily limit.
      _coins = results[3] as int?;
      final status = results[4];
      final used = status is Map ? status['spinsUsed'] : null;
      _spins = used is num ? used.toInt() : null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
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
            _segmentedTabs(),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary))
                  : _error != null
                      ? _ErrorView(error: _error!, onRetry: _loadAll)
                      : RefreshIndicator(
                          color: AppColors.primary,
                          backgroundColor: AppColors.cardBackground,
                          onRefresh: _loadAll,
                          child: TabBarView(
                            controller: _tabs,
                            children: [
                              _activityFailed
                                  ? _ErrorView(error: 'Activity could not be loaded.', onRetry: _loadAll)
                                  : _ActivityTab(
                                      activity: _activity,
                                      coins: _coins,
                                      spins: _spins,
                                    ),
                              _withdrawalsFailed
                                  ? _ErrorView(error: 'Withdrawals could not be loaded.', onRetry: _loadAll)
                                  : _WithdrawalsTab(withdrawals: _withdrawals),
                              _referralsFailed
                                  ? _ErrorView(error: 'Referrals could not be loaded.', onRetry: _loadAll)
                                  : _ReferralsTab(
                                      code: _referralCode,
                                      referralLink: _referralLink,
                                      total: _totalReferrals,
                                      active: _activeReferrals,
                                      coins: _referralCoins,
                                      list: _referralList,
                                    ),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  /// Orange header with back arrow + title (per design sheet).
  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 14, 14),
      decoration: const BoxDecoration(gradient: AppColors.brandHeader),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Tracking',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _loadAll,
            icon: Icon(Icons.refresh_rounded,
                color: Colors.white.withOpacity(0.95), size: 20),
          ),
        ],
      ),
    );
  }

  /// White pill segmented bar sitting just under the header.
  Widget _segmentedTabs() {
    return Container(
      color: _bg,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: AppColors.border),
        ),
        child: TabBar(
          controller: _tabs,
          dividerColor: Colors.transparent,
          indicator: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppRadius.full),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.all(4),
          tabs: const [
            Tab(text: 'Activity'),
            Tab(text: 'Withdrawals'),
            Tab(text: 'Referrals'),
          ],
        ),
      ),
    );
  }
}

// =================== ACTIVITY TAB ===================
class _ActivityTab extends StatelessWidget {
  final List<Map<String, dynamic>> activity;
  final int? coins, spins;
  const _ActivityTab({required this.activity, required this.coins, required this.spins});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: [
        // Balance hero (white card, orange figure + gold coin icon)
        _balanceHero(),
        const SizedBox(height: 16),
        // stats grid
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.0,
          children: [
            _StatCard('Balance', coins == null ? '—' : '$coins', Icons.emoji_events_rounded, AppColors.gold),
            _StatCard('Spins Used', spins == null ? '—' : '$spins', Icons.casino_rounded, AppColors.primary),
            _StatCard('Activity', '${activity.length}', Icons.history_rounded, const Color(0xFF3B82F6)),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Text('Recent Activity',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                )),
            const Spacer(),
            if (activity.isNotEmpty)
              Text('${activity.length} items',
                  style: AppTextStyles.bodySmall),
          ],
        ),
        const SizedBox(height: 10),
        if (activity.isEmpty)
          const _Empty('No activity yet. Complete a task or spin!')
        else
          ...activity.map((a) => _ActivityItem(a)),
      ],
    );
  }

  Widget _balanceHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Available Coins',
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      coins == null ? '—' : '$coins',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text(
                        coins == null ? '' : 'server balance',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              gradient: AppColors.goldGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.monetization_on_rounded,
                color: Colors.white, size: 30),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final Map<String, dynamic> a;
  const _ActivityItem(this.a);

  @override
  Widget build(BuildContext context) {
    final type = a['type']?.toString() ?? 'task';
    final title = a['title']?.toString() ?? '';
    final rawCoins = a['coins'];
    final coins = rawCoins is num ? rawCoins.toInt() : null;
    final status = a['status']?.toString() ?? '';
    final at = a['at'];

    final spec = _typeSpec(type);
    final positive = coins != null && coins > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: spec.$2.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(spec.$1, color: spec.$2, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (status.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _StatusDot(status),
                      ),
                    Flexible(
                      child: Text(_fmtDate(at),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (coins != null)
            Text(
              positive ? '+$coins' : '$coins',
              style: TextStyle(
                color: positive ? AppColors.success : AppColors.error,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }

  (IconData, Color) _typeSpec(String t) {
    switch (t) {
      case 'task':
        return (Icons.task_alt_rounded, AppColors.success);
      case 'withdrawal':
        return (Icons.account_balance_wallet_rounded, const Color(0xFF3B82F6));
      case 'spin':
        return (Icons.casino_rounded, AppColors.primary);
      case 'survey':
        return (Icons.poll_rounded, AppColors.primaryDark);
      case 'scratch':
        return (Icons.card_giftcard_rounded, const Color(0xFFEC4899));
      default:
        return (Icons.bolt_rounded, AppColors.primary);
    }
  }
}

/// Green "Completed" status dot + label (per design sheet).
class _StatusDot extends StatelessWidget {
  final String status;
  const _StatusDot(this.status);

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(_statusLabel(status),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            )),
      ],
    );
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'PENDING':
        return 'Pending';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'UNDER_REVIEW':
        return 'Under Review';
      case 'VERIFIED':
      case 'COMPLETED':
      case 'DONE':
        return 'Completed';
      case 'REJECTED':
        return 'Rejected';
      case 'FAILED':
        return 'Failed';
      case 'ANOMALY':
        return 'Flagged';
      case 'REFUNDED':
        return 'Refunded';
      default:
        return s;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'VERIFIED':
      case 'COMPLETED':
      case 'DONE':
        return AppColors.success;
      case 'REJECTED':
      case 'FAILED':
        return AppColors.error;
      case 'REFUNDED':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }
}
// =================== WITHDRAWALS TAB ===================
class _WithdrawalsTab extends StatelessWidget {
  final List<Map<String, dynamic>> withdrawals;
  const _WithdrawalsTab({required this.withdrawals});

  @override
  Widget build(BuildContext context) {
    if (withdrawals.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 40),
          _Empty('No withdrawals yet.\nYour withdrawal history will appear here.'),
        ],
      );
    }
    final completed =
        withdrawals.where((w) => w['status']?.toString() == 'COMPLETED').length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: [
        _withdrawStats(withdrawals.length, completed),
        const SizedBox(height: 16),
        ...withdrawals.map((w) => _WithdrawalItem(w)),
      ],
    );
  }

  Widget _withdrawStats(int total, int completed) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.4,
      children: [
        _StatCard('Total Withdrawals', '$total',
            Icons.account_balance_wallet_outlined, const Color(0xFF3B82F6)),
        _StatCard('Completed', '$completed',
            Icons.check_circle_outline_rounded, AppColors.success),
      ],
    );
  }
}

class _WithdrawalItem extends StatelessWidget {
  final Map<String, dynamic> w;
  const _WithdrawalItem(this.w);

  @override
  Widget build(BuildContext context) {
    final status = w['status']?.toString() ?? 'UNKNOWN';
    final rawAmount = w['amount'] ?? w['coins'];
    final amount = rawAmount is num ? rawAmount.toInt() : null;
    final method = w['method']?.toString() ?? 'UNKNOWN';
    final createdAt = w['createdAt'];
    final processedAt = w['processedAt'];
    final reason = w['rejectionReason']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(_methodIcon(method),
                    color: AppColors.primaryDark, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${amount == null ? 'Amount unavailable' : '$amount coins'} via ${_methodLabel(method)}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        )),
                    Text(_fmtDate(createdAt),
                        style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              _StatusChip(status),
            ],
          ),
          const SizedBox(height: 10),
          if (status != 'UNKNOWN')
            _Timeline(status: status, createdAt: createdAt, processedAt: processedAt),
          if (reason != null && reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text('Reason: $reason',
                  style: const TextStyle(
                      color: AppColors.error, fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }

  IconData _methodIcon(String m) {
    switch (m.toUpperCase()) {
      case 'UPI':
        return Icons.account_balance_rounded;
      case 'BANK_TRANSFER':
      case 'BANK':
        return Icons.account_balance_outlined;
      default:
        return Icons.payment_rounded;
    }
  }

  String _methodLabel(String m) {
    switch (m.toUpperCase()) {
      case 'UPI':
        return 'UPI';
      case 'BANK_TRANSFER':
      case 'BANK':
        return 'Bank Transfer';
      default:
        return m;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(_label(),
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          )),
    );
  }

  Color _color() {
    switch (status) {
      case 'COMPLETED':
        return AppColors.success;
      case 'REJECTED':
      case 'FAILED':
        return AppColors.error;
      case 'REFUNDED':
        return AppColors.warning;
      case 'PROCESSING':
        return AppColors.primary;
      case 'UNDER_REVIEW':
        return AppColors.warning;
      default:
        return const Color(0xFF3B82F6);
    }
  }

  String _label() {
    switch (status) {
      case 'PENDING':
        return 'Pending';
      case 'UNDER_REVIEW':
        return 'Under Review';
      case 'PROCESSING':
        return 'Processing';
      case 'COMPLETED':
        return 'Completed';
      case 'FAILED':
        return 'Failed';
      case 'REJECTED':
        return 'Rejected';
      case 'REFUNDED':
        return 'Refunded';
      default:
        return status;
    }
  }
}

class _Timeline extends StatelessWidget {
  final String status;
  final dynamic createdAt;
  final dynamic processedAt;
  const _Timeline({required this.status, this.createdAt, this.processedAt});

  @override
  Widget build(BuildContext context) {
    final stages = <String>['Requested', 'In Review', 'Processing', 'Paid'];
    final reached = _stageIndex();
    return Row(
      children: List.generate(stages.length * 2 - 1, (i) {
        if (i.isOdd) {
          final lineDone = (i ~/ 2) < reached;
          return Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              color: lineDone ? AppColors.success : AppColors.border,
            ),
          );
        }
        final idx = i ~/ 2;
        final done = idx <= reached;
        return Icon(
          done ? Icons.check_circle : Icons.radio_button_unchecked,
          color: done ? AppColors.success : AppColors.textTertiary,
          size: 16,
        );
      }),
    );
  }

  int _stageIndex() {
    switch (status) {
      case 'PENDING':
        return 0;
      case 'UNDER_REVIEW':
        return 1;
      case 'PROCESSING':
        return 2;
      case 'COMPLETED':
        return 3;
      case 'FAILED':
      case 'REJECTED':
      case 'REFUNDED':
        return 0; // show as not progressed
      default:
        return 0;
    }
  }
}

// =================== REFERRALS TAB ===================
class _ReferralsTab extends StatelessWidget {
  final String code;
  final String referralLink;
  final int? total, active, coins;
  final List<Map<String, dynamic>> list;
  const _ReferralsTab({
    required this.code,
    required this.referralLink,
    required this.total,
    required this.active,
    required this.coins,
    required this.list,
  });

  @override
  Widget build(BuildContext context) {
    final link = referralLink.trim();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: [
        // stats grid
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.0,
          children: [
            _StatCard('Invited', total == null ? '—' : '$total', Icons.group_rounded,
                const Color(0xFF3B82F6)),
            _StatCard('Active', active == null ? '—' : '$active', Icons.person_rounded,
                AppColors.success),
            _StatCard('Coins', coins == null ? '—' : '$coins', Icons.emoji_events_rounded,
                AppColors.gold),
          ],
        ),
        const SizedBox(height: 20),
        // shareable code card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.brandHeader,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Column(
            children: [
              const Icon(Icons.card_giftcard_rounded,
                  color: Colors.white, size: 30),
              const SizedBox(height: 8),
              const Text('Invite friends, earn coins',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: Colors.white.withOpacity(0.35)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        link.isEmpty ? 'Referral link unavailable' : link,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copy referral link',
                      style: IconButton.styleFrom(
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.white54,
                      ),
                      onPressed: link.isEmpty
                          ? null
                          : () async {
                              await Clipboard.setData(
                                  ClipboardData(text: link));
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Referral link copied')),
                              );
                            },
                      icon: const Icon(Icons.copy_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Text('Your Referrals',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                )),
            const Spacer(),
            if (list.isNotEmpty)
              Text('${list.length} friends', style: AppTextStyles.bodySmall),
          ],
        ),
        const SizedBox(height: 10),
        if (list.isEmpty)
          const _Empty('No referrals yet.\nShare your link to start earning!')
        else
          ...list.map((r) {
            final referred = r['referred'] as Map?;
            final name = referred?['name']?.toString() ??
                referred?['phone']?.toString() ??
                'Name unavailable';
            final rawEarned = r['coinsEarned'];
            final earned = rawEarned is num ? rawEarned.toInt() : null;
            final rawActive = r['isActive'];
            final bool? isActive = rawActive is bool ? rawActive : null;
            final at = r['createdAt'];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.card,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ((isActive == true)
                              ? AppColors.success
                              : AppColors.textTertiary)
                          .withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.person_rounded,
                        color: isActive == true
                            ? AppColors.success
                            : AppColors.textTertiary,
                        size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            )),
                        Text(
                            '${_fmtDate(at)}  •  ${isActive == null ? 'Status unavailable' : (isActive == true ? 'Active' : 'Inactive')}',
                            style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                  if (earned != null)
                    Text('+$earned',
                        style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        )),
                ],
              ),
            );
          }),
      ],
    );
  }
}

// =================== SHARED ===================
class _Empty extends StatelessWidget {
  final String text;
  const _Empty(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          const Icon(Icons.inbox_rounded,
              size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              )),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 44, color: AppColors.error),
            const SizedBox(height: 14),
            const Text('Failed to load tracking data',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(error,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

String _mon(int m) => const [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ][m];

String _fmtDate(dynamic v) {
  if (v == null) return '';
  try {
    DateTime dt;
    if (v is String) {
      dt = DateTime.parse(v);
    } else if (v is DateTime) {
      dt = v;
    } else {
      return v.toString();
    }
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day} ${_mon(dt.month)}';
  } catch (_) {
    return v.toString();
  }
}
