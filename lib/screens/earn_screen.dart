import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../services/app_repository.dart';
import '../services/offerwall_service.dart';
import '../services/paymentwall_service.dart';
import '../widgets/cv_header.dart';
import 'offerwall_screen.dart';
import 'paymentwall_screen.dart';
import 'surveys_screen.dart';
import 'task_detail_screen.dart';
import 'tracking_screen.dart';

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
    });
    final results = await Future.wait<dynamic>([
      AppRepository.instance.fetchSurveys(),
      AppRepository.instance.fetchOffers(),
      AppRepository.instance.fetchActivity(),
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
      _offerwallOffers = (results[3] as List<OfferwallOffer>?) ?? [];
      _paymentwallOffers = (results[4] as List<PaymentwallOffer>?) ?? [];
      _offerwallFailed = results[3] == null;
      _paymentwallFailed = results[4] == null;
      _loading = false;
    });
  }

  void _push(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  String _title(Map m) => (m['title'] ?? m['name'] ?? '').toString().trim();
  String _description(Map m) => (m['shortDesc'] ?? m['description'] ?? m['provider'] ?? '').toString().trim();
  String _id(Map m) => (m['id'] ?? m['offerId'] ?? m['providerOfferId'] ?? '')
      .toString()
      .trim();
  @override
  Widget build(BuildContext context) {
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
                  CvHeader(showBack: Navigator.of(context).canPop()),
                  Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Explore activities', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    const SizedBox(height: 3),
                    const Text('Tasks, surveys and offers currently available', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    if (!_loading) _summary(),
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
  }

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

  Widget _categoryTabs() => SizedBox(
    height: 48,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _categories.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (_, i) {
        final category = _categories[i];
        return ChoiceChip(
          label: Text(category),
          selected: _category == category,
          showCheckmark: false,
          onSelected: (_) => setState(() => _category = category),
          selectedColor: AppColors.primary,
          backgroundColor: AppColors.surface,
          side: BorderSide(color: _category == category ? AppColors.primary : AppColors.border),
          labelStyle: TextStyle(
            color: _category == category ? Colors.white : AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        );
      },
    ),
  );

  Widget _heading(String title, VoidCallback? onTap) => Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 10), child: Row(children: [Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)), const Spacer(), if (onTap != null) TextButton(onPressed: onTap, child: const Text('View all'))]));

  Widget _surveyList() {
    if (_surveysFailed) return _empty('Surveys could not be loaded.', retry: true);
    final list = _surveys.whereType<Map>().where((m) => _title(m).isNotEmpty).take(10).toList();
    if (list.isEmpty) return _empty('No surveys available right now');
    return Column(children: list.map((m) {
      return _item(title: _title(m), description: _description(m), icon: Icons.poll_rounded, action: () => _push(const SurveysScreen()));
    }).toList());
  }

  Widget _offerList() {
    if (_offersFailed) return _empty('Offers could not be loaded.', retry: true);
    final list = _offers
        .whereType<Map>()
        .where((m) => _title(m).isNotEmpty && _id(m).isNotEmpty)
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
    if (_offerwallFailed) return _empty('Offerwall offers could not be fetched.', retry: true);
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
    if (_paymentwallFailed) return _empty('Paymentwall offers could not be fetched.', retry: true);
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

  Widget _item({required String title, required String description,
      required IconData icon, required VoidCallback action}) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
    child: Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: action,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(children: [
            Container(width: 42, height: 42,
              decoration: BoxDecoration(color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(11)),
              child: Icon(icon, color: AppColors.primary)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(description, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ])),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
          ]),
        ),
      ),
    ),
  );

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
