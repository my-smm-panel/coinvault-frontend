import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// Help Center: guidance stays neutral when values are configured by the
/// backend and may change over time.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faqs = [
    {
      'q': 'How do I earn coins?',
      'a': 'Open the relevant earning screen and follow the activities currently returned by the server. Reward details are shown there when available.'
    },
    {
      'q': 'How do I withdraw?',
      'a': 'Open Wallet and choose one of the withdrawal methods currently provided by the server. Enter the requested details and review the values shown before submitting.'
    },
    {
      'q': 'Where can I check reward values?',
      'a': 'Reward values are supplied by the backend and are displayed on each available survey, offer, task, or other earning screen.'
    },
    {
      'q': 'How many spins can I use?',
      'a': 'Open the Spin screen to see the current server-provided availability and any limits for your account.'
    },
    {
      'q': 'My withdrawal is pending. What now?',
      'a': 'Check Wallet or History for the latest server-provided status. If the status needs attention, use the in-app support flow.'
    },
    {
      'q': 'How do referrals work?',
      'a': 'Open Refer & Earn to view the current referral instructions and any values configured for your account.'
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
                        'Find general guidance below. For account-specific values, use the relevant screen.',
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
