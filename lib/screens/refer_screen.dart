import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_theme.dart';
import '../services/app_repository.dart';

/// Refer & Earn (kit screen 12): code card, copy buttons, stats.
class ReferScreen extends StatefulWidget {
  const ReferScreen({super.key});

  @override
  State<ReferScreen> createState() => _ReferScreenState();
}

class _ReferScreenState extends State<ReferScreen> {
  bool _loading = true;
  Map<String, dynamic> _info = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final info = await AppRepository.instance.referralInfo();
    if (!mounted) return;
    setState(() {
      _info = info;
      _loading = false;
    });
  }

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final code = (_info['referralCode'] ?? '').toString();
    final link = (_info['referralLink'] ?? '').toString();
    final total = ((_info['totalReferrals'] ?? 0) as num).toInt();
    final active = ((_info['activeReferrals'] ?? 0) as num).toInt();
    final earned = ((_info['totalCoinsEarned'] ?? 0) as num).toInt();
    final refs = _info['referrals'];
    final refList = refs is List ? refs : [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Refer & Earn')),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppRadius.lg),
                          child: Image.asset(
                            'assets/app_icon_name.png',
                            height: 90,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Invite friends, earn coins',
                          style: AppTextStyles.titleMedium
                              .copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Both of you get bonus coins on signup',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                code.isEmpty ? '—' : code,
                                style: AppTextStyles.headlineMedium.copyWith(
                                  color: AppColors.primary,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: code.isEmpty
                                    ? null
                                    : () => _copy(code, 'Referral code'),
                                child: const Icon(Icons.copy_rounded,
                                    color: AppColors.primary, size: 20),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (link.isNotEmpty)
                    InkWell(
                      onTap: () => _copy(link, 'Referral link'),
                      borderRadius:
                          BorderRadius.circular(AppRadius.lg),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(link,
                                  style: AppTextStyles.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            const Icon(Icons.copy_rounded,
                                size: 18,
                                color: AppColors.textTertiary),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _stat('Referrals', '$total', Icons.group_rounded),
                      const SizedBox(width: 10),
                      _stat('Active', '$active', Icons.verified_rounded),
                      const SizedBox(width: 10),
                      _stat('Earned', '$earned', Icons.monetization_on_rounded),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Recent Referrals',
                      style: AppTextStyles.titleMedium),
                  const SizedBox(height: 8),
                  if (refList.isEmpty)
                    Text('No referrals yet. Share your code!',
                        style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textTertiary)),
                  ...refList.take(20).map((e) {
                    final m = Map<String, dynamic>.from(e as Map);
                    final referred = m['referred'];
                    final name = referred is Map
                        ? ((referred['name'] ?? 'Friend').toString())
                        : 'Friend';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius:
                            BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                AppColors.primaryContainer,
                            child: Text(
                              name.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(name)),
                          Text(
                            '+${((m['coinsEarned'] ?? 0) as num).toInt()}',
                            style: const TextStyle(
                                color: AppColors.gold,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }

  Widget _stat(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(height: 4),
            Text(value,
                style: AppTextStyles.titleMedium
                    .copyWith(fontWeight: FontWeight.w800)),
            Text(label, style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }
}
