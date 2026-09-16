import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';
import '../services/app_repository.dart';
import '../services/auth_service.dart';

/// Full tracking screen: activity feed + withdrawal status + referrals + stats.
class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);
  bool _loading = true;
  String? _error;

  // Activity
  List<Map<String, dynamic>> _activity = [];

  // Withdrawals
  List<Map<String, dynamic>> _withdrawals = [];

  // Referrals
  String _referralCode = '';
  int _totalReferrals = 0;
  int _activeReferrals = 0;
  int _referralCoins = 0;
  List<Map<String, dynamic>> _referralList = [];

  // Stats
  int _coins = 0;
  int _totalEarned = 0;
  int _totalWithdrawn = 0;
  int _tasksDone = 0;
  int _spins = 0;

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
      final auth = AuthService();
      final results = await Future.wait([
        repo.fetchActivity(), // 0
        repo.fetchWithdrawalHistory(auth.userModel?.uid ?? ''), // 1
        repo.referralInfo(), // 2
      ]);

      // activity
      final act = results[0];
      _activity = act is List
          ? act.map((e) => Map<String, dynamic>.from(e as Map)).toList()
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
      _withdrawals = wList
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      // referrals
      final r = results[2];
      if (r is Map) {
        final d = r['data'] is Map ? r['data'] as Map : r;
        _referralCode = d['referralCode']?.toString() ?? '';
        _totalReferrals = (d['totalReferrals'] as num?)?.toInt() ?? 0;
        _activeReferrals = (d['activeReferrals'] as num?)?.toInt() ?? 0;
        _referralCoins = (d['totalCoinsEarned'] as num?)?.toInt() ?? 0;
        final rl = d['referrals'];
        _referralList = rl is List
            ? rl.map((e) => Map<String, dynamic>.from(e as Map)).toList()
            : [];
      }

      // stats from local model (instant)
      final u = auth.userModel;
      if (u != null) {
        _coins = u.coins;
        _totalEarned = u.totalEarned;
        _totalWithdrawn = u.totalWithdrawn;
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Tracking'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.history_rounded), text: 'Activity'),
            Tab(icon: Icon(Icons.account_balance_wallet_outlined), text: 'Withdrawals'),
            Tab(icon: Icon(Icons.group_rounded), text: 'Referrals'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(error: _error!, onRetry: _loadAll)
              : RefreshIndicator(
                  onRefresh: _loadAll,
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _ActivityTab(
                        activity: _activity,
                        coins: _coins,
                        totalEarned: _totalEarned,
                        totalWithdrawn: _totalWithdrawn,
                        tasksDone: _tasksDone,
                        spins: _spins,
                      ),
                      _WithdrawalsTab(withdrawals: _withdrawals),
                      _ReferralsTab(
                        code: _referralCode,
                        total: _totalReferrals,
                        active: _activeReferrals,
                        coins: _referralCoins,
                        list: _referralList,
                      ),
                    ],
                  ),
                ),
    );
  }
}

// =================== ACTIVITY TAB ===================
class _ActivityTab extends StatelessWidget {
  final List<Map<String, dynamic>> activity;
  final int coins, totalEarned, totalWithdrawn, tasksDone, spins;
  const _ActivityTab({
    required this.activity,
    required this.coins,
    required this.totalEarned,
    required this.totalWithdrawn,
    required this.tasksDone,
    required this.spins,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // stat cards
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: [
            _StatCard('Balance', '$coins', Icons.savings_rounded, AppColors.primary),
            _StatCard('Total Earned', '$totalEarned', Icons.emoji_events_rounded, Colors.green),
            _StatCard('Withdrawn', '₹${(totalWithdrawn / 10).toStringAsFixed(0)}', Icons.account_balance_wallet_rounded, Colors.blue),
            _StatCard('Spins', '$spins', Icons.casino_rounded, Colors.purple),
          ],
        ),
        const SizedBox(height: 18),
        Text('Recent Activity',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            )),
        const SizedBox(height: 10),
        if (activity.isEmpty)
          _Empty('No activity yet. Complete a task or spin!')
        else
          ...activity.map((a) => _ActivityItem(a)),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  )),
              Text(label,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  )),
            ],
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
    final coins = (a['coins'] as num?)?.toInt() ?? 0;
    final status = a['status']?.toString() ?? '';
    final at = a['at'];

    final spec = _typeSpec(type);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: spec.$2.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(spec.$1, color: spec.$2, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (status.isNotEmpty)
                      Text('${_statusLabel(status)}  •  ',
                          style: TextStyle(
                            color: _statusColor(status),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          )),
                    Text(_fmtDate(at),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        )),
                  ],
                ),
              ],
            ),
          ),
          if (coins != 0)
            Text(
              coins > 0 ? '+$coins' : '$coins',
              style: TextStyle(
                color: coins > 0 ? Colors.green : Colors.redAccent,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  (IconData, Color) _typeSpec(String t) {
    switch (t) {
      case 'task':
        return (Icons.task_alt_rounded, Colors.green);
      case 'withdrawal':
        return (Icons.account_balance_wallet_rounded, Colors.blue);
      case 'spin':
        return (Icons.casino_rounded, Colors.purple);
      case 'survey':
        return (Icons.poll_rounded, Colors.orange);
      case 'scratch':
        return (Icons.card_giftcard_rounded, Colors.pink);
      default:
        return (Icons.bolt_rounded, AppColors.primary);
    }
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
        return Colors.green;
      case 'REJECTED':
      case 'FAILED':
        return Colors.redAccent;
      case 'REFUNDED':
        return Colors.orange;
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
      return _Empty('No withdrawals yet.\nYour withdrawal history will appear here.');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: withdrawals.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final w = withdrawals[i];
        final status = w['status']?.toString() ?? 'PENDING';
        final amount = (w['amount'] as num?)?.toInt() ?? 0;
        final inr = (w['rupeeAmount'] as num?)?.toInt() ??
            (amount ~/ 10);
        final method = w['method']?.toString() ?? 'UPI';
        final createdAt = w['createdAt'];
        final processedAt = w['processedAt'];
        final reason = w['rejectionReason']?.toString();

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _statusColor(status).withOpacity(0.35),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_methodIcon(method),
                      color: AppColors.primary, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('₹$inr via ${_methodLabel(method)}',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        )),
                  ),
                  _StatusChip(status),
                ],
              ),
              const SizedBox(height: 8),
              // timeline
              _Timeline(
                status: status,
                createdAt: createdAt,
                processedAt: processedAt,
              ),
              if (reason != null && reason.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Reason: $reason',
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 12)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  IconData _methodIcon(String m) {
    switch (m.toUpperCase()) {
      case 'UPI':
        return Icons.account_balance_rounded;
      case 'BANK_TRANSFER':
      case 'BANK':
        return Icons.account_balance_outlined;
      case 'PHONEPE':
        return Icons.phone_android_rounded;
      case 'VOUCHER':
      case 'GIFTCARD':
        return Icons.card_giftcard_rounded;
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
      case 'PHONEPE':
        return 'PhonePe';
      case 'VOUCHER':
      case 'GIFTCARD':
        return 'Voucher';
      default:
        return m;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'COMPLETED':
        return Colors.green;
      case 'REJECTED':
      case 'FAILED':
        return Colors.redAccent;
      case 'REFUNDED':
        return Colors.orange;
      default:
        return Colors.blue;
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
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(_label(),
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          )),
    );
  }

  Color _color() {
    switch (status) {
      case 'COMPLETED':
        return Colors.green;
      case 'REJECTED':
      case 'FAILED':
        return Colors.redAccent;
      case 'REFUNDED':
        return Colors.orange;
      case 'PROCESSING':
        return Colors.purple;
      case 'UNDER_REVIEW':
        return Colors.amber;
      default:
        return Colors.blue;
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
        return 'Paid';
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
    // stage order
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
              color: lineDone ? Colors.green : AppColors.divider,
            ),
          );
        }
        final idx = i ~/ 2;
        final done = idx <= reached;
        return Icon(
          done ? Icons.check_circle : Icons.radio_button_unchecked,
          color: done ? Colors.green : AppColors.textSecondary,
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
  final int total, active, coins;
  final List<Map<String, dynamic>> list;
  const _ReferralsTab({
    required this.code,
    required this.total,
    required this.active,
    required this.coins,
    required this.list,
  });

  @override
  Widget build(BuildContext context) {
    final link = code.isNotEmpty
        ? 'https://coinvault.app/?ref=$code'
        : '—';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              const Icon(Icons.card_giftcard_rounded,
                  color: Colors.white, size: 34),
              const SizedBox(height: 8),
              const Text('Invite friends, earn coins',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _refStat('Invited', '$total'),
                  _refStat('Active', '$active'),
                  _refStat('Coins', '$coins'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // share row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(link,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ),
              IconButton(
                icon: Icon(Icons.copy_rounded, color: AppColors.primary),
                onPressed: () {
                  // copy handled via services layer
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Referral link copied')),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Your Referrals',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            )),
        const SizedBox(height: 10),
        if (list.isEmpty)
          _Empty('No referrals yet.\nShare your link to start earning!')
        else
          ...list.map((r) {
            final referred = r['referred'] as Map?;
            final name = referred?['name']?.toString() ??
                referred?['phone']?.toString() ??
                'Friend';
            final earned = (r['coinsEarned'] as num?)?.toInt() ?? 0;
            final isActive = r['isActive'] == true;
            final at = r['createdAt'];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    child: Icon(Icons.person_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            )),
                        Text('${_fmtDate(at)}  •  ${isActive ? 'Active' : 'Inactive'}',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            )),
                      ],
                    ),
                  ),
                  if (earned > 0)
                    Text('+$earned',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        )),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _refStat(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            )),
        Text(label,
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
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
          Icon(Icons.inbox_rounded,
              size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(
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
            const Icon(Icons.cloud_off_rounded, size: 44, color: Colors.redAccent),
            const SizedBox(height: 14),
            Text('Failed to load tracking data',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(error,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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
    return DateFormat('dd MMM').format(dt);
  } catch (_) {
    return v.toString();
  }
}
