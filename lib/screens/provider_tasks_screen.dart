import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/provider_logos.dart';

/// One provider's available tasks on its own page.
/// Header shows the company logo big; below, only its tasks.
class ProviderTasksScreen extends StatelessWidget {
  final String provider;
  const ProviderTasksScreen({super.key, required this.provider});

  static const Map<String, List<Map<String, dynamic>>> _tasksBy = {
    'PubScale': [
      {'title': 'Ludo Supreme', 'desc': 'Install & play 5 games', 'coins': 500, 'steps': ['Install Ludo Supreme from Play Store', 'Open & create account', 'Play 5 Ludo matches', 'Reach level 3 — Coins credited']},
      {'title': 'Rummy Circle', 'desc': 'Install & play 3 rounds', 'coins': 300, 'steps': ['Install Rummy Circle', 'Register with mobile', 'Play 3 cash games', 'Complete KYC — Coins credited']},
    ],
    'Cint': [
      {'title': 'Shopping Survey', 'desc': '10 min brand survey', 'coins': 150, 'steps': ['Open survey', 'Answer all questions honestly', 'Submit — Coins credited in 10 min']},
      {'title': 'Complete Profile', 'desc': 'Fill all fields', 'coins': 25, 'steps': ['Complete your profile', 'Add phone & email', 'Submit — Coins credited']},
    ],
    'TimeWall': [
      {'title': 'Daily Check-in', 'desc': 'Open app today', 'coins': 25, 'steps': ['Open CoinVault today', 'Tap Check-in — Coins credited']},
      {'title': 'Watch & Earn', 'desc': 'Watch 3 video ads', 'coins': 30, 'steps': ['Tap Start', 'Watch each ad till end', 'Coins credited per video']},
    ],
    'BitLabs': [
      {'title': 'Tech Preferences', 'desc': '5 min survey — Earn quick', 'coins': 75, 'steps': ['Open survey', 'Answer tech questions', 'Submit — Coins credited']},
      {'title': 'Mobile Gaming Survey', 'desc': '6 min — gaming habits', 'coins': 80, 'steps': ['Open survey', 'Share gaming preferences', 'Submit — Coins credited']},
    ],
    'CPX Research': [
      {'title': 'Finance & Banking', 'desc': '10 min — finance survey', 'coins': 120, 'steps': ['Open survey', 'Answer finance questions', 'Submit — Coins credited']},
      {'title': 'Consumer Habits', 'desc': '8 min — shopping survey', 'coins': 100, 'steps': ['Open survey', 'Answer honestly', 'Submit — Coins credited']},
    ],
    'Pollfish': [
      {'title': 'Quick Poll', 'desc': '1 min poll', 'coins': 45, 'steps': ['Answer the poll', 'Submit — Instant coins']},
      {'title': 'Shopping Behavior', 'desc': '12 min survey', 'coins': 150, 'steps': ['Open survey', 'Complete 12 min', 'Submit — Coins credited']},
    ],
    'OfferPro': [
      {'title': 'Rate App', 'desc': 'Leave 5-star review', 'coins': 30, 'steps': ['Open Play Store', 'Rate 5 stars + review', 'Screenshot & verify — Coins credited']},
      {'title': 'Sign up Bonus', 'desc': 'Create free account', 'coins': 50, 'steps': ['Tap Start', 'Create account on partner site', 'Verify email — Coins credited']},
    ],
    'GrowDeck': [
      {'title': 'Share on WhatsApp', 'desc': 'Share referral link', 'coins': 15, 'steps': ['Tap Share', 'Send to 1 friend on WhatsApp', 'Coins credited when opened']},
      {'title': 'Invite Bonus', 'desc': 'Invite 1 friend', 'coins': 40, 'steps': ['Share your referral code', 'Friend signs up & completes 1 task', 'Coins credited']},
    ],
    'CPI Droid': [
      {'title': 'MPL Ludo', 'desc': 'Install & play 5 games', 'coins': 350, 'steps': ['Install MPL', 'Open & sign up', 'Play 5 Ludo games', 'Coins credited in 24h']},
      {'title': 'Dream11', 'desc': 'Install & create team', 'coins': 200, 'steps': ['Install Dream11', 'Create your first team', 'Join 1 contest — Coins credited']},
    ],
    'Lootably': [
      {'title': 'Watch Video Ad', 'desc': 'Watch 30-sec video', 'coins': 10, 'steps': ['Tap Start', 'Watch video till end', 'Coins credited']},
      {'title': 'Offer Wall', 'desc': 'Complete partner offer', 'coins': 80, 'steps': ['Open wall', 'Complete any offer', 'Coins credited in 10 min']},
    ],
  };

  @override
  Widget build(BuildContext context) {
    final color = ProviderLogos.colorFor(provider);
    final tasks = _tasksBy[provider] ??
        [
          {'title': 'Daily Task', 'desc': 'Check back soon', 'coins': 20},
        ];
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B12),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.55)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              size: 20),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('${tasks.length} tasks',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ProviderLogo(provider, size: 84, radius: 20),
                  const SizedBox(height: 8),
                  Text(provider,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800)),
                  const Text('Available tasks',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: tasks.length,
                itemBuilder: (_, i) {
                  final t = tasks[i];
                  return InkWell(
                    onTap: () =>
                        _showDetail(context, provider, t, color),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF17171F),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: color.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          ProviderLogo(provider, size: 46),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(t['title'] as String,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14)),
                                Text(t['desc'] as String,
                                    style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 11)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                      Icons.monetization_on_rounded,
                                      size: 15,
                                      color: AppColors.gold),
                                  const SizedBox(width: 3),
                                  Text('+${t['coins']}',
                                      style: const TextStyle(
                                          color: AppColors.gold,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () =>
                                    _showDetail(context, provider, t,
                                        color),
                                borderRadius:
                                    BorderRadius.circular(8),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient:
                                        AppColors.primaryGradient,
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: const Text('Start',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight:
                                              FontWeight.w800)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, String provider,
      Map<String, dynamic> t, Color color) {
    final steps = (t['steps'] as List?)?.cast<String>() ?? [t['desc'] as String];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF17171F),
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Colors.white10)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ProviderLogo(provider, size: 56),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t['title'] as String,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800)),
                      Text(provider,
                          style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('+${t['coins']} coins',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text('How to earn',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...steps.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text('${e.key + 1}',
                              style: TextStyle(
                                  color: color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(e.value,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Task started! Complete steps to earn coins.')));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Start Task',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
