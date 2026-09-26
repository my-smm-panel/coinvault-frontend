import 'api_client.dart';

/// Parsed offer from Offerwall.GG with coinReward as the primary reward field.
class OfferwallOffer {
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

  OfferwallOffer({
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
  });

  factory OfferwallOffer.fromApi(Map<String, dynamic> m) {
    return OfferwallOffer(
      id: (m['id'] ?? m['providerOfferId'] ?? '').toString(),
      title: (m['title'] ?? m['name'] ?? '').toString().trim(),
      provider: (m['provider'] ?? m['providerName'] ?? 'Offerwall.GG').toString(),
      coinReward: _readReward(m['coinReward'] ?? m['coins'] ?? m['reward']),
      shortRequirement: (m['shortRequirement'] ?? m['shortDesc'] ?? m['description'])?.toString(),
      estimatedTime: (m['estimatedTime'] ?? m['duration'])?.toString(),
      description: (m['description'] ?? m['desc'])?.toString(),
      clickUrl: (m['clickUrl'] ?? m['url'])?.toString(),
      goals: _parseList(m['goals'] ?? m['goal'] ?? m['milestones']),
      requirements: _parseList(m['requirements'] ?? m['requirement']),
      rules: _parseList(m['rules'] ?? m['rule']),
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
      };
}

/// API client for Offerwall.GG offers.
/// Wraps the backend endpoints and never throws to the UI — all errors
/// return null so the screen can show a proper error/empty state.
class OfferwallService {
  OfferwallService._();
  static final OfferwallService instance = OfferwallService._();

  final ApiClient _api = ApiClient.instance;

  /// Fetch the Offerwall.GG offer list.
  /// Calls GET /api/offerwall-gg (authenticated).
  /// Returns parsed offers on success, null on network/server error.
  Future<List<OfferwallOffer>?> fetchOffers() async {
    try {
      final res = await _api.get('/api/offerwall-gg');
      if (res is Map && res['success'] == true) {
        final data = res['data'];
        final dynamic rawItems = data is Map
            ? (data['items'] ?? data['offers'])
            : (data is List ? data : (res['items'] ?? res['offers']));
        if (rawItems is! List) return null;
        return rawItems
            .whereType<Map>()
            .where((m) {
              final id = (m['id'] ?? m['providerOfferId'] ?? '').toString().trim();
              final title = (m['title'] ?? m['name'] ?? '').toString().trim();
              return id.isNotEmpty && title.isNotEmpty;
            })
            .map((m) => OfferwallOffer.fromApi(Map<String, dynamic>.from(m)))
            .toList();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Start an offer — gets the clickUrl for redirect.
  /// Calls POST /api/offerwall-gg/:id/start (authenticated).
  /// Returns the redirectUrl string on success, null on error.
  Future<String?> startOffer(String offerId) async {
    try {
      final id = Uri.encodeComponent(offerId);
      final res = await _api.post('/api/offerwall-gg/$id/start', {});
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

  /// Resolve details only from an offer returned by the verified list route.
  Future<OfferwallOffer?> fetchOfferDetail(String id) async {
    final offers = await fetchOffers();
    if (offers == null) return null;
    for (final offer in offers) {
      if (offer.id == id) return offer;
    }
    return null;
  }
}