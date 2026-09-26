import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/app_models.dart';
import '../services/api_client.dart';
import '../services/app_repository.dart';
import '../services/auth_service.dart';
import '../services/balance_stream.dart';
import '../widgets/cv_header.dart';

/// Withdrawal screen backed by the authenticated wallet and methods APIs.
/// Only methods returned by the server are shown; no local balance mutation is
/// performed after a successful request.
class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  static const _bg = Color(0xFFFAFAF8);

  UserModel? _user;
  int? _balance;
  List<Map<String, dynamic>> _methods = [];
  List<Map<String, dynamic>> _recent = [];
  String? _selectedMethod;
  bool _loading = true;
  bool _methodsFailed = false;
  bool _historyFailed = false;
  bool _submitting = false;
  String? _error;

  final _upiController = TextEditingController();
  final _bankController = TextEditingController();
  final _amountController = TextEditingController();
  String? _detailsError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = AuthService();
    _user = auth.userModel;
    final results = await Future.wait<dynamic>([
      AppRepository.instance.fetchWalletBalance(),
      AppRepository.instance.fetchWithdrawalMethods(),
      AppRepository.instance.fetchWithdrawalHistory(''),
    ]);
    if (!mounted) return;
    final rawMethods = results[1] as List? ?? const [];
    final methods = rawMethods
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((m) {
          final id = (m['method'] ?? m['id'] ?? '').toString().toUpperCase();
          return id == 'UPI' || id == 'BANK_TRANSFER';
        })
        .toList();
    final rawRecent = results[2] as List? ?? const [];
    setState(() {
      _balance = results[0] as int?;
      _methods = methods;
      _methodsFailed = results[1] == null;
      _historyFailed = results[2] == null;
      _recent = rawRecent.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).take(5).toList();
      _selectedMethod = methods.isEmpty ? null : _methodId(methods.first);
      _loading = false;
      if (results[1] == null) {
        _error = 'Withdrawal methods could not be fetched. Pull to retry.';
      } else if (results[0] == null && methods.isEmpty) {
        _error = 'Withdrawal details are not available right now.';
      }
    });
  }

  String _methodId(Map<String, dynamic> method) =>
      (method['method'] ?? method['id'] ?? '').toString().toUpperCase();

  Map<String, dynamic>? get _selectedConfig {
    for (final m in _methods) {
      if (_methodId(m) == _selectedMethod) return m;
    }
    return null;
  }

  int? get _minCoins {
    final raw = _selectedConfig?['minCoins'];
    return raw is num ? raw.toInt() : null;
  }

  int? get _feeCoins {
    final raw = _selectedConfig?['feeCoins'];
    return raw is num ? raw.toInt() : null;
  }

  int? get _enteredCoins => int.tryParse(_amountController.text.trim());

  bool get _canWithdraw {
    final amount = _enteredCoins;
    return !_submitting && _balance != null && _selectedConfig != null &&
        amount != null && _minCoins != null && amount >= _minCoins! && amount <= _balance!;
  }

  String get _methodLabel => _selectedMethod == 'BANK_TRANSFER' ? 'Bank Transfer' : 'UPI';

  Future<void> _submitWithdrawal() async {
    final amount = _enteredCoins;
    final method = _selectedMethod;
    if (!_canWithdraw || amount == null || method == null || _user == null) return;
    final details = method == 'UPI' ? _upiController.text.trim() : _bankController.text.trim();
    if (details.isEmpty) {
      setState(() => _detailsError = method == 'UPI' ? 'Enter UPI ID' : 'Enter bank details');
      return;
    }
    if (method == 'UPI' && !details.contains('@')) {
      setState(() => _detailsError = 'Enter a valid UPI ID');
      return;
    }
    setState(() {
      _detailsError = null;
      _submitting = true;
    });
    try {
      await AppRepository.instance.submitWithdrawal(
        uid: _user!.uid,
        coins: amount,
        method: method == 'UPI' ? 'upi' : 'bank',
        details: details,
      );
      if (!mounted) return;
      await AppRepository.instance.fetchWalletBalance();
      await _loadRecent();
      _amountController.clear();
      _showSuccessDialog(amount);
    } on ApiException catch (e) {
      if (mounted) _showSnackBar(e.message);
    } catch (e) {
      if (mounted) _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _loadRecent() async {
    final list = await AppRepository.instance.fetchWithdrawalHistory('');
    if (!mounted) return;
    setState(() {
      _historyFailed = list == null;
      _recent = list
              ?.whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .take(5)
              .toList() ??
          [];
    });
  }

  void _showSuccessDialog(int coins) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Request submitted'),
        content: Text('$coins coins were submitted for ${_methodLabel}. The server will update the request status.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done'))],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _upiController.dispose();
    _bankController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppColors.primary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 28),
            children: [
              const CvHeader(),
              const SizedBox(height: 12),
              const Text('Withdraw', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              const Text('Submit a coin withdrawal request', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 18),
              _balanceCard(),
              const SizedBox(height: 20),
              if (_loading)
                const Center(child: Padding(padding: EdgeInsets.all(28), child: CircularProgressIndicator(color: AppColors.primary)))
              else if (_methodsFailed || (_error != null && _methods.isEmpty))
                _empty(_error ?? 'Withdrawal methods are unavailable.')
              else if (_methods.isEmpty)
                _empty('No supported withdrawal methods are available.')
              else ...[
                const Text('Choose a withdrawal method', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const SizedBox(height: 10),
                ..._methods.map(_methodRow),
                if (_selectedConfig != null) ...[
                  const SizedBox(height: 18),
                  _detailsField(),
                  const SizedBox(height: 16),
                  const Text('Amount (coins)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  _amountField(),
                  if (_minCoins != null || _feeCoins != null) ...[
                    const SizedBox(height: 8),
                    Text([
                      if (_minCoins != null) 'Minimum: $_minCoins coins',
                      if (_feeCoins != null) 'Fee: $_feeCoins coins',
                    ].join('  •  '), style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _canWithdraw ? _submitWithdrawal : null,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
                      child: _submitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Submit withdrawal', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                const Text('Recent Withdrawals', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const SizedBox(height: 10),
                _recentList(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _balanceCard() {
    final balance = BalanceStream.instance.value ?? _balance;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.border), boxShadow: AppShadows.card),
      child: Row(children: [
        const Icon(Icons.monetization_on_rounded, color: AppColors.primary, size: 24),
        const SizedBox(width: 9),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Available balance', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(balance == null ? '— coins' : '$balance coins', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        ])),
      ]),
    );
  }

  Widget _methodRow(Map<String, dynamic> method) {
    final id = _methodId(method);
    final selected = _selectedMethod == id;
    final title = (method['name'] ?? (id == 'BANK_TRANSFER' ? 'Bank Transfer' : 'UPI')).toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => setState(() { _selectedMethod = id; _detailsError = null; }),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(color: selected ? const Color(0xFFFFFBF2) : AppColors.cardBackground, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.8 : 1)),
          child: Row(children: [
            Icon(id == 'UPI' ? Icons.qr_code_rounded : Icons.account_balance_rounded, color: selected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary))),
            Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded, color: selected ? AppColors.primary : AppColors.textTertiary),
          ]),
        ),
      ),
    );
  }

  Widget _detailsField() {
    final upi = _selectedMethod == 'UPI';
    return TextField(
      controller: upi ? _upiController : _bankController,
      maxLines: upi ? 1 : 2,
      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: upi ? 'UPI ID' : 'Bank details',
        hintText: upi ? 'yourname@upi' : 'Account holder, account number, IFSC',
        errorText: _detailsError,
        prefixIcon: Icon(upi ? Icons.qr_code_rounded : Icons.account_balance_rounded, color: AppColors.primary),
        filled: true,
        fillColor: AppColors.cardBackground,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.border)),
      ),
    );
  }

  Widget _amountField() {
    return TextField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
      decoration: InputDecoration(
        hintText: 'Enter coins',
        prefixIcon: const Icon(Icons.monetization_on_rounded, color: AppColors.primary),
        filled: true,
        fillColor: AppColors.cardBackground,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.border)),
      ),
    );
  }

  Widget _recentList() {
    if (_historyFailed) return _empty('Withdrawal history could not be fetched.');
    if (_recent.isEmpty) return _empty('No withdrawal history');
    return Container(
      decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.border)),
      child: Column(children: _recent.map((item) {
        final amount = item['amount'] ?? item['coins'];
        final status = (item['status'] ?? 'UNKNOWN').toString();
        final method = (item['method'] ?? '').toString();
        return ListTile(
          leading: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary),
          title: Text(amount is num ? '${amount.toInt()} coins' : 'Amount unavailable', style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(method.isEmpty ? status : '$method • $status', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        );
      }).toList()),
    );
  }

  Widget _empty(String message) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.border)),
        child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      );
}
