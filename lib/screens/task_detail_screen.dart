import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_theme.dart';
import '../core/provider_logos.dart';
import '../widgets/state_views.dart';

/// Full task detail page — opened from provider tasks / popular tasks.
/// Shows big header (provider brand), coins banner, step-by-step guide,
/// time estimate, and a Start button that tracks "in progress" state.
class TaskDetailScreen extends StatefulWidget {
  final String provider;
  final String title;
  final String desc;
  final int coins;
  final List<String> steps;

  const TaskDetailScreen({
    super.key,
    required this.provider,
    required this.title,
    required this.desc,
    required this.coins,
    required this.steps,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  bool _started = false;

  @override
  Widget build(BuildContext context) {
    final color = ProviderLogos.colorFor(widget.provider);
    final minutes = (widget.coins ~/ 20).clamp(1, 60);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B12),
      body: SafeArea(
        child: Column(
          children: [
            // ===== Header =====
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: AppColors.brandHeader,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
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
                      child: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ProviderLogo(widget.provider,
                        size: 38, radius: 8),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.provider,
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text('Official partner task',
                            style: GoogleFonts.inter(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===== Reward banner =====
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withOpacity(0.35),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/coin.png',
                            width: 44,
                            height: 44,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.monetization_on_rounded,
                                color: Colors.white,
                                size: 44),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '+${widget.coins} coins',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                'on completion',
                                style: GoogleFonts.inter(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 12),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.schedule_rounded,
                                    color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '$minutes min',
                                  style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ===== Title + desc =====
                    Text(
                      widget.title,
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.desc,
                      style: GoogleFonts.inter(
                          color: Colors.white54, fontSize: 13, height: 1.5),
                    ),

                    const SizedBox(height: 20),

                    // ===== Steps card =====
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF17171F),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: color.withOpacity(0.35)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.checklist_rounded,
                                  color: color, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'How to complete',
                                style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ...widget.steps.asMap().entries.map(
                                (e) => Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 10),
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
                                          border: Border.all(
                                              color: color
                                                  .withOpacity(0.5)),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${e.key + 1}',
                                            style: GoogleFonts.inter(
                                                color: color,
                                                fontSize: 12,
                                                fontWeight:
                                                    FontWeight.w800),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4),
                                          child: Text(
                                            e.value,
                                            style: GoogleFonts.inter(
                                                color: Colors.white70,
                                                fontSize: 13,
                                                height: 1.4),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ===== Rules =====
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF17171F),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.06)),
                      ),
                      child: Column(
                        children: [
                          _rule('Coins credit after verification'),
                          _rule('One attempt per user per task'),
                          _rule('Use real details — fake info = no payout'),
                          _rule('Keep the app installed until verified'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // ===== Bottom CTA =====
            Container(
              padding: EdgeInsets.fromLTRB(
                  16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
              decoration: BoxDecoration(
                color: const Color(0xFF0B0B12),
                border: Border(
                    top: BorderSide(
                        color: Colors.white.withOpacity(0.06))),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _started
                      ? null
                      : () {
                          setState(() => _started = true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Task started! Complete the steps to earn coins.')),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _started ? const Color(0xFF1E2740) : color,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF1E2740),
                    disabledForegroundColor: Colors.white54,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _started
                            ? Icons.hourglass_top_rounded
                            : Icons.play_arrow_rounded,
                        size: 22,
                        color: _started ? Colors.white54 : Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _started ? 'In Progress…' : 'Start Task',
                        style: GoogleFonts.inter(
                          color: _started ? Colors.white54 : Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rule(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 14, color: Colors.white38),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                  color: Colors.white54, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
