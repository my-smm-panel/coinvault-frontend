import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_theme.dart';
import '../services/auth_service.dart';
import '../models/app_models.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  bool _loading = true;

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
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    await AuthService().signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Text('Please sign in', style: AppTextStyles.bodyMedium),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: AppShadows.elevated,
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    backgroundImage: _user!.photoUrl != null 
                        ? NetworkImage(_user!.photoUrl!) 
                        : null,
                    child: _user!.photoUrl == null
                        ? Text(
                            _user!.displayName.substring(0, 1).toUpperCase(),
                            style: AppTextStyles.displayLarge.copyWith(color: Colors.white),
                          )
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _user!.displayName,
                    style: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
                  ),
                  if (_user!.email != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _user!.email!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  // Coins display
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.monetization_on_rounded, color: AppColors.gold, size: 24),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_user!.coins} Coins',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '≈ ₹${(_user!.coins / 10).toStringAsFixed(1)}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Stats Grid
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Total Earned',
                    value: '${_user!.coins}',
                    subtitle: 'coins',
                    icon: Icons.trending_up_rounded,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _StatCard(
                    title: 'Spins Used Today',
                    value: '${_user!.dailySpinsUsed}',
                    subtitle: '/ 2',
                    icon: Icons.casino_rounded,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            // Withdrawal Info Section
            _buildSection('Withdrawal Details', [
              if (_user!.upiId != null && _user!.upiId!.isNotEmpty)
                _InfoTile(
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'UPI ID',
                  subtitle: _user!.upiId!,
                  color: AppColors.primary,
                ),
              if (_user!.bankDetails != null && _user!.bankDetails!.isNotEmpty)
                _InfoTile(
                  icon: Icons.account_balance_rounded,
                  title: 'Bank Details',
                  subtitle: _user!.bankDetails!,
                  color: AppColors.success,
                ),
              if ((_user!.upiId == null || _user!.upiId!.isEmpty) &&
                  (_user!.bankDetails == null || _user!.bankDetails!.isEmpty))
                _InfoTile(
                  icon: Icons.info_outline_rounded,
                  title: 'No withdrawal method saved',
                  subtitle: 'Add UPI or Bank details in Withdraw screen',
                  color: AppColors.textTertiary,
                ),
            ]),

            const SizedBox(height: AppSpacing.lg),

            // Settings
            _buildSection('Settings', [
              _InfoTile(
                icon: Icons.notifications_rounded,
                title: 'Notifications',
                subtitle: 'Manage push notifications',
                color: AppColors.primary,
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                onTap: () {},
              ),
              _InfoTile(
                icon: Icons.help_outline_rounded,
                title: 'Help & Support',
                subtitle: 'FAQs, contact us',
                color: AppColors.success,
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                onTap: () {},
              ),
              _InfoTile(
                icon: Icons.privacy_tip_rounded,
                title: 'Privacy Policy',
                subtitle: 'Read our privacy policy',
                color: AppColors.warning,
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                onTap: () {},
              ),
              _InfoTile(
                icon: Icons.description_rounded,
                title: 'Terms of Service',
                subtitle: 'Read terms and conditions',
                color: AppColors.error,
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                onTap: () {},
              ),
            ]),

            const SizedBox(height: AppSpacing.xl),

            // App Version
            Text(
              'CoinVault v1.0.0',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.divider),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            children: children.map((child) => child).toList(),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.divider),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(value, style: AppTextStyles.headlineMedium.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
          )),
          Text(subtitle, style: AppTextStyles.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Text(title, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}