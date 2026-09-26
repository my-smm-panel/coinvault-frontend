import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../services/app_repository.dart';
import '../services/balance_stream.dart';
import '../services/offerwall_service.dart';
import '../services/paymentwall_service.dart';
import '../widgets/cv_header.dart';
import 'offerwall_screen.dart';
import 'paymentwall_screen.dart';
import 'surveys_screen.dart';
import 'task_detail_screen.dart';
import 'tracking_screen.dart';

class _SpotlightItem {
  final String title;
  final String description;
  final String kind;
  final IconData icon;
  final VoidCallback onTap;

  const _SpotlightItem({required this.title, required this.description,
    required this.kind, required this.icon, required this.onTap});
}

class _RotatingSpotlight extends StatefulWidget {
  final List<_SpotlightItem> items;
  const _RotatingSpotlight({required this.items});

  @override
  State<_RotatingSpotlight> createState() => _RotatingSpotlightState();
}

class _RotatingSpotlightState extends State<_RotatingSpotlight> {
  late final PageController _controller;
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: .92);
    _startRotation();
  }

  @override
  void didUpdateWidget(covariant _RotatingSpotlight oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) _startRotation();
  }

  void _startRotation() {
    _timer?.cancel();
    if (widget.items.length < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_controller.hasClients || widget.items.isEmpty) return;
      _index = (_index + 1) % widget.items.length;
      _controller.animateToPage(_index,
          duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(
        height: 148,
        child: PageView.builder(
          controller: _controller,
          itemCount: widget.items.length,
          onPageChanged: (index) => setState(() => _index = index),
          itemBuilder: (context, index) {
            final item = widget.items[index];
            return Padding(
              padding: const EdgeInsets.only(right: 9),
              child: InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFEAF7F1), Color(0xFFF8FCF9)]),
                    border: Border.all(color: AppColors.primary.withOpacity(.18)),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Row(children: [
                    Container(width: 44, height: 44,
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(.1), borderRadius: BorderRadius.circular(13)),
                      child: Icon(item.icon, color: AppColors.primary)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(item.kind.toUpperCase(), style: const TextStyle(fontSize: 9.5, letterSpacing: .7, fontWeight: FontWeight.w900, color: AppColors.primaryDark)),
                      const SizedBox(height: 4),
                      Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                      if (item.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11.5, height: 1.3, color: AppColors.textSecondary)),
                      ],
                      const SizedBox(height: 5),
                      const Text('Tap to explore  →', style: TextStyle(fontSize: 10.5, color: AppColors.primary, fontWeight: FontWeight.w800)),
                    ])),
                  ]),
                ),
              ),
            );
          },
        ),
      ),
      if (widget.items.length > 1) ...[
        const SizedBox(height: 7),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < widget.items.length; i++)
            AnimatedContainer(duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 2), width: i == _index ? 15 : 5, height: 5,
              decoration: BoxDecoration(color: i == _index ? AppColors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(4))),
        ]),
      ],
    ]);
  }
}

/// Earn tab. Every offer, reward, and status shown here comes from an API
/// response; no local reward policy or duration estimate is added.
class EarnScreen extends StatefulWidget {
  const EarnScreen({super.key});

  @override
  State<EarnScreen> createState() => _EarnScreenState();
}

class _EarnScreenState extends State<EarnScreen> {
  List<dynamic> _surveys = [];
  List<dynamic> _offers = [];
  List<dynamic> _activity = [];
  List<OfferwallOffer> _offerwallOffers = [];
  List<PaymentwallOffer> _paymentwallOffers = [];
  bool _activityFailed = false;
  bool _surveysFailed = false;
  bool _offersFailed = false;
  bool _offerwallFailed = false;
  bool _paymentwallFailed = false;
  bool _loading = true;
  bool _failed = false;
  String _category = 'All';

  static const _categories = [
    'All',
    'Surveys',
    'Offers',
    'Offerwall',
    'Paymentwall',
  ];

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
    final results = await Future.wait<dynamic>([
      AppRepository.instance.fetchSurveys(),
      AppRepository.instance.fetchOffers(),
      AppRepository.instance.fetchActivity(),
      AppRepository.instance.fetchWalletBalance(),
      OfferwallService.instance.fetchOffers(),
      PaymentwallService.instance.fetchOffers(),
    ]);
    if (!mounted) return;
    setState(() {
      _surveys = (results[0] as List<dynamic>?) ?? [];
      _offers = (results[1] as List<dynamic>?) ?? [];
      _activity = (results[2] as List<dynamic>?) ?? [];
      _activityFailed = results[2] == null;
      _surveysFailed = results[0] == null;
      _offersFailed = results[1] == null;
      _offerwallOffers = (results[4] as List<OfferwallOffer>?) ?? [];
      _paymentwallOffers = (results[5] as List<PaymentwallOffer>?) ?? [];
      _offerwallFailed = results[4] == null;
      _paymentwallFailed = results[5] == null;
      _failed = results[0] == null || results[1] == null;
      _loading = false;
    });
  }

  void _push(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  String _title(Map m) => (m['title'] ?? m['name'] ?? '').toString().trim();
  String _description(Map m) => (m['shortDesc'] ?? m['description'] ?? m['provider'] ?? '').toString().trim();
  String _id(Map m) => (m['id'] ?? m['offerId'] ?? m['providerOfferId'] ?? '')
      .toString()
      .trim();
  List<_SpotlightItem> _spotlightItems() {
    final items = <_SpotlightItem>[];
    for (final raw in _surveys.whereType<Map>().where((m) => _title(m).isNotEmpty).take(4)) {
      items.add(_SpotlightItem(
        title: _title(raw),
        description: _description(raw),
        kind: 'Survey',
        icon: Icons.poll_rounded,
        onTap: () => _push(const SurveysScreen()),
      ));
    }
    for (final raw in _offers.whereType<Map>().where((m) => _title(m).isNotEmpty && _id(m).isNotEmpty).take(4)) {
      final instructions = raw['instructions'];
      final steps = instructions is List ? instructions.map((e) => e.toString()).toList() : null;
      items.add(_SpotlightItem(
        title: _title(raw),
        description: _description(raw),
        kind: 'Task / Offer',
        icon: Icons.task_alt_rounded,
        onTap: () => _push(TaskDetailScreen(
          provider: (raw['provider'] ?? raw['providerName'] ?? '').toString(),
          title: _title(raw),
          desc: _description(raw),
          coins: null,
          steps: steps,
          offerId: _id(raw),
        )),
      ));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: BalanceStream.instance,
      builder: (context, _) {
        final balance = BalanceStream.instance.value;
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 28),
                children: [
                  const CvHeader(),
                  Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Earn Coins', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    const SizedBox(height: 3),
                    const Text('Choose an activity returned by the server', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 14),
                    _balance(balance),
                    const SizedBox(height: 14),
                    _summary(),
                    if (!_loading && _spotlightItems().isNotEmpty) ...[
                      const SizedBox(height: 14),
                      const Text('Featured activities', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      _RotatingSpotlight(items: _spotlightItems()),
                    ],
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _push(const TrackingScreen()),
                        icon: const Icon(Icons.history_rounded, size: 16),
                        label: const Text('View activity'),
                      ),
                    ),
                  ])),
                  const SizedBox(height: 16),
                  _categoryTabs(),
                  const SizedBox(height: 16),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 36),
                      child: Column(
                        children: [
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Loading activities…',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_failed)
                    _empty('Activities could not be loaded.', retry: true)
                  else ...[
                    if (_category == 'All' || _category == 'Surveys') ...[
                      _heading('Surveys', () => _push(const SurveysScreen())),
                      _surveyList(),
                      const SizedBox(height: 20),
                    ],
                    if (_category == 'All' || _category == 'Offers') ...[
                      _heading('Offers', null),
                      _offerList(),
                      const SizedBox(height: 20),
                    ],
                    if (_category == 'All' || _category == 'Offerwall') ...[
                      _heading(
                        'Offerwall.GG',
                        () => _push(const OfferwallScreen()),
                      ),
                      _offerwallList(),
                      const SizedBox(height: 20),
                    ],
                    if (_category == 'All' || _category == 'Paymentwall') ...[
                      _heading(
                        'Paymentwall',
                        () => _push(const PaymentwallScreen()),
                      ),
                      _paymentwallList(),
                    ],
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _balance(int? balance) => Container(margin: const EdgeInsets.symmetric(horizontal: 0), padding: const EdgeInsets.all(15), decoration: _cardDec(), child: Row(children: [const Icon(Icons.monetization_on_rounded, color: AppColors.primary, size: 25), const SizedBox(width: 9), const Text('Wallet balance', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)), const Spacer(), Text(balance == null ? '—' : '$balance coins', style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800))]));

  Widget _summary() {
    final completed = _activity
        .where((e) =>
            e is Map &&
            (e['status'] ?? '').toString().toUpperCase() == 'COMPLETED')
        .length;
    return Row(
      children: [
        Expanded(
          child: _stat('Surveys', _surveysFailed ? '—' : '${_surveys.length}'),
        ),
        Expanded(
          child: _stat('Offers', _offersFailed ? '—' : '${_offers.length}'),
        ),
        Expanded(
          child: _stat('Completed', _activityFailed ? '—' : '$completed'),
        ),
      ],
    );
  }

  Widget _stat(String label, String value) => Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(vertical: 11), decoration: _cardDec(), child: Column(children: [Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)), const SizedBox(height: 2), Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))]));

  Widget _categoryTabs() => SizedBox(height: 44, child: ListView.separated(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: _categories.length, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (_, i) { final category = _categories[i]; final selected = _category == category; return GestureDetector(onTap: () => setState(() => _category = category), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16), alignment: Alignment.center, decoration: BoxDecoration(color: selected ? AppColors.primary : AppColors.cardBackground, borderRadius: BorderRadius.circular(20), border: Border.all(color: selected ? AppColors.primary : AppColors.border)), child: Text(category, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: selected ? Colors.white : AppColors.textSecondary)))); }));

  Widget _heading(String title, VoidCallback? onTap) => Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 10), child: Row(children: [Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)), const Spacer(), if (onTap != null) TextButton(onPressed: onTap, child: const Text('View all'))]));

  Widget _surveyList() {
    final list = _surveys.whereType<Map>().where((m) => _title(m).isNotEmpty).take(10).toList();
    if (list.isEmpty) return _empty('No surveys available right now');
    return Column(children: list.map((m) {
      return _item(title: _title(m), description: _description(m), icon: Icons.poll_rounded, action: () => _push(const SurveysScreen()));
    }).toList());
  }

  Widget _offerList() {
    final list = _offers
        .whereType<Map>()
        .where((m) => _title(m).isNotEmpty && _id(m).isNotEmpty)
        .take(10)
        .toList();
    if (list.isEmpty) return _empty('No offers available right now');
    return Column(
      children: list.map((m) {
        final instructions = m['instructions'];
        // Keep list cards concise; the full server-provided instructions are
        // passed to the detail page below.
        final desc = _description(m);
        final steps = instructions is List
            ? instructions
                .where((e) => e != null && e.toString().trim().isNotEmpty)
                .map((e) => e.toString())
                .toList()
            : null;
        return _item(
          title: _title(m),
          description: desc,
          icon: Icons.local_offer_rounded,
          action: () => _push(TaskDetailScreen(
            provider: (m['provider'] ?? m['providerName'] ?? '').toString(),
            title: _title(m),
            desc: desc,
            coins: null,
            steps: steps,
            offerId: _id(m),
          )),
        );
      }).toList(),
    );
  }

  Widget _offerwallList() {
    if (_offerwallFailed) return _empty('Offerwall offers could not be fetched.');
    if (_offerwallOffers.isEmpty) return _empty('No Offerwall.GG offers available right now');
    return Column(
      children: _offerwallOffers.take(5).map((offer) => _item(
        title: offer.title,
        description: offer.shortRequirement ?? offer.description ?? '',
        icon: Icons.local_offer_rounded,
        action: () => _push(const OfferwallScreen()),
      )).toList(),
    );
  }

  Widget _paymentwallList() {
    if (_paymentwallFailed) return _empty('Paymentwall offers could not be fetched.');
    if (_paymentwallOffers.isEmpty) return _empty('No Paymentwall offers available right now');
    return Column(
      children: _paymentwallOffers.take(5).map((offer) => _item(
        title: offer.title,
        description: offer.shortRequirement ?? offer.description ?? '',
        icon: Icons.local_offer_rounded,
        action: () => _push(const PaymentwallScreen()),
      )).toList(),
    );
  }

  Widget _item({required String title, required String description, required IconData icon, required VoidCallback action}) => Container(margin: const EdgeInsets.fromLTRB(16, 0, 16, 10), padding: const EdgeInsets.all(14), decoration: _cardDec(), child: Row(children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(11)), child: Icon(icon, color: AppColors.primary)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)), if (description.isNotEmpty) ...[const SizedBox(height: 4), Text(description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary))]])), IconButton(onPressed: action, icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.primary))]));

  Widget _empty(String text, {bool retry = false}) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: _cardDec(),
        child: Column(
          children: [
            Icon(
              retry ? Icons.cloud_off_rounded : Icons.inbox_outlined,
              color: AppColors.textTertiary,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            if (retry) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      );
  BoxDecoration _cardDec() => BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.border), boxShadow: AppShadows.card);
}
