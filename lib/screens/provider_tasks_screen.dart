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
      {'title': 'Install Game & Play', 'desc': 'Reach level 5', 'coins': 500},
      {'title': 'Try New App', 'desc': 'Open for 2 minutes', 'coins': 300},
    ],
    'Cint': [
      {'title': 'Shopping Survey', 'desc': '10 min survey', 'coins': 150},
      {'title': 'Complete Profile', 'desc': 'Fill all fields', 'coins': 25},
    ],
    'TimeWall': [
      {'title': 'Daily Check-in', 'desc': 'Open app today', 'coins': 25},
      {'title': 'Watch 3 Videos', 'desc': 'Short video ads', 'coins': 30},
    ],
    'BitLabs': [
      {'title': 'Tech Preferences', 'desc': '5 min survey', 'coins': 75},
      {'title': 'Mobile Gaming Survey', 'desc': '6 min survey', 'coins': 80},
    ],
    'CPX Research': [
      {'title': 'Finance & Banking', 'desc': '10 min survey', 'coins': 120},
      {'title': 'Consumer Habits', 'desc': '8 min survey', 'coins': 100},
    ],
    'Pollfish': [
      {'title': 'Quick Poll', 'desc': '1 min poll', 'coins': 45},
      {'title': 'Shopping Behavior', 'desc': '12 min survey', 'coins': 150},
    ],
    'OfferPro': [
      {'title': 'Rate App', 'desc': '5-star review', 'coins': 30},
      {'title': 'Sign up Bonus', 'desc': 'Create free account', 'coins': 50},
    ],
    'GrowDeck': [
      {'title': 'Share on WhatsApp', 'desc': 'Share referral link', 'coins': 15},
      {'title': 'Invite Bonus', 'desc': 'Invite 1 friend', 'coins': 40},
    ],
    'CPI Droid': [
      {'title': 'Install & Open', 'desc': 'Install partner app', 'coins': 50},
      {'title': 'Reach Level 5', 'desc': 'Play to level 5', 'coins': 200},
    ],
    'Lootably': [
      {'title': 'Watch Video Ad', 'desc': '30-second video', 'coins': 10},
      {'title': 'Daily Video', 'desc': 'Watch daily video', 'coins': 15},
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
                  return Container(
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
                              onTap: () => ScaffoldMessenger.of(
                                      context)
                                  .showSnackBar(const SnackBar(
                                      content: Text(
                                          'Task started! Complete to earn coins.'))),
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
