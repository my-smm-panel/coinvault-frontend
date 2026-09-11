import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_theme.dart';

/// Scratch card screen — daily free scratch (demo economy: 1/day).
/// Scratch overlay wipes with finger; reward reveals under.
class ScratchScreen extends StatefulWidget {
  const ScratchScreen({super.key});

  @override
  State<ScratchScreen> createState() => _ScratchScreenState();
}

class _ScratchScreenState extends State<ScratchScreen> {
  bool _scratched = false;
  bool _revealed = false;
  int _reward = 0;
  double _wipe = 0.0;

  static const _rewards = [2, 3, 5, 10, 3, 2, 5, 3];

  void _newCard() {
    setState(() {
      _scratched = false;
      _revealed = false;
      _wipe = 0.0;
      _reward = 0;
    });
  }

  void _onScratch(DragUpdateDetails d) {
    if (_revealed) return;
    setState(() {
      _scratched = true;
      _wipe = (_wipe + 0.06).clamp(0.0, 1.0);
      if (_wipe >= 0.55 && !_revealed) {
        _revealed = true;
        _reward = _rewards[math.Random().nextInt(_rewards.length)];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B12),
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Scratch & Win',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'One free scratch card every day 🎫',
                      style: GoogleFonts.inter(
                          color: Colors.white54, fontSize: 13),
                    ),
                    const SizedBox(height: 28),

                    // ===== Scratch card =====
                    GestureDetector(
                      onPanUpdate: _onScratch,
                      child: Container(
                        width: size.width * 0.82,
                        height: size.width * 0.52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2A1A0A), Color(0xFF171008)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                              color: AppColors.gold.withOpacity(0.5),
                              width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gold.withOpacity(0.25),
                              blurRadius: 40,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Reward under the scratch layer
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset('assets/coin.png',
                                      width: 64,
                                      height: 64,
                                      errorBuilder: (_, __, ___) => const Icon(
                                          Icons.monetization_on_rounded,
                                          color: AppColors.gold,
                                          size: 64)),
                                  const SizedBox(height: 10),
                                  Text(
                                    _revealed
                                        ? 'You won $_reward coins!'
                                        : 'Scratch to reveal',
                                    style: GoogleFonts.inter(
                                      color: _revealed
                                          ? AppColors.goldLight
                                          : Colors.white38,
                                      fontSize: _revealed ? 22 : 14,
                                      fontWeight: _revealed
                                          ? FontWeight.w900
                                          : FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Scratch foil
                            if (!_revealed)
                              Opacity(
                                opacity: 1.0 - _wipe,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        const Color(0xFF4A4A52),
                                        const Color(0xFF6B6B75)
                                            .withOpacity(0.95),
                                        const Color(0xFF3A3A42),
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: _wipe > 0.02
                                        ? const SizedBox.shrink()
                                        : Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.touch_app_rounded,
                                                  size: 40,
                                                  color: Colors.white
                                                      .withOpacity(0.85)),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Swipe to scratch',
                                                style: GoogleFonts.inter(
                                                    color: Colors.white70,
                                                    fontSize: 13,
                                                    fontWeight:
                                                        FontWeight.w700),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ===== Action buttons =====
                    if (_revealed)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _newCard,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                          ),
                          child: Text(
                            'Claim & Scratch Again',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                        ),
                      )
                    else if (_scratched)
                      Text(
                        'Keep scratching…',
                        style: GoogleFonts.inter(
                            color: Colors.white38, fontSize: 12),
                      )
                    else
                      Text(
                        '👆 Swipe your finger on the card',
                        style: GoogleFonts.inter(
                            color: Colors.white38, fontSize: 12),
                      ),

                    const SizedBox(height: 24),

                    // ===== Rewards table =====
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF17171F),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.06)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.emoji_events_rounded,
                                  color: AppColors.gold, size: 18),
                              const SizedBox(width: 8),
                              Text('Scratch Rewards',
                                  style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [2, 3, 5, 10].map((c) {
                              final best = c == 10;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: best
                                      ? AppColors.gold.withOpacity(0.12)
                                      : const Color(0xFF1E2740),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: best
                                          ? AppColors.gold
                                              .withOpacity(0.5)
                                          : Colors.white12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                        Icons.monetization_on_rounded,
                                        size: 14,
                                        color: best
                                            ? AppColors.gold
                                            : Colors.white54),
                                    const SizedBox(width: 5),
                                    Text('$c coins',
                                        style: GoogleFonts.inter(
                                            color: best
                                                ? AppColors.gold
                                                : Colors.white,
                                            fontSize: 12,
                                            fontWeight:
                                                FontWeight.w600)),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '1 scratch daily • resets at midnight',
                            style: GoogleFonts.inter(
                                color: Colors.white38, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF17171F),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: AppColors.primary.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt_rounded,
                    color: AppColors.primaryLight, size: 15),
                const SizedBox(width: 4),
                Text('1 Free Today',
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
