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
    // Total ever won (real backend history).
    try {
      final h = await AppRepository.instance.spinHistoryList();
      var sum = 0;
      for (final e in h) {
        if (e is Map) sum += (((e['reward'] ?? 0) as num).toInt());
      }
      if (mounted) setState(() {
        _totalWon = sum;
        _recentWins = h.take(5).toList();
      });
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
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: AppShadows.elevated,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (won)
                Image.asset(
                  'assets/coin.png',
                  width: 76,
                  height: 76,
                  errorBuilder: (_, __, ___) =>
                      const SizedBox.shrink(),
                ),
              if (won) const SizedBox(height: AppSpacing.md),
              // Reward animation
              Container(
                width: 100,
                height: 100,
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
                won ? 'Awesome! Congratulations!' : 'Better luck next time!',
                style: AppTextStyles.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                won
                    ? 'You won $_lastReward coins — added to your wallet'
                    : 'No coins this time. Try again tomorrow!',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Awesome!'),
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
    return Scaffold(
      backgroundColor: AppColors.spinDark,
      appBar: AppBar(
        backgroundColor: AppColors.spinDark,
        foregroundColor: Colors.white,
        title: const Text('Spin & Win'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'My history',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const HistoryScreen()),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/spin_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const SizedBox.shrink(),
            ),
          ),
          SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              // Bear mascot
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(AppRadius.xl),
                child: Image.asset(
                  'assets/app_icon_name.png',
                  height: 110,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Stats: spins left + total won (real data)
              Row(
                children: [
                  Expanded(
                    child: _spinStat(
                        Icons.donut_large_rounded,
                        '$_remainingSpins',
                        'Spins Left',
                        AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _spinStatImage(
                        'assets/coin.png',
                        '$_totalWon',
                        'Total Won'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
            // Status message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.spinCard,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: _remainingSpins > 0
                      ? AppColors.primary.withOpacity(0.5)
                      : Colors.white12,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _remainingSpins > 0 ? Icons.donut_large_rounded : Icons.lock_rounded,
                    color: _remainingSpins > 0 ? AppColors.primary : Colors.white38,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: _remainingSpins > 0 ? Colors.white : Colors.white60,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            
            // Spin Wheel (wheel rotates, pointer stays fixed on top)
            Stack(
              alignment: Alignment.topCenter,
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationAnim.value,
                      child: child,
                    );
                  },
                  child: _buildWheel(),
                ),
                Positioned(
                  top: 0,
                  child: CustomPaint(
                    size: const Size(36, 22),
                    painter:
                        _TrianglePainter(color: AppColors.gold),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Spin Button (kit orange)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_spinning || _redeeming || _remainingSpins <= 0) ? null : _spin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _remainingSpins > 0 ? AppColors.primary : AppColors.spinCard,
                  foregroundColor: _remainingSpins > 0 ? Colors.white : Colors.white38,
                  disabledBackgroundColor: AppColors.spinCard,
                  disabledForegroundColor: Colors.white38,
                  elevation: _remainingSpins > 0 ? 4 : 0,
                  shadowColor: AppColors.primary.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
                child: _spinning
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Text('Spinning...', style: AppTextStyles.labelLarge),
                        ],
                      )
                    : Text(
                        _remainingSpins > 0 ? 'SPIN NOW' : 'NO SPINS LEFT',
                        style: AppTextStyles.labelLarge.copyWith(
                          fontWeight: FontWeight.w700,
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
        ],
      ),
    );
  }

  /// Recent wins preview — real spin history from the backend.
  Widget _buildRecentWins() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Recent Wins',
                style: AppTextStyles.titleMedium
                    .copyWith(color: Colors.white)),
            const Spacer(),
            InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const HistoryScreen()),
              ),
              child: Text('View all',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (_recentWins.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.spinCard,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                const Icon(Icons.history_rounded,
                    color: Colors.white38, size: 20),
                const SizedBox(width: AppSpacing.sm),
                const Expanded(
                  child: Text(
                    'No spins yet — your wins will show here',
                    style:
                        TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.spinCard,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: List.generate(_recentWins.length, (i) {
                final w = _recentWins[i] as Map;
                final reward =
                    ((w['reward'] ?? 0) as num).toInt();
                final when = (w['createdAt'] ??
                        w['created_at'] ??
                        '')
                    .toString();
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: reward > 0
                              ? AppColors.gold.withOpacity(0.15)
                              : Colors.white10,
                        ),
                        child: Icon(
                          reward > 0
                              ? Icons.monetization_on_rounded
                              : Icons.close_rounded,
                          size: 16,
                          color: reward > 0
                              ? AppColors.gold
                              : Colors.white38,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          reward > 0
                              ? 'Won $reward coins'
                              : 'No reward',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        _shortDate(when),
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        // Daily tip card (own, not a copy)
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.18),
                AppColors.spinCard,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border:
                Border.all(color: AppColors.primary.withOpacity(0.35)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lightbulb_rounded,
                    color: AppColors.gold, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              const Expanded(
                child: Text(
                  'Tip: 2 free spins every day. Use them before midnight — they don\'t carry over!',
                  style:
                      TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  String _shortDate(String iso) {
    if (iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      if (dt.year == now.year &&
          dt.month == now.month &&
          dt.day == now.day) {
        final h = dt.hour.toString().padLeft(2, '0');
        final m = dt.minute.toString().padLeft(2, '0');
        return '$h:$m';
      }
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return '';
    }
  }

  /// Small stat card for the spin header (icon version).
  Widget _spinStat(
      IconData icon, String value, String label, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.spinCard.withOpacity(0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  /// Small stat card for the spin header (image version).
  Widget _spinStatImage(String asset, String value, String label) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.spinCard.withOpacity(0.9),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppColors.gold.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Image.asset(asset,
              width: 26,
              height: 26,
              errorBuilder: (_, __, ___) => const Icon(
                  Icons.monetization_on_rounded,
                  color: AppColors.gold,
                  size: 26)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWheel() {
    // Outer bulb ring positions (12 bulbs around the wheel).
    final bulbs = List.generate(12, (i) {
      final a = (i * 2 * math.pi / 12) - math.pi / 2;
      return Offset(150 + 158 * math.cos(a), 150 + 158 * math.sin(a));
    });
    return SizedBox(
      width: 320,
      height: 320,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Bulbs
          ...bulbs.map((o) => Positioned(
                left: o.dx - 7,
                top: o.dy - 7,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _spinning
                        ? AppColors.gold
                        : AppColors.gold.withOpacity(0.45),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withOpacity(0.7),
                        blurRadius: _spinning ? 12 : 5,
                      ),
                    ],
                  ),
                ),
              )),
          // Wheel disc
          Container(
            width: 290,
            height: 290,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold, width: 7),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.45),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.25),
                  blurRadius: 70,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Wheel segments (own warm palette)
                CustomPaint(
                  size: const Size(290, 290),
                  painter: _WheelPainter(segments: _segments),
                ),
                // Center hub with bear
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: AppColors.spinDark,
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: AppColors.gold, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/app_icon.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.donut_large_rounded,
                        size: 38,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Top pointer is rendered fixed outside (see build).
        ],
      ),
    );
  }

  Widget _buildRewardsLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Possible Rewards',
            style: AppTextStyles.titleMedium.copyWith(color: Colors.white)),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: [10, 3, 2].map((coins) {
            final is10 = coins == 10;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: is10 ? AppColors.gold.withOpacity(0.15) : AppColors.spinCard,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(
                  color: is10 ? AppColors.gold.withOpacity(0.5) : Colors.white12,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.monetization_on_rounded,
                    size: 18,
                    color: is10 ? AppColors.gold : Colors.white70,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$coins coins',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: is10 ? AppColors.gold : Colors.white,
                      fontWeight: is10 ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  if (is10) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        'BEST',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
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
        color: AppColors.spinCard,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: Colors.white12),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Text('How It Works',
                  style: AppTextStyles.titleMedium.copyWith(color: Colors.white)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _HowStep(number: '1', text: 'You get 2 free spins every day'),
          _HowStep(number: '2', text: 'Spin the wheel to win 10, 2, or 3 coins'),
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
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(text,
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70)),
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
    
    // Own warm palette (no purple) - index-safe for any slice count.
    final colors = [
      AppColors.gold,          // 10 coins - best
      AppColors.primary,       // hot orange
      const Color(0xFFB34700), // deep orange
      const Color(0xFFFFD54F), // light gold
    ];

    for (int i = 0; i < segments.length; i++) {
      final startAngle = i * segmentAngle - math.pi / 2;

      // Segment background
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
      
      // Segment border
      final borderPaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawPath(path, borderPaint);
      
      // Text label
      final textAngle = startAngle + segmentAngle / 2;
      final textRadius = radius * 0.65;
      final textX = center.dx + textRadius * math.cos(textAngle);
      final textY = center.dy + textRadius * math.sin(textAngle);
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${segments[i]}',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
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

/// Triangle painter for the spin wheel pointer
class _TrianglePainter extends CustomPainter {
  final Color color;
  
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}