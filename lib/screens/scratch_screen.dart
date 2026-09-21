import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_theme.dart';
import '../services/app_repository.dart';
import '../services/auth_service.dart';

/// Scratch card screen — backend-fetched (POST /api/scratch for reward, GET /api/scratch/status).
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
  bool _loading = true;
  bool _claiming = false;
  int _remaining = 1;

  void _newCard() {
    setState(() {
      _scratched = false;
      _revealed = false;
      _wipe = 0.0;
      _reward = 0;
    });
  }

  void _onScratch(DragUpdateDetails d) {
    if (_revealed || _claiming) return;
    setState(() {
      _scratched = true;
      _wipe = (_wipe + 0.06).clamp(0.0, 1.0);
      if (_wipe >= 0.55 && !_revealed) {
        _revealed = true;
        // Keep visual reward pending — real reward from backend
        // (will be set after backend respond)
        _reward = 0;
      }
    });
  }

  Future<void> _claimReward() async {
    if (_claiming) return;
    setState(() => _claiming = true);
    try {
      final data = await AppRepository.instance.scratchCard();
      if (!mounted) return;
      if (data != null && data['reward'] is int) {
        final reward = data['reward'] as int;
        setState(() => _reward = reward);
        // Optimistic local credit
        try {
          AuthService().addCoins(reward);
        } catch (_) {}
      } else {
        // Backend unreachable — show error, no fake reward
        setState(() => _reward = 0);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not claim reward. Please try again.')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _reward = 0);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  Future<void> _refreshStatus() async {
    try {
      final status = await AppRepository.instance.scratchStatus();
      if (!mounted) return;
      if (status != null) {
        setState(() {
          _remaining = status['remaining'] as int? ?? 1;
        });
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _refreshStatus();
    // Don't set _loading=false until after status check
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
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
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'One free scratch card every day 🎫',
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Scratch card
                    GestureDetector(
                      onPanUpdate: _onScratch,
                      onPanEnd: (_) {
                        if (_scratched && !_revealed) {
                          _revealed = true;
                          setState(() {});
                        }
                      },
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
                            width: 2,
                          ),
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
                            // Card base (hidden under scratch layer)
                            Positioned.fill(
                              child: _revealed || _wipe > 0.02
                                  ? const SizedBox.shrink()
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.touch_app_rounded,
                                          size: 40,
                                          color: AppColors
                                                  .textPrimary
                                                  .withOpacity(0.85),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Swipe to scratch',
                                          style: GoogleFonts.inter(
                                            color: Colors.white70,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                            // Scratch layer
                            if (_wipe < 1.0)
                              ClipPath(
                                clipper: _ScratchClipper(
                                  wipe: _wipe,
                                  size: size.width * 0.82,
                                ),
                                child: Container(
                                  width: size.width * 0.82,
                                  height: size.width * 0.52,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.gold.withOpacity(0.15),
                                        AppColors.primary.withOpacity(0.1),
                                        Colors.white12,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius:
                                        BorderRadius.circular(22),
                                    border: Border.all(
                                      color: AppColors.gold.withOpacity(0.6),
                                      width: 3,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '+${_reward > 0 ? _reward : "??"}',
                                      style: GoogleFonts.inter(
                                        color: _reward > 0
                                            ? AppColors.goldLight
                                            : Colors.white24,
                                        fontSize: 56,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Action buttons
                    if (_revealed && !_claiming) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _claimReward,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                          ),
                          child: Text(
                            _reward > 0
                                ? 'Claim & Scratch Again'
                                : 'Reveal Reward',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      )
                    ] else if (_claiming) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                          ),
                          child: const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    ] else if (_revealed && _reward > 0) ...[
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
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      )
                    ] else if (_scratched)
                      Text(
                        'Keep scratching…',
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      )
                    else
                      Text(
                        '👆 Swipe your finger on the card',
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Rewards table (static visual guide)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.textPrimary.withOpacity(0.06),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                  Icons.emoji_events_rounded,
                                  color: AppColors.gold,
                                  size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Scratch Rewards',
                                style: GoogleFonts.inter(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
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
                                      : const Color(0xFFE8F0FF),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: best
                                        ? AppColors.gold.withOpacity(0.5)
                                        : AppColors.border,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.monetization_on_rounded,
                                      size: 14,
                                      color: best
                                          ? AppColors.gold
                                          : AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      '$c coins',
                                      style: GoogleFonts.inter(
                                        color: best
                                            ? AppColors.gold
                                            : AppColors.textPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '1 scratch daily • resets at midnight',
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
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
            icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary,
                size: 20),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.primary.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                const Icon(
                    Icons.bolt_rounded,
                    color: AppColors.primaryLight,
                    size: 15),
                const SizedBox(width: 4),
                Text(
                  '$_remaining Free Today',
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

/// Custom clipper that reveals a growing region of the scratch card.
class _ScratchClipper extends CustomClipper<Path> {
  final double wipe;
  final double size;

  _ScratchClipper({required this.wipe, required this.size});

  @override
  Path getClip(Size size) {
    if (wipe >= 1.0) return Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    // Circular reveal: start from center, grow outward
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = (wipe * (size.width * 0.5)).clamp(0.0, size.width * 0.5);
    return Path()
      ..addOval(
        Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
      );
  }

  @override
  bool shouldReclip(_ScratchClipper oldClipper) => wipe != oldClipper.wipe;
}
