import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../services/auth_service.dart';
import '../services/app_repository.dart';
import '../services/api_client.dart';
import '../models/app_models.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
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
      // Server debits Supabase ledger atomically - throws with server
      // message on failure (insufficient balance, limit, validation).
      await repo.submitWithdrawal(
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
        _showSuccessDialog(coins, coins / 10);
      }
    } on ApiException catch (e) {
      if (mounted) _showSnackBar(e.message);
    } catch (_) {
      if (mounted) _showSnackBar('Error occurred. Please try again.');
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
            color: AppColors.surface,
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
                    colors: [AppColors.success, AppColors.success.withOpacity(0.8)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, size: 40, color: Colors.white),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    );
  }

  /// Voucher brand selector chip (Amazon / OLA / Gift).
  Widget _brandChip(String label, IconData icon, Color color) {
    final sel = _voucherBrand == label;
    return InkWell(
      onTap: () => setState(() => _voucherBrand = label),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: sel ? color.withOpacity(0.18) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: sel ? color : AppColors.divider, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: sel ? color : Colors.white54, size: 18),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: sel ? color : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Withdraw')),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Withdraw Coins')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Card (kit orange)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Balance',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_user!.coins}',
                        style: AppTextStyles.displayLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'coins',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      '≈ ₹${(_user!.coins / 10).toStringAsFixed(1)}  •  100 coins = ₹10',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Withdrawal Method Selection
            Text('Withdrawal Method', style: AppTextStyles.titleMedium),
            const SizedBox(height: AppSpacing.md),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.85,
              children: [
                _MethodCard(
                  icon: Icons.flash_on_rounded,
                  title: 'UPI',
                  subtitle: 'ID',
                  isSelected: _selectedMethod == 'upi',
                  color: const Color(0xFF16A34A),
                  onTap: () => setState(() => _selectedMethod = 'upi'),
                ),
                _MethodCard(
                  icon: Icons.account_balance_rounded,
                  title: 'Bank',
                  subtitle: 'Transfer',
                  isSelected: _selectedMethod == 'bank',
                  color: const Color(0xFF1D4ED8),
                  onTap: () => setState(() => _selectedMethod = 'bank'),
                ),
                _MethodCard(
                  icon: Icons.phone_iphone_rounded,
                  title: 'PhonePe',
                  subtitle: 'UPI app',
                  isSelected: _selectedMethod == 'phonepe',
                  color: const Color(0xFF7C3AED),
                  onTap: () => setState(() => _selectedMethod = 'phonepe'),
                ),
                _MethodCard(
                  icon: Icons.card_giftcard_rounded,
                  title: 'Voucher',
                  subtitle: 'Amazon/OLA',
                  isSelected: _selectedMethod == 'voucher',
                  color: const Color(0xFFEC4899),
                  onTap: () => setState(() => _selectedMethod = 'voucher'),
                ),
              ],
            ),
            if (_selectedMethod == 'voucher') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  _brandChip('Amazon', Icons.shopping_cart_rounded,
                      const Color(0xFFFF9900)),
                  const SizedBox(width: 8),
                  _brandChip('OLA', Icons.directions_car_rounded,
                      const Color(0xFF34D399)),
                  const SizedBox(width: 8),
                  _brandChip('Gift', Icons.card_giftcard_rounded,
                      const Color(0xFFEC4899)),
                ],
              ),
            ],
            
            const SizedBox(height: AppSpacing.xl),
            
            // Input Fields
            if (_selectedMethod == 'upi') ...[
              TextField(
                controller: _upiController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'UPI ID',
                  hintText: 'yourname@upi',
                  prefixIcon: const Icon(Icons.qr_code_rounded),
                  errorText: _upiError,
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
            ] else if (_selectedMethod == 'bank') ...[
              TextField(
                controller: _bankController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Bank Details',
                  hintText: 'Account Holder Name, Account Number, IFSC',
                  prefixIcon: const Icon(Icons.account_balance_rounded),
                  errorText: _bankError,
                ),
                maxLines: 2,
                textInputAction: TextInputAction.next,
              ),
            ] else ...[
              TextField(
                controller: _voucherController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: _selectedMethod == 'phonepe'
                      ? 'PhonePe Number'
                      : 'Mobile / Email',
                  hintText: _selectedMethod == 'phonepe'
                      ? '10-digit mobile'
                      : 'Email where voucher is sent',
                  prefixIcon: Icon(
                    _selectedMethod == 'phonepe'
                        ? Icons.phone_iphone_rounded
                        : Icons.alternate_email_rounded,
                  ),
                ),
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
              ),
            ],
            
            const SizedBox(height: AppSpacing.lg),
            
            // Amount Input (₹ — direct paisa, converted to coins on submit)
            Builder(builder: (_) {
              final t = _amountController.text.trim();
              final r = double.tryParse(t);
              final preview = (r != null && t.isNotEmpty)
                  ? ' ≈ ${(r * 10).round()} coins'
                  : '';
              return TextField(
                controller: _amountController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Amount (₹)',
                  hintText: 'Enter amount — e.g. 10, 50, 100',
                  prefixIcon: const Icon(Icons.currency_rupee_rounded),
                  helperText: 'Available: ₹${_maxWithdrawableRupees.toStringAsFixed(1)}${preview.isEmpty ? '' : ' • You entered:$preview'}',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: _onAmountChange,
                textInputAction: TextInputAction.done,
              );
            }),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Withdraw Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _loading || _maxWithdrawableCoins < 100 ? null : _submitWithdrawal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _maxWithdrawableCoins >= 100 ? AppColors.gold : AppColors.surfaceVariant,
                  disabledBackgroundColor: AppColors.surfaceVariant,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        _maxWithdrawableCoins >= 100 
                            ? 'REQUEST WITHDRAWAL' 
                            : 'MINIMUM 100 COINS REQUIRED',
                        style: AppTextStyles.labelLarge.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Terms
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Important', style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary)),
                  const SizedBox(height: AppSpacing.sm),
                  _TermItem('Minimum withdrawal: 100 coins (₹10)'),
                  _TermItem('Amount must be in multiples of 100 coins'),
                  _TermItem('UPI payments: usually within 24 hours'),
                  _TermItem('Bank transfers: 1-2 business days'),
                  _TermItem('Admin manually approves each request'),
                  _TermItem('Details saved for future withdrawals'),
                ],
              ),
            ),
          ],
        ),
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
          color: isSelected ? color.withOpacity(0.08) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isSelected ? color : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? AppShadows.card : null,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? color : color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                icon,
                size: 28,
                color: isSelected ? Colors.white : color,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
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

class _ConversionRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _ConversionRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: highlight ? FontWeight.w600 : FontWeight.w400,
              color: highlight ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
              color: highlight ? AppColors.gold : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TermItem extends StatelessWidget {
  final String text;

  const _TermItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: AppTextStyles.bodySmall)),
        ],
      ),
    );
  }
}