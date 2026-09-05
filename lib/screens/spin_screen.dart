import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_theme.dart';
import '../services/auth_service.dart';
import '../services/app_repository.dart';
import '../services/api_client.dart';
import '../models/app_models.dart';

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
  bool _showResult = false;
  int _remainingSpins = 2;
  String _statusMessage = 'You have 2 free spins';

  final List<int> _segments = [10, 2, 3]; // 100 is NEVER included - weighted 0%
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
        return;
      }
    } catch (_) {}
    if (!mounted) return;
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

  int _getWeightedReward() {
    final random = math.Random();
    final roll = random.nextDouble();
    
    if (roll < 0.40) return 10;      // 40%
    else if (roll < 0.70) return 2;  // 30%
    else return 3;                    // 30%
    // 100 coins is NEVER returned (0% weight)
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Spin Wheel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () {}, // Spin history
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            // Status message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: _remainingSpins > 0 
                    ? AppColors.primaryContainer 
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: _remainingSpins > 0 
                      ? AppColors.primary.withOpacity(0.3) 
                      : AppColors.divider,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _remainingSpins > 0 ? Icons.casino_rounded : Icons.lock_rounded,
                    color: _remainingSpins > 0 ? AppColors.primary : AppColors.textTertiary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: _remainingSpins > 0 ? AppColors.primary : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            
            // Spin Wheel
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
            
            const SizedBox(height: AppSpacing.xl),
            
            // Spin Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_spinning || _redeeming || _remainingSpins <= 0) ? null : _spin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _remainingSpins > 0 ? AppColors.gold : AppColors.surfaceVariant,
                  foregroundColor: _remainingSpins > 0 ? Colors.white : AppColors.textTertiary,
                  disabledBackgroundColor: AppColors.surfaceVariant,
                  disabledForegroundColor: AppColors.textTertiary,
                  elevation: _remainingSpins > 0 ? 4 : 0,
                  shadowColor: AppColors.gold.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
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
          ],
        ),
      ),
    );
  }

  Widget _buildWheel() {
    return Container(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Wheel segments
          CustomPaint(
            size: const Size(280, 280),
            painter: _WheelPainter(segments: _segments),
          ),
          // Center circle
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              boxShadow: AppShadows.card,
              border: Border.all(color: AppColors.divider, width: 2),
            ),
            child: Icon(
              Icons.casino_rounded,
              size: 36,
              color: AppColors.gold,
            ),
          ),
          // Top pointer (fixed)
          Positioned(
            top: -12,
            child: CustomPaint(
              size: const Size(32, 12),
              painter: _TrianglePainter(color: AppColors.primary),
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
        Text('Possible Rewards', style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: _segments.map((coins) {
            final is10 = coins == 10;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: is10 ? AppColors.goldContainer : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(
                  color: is10 ? AppColors.gold.withOpacity(0.3) : AppColors.divider,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.monetization_on_rounded,
                    size: 18,
                    color: is10 ? AppColors.gold : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$coins coins',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: is10 ? AppColors.gold : AppColors.textPrimary,
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.divider),
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
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Text('How It Works', style: AppTextStyles.titleMedium),
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
            child: Text(text, style: AppTextStyles.bodyMedium),
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
    
    final colors = [
      AppColors.gold,      // 10 coins - best
      AppColors.primary,   // 2 coins
      AppColors.success,   // 3 coins
    ];
    
    for (int i = 0; i < segments.length; i++) {
      final startAngle = i * segmentAngle - math.pi / 2;
      
      // Segment background
      final paint = Paint()
        ..color = colors[i]
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