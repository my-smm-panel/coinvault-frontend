import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_theme.dart';
import '../core/provider_logos.dart';
import '../widgets/app_logo.dart';
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
      backgroundColor: const Color(0xFFF7F8FA),
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
                          color: AppColors.textPrimary, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: AppLogo(
                      provider: widget.provider,
                      title: widget.title,
                      size: 44,
                      radius: 10,
                      fallbackIcon: Icons.task_alt_rounded,
                      fallbackColor: color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.provider,
                          style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text('Official partner task',
                            style: GoogleFonts.inter(
                                color: AppColors.textPrimary.withOpacity(0.85),
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
                                color: AppColors.textPrimary,
                                size: 44),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '+${widget.coins} coins',
                                style: GoogleFonts.inter(
                                  color: AppColors.textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                'on completion',
                                style: GoogleFonts.inter(
                                    color: AppColors.textPrimary.withOpacity(0.9),
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
                                    color: AppColors.textPrimary, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '$minutes min',
                                  style: GoogleFonts.inter(
                                      color: AppColors.textPrimary,
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
                          color: AppColors.textPrimary,
                          fontSize: 19,
                          fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.desc,
                      style: GoogleFonts.inter(
                          color: AppColors.textSecondary, fontSize: 13, height: 1.5),
                    ),

                    const SizedBox(height: 20),

                    // ===== Steps card =====
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
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
                                    color: AppColors.textPrimary,
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
                                                color: AppColors.textPrimary,
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
                        color: const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.textPrimary.withOpacity(0.06)),
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
                color: const Color(0xFFF7F8FA),
                border: Border(
                    top: BorderSide(
                        color: AppColors.textPrimary.withOpacity(0.06))),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _started
                      ? null
                      : () => _showConfirmation(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _started ? const Color(0xFFE8F0FF) : color,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE8F0FF),
                    disabledForegroundColor: AppColors.textSecondary,
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
                        color: _started ? AppColors.textSecondary : Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _started ? 'In Progress…' : 'Start Task',
                        style: GoogleFonts.inter(
                          color: _started ? AppColors.textSecondary : Colors.white,
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

  /// Rules + confirmation gate before a task actually starts.
  /// The user must read the rules and tap "I Understand" — only then is
  /// the task marked started. Prevents accidental taps / fraud disputes.
  void _showConfirmation(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFFFFF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7E7E7),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7E6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.shield_rounded,
                        color: Color(0xFFF59E0B), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Before you start',
                      style: GoogleFonts.inter(
                          fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...[
                'Coins are credited only after the partner verifies completion.',
                'Use real, accurate information — fake details = no payout.',
                'One attempt per user per task.',
                'Keep the app installed until verification is complete.',
                'Do not use VPN or emulators — rewards will be rejected.',
              ].map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            size: 17, color: Color(0xFF16A34A)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            r,
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                height: 1.4,
                                color: const Color(0xFF171717)),
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7E6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF3E3C2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on_rounded,
                        color: Color(0xFFF59E0B), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Reward: +${widget.coins} coins on completion',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF171717)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetCtx),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE7E7E7)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Cancel',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6B7280))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          setState(() => _started = true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Task started! Complete the steps to earn coins.'),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('I Understand, Start',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
              size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
