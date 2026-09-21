import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/app_models.dart';
import '../services/api_client.dart';
import '../services/app_repository.dart';
import '../services/auth_service.dart';
import '../widgets/cv_header.dart';

/// Withdraw — CoinVault light premium design (global header + prompt layout).
///
/// Global header → page title → Available Balance card → 4 method cards
/// (vertical stack) → amount input + quick chips → primary button →
/// security note → Recent Withdrawals.
class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  static const _bg = Color(0xFFFAFAF8);
  static const int _minCoins = 100;

  UserModel? _user;
  bool _loading = false;
  String _selectedMethod = 'upi';
  String _voucherBrand = 'Amazon';
  List<Map<String, dynamic>> _recent = const [];
  bool _recentLoading = false;

  // Gift-card brands come from the backend — never hardcoded.
  List<Map<String, dynamic>> _brands = [];

  final _upiController = TextEditingController();
  final _bankController = TextEditingController();
  final _voucherController = TextEditingController();
  final _amountController = TextEditingController();
  String? _upiError;
  String? _bankError;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadRecent();
    _loadBrands();
  }

  Future<void> _loadBrands() async {
    final list = await AppRepository.instance.fetchGiftCards();
    if (!mounted || list == null) return;
    final brands = list
        .whereType<Map>()
        .map((e) => <String, dynamic>{'name': (e['name'] ?? e['brand'] ?? 'Gift Card').toString()})
        .toList();
    setState(() {
      _brands = brands;
      if (brands.isNotEmpty) _voucherBrand = brands.first['name'] as String;
    });
  }

  Future<void> _loadUser() async {
    setState(() => _loading = true);
    final auth = AuthService();
    if (auth.isLoggedIn) {
      setState(() {
        _user = auth.userModel;
        _upiController.text = _user?.upiId ?? '';
        _bankController.text = _user?.bankDetails ?? '';
      });
      if (mounted) {
        final coins = _user?.coins ?? 0;
        _amountController.text = coins >= 100 ? '100' : (coins > 0 ? coins.toString() : '100');
      }
    } else {
      _amountController.text = '100';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadRecent() async {
    setState(() => _recentLoading = true);
    try {
      final items = await AppRepository.instance
          .fetchWithdrawalHistory(_user?.uid ?? '');
      setState(() {
        _recent = items.take(5).map((e) {
          final m = e as Map<String, dynamic>;
          return <String, dynamic>{
            'method': (m['method'] as String?) ?? 'upi',
            'coins': ((m['coins'] as num?) ?? 0).toInt(),
            'rupees': ((m['rupees'] as num?) ??
                    ((m['amount'] as num?) ?? 0).toDouble())
                .toDouble(),
            'status': (m['status'] as String?) ?? 'pending',
          };
        }).toList();
      });
    } catch (_) {
      // keep empty
    } finally {
      if (mounted) setState(() => _recentLoading = false);
    }
  }

  int get _coins => _user?.coins ?? 0;
  double get _rupees => _coins / 10;

  int? get _enteredCoins {
    final t = _amountController.text.trim();
    final n = int.tryParse(t);
    return n;
  }

  double get _enteredRupees {
    final c = _enteredCoins;
    return c == null ? 0 : c / 10;
  }

  bool get _canWithdraw {
    final c = _enteredCoins;
    return c != null && c >= _minCoins && c <= _coins;
  }

  String get _methodLabel {
    switch (_selectedMethod) {
      case 'bank':
        return 'Bank Transfer';
      case 'phonepe':
        return 'PhonePe';
      case 'voucher':
        return 'Gift Cards';
      default:
        return 'UPI';
    }
  }

  IconData get _methodIcon {
    switch (_selectedMethod) {
      case 'bank':
        return Icons.account_balance_rounded;
      case 'phonepe':
        return Icons.phone_iphone_rounded;
      case 'voucher':
        return Icons.card_giftcard_rounded;
      default:
        return Icons.qr_code_rounded;
    }
  }

  static String _fmt(int n) {
    final s = StringBuffer();
    final str = n.abs().toString();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count != 0 && count % 3 == 0) s.write(',');
      s.write(str[i]);
      count++;
    }
    final rev = s.toString().split('').reversed.join();
    return n < 0 ? '-$rev' : rev;
  }

  Future<void> _submitWithdrawal() async {
    if (_user == null) return;

    final coins = _enteredCoins;
    if (coins == null) {
      _showSnackBar('Enter amount in coins');
      return;
    }
    if (coins < _minCoins) {
      _showSnackBar('Minimum withdrawal is 100 coins');
      return;
    }
    if (coins > _user!.coins) {
      _showSnackBar('Insufficient balance');
      return;
    }

    String details = '';
    if (_selectedMethod == 'upi') {
      if (_upiController.text.trim().isEmpty) {
        setState(() => _upiError = 'Enter UPI ID');
        return;
      }
      if (!_upiController.text.contains('@')) {
        setState(() => _upiError = 'Invalid UPI ID format');
        return;
      }
      details = _upiController.text.trim();
      setState(() => _upiError = null);
    } else if (_selectedMethod == 'bank') {
      if (_bankController.text.trim().isEmpty) {
        setState(() => _bankError = 'Enter bank details');
        return;
      }
      details = _bankController.text.trim();
      setState(() => _bankError = null);
    } else {
      if (_voucherController.text.trim().isEmpty) {
        _showSnackBar(_selectedMethod == 'phonepe'
            ? 'Enter your PhonePe number'
            : 'Enter mobile/email for the voucher');
        return;
      }
      details = _selectedMethod == 'voucher'
          ? '$_voucherBrand | ${_voucherController.text.trim()}'
          : _voucherController.text.trim();
    }

    setState(() => _loading = true);
    try {
      await AppRepository.instance.submitWithdrawal(
        uid: _user!.uid,
        coins: coins,
        method: _selectedMethod,
        details: details,
      );
      if (mounted) {
        await AuthService().deductCoins(coins);
        await AuthService().updateWithdrawInfo(
          upiId: _selectedMethod == 'upi' ? details : null,
          bankDetails: _selectedMethod == 'bank' ? details : null,
        );
        _user = AuthService().userModel;
        _amountController.clear();
        await _loadRecent();
        _showSuccessDialog(coins, coins / 10);
      }
    } on ApiException catch (e) {
      if (mounted) _showSnackBar(e.message);
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        _showSnackBar(msg.isEmpty ? 'Error occurred. Please try again.' : msg);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSuccessDialog(int coins, double rupees) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: AppShadows.elevated,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.success,
                      AppColors.success.withOpacity(0.8)
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    size: 38, color: Colors.white),
              ),
              const SizedBox(height: 14),
              const Text('Request Submitted!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  )),
              const SizedBox(height: 6),
              Text(
                '${_fmt(coins)} coins (₹${rupees.toStringAsFixed(0)})',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Payment will be processed within 24-48 hours.\n'
                'You will receive a notification when done.',
                style: TextStyle(
                    fontSize: 12.5, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    );
  }

  @override
  void dispose() {
    _upiController.dispose();
    _bankController.dispose();
    _voucherController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // ───────────────────────────── UI ──────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Column(
            children: const [
              CvHeader(),
              Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CvHeader(),
              const SizedBox(height: 12),
              const Text(
                'Withdraw',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Redeem your coins for rewards',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),

              // Available balance (compact)
              _balanceCard(),
              const SizedBox(height: 20),

              // Methods
              const Text(
                'Choose a withdrawal method',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              _methodRow('upi', Icons.qr_code_rounded, 'UPI',
                  'Fast digital payout', const Color(0xFF10B981)),
              const SizedBox(height: 10),
              _methodRow('bank', Icons.account_balance_rounded, 'Bank Transfer',
                  'Transfer directly to your bank', const Color(0xFF3B82F6)),
              const SizedBox(height: 10),
              _methodRow('phonepe', Icons.phone_iphone_rounded, 'PhonePe',
                  'Digital wallet payout', const Color(0xFF5F259F)),
              const SizedBox(height: 10),
              _methodRow('voucher', Icons.card_giftcard_rounded, 'Gift Cards',
                  'Redeem available vouchers', const Color(0xFFEC4899)),

              // Account details per method
              const SizedBox(height: 18),
              _detailsField(),

              // Brand picker (Gift Cards only)
              if (_selectedMethod == 'voucher') ...[
                const SizedBox(height: 16),
                const Text(
                  'Choose a gift card brand',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                _brandGrid(),
                const SizedBox(height: 10),
                _selectedBrandChip(),
              ],
              const SizedBox(height: 16),

              // Amount
              const Text(
                'Enter withdrawal amount',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              _amountField(),
              const SizedBox(height: 10),
              _quickChips(),
              const SizedBox(height: 18),

              // Primary button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed:
                      _loading || !_canWithdraw ? null : _submitWithdrawal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: const Color(0xFFE7E7E7),
                    disabledForegroundColor: const Color(0xFF9CA3AF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'Withdraw ₹${_enteredRupees.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // Security note
              Row(
                children: const [
                  Icon(Icons.lock_outline_rounded,
                      size: 13, color: AppColors.textSecondary),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Withdrawals may require verification before processing.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Recent withdrawals
              const Text(
                'Recent Withdrawals',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              _recentList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _balanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Available Balance',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Icon(Icons.monetization_on_rounded,
                        color: AppColors.primary, size: 22),
                    const SizedBox(width: 6),
                    Text(
                      _fmt(_coins),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text('Coins',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        )),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '≈ ₹${_rupees.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E6),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.primary.withOpacity(0.25)),
            ),
            child: Text(
              'Min: $_minCoins Coins',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _methodRow(
      String key, IconData icon, String title, String subtitle, Color color) {
    final selected = _selectedMethod == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = key),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFFFFBF2)
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.8 : 1,
          ),
          boxShadow: selected ? AppShadows.card : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected ? color : color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon,
                  size: 20, color: selected ? Colors.white : color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      )),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      )),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? AppColors.primary : const Color(0xFFC9CDD4),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailsField() {
    if (_selectedMethod == 'upi') {
      return _field(
        controller: _upiController,
        label: 'UPI ID',
        hint: 'yourname@upi',
        icon: Icons.qr_code_rounded,
        error: _upiError,
      );
    } else if (_selectedMethod == 'bank') {
      return _field(
        controller: _bankController,
        label: 'Bank Details',
        hint: 'Account Holder Name, Account Number, IFSC',
        icon: Icons.account_balance_rounded,
        error: _bankError,
        maxLines: 2,
      );
    }
    return _field(
      controller: _voucherController,
      label: _selectedMethod == 'phonepe' ? 'PhonePe Number' : 'Mobile / Email',
      hint: _selectedMethod == 'phonepe'
          ? '10-digit mobile'
          : 'Email where voucher is sent',
      icon: _selectedMethod == 'phonepe'
          ? Icons.phone_iphone_rounded
          : Icons.alternate_email_rounded,
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? error,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFB9BDC4), fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 19),
        errorText: error,
        filled: true,
        fillColor: AppColors.cardBackground,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
    );
  }

  Widget _amountField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: _canWithdraw ? AppColors.primary : AppColors.border,
          width: _canWithdraw ? 1.8 : 1,
        ),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 13),
            child: Icon(Icons.monetization_on_rounded,
                color: AppColors.primary, size: 20),
          ),
          Expanded(
            child: TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
              decoration: const InputDecoration(
                hintText: '100 Coins',
                hintStyle:
                    TextStyle(color: Color(0xFFB9BDC4), fontSize: 15),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 13),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Text(
              '₹${_enteredRupees.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Gift card brands ────────────────────────────
    // _brands is loaded from the backend in _loadBrands().

  static String _brandImage(String name) {
    switch (name) {
      case 'Amazon Pay':
        return 'assets/brands/amazon.png';
      case 'PhonePe':
        return 'assets/brands/phonepe.png';
      case 'Paytm':
        return 'assets/brands/paytm.png';
      case 'Flipkart':
        return 'assets/brands/flipkart.png';
      case 'Google Play':
        return 'assets/brands/googleplay.png';
      case 'Myntra':
        return 'assets/brands/myntra.png';
      case 'Ajio':
        return 'assets/brands/ajio.png';
      case 'Swiggy':
        return 'assets/brands/swiggy.png';
      case 'Zomato':
        return 'assets/brands/zomato.png';
      case 'Netflix':
        return 'assets/brands/netflix.png';
      case 'Spotify':
        return 'assets/brands/spotify.png';
      case 'OLA':
        return 'assets/brands/ola.png';
      default:
        return 'assets/brands/amazon.png';
    }
  }

  Widget _brandGrid() {
    if (_brands.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text('No gift cards available yet',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      );
    }
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 9,
      crossAxisSpacing: 9,
      childAspectRatio: 1.05,
      children: _brands.map((b) {
        final name = b['name'] as String;
        final selected = _voucherBrand == name;
        return GestureDetector(
          onTap: () => setState(() => _voucherBrand = name),
          child: Container(
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFFFFFBF2)
                  : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 1.8 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Image.asset(
                    _brandImage(name),
                    width: 34,
                    height: 34,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      width: 34,
                      height: 34,
                      color: AppColors.surfaceVariant,
                      child: const Icon(Icons.card_giftcard_rounded,
                          size: 18, color: AppColors.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _selectedBrandChip() {
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded,
            size: 15, color: AppColors.success),
        const SizedBox(width: 6),
        Text(
          'Selected: $_voucherBrand',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _quickChips() {
    const amounts = [100, 250, 500, 1000];
    return Row(
      children: amounts.map((a) {
        final active = _enteredCoins == a;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
                right: a == amounts.last ? 0 : 8, left: a == 100 ? 0 : 0),
            child: GestureDetector(
              onTap: () =>
                  setState(() => _amountController.text = a.toString()),
              child: Container(
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.primary
                      : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: active ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Text(
                  _fmt(a),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: active
                        ? Colors.white
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _recentList() {
    if (_recentLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primary),
          ),
        ),
      );
    }
    if (_recent.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text(
          'No withdrawals yet',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (int i = 0; i < _recent.length; i++) ...[
            _recentRow(_recent[i]),
            if (i != _recent.length - 1)
              const Divider(height: 1, color: AppColors.border),
          ],
        ],
      ),
    );
  }

  Widget _recentRow(Map<String, dynamic> item) {
    final method = (item['method'] as String?) ?? 'upi';
    final coins = (item['coins'] as num?)?.toInt() ?? 0;
    final rupees = (item['rupees'] as num?)?.toDouble() ?? coins / 10;
    final status = (item['status'] as String?) ?? 'pending';

    IconData icon;
    Color iconColor;
    switch (method) {
      case 'bank':
        icon = Icons.account_balance_rounded;
        iconColor = const Color(0xFF3B82F6);
        break;
      case 'phonepe':
        icon = Icons.phone_iphone_rounded;
        iconColor = const Color(0xFF5F259F);
        break;
      case 'voucher':
        icon = Icons.card_giftcard_rounded;
        iconColor = const Color(0xFFEC4899);
        break;
      default:
        icon = Icons.qr_code_rounded;
        iconColor = const Color(0xFF10B981);
    }

    String statusLabel;
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'paid':
      case 'completed':
      case 'success':
        statusLabel = 'Completed';
        statusColor = AppColors.success;
        break;
      case 'failed':
      case 'rejected':
        statusLabel = 'Failed';
        statusColor = AppColors.error;
        break;
      default:
        statusLabel = 'Processing';
        statusColor = AppColors.primary;
    }

    final methodName = method == 'bank'
        ? 'Bank Transfer'
        : method == 'voucher'
            ? 'Gift Cards'
            : method == 'phonepe'
                ? 'PhonePe'
                : 'UPI';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(methodName,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                )),
          ),
          Text(
            '${_fmt(coins)} Coins · ₹${rupees.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
