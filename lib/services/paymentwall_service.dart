import 'api_client.dart';

/// Parsed offer from Paymentwall with coinReward as the primary reward field.
class PaymentwallOffer {
  final String id;
  final String title;
  final String provider;
  final int coinReward;
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
    required this.coinReward,
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
      title: (m['title'] ?? m['name'] ?? 'Offer').toString(),
      provider: (m['provider'] ?? m['providerName'] ?? 'Paymentwall').toString(),
      coinReward: ((m['coinReward'] ?? m['coins'] ?? m['reward'] ?? 0) as num).toInt(),
      shortRequirement: (m['shortRequirement'] ?? m['shortDesc'] ?? m['description'])?.toString(),
      estimatedTime: (m['estimatedTime'] ?? m['duration'])?.toString(),
      description: (m['description'] ?? m['desc'])?.toString(),
      clickUrl: (m['clickUrl'] ?? m['url'])?.toString(),
      goals: _parseList(m['goals'] ?? m['goal'] ?? m['milestones']),
      requirements: _parseList(m['requirements'] ?? m['requirement']),
      rules: _parseList(m['rules'] ?? m['rule']),
      isVariable: (m['isVariable'] ?? m['variable'] ?? false) as bool,
    );
  }

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

  /// Fetch the Paymentwall offer list.
  /// Calls GET /api/paymentwall (authenticated).
  /// Returns parsed offers on success, null on network/server error.
  Future<List<PaymentwallOffer>?> fetchOffers() async {
    try {
      final res = await _api.get('/api/paymentwall');
      if (res is Map) {
        final data = res['data'];
        List<dynamic> items;
        if (data is Map) {
          items = (data['items'] ?? data['offers'] ?? []) as List? ?? [];
        } else if (data is List) {
          items = data;
        } else {
          items = (res['items'] ?? res['offers'] ?? []) as List? ?? [];
        }
        return items
            .whereType<Map>()
            .map((m) => PaymentwallOffer.fromApi(Map<String, dynamic>.from(m)))
            .toList();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Start an offer — gets the clickUrl for redirect.
  /// Calls POST /api/paymentwall/:id/start (authenticated).
  /// Returns the redirectUrl string on success, null on error.
  Future<String?> startOffer(String offerId) async {
    try {
      final res = await _api.post('/api/paymentwall/$offerId/start', {});
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

  /// Fetch full details for a single offer.
  /// Calls GET /api/paymentwall/:id (authenticated).
  /// Returns null on error.
  Future<PaymentwallOffer?> fetchOfferDetail(String id) async {
    try {
      final res = await _api.get('/api/paymentwall/$id');
      if (res is Map) {
        final data = res['data'];
        if (data is Map) {
          return PaymentwallOffer.fromApi(Map<String, dynamic>.from(data));
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}