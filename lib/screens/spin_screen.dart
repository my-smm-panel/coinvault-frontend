import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_theme.dart';
import '../services/api_client.dart';
import '../services/app_repository.dart';
import '../services/balance_stream.dart';
import '../screens/earn_screen.dart';
import 'history_screen.dart';

/// Spin and Win. Availability, reward, and wallet balance are server-owned.
class SpinScreen extends StatefulWidget {
  const SpinScreen({super.key});

  @override
  State<SpinScreen> createState() => _SpinScreenState();
}

class _SpinScreenState extends State<SpinScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _rotationAnim;
  static const int _segmentCount = 8;
  bool _spinning = false;
  bool _redeeming = false;
  int? _remainingSpins;
  int? _lastReward;
  int? _totalWon;
  List<dynamic> _recentWins = [];
  bool _historyFailed = false;
  String _statusMessage = 'Checking spin availability…';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 2800), vsync: this);
    _rotationAnim = const AlwaysStoppedAnimation<double>(0);
    _controller.addStatusListener(_onAnimationStatus);
    _loadSpins();
  }

  Future<void> _loadSpins() async {
    final status = await AppRepository.instance.spinStatus();
    if (!mounted) return;
    int? left;
    if (status != null && status['dailyLimit'] is num && status['spinsUsed'] is num) {
      final limit = (status['dailyLimit'] as num).toInt();
      final used = (status['spinsUsed'] as num).toInt();
      left = (limit - used).clamp(0, limit).toInt();
    }
    setState(() {
      _remainingSpins = left;
      _statusMessage = left == null
          ? 'Spin availability is unavailable'
          : left > 0
              ? '$left spin${left == 1 ? '' : 's'} available'
              : 'No spins available';
    });
    try {
      final h = await AppRepository.instance.spinHistoryList();
      if (!mounted) return;
      int total = 0;
      bool hasReward = false;
      for (final e in h ?? const <dynamic>[]) {
        final raw = e is Map ? e['reward'] ?? e['coins'] : null;
        if (raw is num) {
          total += raw.toInt();
          hasReward = true;
        }
      }
      setState(() {
        _historyFailed = h == null;
        _totalWon = hasReward ? total : null;
        _recentWins = h?.take(3).toList() ?? [];
      });
    } catch (_) {}
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() {
        _spinning = false;
        _redeeming = true;
      });
      _redeemServerSpin();
    }
  }

  Future<void> _redeemServerSpin() async {
    try {
      final data = await AppRepository.instance.spinNow();
      if (!mounted) return;
      final rawReward = data['coins'] ?? data['reward'];
      setState(() {
        _lastReward = rawReward is num ? rawReward.toInt() : null;
        _redeeming = false;
        _remainingSpins = data['dailyLimit'] is num && data['spinsUsed'] is num
            ? ((data['dailyLimit'] as num).toInt() - (data['spinsUsed'] as num).toInt()).clamp(0, (data['dailyLimit'] as num).toInt()).toInt()
            : _remainingSpins;
        _statusMessage = _remainingSpins == null
            ? 'Spin result received'
            : _remainingSpins! > 0
                ? '${_remainingSpins!} spin${_remainingSpins == 1 ? '' : 's'} available'
                : 'No spins available';
      });
      await _loadSpins();
      if (mounted) _showResultDialog();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _redeeming = false;
        _statusMessage = e.message;
      });
      await _loadSpins();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) {
        setState(() {
          _redeeming = false;
          _statusMessage = 'Spin failed. Check your connection and try again.';
        });
      }
    }
  }

  void _spin() {
    if (_spinning || _redeeming || _remainingSpins == null || _remainingSpins! <= 0) return;
    setState(() {
      _spinning = true;
      _statusMessage = 'Spinning…';
    });
    final segmentAngle = 2 * math.pi / _segmentCount;
    final randomSegment = math.Random().nextInt(_segmentCount);
    final fullRotations = 5 + math.Random().nextInt(4);
    _rotationAnim = Tween<double>(
      begin: _controller.value,
      end: fullRotations * 2 * math.pi + randomSegment * segmentAngle + segmentAngle / 2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.decelerate));
    _controller.forward(from: 0);
  }

  void _showResultDialog() {
    final reward = _lastReward;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(reward == null ? 'Spin complete' : 'Spin result'),
        content: Text(reward == null
            ? 'The server did not return a reward amount.'
            : 'Server reward: $reward coins'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done'))],
      ),
    ).then((_) => _loadSpins());
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
    return ListenableBuilder(
      listenable: BalanceStream.instance,
      builder: (context, _) {
        final balance = BalanceStream.instance.value;
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(children: [
              _header(balance),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xxl),
                  child: Column(children: [
                    _availabilityCard(),
                    const SizedBox(height: AppSpacing.lg),
                    _wheelArea(wheelSize),
                    const SizedBox(height: AppSpacing.lg),
                    Text(_statusMessage, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: AppSpacing.lg),
                    _buildHowItWorks(),
                    const SizedBox(height: AppSpacing.lg),
                    _recentWins(),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EarnScreen())), icon: const Icon(Icons.task_alt_rounded), label: const Text('Earn from available activities'))),
                  ]),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _header(int? balance) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.md, 0),
      child: Row(children: [
        IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20), onPressed: () => Navigator.of(context).maybePop()),
        Text('Spin the Wheel', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 19, fontWeight: FontWeight.w700)),
        const Spacer(),
        if (balance != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(color: AppColors.goldContainer, borderRadius: BorderRadius.circular(AppRadius.full), border: Border.all(color: AppColors.gold.withOpacity(0.35))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.monetization_on_rounded, color: AppColors.gold, size: 18), const SizedBox(width: 6), Text('$balance', style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w800))]),
          ),
      ]),
    );
  }

  Widget _availabilityCard() {
    final left = _remainingSpins;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.border), boxShadow: AppShadows.card),
      child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(AppRadius.md)), child: const Icon(Icons.casino_rounded, color: AppColors.primary, size: 24)),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Spin availability', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(left == null ? 'Checking with server…' : '$left available', style: TextStyle(color: left == null ? AppColors.textSecondary : AppColors.primary, fontSize: 13, fontWeight: FontWeight.w700)),
        ])),
      ]),
    );
  }

  Widget _wheelArea(double wheelSize) {
    final busy = _spinning || _redeeming;
    final canSpin = _remainingSpins != null && _remainingSpins! > 0 && !busy;
    return SizedBox(
      height: wheelSize * 1.18,
      width: wheelSize * 1.2,
      child: Stack(alignment: Alignment.topCenter, children: [
        Positioned.fill(child: Align(alignment: Alignment.bottomCenter, child: Container(width: wheelSize, height: wheelSize, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withOpacity(0.06))))),
        Container(margin: const EdgeInsets.only(top: 14), padding: EdgeInsets.all(wheelSize * 0.045), child: AnimatedBuilder(animation: _controller, builder: (context, child) => Transform.rotate(angle: _rotationAnim.value, child: child), child: _wheel(wheelSize))),
        Positioned(top: 14 + wheelSize * 0.045 + wheelSize / 2 - 38, left: 0, right: 0, child: Align(child: GestureDetector(onTap: canSpin ? _spin : null, child: Container(width: 76, height: 76, decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle, border: Border.all(color: canSpin ? AppColors.primary : AppColors.border, width: 3), boxShadow: [BoxShadow(color: canSpin ? AppColors.primary.withOpacity(0.35) : Colors.black.withOpacity(0.1), blurRadius: 18, spreadRadius: 2)]), child: busy ? const Padding(padding: EdgeInsets.all(22), child: CircularProgressIndicator(strokeWidth: 2.6, color: AppColors.primary)) : Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(canSpin ? Icons.casino_rounded : Icons.lock_rounded, color: canSpin ? AppColors.primary : AppColors.textTertiary, size: 20), const SizedBox(height: 1), Text('SPIN', style: TextStyle(color: canSpin ? AppColors.textPrimary : AppColors.textTertiary, fontSize: 13, fontWeight: FontWeight.w900))]))))),
        const CustomPaint(size: Size(34, 30), painter: _PointerPainter(color: AppColors.textPrimary)),
      ]),
    );
  }

  Widget _wheel(double outer) {
    final disc = outer - 22;
    final bulbs = List.generate(12, (i) {
      final a = (i * 2 * math.pi / 12) - math.pi / 2;
      final r = disc / 2 + 9;
      return Offset(outer / 2 + r * math.cos(a), outer / 2 + r * math.sin(a));
    });
    return SizedBox(width: outer, height: outer, child: Stack(alignment: Alignment.center, children: [
      ...bulbs.map((o) => Positioned(left: o.dx - 5, top: o.dy - 5, child: Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.8), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 3)])))),
      Container(width: disc, height: disc, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 6), boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.28), blurRadius: 30, spreadRadius: 3), BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 24, spreadRadius: 2, offset: const Offset(0, 8))]), child: CustomPaint(size: Size(disc, disc), painter: const _WheelPainter(segmentCount: _segmentCount))),
    ]));
  }

  Widget _buildHowItWorks() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.border)),
      child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20), SizedBox(width: 6), Text('How It Works', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700))]),
        SizedBox(height: 16),
        _HowStep(number: '1', text: 'Start a spin when the server reports availability.'),
        _HowStep(number: '2', text: 'The authenticated server determines the result.'),
        _HowStep(number: '3', text: 'The server response updates your wallet balance.'),
      ]),
    );
  }

  Widget _recentWins() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Icon(Icons.history_rounded, color: AppColors.gold, size: 20), const SizedBox(width: 6), const Text('Recent Spins', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)), if (_totalWon != null) ...[const SizedBox(width: 8), Text('$_totalWon coins recorded', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11))], const Spacer(), InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())), child: const Text('View all ›', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)))]),
      const SizedBox(height: AppSpacing.md),
      if (_recentWins.isEmpty)
        Container(width: double.infinity, padding: const EdgeInsets.all(AppSpacing.md), decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.border)), child: Text(_historyFailed ? 'Spin history could not be fetched.' : 'No spin history available', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)))
      else
        Container(decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.border)), child: Column(children: _recentWins.map((raw) {
          final m = raw is Map ? raw : <String, dynamic>{};
          final reward = m['reward'] ?? m['coins'];
          return ListTile(leading: const Icon(Icons.casino_rounded, color: AppColors.primary), title: Text(reward is num ? '${reward.toInt()} coins' : 'Result recorded', style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text((m['createdAt'] ?? m['created_at'] ?? '').toString(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)));
        }).toList())),
    ]);
  }
}

class _HowStep extends StatelessWidget {
  final String number;
  final String text;
  const _HowStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 24, height: 24, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle), child: Center(child: Text(number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)))), const SizedBox(width: AppSpacing.md), Expanded(child: Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5)))]));
}

class _WheelPainter extends CustomPainter {
  final int segmentCount;
  const _WheelPainter({required this.segmentCount});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final angle = 2 * math.pi / segmentCount;
    const colors = [Color(0xFF4D8AF0), Color(0xFF34B96E), Color(0xFFE53946), Color(0xFF8E5BFF), Color(0xFFFF8C42), Color(0xFFF5C518)];
    for (var i = 0; i < segmentCount; i++) {
      final path = Path()..moveTo(center.dx, center.dy)..arcTo(Rect.fromCircle(center: center, radius: radius), i * angle - math.pi / 2, angle, false)..close();
      canvas.drawPath(path, Paint()..color = colors[i % colors.length]);
      canvas.drawPath(path, Paint()..color = Colors.white.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) => false;
}

class _PointerPainter extends CustomPainter {
  final Color color;
  const _PointerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..moveTo(size.width / 2, size.height)..lineTo(size.width * 0.06, 0)..lineTo(size.width * 0.94, 0)..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(path, Paint()..color = Colors.white.withOpacity(0.6)..style = PaintingStyle.stroke..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(covariant _PointerPainter oldDelegate) => false;
}
