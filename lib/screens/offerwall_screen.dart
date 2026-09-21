import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/provider_logos.dart';
import '../widgets/app_logo.dart';
import '../services/offerwall_service.dart';
import '../widgets/state_views.dart';
import '../widgets/cv_header.dart';
import 'offer_detail_screen.dart';

/// Offerwall.GG offers screen — light/white premium design.
/// Header (title + subtitle + bell + avatar) → filter chips →
/// "Available Offers" section → vertical offer cards
/// (provider logo, title, provider name, short requirement, reward, time, Start button).
/// Data from GET /api/offers/offerwall-gg (authenticated); start via startOffer().
class OfferwallScreen extends StatefulWidget {
  const OfferwallScreen({super.key});

  @override
  State<OfferwallScreen> createState() => _OfferwallScreenState();
}

class _OfferwallScreenState extends State<OfferwallScreen> {
  String _filter = 'All Providers';
  List<OfferwallOffer> _offers = [];
  bool _loading = true;
  bool _failed = false;

  static const Color _bg = Color(0xFFFAFAF8);
  static const Color _card = Color(0xFFFFFFFF);
  static const Color _border = Color(0xFFE7E7E7);
  static const Color _primaryText = Color(0xFF171717);
  static const Color _secondaryText = Color(0xFF6B7280);
  static const Color _orange = Color(0xFFF59E0B);

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
    final data = await OfferwallService.instance.fetchOffers();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (data == null) {
        _failed = true;
      } else {
        _offers = data;
      }
    });
  }

  /// Providers available in the fetched data (dynamic, never hardcoded).
  List<String> get _providers => _offers
      .map((o) => o.provider)
      .where((p) => p.isNotEmpty)
      .toSet()
      .toList();

  /// Filter by the ACTUAL provider identifier field, not visual hiding.
  List<OfferwallOffer> get _filtered {
    var list = _offers;
    if (_filter == 'Offerwall.GG') {
      list = list.where((o) {
        final p = o.provider.toLowerCase();
        return p == 'offerwall_gg' ||
            p == 'offerwall.gg' ||
            p == 'offerwallgg';
      }).toList();
    } else if (_filter != 'All Providers' && _providers.contains(_filter)) {
      list = list.where((o) => o.provider == _filter).toList();
    }
    return list;
  }

  Future<void> _startOffer(OfferwallOffer offer) async {
    final clickUrl = await OfferwallService.instance.startOffer(offer.id);
    if (!mounted) return;
    if (clickUrl != null && clickUrl.isNotEmpty) {
      // Validate URL is HTTPS before opening
      final uri = Uri.tryParse(clickUrl);
      if (uri != null && uri.scheme == 'https') {
        // Open in external browser — preserves Offerwall.GG tracking chain
        // CoinVault → Offerwall.GG → Advertiser
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not open offer link')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to open this offer right now.')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open this offer right now.')),
        );
      }
    }
  }

  void _openDetail(OfferwallOffer offer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OfferDetailScreen(
          offerId: offer.id,
          provider: offer.provider,
          title: offer.title,
          coins: offer.coinReward,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: _orange,
          backgroundColor: _card,
          onRefresh: _load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: CvHeader()),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(child: _filterChips()),
              const SliverToBoxAdapter(child: SizedBox(height: 6)),
              SliverToBoxAdapter(child: _sectionTitle()),
              if (_loading)
                const SliverToBoxAdapter(
                    child: ShimmerCardList(
                        rows: 4, padding: EdgeInsets.fromLTRB(16, 12, 16, 0)))
              else if (_failed)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorState(
                    message:
                        'Check your internet connection and try again.',
                    onRetry: _load,
                  ),
                )
              else if (list.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.local_offer_outlined,
                    title: 'No offers available',
                    subtitle: _filter != 'All Providers'
                        ? 'For $_filter right now.'
                        : 'New offers are added regularly — check back soon.',
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _offerCard(list[i]),
                    childCount: list.length,
                    addAutomaticKeepAlives: false,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────── FILTERS ───────────────────────────
  Widget _filterChips() {
    final chips = <String>[
      'All Providers',
      'Offerwall.GG',
      ..._providers.where((p) =>
          p.toLowerCase() != 'offerwall_gg' &&
          p.toLowerCase() != 'offerwall.gg' &&
          p.toLowerCase() != 'offerwallgg'),
    ];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = chips[i];
          final active = _filter == c;
          return GestureDetector(
            onTap: () => setState(() => _filter = c),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? _orange : _card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: active ? _orange : _border, width: 1),
              ),
              child: Text(c,
                  style: TextStyle(
                    color: active ? Colors.white : _primaryText,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  )),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────── SECTION TITLE ───────────────────────────
  Widget _sectionTitle() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Available Offers',
              style: TextStyle(
                  color: _primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
          SizedBox(height: 2),
          Text('Complete offers to earn coins',
              style: TextStyle(color: _secondaryText, fontSize: 12)),
        ],
      ),
    );
  }

  // ─────────────────────────── OFFER CARD ───────────────────────────
  Widget _offerCard(OfferwallOffer offer) {
    final title = offer.title.isEmpty ? 'Offer' : offer.title;
    final coins = offer.coinReward;
    final provider = offer.provider.isEmpty ? 'Offerwall.GG' : offer.provider;
    final shortReq = offer.shortRequirement ?? '';
    final estimatedTime = offer.estimatedTime ?? '';
    final color = ProviderLogos.colorFor(provider);
    final inr = (coins / 10).toStringAsFixed(0);

    return GestureDetector(
      onTap: () => _openDetail(offer),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, top: 4),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
          boxShadow: const [
            BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: provider logo + name + reward
              Row(
                children: [
                  AppLogo(
                    provider: provider,
                    title: title,
                    size: 40,
                    fallbackIcon: Icons.local_offer_rounded,
                    fallbackColor: color,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      provider,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _primaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('+${_fmt(coins)} Coins',
                          style: const TextStyle(
                              color: Color(0xFF5A3825),
                              fontSize: 14,
                              fontWeight: FontWeight.w800)),
                      Text('≈ ₹$inr',
                          style: const TextStyle(
                              color: _secondaryText,
                              fontSize: 10)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Title
              Text(title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: _primaryText,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      height: 1.25)),
              const SizedBox(height: 7),
              // Short requirement
              if (shortReq.isNotEmpty)
                Text(shortReq,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: _secondaryText, fontSize: 12, height: 1.3)),
              const SizedBox(height: 7),
              // Meta row
              Row(
                children: [
                  if (estimatedTime.isNotEmpty) ...[
                    const Icon(Icons.access_time_rounded,
                        color: _secondaryText, size: 14),
                    const SizedBox(width: 4),
                    Text(estimatedTime,
                        style: const TextStyle(
                            color: _secondaryText, fontSize: 12)),
                  ],
                  const Spacer(),
                  // Start Offer button
                  SizedBox(
                    height: 34,
                    child: ElevatedButton(
                      onPressed: () => _startOffer(offer),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                      ),
                      child: const Text('Start Offer',
                          style: TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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