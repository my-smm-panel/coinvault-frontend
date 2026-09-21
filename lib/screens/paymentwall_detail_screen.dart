import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/provider_logos.dart';
import '../widgets/app_logo.dart';
import '../services/paymentwall_service.dart';
import '../widgets/state_views.dart';

/// Full Paymentwall offer detail page — opened from PaymentwallScreen.
/// Shows big header (provider brand), coins banner, requirements,
/// multi-step goals (numbered list), rules, and a Start button
/// that opens the clickUrl in the external browser.
class PaymentwallDetailScreen extends StatefulWidget {
  final String offerId;
  final String provider;
  final String title;
  final int coins;

  const PaymentwallDetailScreen({
    super.key,
    required this.offerId,
    required this.provider,
    required this.title,
    required this.coins,
  });

  @override
  State<PaymentwallDetailScreen> createState() => _PaymentwallDetailScreenState();
}

class _PaymentwallDetailScreenState extends State<PaymentwallDetailScreen> {
  PaymentwallOffer? _detail;
  bool _loading = true;
  bool _failed = false;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    final data = await PaymentwallService.instance.fetchOfferDetail(widget.offerId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (data == null) {
        _failed = true;
      } else {
        _detail = data;
      }
    });
  }

  Future<void> _startOffer() async {
    if (_started) return;
    setState(() => _started = true);
    final clickUrl = await PaymentwallService.instance.startOffer(widget.offerId);
    if (!mounted) return;
    if (clickUrl != null && clickUrl.isNotEmpty) {
      final uri = Uri.tryParse(clickUrl);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open offer link')),
          );
          setState(() => _started = false);
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not start offer. Please try again.')),
        );
        setState(() => _started = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = ProviderLogos.colorFor(widget.provider);
    final minutes = (widget.coins ~/ 20).clamp(1, 60);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF8),
      body: SafeArea(
        child: Column(
          children: [
            // ===== Header =====
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.85)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(20)),
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
                    child: AppLogo(
                      provider: widget.provider,
                      title: widget.title,
                      size: 44,
                      radius: 10,
                      fallbackIcon: Icons.local_offer_rounded,
                      fallbackColor: color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.provider.isEmpty ? 'Paymentwall' : widget.provider,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text('Official offer partner',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ===== Content =====
            Expanded(
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: ShimmerCardList(rows: 4, padding: EdgeInsets.zero),
                    )
                  : _failed
                      ? ErrorState(
                          message: 'Unable to load offer details',
                          onRetry: _load,
                        )
                      : _content(color, minutes),
            ),

            // ===== Bottom CTA =====
            if (!_loading && !_failed)
              Container(
                padding: EdgeInsets.fromLTRB(
                    16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAF8),
                  border: Border(
                      top: BorderSide(
                          color: const Color(0xFF171717).withOpacity(0.06))),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _started ? null : _startOffer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _started ? const Color(0xFFE8F0FF) : color,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFE8F0FF),
                      disabledForegroundColor: const Color(0xFF6B7280),
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
                          color: _started
                              ? const Color(0xFF6B7280)
                              : Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _started ? 'Opening…' : 'Start Offer',
                          style: TextStyle(
                            color: _started
                                ? const Color(0xFF6B7280)
                                : Colors.white,
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

  Widget _content(Color color, int minutes) {
    final d = _detail!;
    final requirements = d.requirements;
    final goals = d.goals;
    final rules = d.rules;
    final isVariable = d.isVariable;
    final description = d.description ?? '';
    // Use coinReward from backend detail (may have more accurate value)
    final reward = d.coinReward > 0 ? d.coinReward : widget.coins;
    final inr = (reward / 10).toStringAsFixed(0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== Reward banner =====
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withOpacity(0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on_rounded,
                    color: Color(0xFF5A3825), size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '+${_fmt(reward)} coins',
                        style: const TextStyle(
                          color: Color(0xFF5A3825),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '≈ ₹$inr',
                        style: TextStyle(
                            color: const Color(0xFF5A3825).withOpacity(0.8),
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
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
                        style: const TextStyle(
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

          // ===== Title + description =====
          Text(
            widget.title,
            style: const TextStyle(
                color: Color(0xFF171717),
                fontSize: 19,
                fontWeight: FontWeight.w800),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              description,
              style: const TextStyle(
                  color: Color(0xFF6B7280), fontSize: 13, height: 1.5),
            ),
          ],

          // ===== Variable/Fixed status =====
          if (isVariable) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.35)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.trending_up_rounded, color: Color(0xFFF59E0B), size: 14),
                  SizedBox(width: 4),
                  Text('Variable reward',
                      style: TextStyle(
                          color: Color(0xFFF59E0B),
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // ===== Requirements =====
          if (requirements.isNotEmpty) ...[
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
                      Icon(Icons.checklist_rounded, color: color, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Requirements',
                        style: TextStyle(
                            color: Color(0xFF171717),
                            fontSize: 15,
                            fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ...requirements.asMap().entries.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: color.withOpacity(0.5)),
                                ),
                                child: Center(
                                  child: Text(
                                    '${e.key + 1}',
                                    style: TextStyle(
                                        color: color,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    e.value,
                                    style: const TextStyle(
                                        color: Color(0xFF171717),
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
          ],

          // ===== Goals (multi-step) =====
          if (goals.isNotEmpty) ...[
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
                      Icon(Icons.flag_rounded, color: color, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Goals',
                        style: TextStyle(
                            color: Color(0xFF171717),
                            fontSize: 15,
                            fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ...goals.asMap().entries.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: color.withOpacity(0.5)),
                                ),
                                child: Center(
                                  child: Text(
                                    '${e.key + 1}',
                                    style: TextStyle(
                                        color: color,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    e.value,
                                    style: const TextStyle(
                                        color: Color(0xFF171717),
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
          ],

          // ===== Rules =====
          if (rules.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFF171717).withOpacity(0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rules',
                    style: TextStyle(
                        color: Color(0xFF171717),
                        fontSize: 14,
                        fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  ...rules.map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 14, color: Color(0xFF6B7280)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              r,
                              style: const TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 12,
                                  height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Fallback rules if none from API
          if (rules.isEmpty && requirements.isEmpty && goals.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFF171717).withOpacity(0.06)),
              ),
              child: Column(
                children: [
                  _rule('Coins credit after verification'),
                  _rule('One attempt per user per offer'),
                  _rule('Use real details — fake info = no payout'),
                  _rule('Keep the app installed until verified'),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _rule(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 14, color: Color(0xFF6B7280)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  color: Color(0xFF6B7280), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(int n) {
    final str = n.abs().toString();
    final sb = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) sb.write(',');
      sb.write(str[i]);
    }
    return n.isNegative ? '-$sb' : sb.toString();
  }
}