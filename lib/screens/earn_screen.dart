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
  int? _number(dynamic value) => value is num && value >= 0 ? value.toInt() : null;

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
                    const Padding(padding: EdgeInsets.all(36), child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
                  else if (_failed)
                    _empty('Activities could not be loaded. Pull to retry.')
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

  Widget _categoryTabs() => SizedBox(height: 38, child: ListView.separated(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: _categories.length, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (_, i) { final category = _categories[i]; final selected = _category == category; return GestureDetector(onTap: () => setState(() => _category = category), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16), alignment: Alignment.center, decoration: BoxDecoration(color: selected ? AppColors.primary : AppColors.cardBackground, borderRadius: BorderRadius.circular(20), border: Border.all(color: selected ? AppColors.primary : AppColors.border)), child: Text(category, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: selected ? Colors.white : AppColors.textSecondary)))); }));

  Widget _heading(String title, VoidCallback? onTap) => Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 10), child: Row(children: [Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)), const Spacer(), if (onTap != null) TextButton(onPressed: onTap, child: const Text('View all'))]));

  Widget _surveyList() {
    final list = _surveys.whereType<Map>().where((m) => _title(m).isNotEmpty).take(10).toList();
    if (list.isEmpty) return _empty('No surveys available right now');
    return Column(children: list.map((m) {
      final reward = _number(m['rewardCoins'] ?? m['coins']);
      return _item(title: _title(m), description: _description(m), reward: reward, icon: Icons.poll_rounded, action: () => _push(const SurveysScreen()));
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
        final desc = _description(m).isNotEmpty
            ? _description(m)
            : instructions is List
                ? instructions.where((e) => e != null).join(' • ')
                : '';
        final steps = instructions is List
            ? instructions
                .where((e) => e != null && e.toString().trim().isNotEmpty)
                .map((e) => e.toString())
                .toList()
            : null;
        return _item(
          title: _title(m),
          description: desc,
          reward: _number(m['coins'] ?? m['rewardCoins']),
          icon: Icons.local_offer_rounded,
          action: () => _push(TaskDetailScreen(
            provider: (m['provider'] ?? m['providerName'] ?? '').toString(),
            title: _title(m),
            desc: desc,
            coins: _number(m['coins'] ?? m['rewardCoins']),
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
        reward: offer.coinReward,
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
        reward: offer.coinReward,
        icon: Icons.local_offer_rounded,
        action: () => _push(const PaymentwallScreen()),
      )).toList(),
    );
  }

  Widget _item({required String title, required String description, required int? reward, required IconData icon, required VoidCallback action}) => Container(margin: const EdgeInsets.fromLTRB(16, 0, 16, 10), padding: const EdgeInsets.all(14), decoration: _cardDec(), child: Row(children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(11)), child: Icon(icon, color: AppColors.primary)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)), if (description.isNotEmpty) ...[const SizedBox(height: 4), Text(description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary))], if (reward != null) ...[const SizedBox(height: 5), Text('+${reward!} coins', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.primary))]])), IconButton(onPressed: action, icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.primary))]));

  Widget _empty(String text) => Container(margin: const EdgeInsets.symmetric(horizontal: 16), padding: const EdgeInsets.all(20), decoration: _cardDec(), child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)));
  BoxDecoration _cardDec() => BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.border), boxShadow: AppShadows.card);
}
