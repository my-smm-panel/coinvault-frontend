import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// Help Center (kit screen 23): FAQs + support note.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faqs = [
    {
      'q': 'How do I earn coins?',
      'a': 'Complete tasks, install apps, finish surveys, spin the daily wheel and refer friends. Every reward is credited by our server to your balance.'
    },
    {
      'q': 'How do I withdraw?',
      'a': 'Go to Wallet, enter coins (min 1000 for UPI, 2000 for Bank) with your UPI ID or bank details. Requests are paid manually within 24 hours.'
    },
    {
      'q': '100 coins = how many rupees?',
      'a': '100 coins = ₹10. Withdrawals must be in multiples of 100 coins.'
    },
    {
      'q': 'How many spins per day?',
      'a': 'You get 2 free spins every day. Spins reset at midnight.'
    },
    {
      'q': 'My withdrawal is pending. What now?',
      'a': 'Pending means our team is processing it. UPI/Bank payouts complete within 24 hours. Check History for the live status.'
    },
    {
      'q': 'How do referrals work?',
      'a': 'Share your referral code from Refer & Earn. When a friend signs up with it, both of you get bonus coins.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Help Center')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: Image.asset(
                    'assets/app_icon_name.png',
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.support_agent_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Need help?',
                          style: AppTextStyles.titleMedium
                              .copyWith(color: Colors.white)),
                      Text(
                        'Popular questions answered below. For account issues, reply in the app chat.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Popular Questions', style: AppTextStyles.titleMedium),
          const SizedBox(height: 8),
          ..._faqs.map((f) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.divider),
                ),
                child: ExpansionTile(
                  title: Text(
                    f['q']!,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  iconColor: AppColors.primary,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: Text(f['a']!,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          )),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
