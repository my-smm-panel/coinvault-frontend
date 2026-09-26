import 'api_client.dart';

/// Parsed offer from Paymentwall with coinReward as the primary reward field.
class PaymentwallOffer {
  final String id;
  final String title;
  final String provider;
  final int? coinReward;
  final String? shortRequirement;
  final String? estimatedTime;
  final String? description;
  final String? clickUrl;
  final List<String> goals;
  final List<String> requirements;
  final List<String> rules;
  final bool isVariable;

  PaymentwallOffer({
    required this.id,
    required this.title,
    required this.provider,
    this.coinReward,
    this.shortRequirement,
    this.estimatedTime,
    this.description,
    this.clickUrl,
    this.goals = const [],
    this.requirements = const [],
    this.rules = const [],
    this.isVariable = false,
  });

  factory PaymentwallOffer.fromApi(Map<String, dynamic> m) {
    return PaymentwallOffer(
      id: (m['id'] ?? m['providerOfferId'] ?? '').toString(),
      title: (m['title'] ?? m['name'] ?? '').toString().trim(),
      provider: (m['provider'] ?? m['providerName'] ?? 'Paymentwall').toString(),
      coinReward: _readReward(m['coinReward'] ?? m['coins'] ?? m['reward']),
      shortRequirement: (m['shortRequirement'] ?? m['shortDesc'] ?? m['description'])?.toString(),
      estimatedTime: (m['estimatedTime'] ?? m['duration'])?.toString(),
      description: (m['description'] ?? m['desc'])?.toString(),
      clickUrl: (m['clickUrl'] ?? m['url'])?.toString(),
      goals: _parseList(m['goals'] ?? m['goal'] ?? m['milestones']),
      requirements: _parseList(m['requirements'] ?? m['requirement']),
      rules: _parseList(m['rules'] ?? m['rule']),
      isVariable: m['isVariable'] == true || m['variable'] == true,
    );
  }

  static int? _readReward(dynamic value) => value is num && value >= 0 ? value.toInt() : null;

  static List<String> _parseList(dynamic data) {
    if (data is List) return data.map((e) => e.toString()).toList();
    if (data is String && data.isNotEmpty) {
      return data.split('\n').where((s) => s.trim().isNotEmpty).toList();
    }
    return [];
  }

  /// Convert to plain map for widgets that expect Map<String, dynamic>.
  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'provider': provider,
        'coinReward': coinReward,
        'shortRequirement': shortRequirement,
        'estimatedTime': estimatedTime,
        'description': description,
        'clickUrl': clickUrl,
        'goals': goals,
        'requirements': requirements,
        'rules': rules,
        'isVariable': isVariable,
      };
}

/// API client for Paymentwall offers.
/// Wraps the backend endpoints and never throws to the UI — all errors
/// return null so the screen can show a proper error/empty state.
class PaymentwallService {
  PaymentwallService._();
  static final PaymentwallService instance = PaymentwallService._();

  final ApiClient _api = ApiClient.instance;

  /// Paymentwall offers are read from the backend's verified public catalogue
  /// and filtered by provider. The app does not call an unimplemented
  /// /api/paymentwall route or invent offers locally.
  Future<List<PaymentwallOffer>?> fetchOffers() async {
    try {
      final res = await _api.get('/api/offers', auth: false);
      if (res is! Map || res['success'] != true) return null;
      final data = res['data'];
      final dynamic rawItems = data is Map ? data['items'] : data;
      if (rawItems is! List) return null;
      return rawItems.whereType<Map>().where((m) {
        final provider = (m['provider'] ?? m['providerName'] ?? '').toString().toLowerCase();
        final id = (m['id'] ?? m['providerOfferId'] ?? '').toString().trim();
        final title = (m['title'] ?? m['name'] ?? '').toString().trim();
        final isPaymentwall = provider == 'paymentwall' ||
            provider == 'payment_wall' ||
            provider == 'payment wall';
        return isPaymentwall && id.isNotEmpty && title.isNotEmpty;
      }).map((m) => PaymentwallOffer.fromApi(Map<String, dynamic>.from(m))).toList();
    } catch (_) {
      return null;
    }
  }

  /// Starts a Paymentwall offer through the backend's generic offer route.
  Future<String?> startOffer(String offerId) async {
    try {
      final id = Uri.encodeComponent(offerId);
      final res = await _api.post('/api/offers/$id/start', {});
      if (res is Map && res['success'] == true) {
        final data = res['data'] as Map<String, dynamic>?;
        if (data != null) {
          return data['redirectUrl'] as String?;
        }
        // Fallback: check top-level redirectUrl
        return res['redirectUrl'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Resolves details only from an item returned by the backend catalogue.
  Future<PaymentwallOffer?> fetchOfferDetail(String id) async {
    final offers = await fetchOffers();
    if (offers == null) return null;
    for (final offer in offers) {
      if (offer.id == id) return offer;
    }
    return null;
  }
}