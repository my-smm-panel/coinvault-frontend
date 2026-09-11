import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_theme.dart';
import '../services/auth_service.dart';
import '../services/app_repository.dart';
import '../services/api_client.dart';
import 'history_screen.dart';

class SpinScreen extends StatefulWidget {
  const SpinScreen({super.key});

  @override
  State<SpinScreen> createState() => _SpinScreenState();
}

class _SpinScreenState extends State<SpinScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnim;
  int _lastReward = 0;
  bool _spinning = false;
  bool _redeeming = false; // server redeem in-flight: block second spin
  int _remainingSpins = 2;
  bool _showResult = false;
  int _totalWon = 0;
  int _coins = 0;
  List<dynamic> _recentWins = [];
  String _statusMessage = 'You have 2 free spins';

  // 8-slice wheel, values mirror real payouts (10/2/3). Server decides reward.
  final List<int> _segments = [10, 2, 3, 2, 10, 3, 2, 3];
  // Probabilities: 10=40%, 2=30%, 3=30%

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _rotationAnim = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.decelerate),
    );
    _loadSpins();
    _controller.addStatusListener(_onAnimationStatus);
  }

  Future<void> _loadSpins() async {
    // Server is source of truth for remaining spins (backend enforces limit).
    var serverOk = false;
    try {
      final status = await AppRepository.instance.spinStatus();
      if (status != null && mounted) {
        final limit = (status['dailyLimit'] ?? 2) as int;
        final used = (status['spinsUsed'] ?? 0) as int;
        final left = (limit - used).clamp(0, limit);
        setState(() {
          _remainingSpins = left;
          _statusMessage = left > 0
              ? 'You have $left free spin${left > 1 ? 's' : ''}'
              : 'No spins left today';
        });
        serverOk = true;
      }
    } catch (_) {}
    // Total ever won (real backend history) + wallet coins.
    try {
      final h = await AppRepository.instance.spinHistoryList();
      var sum = 0;
      for (final e in h) {
        if (e is Map) sum += (((e['reward'] ?? 0) as num).toInt());
      }
      if (mounted) setState(() {
        _totalWon = sum;
        _recentWins = h.take(3).toList();
      });
    } catch (_) {}
    try {
      final auth = AuthService();
      final um = auth.userModel;
      if (mounted && um != null) setState(() => _coins = um.coins);
    } catch (_) {}
    if (!mounted || serverOk) return;
    final auth = AuthService();
    setState(() {
      _remainingSpins = auth.getRemainingSpins();
      _statusMessage = _remainingSpins > 0
          ? 'You have $_remainingSpins free spin${_remainingSpins > 1 ? 's' : ''}'
          : 'No spins left today';
    });
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() {
        _spinning = false;
        _redeeming = true; // lock: no second spin before result
      });
      // Reward comes from the SERVER (Supabase ledger) - never local.
      _redeemServerSpin();
    }
  }

  /// Ask backend for the spin outcome. Server decides reward, credits
  /// Supabase, and we mirror it locally + Firebase RTDB. No coins on failure.
  Future<void> _redeemServerSpin() async {
    try {
      final data = await AppRepository.instance.spinNow();
      final reward = ((data['coins'] ?? 0) as num).toInt();
      if (!mounted) return;
      final auth = AuthService();
      if (reward > 0) {
        await auth.addCoins(reward);
      }
      await auth.recordSpin();
      if (!mounted) return;
      setState(() {
        _lastReward = reward;
        _showResult = true;
        _redeeming = false; // unlock: result shown
        _remainingSpins = (_remainingSpins - 1).clamp(0, 99);
        _statusMessage = _remainingSpins > 0
            ? 'You have $_remainingSpins free spin${_remainingSpins > 1 ? 's' : ''} left'
            : 'No spins left today';
      });
      await _loadSpins(); // refresh exact server count
      if (mounted) _showResultDialog();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _redeeming = false; // unlock on failure too
        _statusMessage = e.message;
      });
      await _loadSpins();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _redeeming = false;
        _statusMessage = 'Spin failed. Check connection and try again.';
      });
    }
  }


  void _spin() {
    // Blocked while spinning, redeeming result, or out of spins.
    if (_spinning || _redeeming || _remainingSpins <= 0) return;

    final auth = AuthService();
    if (!auth.canSpin()) {
      setState(() {
        _remainingSpins = 0;
        _statusMessage = 'No spins left today';
      });
      return;
    }

    setState(() {
      _spinning = true;
      _showResult = false;
      _statusMessage = 'Spinning...';
    });

    // Calculate random rotation (multiple full rotations + random segment)
    final segmentAngle = 2 * math.pi / _segments.length;
    final randomSegment = math.Random().nextInt(_segments.length);
    // Add 5-8 full rotations + land on random segment
    final fullRotations = 5 + math.Random().nextInt(4); // 5-8 rotations
    final targetRotation = (fullRotations * 2 * math.pi) +
                          (randomSegment * segmentAngle) +
                          (segmentAngle / 2);

    _rotationAnim = Tween<double>(
      begin: _controller.value,
      end: targetRotation,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.decelerate),
    );

    _controller.forward(from: 0);
  }

  void _showResultDialog() {
    final won = _lastReward > 0;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.surface, AppColors.spinCard],
            ),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: won ? AppColors.gold.withOpacity(0.5) : Colors.white12,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (won ? AppColors.gold : AppColors.primary).withOpacity(0.35),
                blurRadius: 60,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (won)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold.withOpacity(0.6), width: 2),
                  ),
                  child: Image.asset(
                    'assets/coin.png',
                    width: 68,
                    height: 68,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              if (won) const SizedBox(height: AppSpacing.md),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: won ? AppColors.goldGradient : null,
                  color: won ? null : AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (won ? AppColors.gold : AppColors.textTertiary).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    won ? '+$_lastReward' : '0',
                    style: AppTextStyles.displayLarge.copyWith(
                      color: won ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                won ? '🎉 Congratulations!' : 'Better luck next time!',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: won ? AppColors.gold : Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                won
                    ? '$_lastReward coins added to your wallet'
                    : 'No coins this time. Try again tomorrow!',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                  ),
                  child: const Text(
                    'Awesome!',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      setState(() => _showResult = false);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final wheelSize = (size.width * 0.84).clamp(270.0, 330.0);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Stack(
        children: [
          // Background: subtle vertical navy gradient
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0D1220), Color(0xFF0A0E1A)],
                ),
              ),
            ),
          ),
          // Soft orange glow behind the wheel
          Positioned(
            top: size.height * 0.22,
            left: -60,
            right: -60,
            child: Container(
              height: size.width * 0.9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFF5820B).withOpacity(0.14),
                    const Color(0xFFF5820B).withOpacity(0.04),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ===== Header: back + title + help =====
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, AppSpacing.sm, 4, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 20),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      const Text('🎁', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 6),
                      Text(
                        'Spin & Win',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF3A4660)),
                        ),
                        child: const Center(
                          child: Text('?',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        // ===== Stats card: Your Coins | Spins Left =====
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF151C2E),
                            borderRadius: BorderRadius.circular(18),
                            border:
                                Border.all(color: const Color(0xFF243050)),
                          ),
                          child: IntrinsicHeight(
                            child: Row(
                              children: [
                                Expanded(
                                  child: _statHalf(
                                    icon: Icons.monetization_on_rounded,
                                    iconBg: const Color(0xFFFBB040),
                                    iconColor: const Color(0xFF151C2E),
                                    label: 'Your Coins',
                                    value: '$_coins',
                                  ),
                                ),
                                VerticalDivider(
                                  width: 1,
                                  thickness: 1,
                                  color: const Color(0xFF243050).withOpacity(0.7),
                                ),
                                Expanded(
                                  child: _statHalf(
                                    icon: Icons.refresh_rounded,
                                    iconBg: const Color(0xFFF7931E),
                                    iconColor: Colors.white,
                                    label: 'Spins Left',
                                    value: '$_remainingSpins',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // ===== Free spin banner =====
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: const Color(0xFF151C2E),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFF243050)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7931E).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.card_giftcard_rounded,
                                    color: Color(0xFFFBB040), size: 24),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _remainingSpins > 0
                                          ? 'You have $_remainingSpins free spin${_remainingSpins > 1 ? 's' : ''}'
                                          : 'No spins left today',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Spin the wheel and win exciting rewards!',
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF8A93A6),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF12271D),
                                  borderRadius: BorderRadius.circular(AppRadius.full),
                                  border: Border.all(color: const Color(0xFF2E5A45)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.bolt_rounded,
                                        color: Color(0xFF4ADE80), size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      'Free Spin',
                                      style: TextStyle(
                                        color: Color(0xFF4ADE80),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // ===== Wheel =====
                        Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 12),
                              padding: EdgeInsets.all(wheelSize * 0.05),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(0xFFFBB040).withOpacity(0.10),
                                    const Color(0xFFF5820B).withOpacity(0.04),
                                    Colors.transparent,
                                  ],
                                  radius: 0.95,
                                ),
                              ),
                              child: AnimatedBuilder(
                                animation: _controller,
                                builder: (context, child) {
                                  return Transform.rotate(
                                    angle: _rotationAnim.value,
                                    child: child,
                                  );
                                },
                                child: _buildWheel(wheelSize),
                              ),
                            ),
                            // Red triangle pointer (like reference)
                            CustomPaint(
                              size: const Size(36, 30),
                              painter: _PointerPainter(
                                color: const Color(0xFFE53946),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // ===== Spin Now button =====
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: ElevatedButton(
                            onPressed:
                                (_spinning || _redeeming || _remainingSpins <= 0)
                                    ? null
                                    : _spin,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              disabledBackgroundColor: const Color(0xFF1A2238),
                              disabledForegroundColor: const Color(0xFF6B7488),
                              elevation: 4,
                              shadowColor: const Color(0xFFF5820B).withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.full),
                              ),
                            ),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: (_spinning || _redeeming || _remainingSpins <= 0)
                                    ? null
                                    : const LinearGradient(
                                        colors: [Color(0xFFFFB13D), Color(0xFFF5820B)],
                                      ),
                                color: (_spinning || _redeeming || _remainingSpins <= 0)
                                    ? const Color(0xFF1A2238)
                                    : null,
                                borderRadius: BorderRadius.circular(AppRadius.full),
                              ),
                              child: _spinning
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.4,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.md),
                                        Text('Spinning...',
                                            style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700)),
                                      ],
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _remainingSpins > 0
                                              ? Icons.casino_rounded
                                              : Icons.lock_rounded,
                                          size: 22,
                                          color: _remainingSpins > 0
                                              ? Colors.white
                                              : const Color(0xFF6B7488),
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Text(
                                          _remainingSpins > 0
                                              ? 'Spin Now ›'
                                              : 'No Spins Left',
                                          style: GoogleFonts.inter(
                                            color: _remainingSpins > 0
                                                ? Colors.white
                                                : const Color(0xFF6B7488),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // Rewards Legend
                        _buildRewardsLegend(),

                        const SizedBox(height: AppSpacing.xl),

                        // How it works
                        _buildHowItWorks(),

                        const SizedBox(height: AppSpacing.xl),

                        // Recent Wins (real history)
                        _buildRecentWins(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// One half of the stats card.
  Widget _statHalf({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return InkWell(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const HistoryScreen())),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: iconBg.withOpacity(0.4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                        color: const Color(0xFF8A93A6), fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFF6B7488), size: 22),
          ],
        ),
      ),
    );
  }

  /// Recent wins — real spin history from the backend.
  Widget _buildRecentWins() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.emoji_events_rounded,
                color: Color(0xFFFBB040), size: 20),
            const SizedBox(width: 6),
            Text('Recent Wins',
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const Spacer(),
            InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              ),
              child: Text('View all ›',
                  style: GoogleFonts.inter(
                      color: const Color(0xFFF7931E),
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (_recentWins.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: const Color(0xFF151C2E),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF243050)),
            ),
            child: Row(
              children: [
                const Icon(Icons.history_rounded,
                    color: Color(0xFF6B7488), size: 20),
                const SizedBox(width: AppSpacing.sm),
                const Expanded(
                  child: Text(
                    'No spins yet — your wins will show here',
                    style: TextStyle(color: Color(0xFF8A93A6), fontSize: 12),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF151C2E),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF243050)),
            ),
            child: Column(
              children: List.generate(_recentWins.length, (i) {
                final w = _recentWins[i] as Map;
                final reward = ((w['reward'] ?? 0) as num).toInt();
                final when =
                    (w['createdAt'] ?? w['created_at'] ?? '').toString();
                final avColors = [
                  const Color(0xFF3B82F6),
                  const Color(0xFFEC4899),
                  const Color(0xFF22C55E),
                  const Color(0xFFF59E0B),
                ];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: avColors[i % avColors.length],
                        ),
                        child: Center(
                          child: Text(
                            _avatarLetter(w),
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Won $reward coins',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Spin reward',
                              style: GoogleFonts.inter(
                                  color: const Color(0xFF8A93A6),
                                  fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _shortDate(when),
                        style: GoogleFonts.inter(
                            color: const Color(0xFF8A93A6), fontSize: 11),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '🪙 $reward',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFFBB040),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  String _avatarLetter(Map w) {
    final name =
        (w['userName'] ?? w['displayName'] ?? w['name'] ?? 'You').toString();
    return name.isNotEmpty ? name[0].toUpperCase() : 'Y';
  }

  String _shortDate(String iso) {
    if (iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return '';
    }
  }

  Widget _buildWheel(double outer) {
    final disc = outer - 22;
    // Gold bulbs around the rim (12)
    final bulbs = List.generate(12, (i) {
      final a = (i * 2 * math.pi / 12) - math.pi / 2;
      final r = disc / 2 + 9;
      return Offset(outer / 2 + r * math.cos(a), outer / 2 + r * math.sin(a));
    });
    return SizedBox(
      width: outer,
      height: outer,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ...bulbs.map((o) => Positioned(
                left: o.dx - 5,
                top: o.dy - 5,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _spinning
                        ? const Color(0xFFFFC93C)
                        : const Color(0xFFFFC93C).withOpacity(0.55),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFC93C).withOpacity(0.7),
                        blurRadius: _spinning ? 12 : 5,
                      ),
                    ],
                  ),
                ),
              )),
          // Wheel disc — burnt orange + cream segments (reference palette)
          Container(
            width: disc,
            height: disc,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFC93C), width: 5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF5820B).withOpacity(0.45),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: const Color(0xFFFFC93C).withOpacity(0.2),
                  blurRadius: 60,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size(disc, disc),
                  painter: _WheelPainter(segments: _segments),
                ),
                // Center hub: orange circle with "SPIN" + crown (like ref)
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF7931E), Color(0xFFE8641C)],
                    ),
                    border: Border.all(color: Colors.white.withOpacity(0.85), width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.workspace_premium_rounded,
                          color: Colors.white, size: 20),
                      Text(
                        'SPIN',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.card_giftcard_rounded,
                color: Color(0xFFFBB040), size: 20),
            const SizedBox(width: 6),
            Text('Possible Rewards',
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: [10, 3, 2].map((coins) {
            final is10 = coins == 10;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: is10
                    ? const Color(0xFFF5C518).withOpacity(0.12)
                    : const Color(0xFF1E2740),
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(
                  color: is10
                      ? const Color(0xFFF5C518).withOpacity(0.5)
                      : const Color(0xFF243050),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.monetization_on_rounded,
                    size: 18,
                    color: is10 ? const Color(0xFFF5C518) : const Color(0xFF8A93A6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$coins coins',
                    style: GoogleFonts.inter(
                      color: is10 ? const Color(0xFFF5C518) : Colors.white,
                      fontWeight: is10 ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  if (is10) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5C518),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: const Text(
                        'BEST',
                        style: TextStyle(
                          color: Color(0xFF1A2238),
                          fontWeight: FontWeight.w800,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildHowItWorks() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFF151C2E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF243050)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_rounded,
                  color: Color(0xFFFBB040), size: 20),
              const SizedBox(width: 6),
              Text('How It Works',
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _HowStep(number: '1', text: 'You get 2 free spins every day'),
          _HowStep(number: '2', text: 'Spin the wheel to win 10, 2 or 3 coins'),
          _HowStep(number: '3', text: 'Coins are added to your balance instantly'),
          _HowStep(number: '4', text: '100 coins = ₹10, withdraw via UPI/Bank'),
          _HowStep(number: '5', text: 'Spin resets at midnight daily'),
        ],
      ),
    );
  }
}

class _HowStep extends StatelessWidget {
  final String number;
  final String text;

  const _HowStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFFF5820B),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                  color: const Color(0xFF8A93A6), fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<int> segments;

  _WheelPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segmentAngle = 2 * math.pi / segments.length;

    // Reference palette: burnt orange + cream yellow alternating
    final colors = [
      const Color(0xFFE8641C), // burnt orange
      const Color(0xFFFFEDC2), // pale cream
    ];

    for (int i = 0; i < segments.length; i++) {
      final startAngle = i * segmentAngle - math.pi / 2;

      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          segmentAngle,
          false,
        )
        ..close();

      canvas.drawPath(path, paint);

      final borderPaint = Paint()
        ..color = Colors.white.withOpacity(0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawPath(path, borderPaint);

      // Text label — dark on cream, white on orange
      final isCream = i % colors.length == 1;
      final textAngle = startAngle + segmentAngle / 2;
      final textRadius = radius * 0.64;
      final textX = center.dx + textRadius * math.cos(textAngle);
      final textY = center.dy + textRadius * math.sin(textAngle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: '${segments[i]}',
          style: GoogleFonts.inter(
            fontSize: radius * 0.185,
            fontWeight: FontWeight.w900,
            color: isCream ? const Color(0xFFB34E10) : Colors.white,
            shadows: [
              Shadow(
                color: isCream
                    ? Colors.white.withOpacity(0.4)
                    : Colors.black.withOpacity(0.35),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(textX - textPainter.width / 2, textY - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Pointer — reference: red/crimson downward triangle.
class _PointerPainter extends CustomPainter {
  final Color color;

  _PointerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(w / 2, h)
      ..lineTo(w * 0.06, 0)
      ..lineTo(w * 0.94, 0)
      ..close();
    canvas.drawPath(path, paint);

    final outline = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, outline);

    canvas.drawCircle(
      Offset(w / 2, 0),
      w * 0.14,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
