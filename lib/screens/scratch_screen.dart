import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_theme.dart';
import '../services/app_repository.dart';

/// Scratch card screen. The server supplies availability and the reward.
class ScratchScreen extends StatefulWidget {
  const ScratchScreen({super.key});

  @override
  State<ScratchScreen> createState() => _ScratchScreenState();
}

class _ScratchScreenState extends State<ScratchScreen> {
  bool _scratched = false;
  bool _revealed = false;
  int? _reward;
  double _wipe = 0.0;
  bool _loading = true;
  bool _claiming = false;
  int? _remaining;

  void _newCard() {
    if (_remaining == 0) return;
    setState(() {
      _scratched = false;
      _revealed = false;
      _wipe = 0.0;
      _reward = null;
    });
  }

  void _onScratch(DragUpdateDetails d) {
    if (_revealed || _claiming || _remaining == null || _remaining == 0) return;
    setState(() {
      _scratched = true;
      _wipe = (_wipe + 0.06).clamp(0.0, 1.0);
      if (_wipe >= 0.55) _revealed = true;
    });
  }

  Future<void> _claimReward() async {
    if (_claiming || _remaining == null || _remaining == 0) return;
    setState(() => _claiming = true);
    try {
      final data = await AppRepository.instance.scratchCard();
      if (!mounted) return;
      final rawReward = data?['reward'];
      final reward = rawReward is num ? rawReward.toInt() : null;
      final rawRemaining = data?['remaining'];
      setState(() {
        _reward = reward;
        if (rawRemaining is num) _remaining = rawRemaining.toInt();
      });
      await _refreshStatus();
      if (mounted && reward == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('The server did not return a scratch reward.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not claim the scratch card. Please try again.')));
      }
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  Future<void> _refreshStatus() async {
    try {
      final status = await AppRepository.instance.scratchStatus();
      if (!mounted) return;
      final raw = status?['remaining'];
      setState(() {
        _remaining = raw is num ? raw.toInt() : null;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final canScratch = !_loading && _remaining != null && _remaining! > 0;
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
                    Text('Scratch & Win',
                        style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text('Scratch a card when one is available',
                        style: GoogleFonts.inter(
                            color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 28),
                    GestureDetector(
                      onPanUpdate: canScratch ? _onScratch : null,
                      onPanEnd: (_) {
                        if (_scratched && !_revealed && canScratch) {
                          setState(() => _revealed = true);
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
                              end: Alignment.bottomRight),
                          border: Border.all(
                              color: AppColors.gold.withOpacity(0.5), width: 2),
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.gold.withOpacity(0.25),
                                blurRadius: 40,
                                spreadRadius: 2)
                          ],
                        ),
                        child: Stack(
                          children: [
                            if (!_revealed && _wipe <= 0.02)
                              const Positioned.fill(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.touch_app_rounded,
                                        size: 40, color: Colors.white70),
                                    SizedBox(height: 8),
                                    Text('Swipe to scratch',
                                        style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                            if (_wipe < 1.0 && canScratch)
                              ClipPath(
                                clipper: _ScratchClipper(wipe: _wipe),
                                child: Container(
                                  width: size.width * 0.82,
                                  height: size.width * 0.52,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [
                                      AppColors.gold.withOpacity(0.15),
                                      AppColors.primary.withOpacity(0.1),
                                      Colors.white12
                                    ]),
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                        color: AppColors.gold.withOpacity(0.6),
                                        width: 3),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _reward == null ? '+?' : '+$_reward',
                                      style: GoogleFonts.inter(
                                          color: _reward == null
                                              ? Colors.white24
                                              : AppColors.goldLight,
                                          fontSize: 56,
                                          fontWeight: FontWeight.w900),
                                    ),
                                  ),
                                ),
                              ),
                            if (!canScratch && !_loading)
                              const Center(
                                child: Text('No scratch card available',
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w700)),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (_revealed && !_claiming && _reward == null)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: canScratch ? _claimReward : null,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(26))),
                          child: const Text('Reveal Reward',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 15)),
                        ),
                      )
                    else if (_claiming)
                      const SizedBox(
                        width: 52,
                        height: 52,
                        child: CircularProgressIndicator(
                            color: AppColors.primary),
                      )
                    else if (_reward != null && _remaining != 0)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _newCard,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(26))),
                          child: const Text('Scratch Again',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 15)),
                        ),
                      )
                    else
                      Text(
                        _loading
                            ? 'Checking card availability…'
                            : 'Scratch availability is determined by the server.',
                        style: GoogleFonts.inter(
                            color: AppColors.textSecondary, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              color: AppColors.textSecondary, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Rewards and availability are supplied by the authenticated server.',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  height: 1.4),
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
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textPrimary, size: 20),
              onPressed: () => Navigator.of(context).maybePop()),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border)),
            child: Text(
              _loading ? 'Checking…' : (_remaining == null ? '—' : '$_remaining available'),
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _ScratchClipper extends CustomClipper<Path> {
  final double wipe;
  const _ScratchClipper({required this.wipe});

  @override
  Path getClip(Size size) {
    final radius = (wipe * size.width * 0.5).clamp(0.0, size.width * 0.5);
    return Path()
      ..addOval(Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2), radius: radius));
  }

  @override
  bool shouldReclip(_ScratchClipper oldClipper) => wipe != oldClipper.wipe;
}
