import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_theme.dart';
import '../services/auth_service.dart';
import '../services/app_repository.dart';
import '../services/api_client.dart';
import '../screens/earn_screen.dart';
import 'history_screen.dart';

/// Spin & Win — light theme (design sheet: white background, colorful
/// wheel, "Daily Free Spin" countdown card, white SPIN hub, promo banner).
///
/// The wheel is purely visual: the SERVER decides the reward
/// (AppRepository.instance.spinNow) and credits Supabase. We only restyle
/// the UI here — the _spinning / _redeeming / _remainingSpins state machine
/// and _redeemServerSpin are unchanged from the dark version.
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
  int _totalWon = 0;
  int _coins = 0;
  List<dynamic> _recentWins = [];
  String _statusMessage = 'You have 2 free spins';

  // Daily free spin countdown — resets at local midnight.
  Timer? _countdownTimer;
  Duration _timeToReset = const Duration(hours: 11, minutes: 40, seconds: 30);

  // 8-slice wheel — EXACT reference pattern: 10,2,10,2,10,5,5,3
  // (server still decides actual reward; wheel is visual only)
  final List<int> _segments = [10, 2, 10, 2, 10, 5, 5, 3];

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
    _tickCountdown();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _tickCountdown();
    });
  }

  void _tickCountdown() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final left = tomorrow.difference(now);
    setState(() => _timeToReset = left.isNegative ? Duration.zero : left);
  }

  String _fmtCountdown() {
    final h = _timeToReset.inHours.remainder(24).toString().padLeft(2, '0');
    final m = _timeToReset.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _timeToReset.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<void> _loadSpins() async {
    // Server is source of truth for remaining spins (backend enforces limit).
    final status = await AppRepository.instance.spinStatus();
    if (!mounted) return;
    if (status != null) {
      final limit = (status['dailyLimit'] ?? 2) as int;
      final used = (status['spinsUsed'] ?? 0) as int;
      final left = (limit - used).clamp(0, limit);
      setState(() {
        _remainingSpins = left;
        _statusMessage = left > 0
            ? 'You have $left free spin${left > 1 ? 's' : ''}'
            : 'No spins left today';
      });
    }
    // Total ever won (real backend history).
    try {
      final h = await AppRepository.instance.spinHistoryList();
      if (!mounted) return;
      var sum = 0;
      for (final e in h) {
        if (e is Map) sum += (((e['reward'] ?? 0) as num).toInt());
      }
      setState(() {
        _totalWon = sum;
        _recentWins = h.take(3).toList();
      });
    } catch (_) {}
    try {
      final auth = AuthService();
      final um = auth.userModel;
      if (mounted && um != null) setState(() => _coins = um.coins);
    } catch (_) {}
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
      // Credit coins INSTANTLY (local first, background sync)
      if (reward > 0) {
        auth.addCoins(reward); // no await — instant UI
      }
      auth.recordSpin(); // no await
      if (!mounted) return;
      // Optimistic decrement for instant feedback.
      setState(() {
        _lastReward = reward;
        _coins = auth.userModel?.coins ?? _coins; // wallet updates NOW
        _redeeming = false; // unlock: result shown
        _remainingSpins = (_remainingSpins - 1).clamp(0, 99);
        _statusMessage = _remainingSpins > 0
            ? 'You have $_remainingSpins free spin${_remainingSpins > 1 ? 's' : ''} left'
            : 'No spins left today';
      });
      // Refresh exact server count BEFORE showing the result dialog, so the
      // value the user sees is the one the backend actually credited.
      await _loadSpins();
      if (mounted) _showResultDialog();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _redeeming = false; // unlock on failure — spin available again
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
        _redeeming = false; // unlock — do NOT leave user stuck
        _statusMessage = 'Spin failed. Check connection and try again.';
      });
    }
  }

  void _spin() {
    // Blocked while spinning, redeeming result, or out of spins.
    // _remainingSpins is already server-authoritative (set by _loadSpins),
    // so we don't re-check against the cached user model here.
    if (_spinning || _redeeming || _remainingSpins <= 0) return;

    setState(() {
      _spinning = true;
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
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: won ? AppColors.gold.withOpacity(0.5) : AppColors.border,
              width: 1.5,
            ),
            boxShadow: AppShadows.elevated,
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
                      color: (won ? AppColors.gold : AppColors.primary).withOpacity(0.3),
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
                  color: won ? AppColors.primaryDark : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                won
                    ? '$_lastReward coins added to your wallet'
                    : 'No coins this time. Try again tomorrow!',
                style: AppTextStyles.bodyMedium,
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
      // Result dialog dismissed — refresh state from the server.
      _loadSpins();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final wheelSize = (size.width * 0.84).clamp(270.0, 330.0);

    return Scaffold(
      // Light theme per design sheet: white surface on #F7F8FA background
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ===== Header: back + title + coin balance =====
            _buildHeader(),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xxl),
                child: Column(
                  children: [
                    // ===== Daily Free Spin countdown card =====
                    _buildDailyFreeSpinCard(),

                    const SizedBox(height: AppSpacing.lg),

                    // ===== Colorful wheel + center SPIN + top pointer =====
                    _buildWheelArea(wheelSize),

                    const SizedBox(height: AppSpacing.lg),

                    // ===== Remaining spins status =====
                    _buildSpinsStatus(),

                    const SizedBox(height: AppSpacing.lg),

                    // ===== Yellow promo banner + View Providers =====
                    _buildPromoBanner(),

                    const SizedBox(height: AppSpacing.lg),

                    // Rewards Legend
                    _buildRewardsLegend(),

                    const SizedBox(height: AppSpacing.lg),

                    // How it works
                    _buildHowItWorks(),

                    const SizedBox(height: AppSpacing.lg),

                    // Recent Wins (real history)
                    _buildRecentWins(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Header — back arrow + "Spin the Wheel" + coin balance pill (light sheet)
  // ===========================================================================
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.md, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary, size: 20),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Text(
            'Spin the Wheel',
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          // Coin balance pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.goldContainer,
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(color: AppColors.gold.withOpacity(0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/coin.png',
                  width: 18,
                  height: 18,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.monetization_on_rounded,
                    color: AppColors.gold,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$_coins',
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Daily Free Spin card — clock icon + live countdown to midnight
  // (design sheet: "Next spin in 11:40:30")
  // ===========================================================================
  Widget _buildDailyFreeSpinCard() {
    final ready = _remainingSpins > 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.access_time_rounded,
                color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Free Spin',
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Next spin in ${_fmtCountdown()}',
                  style: GoogleFonts.inter(
                    color: ready ? AppColors.primary : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: ready ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: ready
                  ? AppColors.success.withOpacity(0.12)
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(
                color: ready
                    ? AppColors.success.withOpacity(0.4)
                    : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt_rounded,
                    color: ready ? AppColors.success : AppColors.textTertiary,
                    size: 14),
                const SizedBox(width: 4),
                Text(
                  ready ? '$_remainingSpins Left' : 'Done',
                  style: TextStyle(
                    color: ready ? AppColors.success : AppColors.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Wheel area — colorful 8-slice wheel, white SPIN hub at center,
  // dark pointer at top, soft glow behind.
  // ===========================================================================
  Widget _buildWheelArea(double wheelSize) {
    return SizedBox(
      height: wheelSize * 1.18,
      width: wheelSize * 1.2,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Soft orange glow behind the wheel (light-theme subtle)
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: wheelSize,
                height: wheelSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.06),
                ),
              ),
            ),
          ),

          // The wheel itself
          Container(
            margin: const EdgeInsets.only(top: 14),
            padding: EdgeInsets.all(wheelSize * 0.045),
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

          // Center SPIN button (tappable — same guard as the big button)
          Positioned(
            top: 14 + wheelSize * 0.045 + wheelSize / 2 - 38,
            left: 0,
            right: 0,
            child: Align(
              child: _buildSpinHub(),
            ),
          ),

          // Dark pointer at top
          const CustomPaint(
            size: Size(34, 30),
            painter: _PointerPainter(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  /// Center white SPIN button (design sheet) — starts a spin with the same
  /// state-machine guards as the footer button.
  Widget _buildSpinHub() {
    final busy = _spinning || _redeeming;
    final canSpin = _remainingSpins > 0 && !busy;
    return GestureDetector(
      onTap: canSpin ? _spin : null,
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: canSpin ? AppColors.primary : AppColors.border,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: canSpin
                  ? AppColors.primary.withOpacity(0.35)
                  : Colors.black.withOpacity(0.10),
              blurRadius: 18,
              spreadRadius: 2,
            ),
          ],
        ),
        child: busy
            ? const Padding(
                padding: EdgeInsets.all(22),
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _remainingSpins > 0
                        ? Icons.casino_rounded
                        : Icons.lock_rounded,
                    color: _remainingSpins > 0
                        ? AppColors.primary
                        : AppColors.textTertiary,
                    size: 20,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'SPIN',
                    style: GoogleFonts.inter(
                      color: _remainingSpins > 0
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ===========================================================================
  // Remaining spins status line
  // ===========================================================================
  Widget _buildSpinsStatus() {
    return Text(
      _statusMessage,
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(
        color: _remainingSpins > 0
            ? AppColors.textSecondary
            : AppColors.textTertiary,
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // ===========================================================================
  // Yellow promo banner — "20% EXTRA COINS" + "View Providers" orange pill
  // ===========================================================================
  Widget _buildPromoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 12, 12, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFD93D), Color(0xFFF59E0B)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '20% EXTRA COINS',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'on every offer you complete',
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.92),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Material(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.full),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EarnScreen()),
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View Providers',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded,
                        color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
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
                color: AppColors.gold, size: 20),
            const SizedBox(width: 6),
            Text('Recent Wins',
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            if (_totalWon > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.goldContainer,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '$_totalWon won all-time',
                  style: GoogleFonts.inter(
                    color: AppColors.primaryDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            const Spacer(),
            InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              ),
              child: Text('View all ›',
                  style: GoogleFonts.inter(
                      color: AppColors.primary,
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
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.history_rounded,
                    color: AppColors.textTertiary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'No spins yet — your wins will show here',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: List.generate(_recentWins.length, (i) {
                final w = _recentWins[i] as Map;
                final reward = ((w['reward'] ?? 0) as num).toInt();
                final when =
                    (w['createdAt'] ?? w['created_at'] ?? '').toString();
                final avColors = [
                  AppColors.primary,
                  AppColors.gold,
                  AppColors.success,
                  const Color(0xFF3B82F6),
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
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Spin reward',
                              style: GoogleFonts.inter(
                                  color: AppColors.textTertiary,
                                  fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _shortDate(when),
                        style: GoogleFonts.inter(
                            color: AppColors.textTertiary, fontSize: 11),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$reward coins',
                        style: GoogleFonts.inter(
                          color: AppColors.gold,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        reward > 0
                            ? Icons.monetization_on_rounded
                            : Icons.history_rounded,
                        size: 15,
                        color: reward > 0
                            ? AppColors.gold
                            : AppColors.textTertiary,
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
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
    // White bulbs around the rim (12)
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
                        ? Colors.white
                        : Colors.white.withOpacity(0.75),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(_spinning ? 0.18 : 0.08),
                        blurRadius: _spinning ? 8 : 3,
                      ),
                    ],
                  ),
                ),
              )),
          // Wheel disc — colorful segments with a white rim ring
          Container(
            width: disc,
            height: disc,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 6),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.28),
                  blurRadius: 30,
                  spreadRadius: 3,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
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
                // Center hub is rendered on top of the wheel in
                // _buildWheelArea (white SPIN button, design sheet).
                const SizedBox.shrink(),
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
                color: AppColors.gold, size: 20),
            const SizedBox(width: 6),
            Text('Possible Rewards',
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
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
                    ? AppColors.gold.withOpacity(0.12)
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(
                  color: is10
                      ? AppColors.gold.withOpacity(0.5)
                      : AppColors.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.monetization_on_rounded,
                    size: 18,
                    color: is10 ? AppColors.gold : AppColors.textTertiary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$coins coins',
                    style: GoogleFonts.inter(
                      color: is10 ? AppColors.primaryDark : AppColors.textPrimary,
                      fontWeight: is10 ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  if (is10) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: const Text(
                        'BEST',
                        style: TextStyle(
                          color: Colors.white,
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
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 6),
              Text('How It Works',
                  style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
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
              color: AppColors.primary,
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
                  color: AppColors.textSecondary, fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Colorful 8-slice wheel — design sheet palette:
/// blue / green / red / purple / orange / yellow, "+50" label, coin icon
/// and a gift box on the prize slices.
class _WheelPainter extends CustomPainter {
  final List<int> segments;

  const _WheelPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segmentAngle = 2 * math.pi / segments.length;

    // Design sheet: 6 vivid slice colors cycled around the wheel.
    final colors = [
      const Color(0xFF4D8AF0), // blue
      const Color(0xFF34B96E), // green
      const Color(0xFFE53946), // red
      const Color(0xFF8E5BFF), // purple
      const Color(0xFFFF8C42), // orange
      const Color(0xFFF5C518), // yellow
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
        ..color = Colors.white.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawPath(path, borderPaint);

      // Label: "+50" on the big slice, coin icon, gift box on others.
      final textAngle = startAngle + segmentAngle / 2;
      final textRadius = radius * 0.64;
      final textX = center.dx + textRadius * math.cos(textAngle);
      final textY = center.dy + textRadius * math.sin(textAngle);

      // Yellow slices need dark text, everything else white.
      final isYellow = colors[i % colors.length] == const Color(0xFFF5C518);
      final labelColor = isYellow ? const Color(0xFF8A6212) : Colors.white;
      final label = '+${segments[i]}';

      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: GoogleFonts.inter(
            fontSize: radius * 0.16,
            fontWeight: FontWeight.w900,
            color: labelColor,
            shadows: [
              Shadow(
                color: isYellow
                    ? Colors.white.withOpacity(0.5)
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

      // Prize glyph above the label: gift box on 5-coin slices, coin on the
      // rest — drawn as vector paths (no emoji rendering issues).
      final isGift = segments[i] == 5;
      final iconSize = radius * 0.2;
      final iconCenter = Offset(
        textX,
        textY - radius * 0.18,
      );
      _drawGiftOrCoin(canvas, iconCenter, iconSize, isGift, labelColor);
    }
  }

  void _drawGiftOrCoin(
      Canvas canvas, Offset c, double s, bool isGift, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.09
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (isGift) {
      // box
      final r = Rect.fromCenter(center: c, width: s, height: s * 0.78);
      canvas.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(s * 0.14)),
          paint);
      // vertical ribbon
      canvas.drawLine(Offset(c.dx, r.top), Offset(c.dx, r.bottom), paint);
      // horizontal ribbon
      canvas.drawLine(
          Offset(r.left, c.dy + s * 0.04), Offset(r.right, c.dy + s * 0.04),
          paint);
      // bow loops
      final bowR = s * 0.16;
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(c.dx - s * 0.2, r.top + bowR * 0.5),
              width: bowR * 2,
              height: bowR),
          paint);
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(c.dx + s * 0.2, r.top + bowR * 0.5),
              width: bowR * 2,
              height: bowR),
          paint);
    } else {
      // coin: outer circle + inner ring + currency tick
      canvas.drawCircle(c, s * 0.5, paint);
      canvas.drawCircle(c, s * 0.33, paint);
      canvas.drawLine(Offset(c.dx, c.dy - s * 0.2),
          Offset(c.dx, c.dy + s * 0.2), paint);
      canvas.drawLine(Offset(c.dx - s * 0.14, c.dy - s * 0.09),
          Offset(c.dx + s * 0.14, c.dy - s * 0.09), paint);
      canvas.drawLine(Offset(c.dx - s * 0.14, c.dy + s * 0.09),
          Offset(c.dx + s * 0.14, c.dy + s * 0.09), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Pointer — design sheet: dark downward triangle at the top of the wheel.
class _PointerPainter extends CustomPainter {
  final Color color;

  const _PointerPainter({required this.color});

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
      ..color = Colors.white.withOpacity(0.6)
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
