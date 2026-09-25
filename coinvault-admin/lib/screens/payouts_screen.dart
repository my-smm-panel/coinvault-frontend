import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PayoutsScreen extends StatefulWidget {
  const PayoutsScreen({super.key});

  @override
  State<PayoutsScreen> createState() => _PayoutsScreenState();
}

class _PayoutsScreenState extends State<PayoutsScreen> {
  List<dynamic> _payouts = [];
  bool _isLoading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _loadPayouts();
  }

  Future<void> _loadPayouts() async {
    String filterPart = '';
    if (_filter != 'all') {
      filterPart = '?status=$_filter';
    }

    final data = await ApiService.get('/api/admin-v2/withdrawals$filterPart');

    if (mounted) {
      setState(() {
        _payouts = data?['data'] ?? [];
        _isLoading = false;
      });
    }
  }

  Future<void> _approvePayout(dynamic payout) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Payout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User: ${payout['userName'] ?? 'Unknown'}'),
            const SizedBox(height: 4),
            Text('Amount: ${payout['amount'] ?? 0} coins'),
            const SizedBox(height: 4),
            Text('Method: ${payout['method'] ?? 'N/A'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await ApiService.put(
        '/api/admin-v2/withdrawals/${payout['id']}/approve',
        {},
      );

      if (result != null && result['success'] == true) {
        _loadPayouts();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payout approved')));
      }
    }
  }

  Future<void> _rejectPayout(dynamic payout) async {
    final result = await ApiService.put(
      '/api/admin-v2/withdrawals/${payout['id']}/reject',
      {'reason': 'Rejected by admin'},
    );

    if (result != null && result['success'] == true) {
      _loadPayouts();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payout rejected')));
    }
  }

  String _getStatusBadge(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
      case 'UNDER_REVIEW':
        return 'Amber';
      case 'APPROVED':
      case 'PROCESSING':
      case 'COMPLETED':
        return 'Green';
      case 'REJECTED':
      case 'FAILED':
        return 'Red';
      default:
        return 'Gray';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filter,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'approved', child: Text('Approved')),
                    DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _filter = value);
                      _loadPayouts();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _payouts.isEmpty
                  ? const Center(child: Text('No payouts found'))
                  : ListView.builder(
                      itemCount: _payouts.length,
                      itemBuilder: (context, index) => _PayoutTile(
                        payout: _payouts[index],
                        onApprove: _approvePayout,
                        onReject: _rejectPayout,
                      ),
                    ),
        ),
      ],
    );
  }
}

class _PayoutTile extends StatelessWidget {
  final dynamic payout;
  final Function(dynamic) onApprove;
  final Function(dynamic) onReject;

  const _PayoutTile({required this.payout, required this.onApprove, required this.onReject});

  @override
  Widget build(BuildContext context) {
    final status = payout['status'] ?? 'UNKNOWN';
    final up = status.toString().toUpperCase();
    final badgeColor = /COMPLETE|ACTIVE|APPROVED|PROCESSING|SETTLED|PAID/.hasMatch(up)
        ? 'Green'
        : /REJECT|FAILED|CANCELLED|DECLINED/.hasMatch(up)
            ? 'Red'
            : /PENDING|UNDER_REVIEW|REVIEW|PROCESS/.hasMatch(up)
                ? 'Amber'
                : 'Gray';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payout['userName'] ?? 'Unknown User',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${payout['amount'] ?? 0} coins',
                        style: const TextStyle(fontSize: 16, color: Colors.green),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor == 'Green'
                        ? Colors.green[100]
                        : badgeColor == 'Red'
                            ? Colors.red[100]
                            : badgeColor == 'Amber'
                                ? Colors.orange[100]
                                : Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 11,
                      color: badgeColor == 'Green'
                          ? Colors.green
                          : badgeColor == 'Red'
                              ? Colors.red
                              : badgeColor == 'Amber'
                                  ? Colors.orange
                                  : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Method: ${payout['method'] ?? 'N/A'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  'Date: ${_formatDate(payout['createdAt'])}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => onReject(payout),
                  style: TextButton.styleFrom(backgroundColor: Colors.grey[100]),
                  child: const Text('Reject', style: TextStyle(color: Colors.red)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => onApprove(payout),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Approve', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dt = DateTime.parse(date as String);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return date.toString();
    }
  }
}
