import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/provider_logos.dart';
import '../services/app_repository.dart';
import '../widgets/app_logo.dart';

/// Detail page for a server-provided offer. Optional content is rendered only
/// when it was supplied by the caller from the backend offer payload.
class OfferDetailScreen extends StatefulWidget {
  final String offerId;
  final String provider;
  final String title;
  final int? coins;
  final String? description;
  final String? duration;
  final List<String>? requirements;
  final List<String>? goals;
  final List<String>? rules;
  final bool? isVariable;

  const OfferDetailScreen({
    super.key,
    required this.offerId,
    required this.provider,
    required this.title,
    this.coins,
    this.description,
    this.duration,
    this.requirements,
    this.goals,
    this.rules,
    this.isVariable,
  });

  @override
  State<OfferDetailScreen> createState() => _OfferDetailScreenState();
}

class _OfferDetailScreenState extends State<OfferDetailScreen> {
  bool _started = false;
  bool _starting = false;

  bool get _hasOfferId => widget.offerId.trim().isNotEmpty;

  Future<void> _startOffer() async {
    if (!_hasOfferId || _started || _starting) return;
    setState(() => _starting = true);
    try {
      final result = await AppRepository.instance.startOffer(widget.offerId.trim());
      if (!mounted) return;
      setState(() {
        _starting = false;
        _started = true;
      });
      final rawUrl = (result['trackingUrl'] ??
              result['clickUrl'] ??
              result['externalUrl'] ??
              result['redirectUrl'] ??
              result['url'] ??
              '')
          .toString()
          .trim();
      final uri = Uri.tryParse(rawUrl);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offer started; no tracking link was provided')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _starting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not start this offer')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = ProviderLogos.colorFor(widget.provider);
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF8),
      body: SafeArea(
        child: Column(
          children: [
            _header(color),
            Expanded(child: _content(color)),
            _bottomCta(color),
          ],
        ),
      ),
    );
  }

  Widget _header(Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
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
                color: Colors.white, borderRadius: BorderRadius.circular(12)),
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
                Text(widget.provider,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (widget.provider.trim().isNotEmpty)
                  Text('Offer details',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.85), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(Color color) {
    final description = widget.description?.trim() ?? '';
    final requirements = widget.requirements ?? const <String>[];
    final goals = widget.goals ?? const <String>[];
    final rules = widget.rules ?? const <String>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title,
              style: const TextStyle(
                  color: Color(0xFF171717),
                  fontSize: 19,
                  fontWeight: FontWeight.w800)),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(description,
                style: const TextStyle(
                    color: Color(0xFF6B7280), fontSize: 13, height: 1.5)),
          ],
          if (widget.isVariable == true) ...[
            const SizedBox(height: 10),
            _statusChip('Variable reward', Icons.trending_up_rounded, color),
          ],
          if (requirements.isNotEmpty) ...[
            const SizedBox(height: 20),
            _numberedCard('Requirements', Icons.checklist_rounded,
                requirements, color),
          ],
          if (goals.isNotEmpty) ...[
            const SizedBox(height: 20),
            _numberedCard('Goals', Icons.flag_rounded, goals, color),
          ],
          if (rules.isNotEmpty) ...[
            const SizedBox(height: 20),
            _rulesCard(rules),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _statusChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(text,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _numberedCard(
      String heading, IconData icon, List<String> values, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.35))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(heading,
              style: const TextStyle(
                  color: Color(0xFF171717),
                  fontSize: 15,
                  fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 14),
        ...values.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withOpacity(0.5))),
                  child: Center(
                      child: Text('${e.key + 1}',
                          style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w800))),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(e.value,
                            style: const TextStyle(
                                color: Color(0xFF171717),
                                fontSize: 13,
                                height: 1.4)))),
              ]),
            )),
      ]),
    );
  }

  Widget _rulesCard(List<String> rules) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF171717).withOpacity(0.06))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Rules',
            style: TextStyle(
                color: Color(0xFF171717),
                fontSize: 14,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        ...rules.map((rule) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.info_outline_rounded,
                    size: 14, color: Color(0xFF6B7280)),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(rule,
                        style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                            height: 1.4))),
              ]),
            )),
      ]),
    );
  }

  Widget _bottomCta(Color color) {
    final enabled = _hasOfferId && !_started && !_starting;
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
          color: const Color(0xFFFAFAF8),
          border: Border(
              top: BorderSide(
                  color: const Color(0xFF171717).withOpacity(0.06)))),
      child: Column(children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: enabled ? _startOffer : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: enabled ? color : const Color(0xFFE8F0FF),
              foregroundColor: enabled ? Colors.white : const Color(0xFF6B7280),
              disabledBackgroundColor: const Color(0xFFE8F0FF),
              disabledForegroundColor: const Color(0xFF6B7280),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26)),
            ),
            child: Text(
              _started
                  ? 'Started'
                  : _starting
                      ? 'Starting…'
                      : _hasOfferId
                          ? 'Start Offer'
                          : 'Start unavailable',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ),
        ),
        if (!_hasOfferId)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('This offer has no valid backend offer ID.',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
          ),
      ]),
    );
  }

}
