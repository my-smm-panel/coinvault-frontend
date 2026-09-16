import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../services/auth_service.dart';
import '../services/app_repository.dart';
import '../services/api_client.dart';
import '../models/app_models.dart';

/// Withdraw — CoinVault light theme (per design sheet).
/// Keeps the 4 methods (UPI / Bank / PhonePe / Voucher), brand grid,
/// ₹-based amount input and full submit logic.
class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  static const _bg = Color(0xFFF7F8FA);

  UserModel? _user;
  bool _loading = false;
  String _selectedMethod = 'upi'; // 'upi' | 'bank' | 'phonepe' | 'voucher'
  String _voucherBrand = 'Amazon'; // Amazon | OLA | Gift
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
  }

  Future<void> _loadUser() async {
    final auth = AuthService();
    if (auth.isLoggedIn) {
      setState(() {
        _user = auth.userModel;
        _upiController.text = _user?.upiId ?? '';
        _bankController.text = _user?.bankDetails ?? '';
      });
    }
  }

  int get _maxWithdrawableCoins {
    final coins = _user?.coins ?? 0;
    return (coins ~/ 100) * 100; // Round down to nearest 100
  }

  double get _maxWithdrawableRupees => _maxWithdrawableCoins / 10;

  @override
  void dispose() {
    _upiController.dispose();
    _bankController.dispose();
    _voucherController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onAmountChange(String value) {
    // Live conversion preview only — do not auto-correct while typing.
    setState(() {});
  }

  Future<void> _submitWithdrawal() async {
    if (_user == null) return;

    // Amount entered is in ₹ — convert to coins (₹1 = 10 coins).
    final rupeesText = _amountController.text.trim();
    final rupees = double.tryParse(rupeesText);
    if (rupees == null || rupeesText.isEmpty) {
      _showSnackBar('Enter amount in ₹ (e.g. 10, 50, 100)');
      return;
    }
    final coins = (rupees * 10).round();
    if (rupees < 10) {
      _showSnackBar('Minimum withdrawal is ₹10 (100 coins)');
      return;
    }
    if (rupees % 10 != 0) {
      _showSnackBar('Amount must be in multiples of ₹10');
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
      final repo = AppRepository.instance;
      // Server validates + debits; throws ApiException with the server
      // message on failure (insufficient balance, limit, validation).
      await repo.submitWithdrawal(
        uid: _user!.uid,
        coins: coins,
        method: _selectedMethod,
        details: details,
      );

      if (mounted) {
        // Coins deducted on server — mirror locally, instantly.
        await AuthService().deductCoins(coins);
        await AuthService().updateWithdrawInfo(
          upiId: _selectedMethod == 'upi' ? details : null,
          bankDetails: _selectedMethod == 'bank' ? details : null,
        );
        _user = AuthService().userModel; // refresh balance
        _amountController.clear();
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
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: AppShadows.elevated,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.success,
                      AppColors.success.withOpacity(0.8)
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.check_rounded, size: 40, color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Request Submitted!', style: AppTextStyles.headlineMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '$coins coins (₹${rupees.toStringAsFixed(1)})',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Payment will be processed within 24-48 hours.\nYou\'ll receive a notification when done.',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
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
            'Withdraw Coins',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  /// White coin-balance card: big orange number + gold coin icon.
  Widget _balanceCard() {
    final coins = _user?.coins ?? 0;
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
                Text(
                  'Available Coins',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$coins',
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
                        '= ₹${(coins / 10).toStringAsFixed(0)}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    '100 coins = ₹10  •  Min withdraw ₹10',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
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

  Widget _sectionTitle(String text, {String? trailing}) {
    return Row(
      children: [
        Text(text, style: AppTextStyles.titleMedium),
        const Spacer(),
        if (trailing != null)
          Text(trailing, style: AppTextStyles.bodySmall),
      ],
    );
  }

  /// Brand grid shown when 'Voucher' method is selected.
  Widget _brandGrid() {
    final brands = [
      {'name': 'Amazon Pay', 'color': const Color(0xFFFF9900), 'icon': Icons.shopping_cart_rounded},
      {'name': 'PhonePe', 'color': const Color(0xFF5F259F), 'icon': Icons.phone_android_rounded},
      {'name': 'Paytm', 'color': const Color(0xFF00B9F1), 'icon': Icons.account_balance_wallet_rounded},
      {'name': 'Flipkart', 'color': const Color(0xFF2874F0), 'icon': Icons.shopping_bag_rounded},
      {'name': 'Google Play', 'color': const Color(0xFF34A853), 'icon': Icons.play_circle_fill_rounded},
      {'name': 'Myntra', 'color': const Color(0xFFFF4466), 'icon': Icons.checkroom_rounded},
      {'name': 'Ajio', 'color': const Color(0xFF2BB1E4), 'icon': Icons.shopping_basket_rounded},
      {'name': 'Swiggy', 'color': const Color(0xFFFF5200), 'icon': Icons.restaurant_rounded},
      {'name': 'Zomato', 'color': const Color(0xFFE23744), 'icon': Icons.restaurant_menu_rounded},
      {'name': 'Netflix', 'color': const Color(0xFFE50914), 'icon': Icons.movie_rounded},
      {'name': 'Spotify', 'color': const Color(0xFF1DB954), 'icon': Icons.music_note_rounded},
      {'name': 'OLA', 'color': const Color(0xFF00C853), 'icon': Icons.directions_car_rounded},
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: brands.length,
      itemBuilder: (_, i) => _brandChip2(brands[i] as Map<String, dynamic>),
    );
  }

  Widget _brandChip2(Map<String, dynamic> brand) {
    final name = brand['name'] as String;
    final color = brand['color'] as Color;
    final icon = brand['icon'] as IconData;
    final isSelected = _voucherBrand == name;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _voucherBrand = name),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: isSelected ? color : AppColors.textTertiary, size: 24),
            const SizedBox(height: 4),
            Text(
              name,
              style: TextStyle(
                  color: isSelected ? color : AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    String? helperText,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icon(prefixIcon, color: AppColors.primary),
      helperText: helperText,
      errorText: errorText,
      filled: true,
      fillColor: AppColors.cardBackground,
      labelStyle: AppTextStyles.bodyMedium
          .copyWith(color: AppColors.textSecondary, fontSize: 13),
      hintStyle: AppTextStyles.bodySmall,
      helperStyle:
          AppTextStyles.bodySmall.copyWith(fontSize: 11),
      errorStyle: AppTextStyles.bodySmall
          .copyWith(color: AppColors.error, fontSize: 11),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Column(
            children: [
              _header(),
              const Expanded(
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
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.md, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              const SizedBox(height: AppSpacing.md),
              _balanceCard(),
              const SizedBox(height: AppSpacing.xl),
              _sectionTitle('Withdraw via',
                  trailing:
                      'Max ₹${_maxWithdrawableRupees.toStringAsFixed(0)}'),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _MethodCard(
                      icon: Icons.qr_code_rounded,
                      title: 'UPI',
                      subtitle: 'Instant',
                      isSelected: _selectedMethod == 'upi',
                      color: const Color(0xFF10B981),
                      onTap: () =>
                          setState(() => _selectedMethod = 'upi'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MethodCard(
                      icon: Icons.account_balance_rounded,
                      title: 'Bank',
                      subtitle: '1-2 days',
                      isSelected: _selectedMethod == 'bank',
                      color: const Color(0xFF3B82F6),
                      onTap: () =>
                          setState(() => _selectedMethod = 'bank'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _MethodCard(
                      icon: Icons.phone_iphone_rounded,
                      title: 'PhonePe',
                      subtitle: 'Wallet',
                      isSelected: _selectedMethod == 'phonepe',
                      color: const Color(0xFF5F259F),
                      onTap: () =>
                          setState(() => _selectedMethod = 'phonepe'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MethodCard(
                      icon: Icons.card_giftcard_rounded,
                      title: 'Voucher',
                      subtitle: 'Gift cards',
                      isSelected: _selectedMethod == 'voucher',
                      color: const Color(0xFFEC4899),
                      onTap: () =>
                          setState(() => _selectedMethod = 'voucher'),
                    ),
                  ),
                ],
              ),
              if (_selectedMethod == 'voucher') ...[
                const SizedBox(height: AppSpacing.md),
                _brandGrid(),
              ],
              const SizedBox(height: AppSpacing.xl),
              _sectionTitle('Details'),
              const SizedBox(height: AppSpacing.sm),
              if (_selectedMethod == 'upi')
                TextField(
                  controller: _upiController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: _fieldDecoration(
                    labelText: 'UPI ID',
                    hintText: 'yourname@upi',
                    prefixIcon: Icons.qr_code_rounded,
                    errorText: _upiError,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                )
              else if (_selectedMethod == 'bank')
                TextField(
                  controller: _bankController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: _fieldDecoration(
                    labelText: 'Bank Details',
                    hintText: 'Account Holder Name, Account Number, IFSC',
                    prefixIcon: Icons.account_balance_rounded,
                    errorText: _bankError,
                  ),
                  maxLines: 2,
                  textInputAction: TextInputAction.next,
                )
              else
                TextField(
                  controller: _voucherController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: _fieldDecoration(
                    labelText: _selectedMethod == 'phonepe'
                        ? 'PhonePe Number'
                        : 'Mobile / Email',
                    hintText: _selectedMethod == 'phonepe'
                        ? '10-digit mobile'
                        : 'Email where voucher is sent',
                    prefixIcon: _selectedMethod == 'phonepe'
                        ? Icons.phone_iphone_rounded
                        : Icons.alternate_email_rounded,
                  ),
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                ),
              const SizedBox(height: AppSpacing.lg),
              Builder(builder: (_) {
                final t = _amountController.text.trim();
                final r = double.tryParse(t);
                final preview =
                    (r != null && t.isNotEmpty) ? ' ≈ ${(r * 10).round()} coins' : '';
                return TextField(
                  controller: _amountController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: _fieldDecoration(
                    labelText: 'Amount (₹)',
                    hintText: 'Enter amount — e.g. 10, 50, 100',
                    prefixIcon: Icons.currency_rupee_rounded,
                    helperText:
                        'Available: ₹${_maxWithdrawableRupees.toStringAsFixed(1)}${preview.isEmpty ? '' : ' • You entered:$preview'}',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: _onAmountChange,
                  textInputAction: TextInputAction.done,
                );
              }),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading || _maxWithdrawableCoins < 100
                      ? null
                      : _submitWithdrawal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.border,
                    disabledForegroundColor: AppColors.textTertiary,
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
                          _maxWithdrawableCoins >= 100
                              ? 'REQUEST WITHDRAWAL'
                              : 'MINIMUM 100 COINS REQUIRED',
                          style: AppTextStyles.labelLarge.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _termsCard(),
            ],
          ),
        ),
      ),
    );
  }

  /// Light "info" card replacing the old dark terms list.
  Widget _termsCard() {
    const terms = [
      'Minimum withdrawal is ₹10 (100 coins)',
      'Payments are processed within 24-48 hours',
      'Earn more coins from tasks, surveys & games',
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.info_outline_rounded,
                  size: 16, color: AppColors.primaryDark),
              SizedBox(width: 6),
              Text(
                'Withdrawal terms',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...terms.map(
            (t) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      size: 15, color: AppColors.success),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      t,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _MethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected ? AppShadows.card : null,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? color
                    : color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                icon,
                size: 26,
                color: isSelected ? Colors.white : color,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(title,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isSelected ? color : AppColors.textPrimary,
                )),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
