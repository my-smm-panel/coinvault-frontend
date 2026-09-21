import 'api_client.dart';

/// API client for Offerwall.GG offers.
/// Wraps the backend endpoints and never throws to the UI — all errors
/// return null so the screen can show a proper error/empty state.
class OfferwallService {
  OfferwallService._();
  static final OfferwallService instance = OfferwallService._();

  final ApiClient _api = ApiClient.instance;

  /// Fetch the Offerwall.GG offer list.
  /// Calls GET /api/offers?provider=offerwall_gg.
  /// Returns null on network/server error.
  Future<List<dynamic>?> fetchOffers() async {
    try {
      final res = await _api.get('/api/offers?provider=offerwall_gg', auth: false);
      if (res is Map && res['data'] is Map) {
        final items = res['data']['items'];
        return items is List ? items : [];
      }
      if (res is Map && res['data'] is List) {
        return res['data'] as List;
      }
      return [];
    } catch (_) {
      return null;
    }
  }

  /// Fetch full details for a single offer.
  /// Calls GET /api/offers/:id.
  /// Returns null on error.
  Future<Map<String, dynamic>?> fetchOfferDetail(String id) async {
    try {
      final res = await _api.get('/api/offers/$id', auth: false);
      if (res is Map && res['success'] == true && res['data'] is Map) {
        return Map<String, dynamic>.from(res['data'] as Map);
      }
      if (res is Map && res['data'] is Map) {
        return Map<String, dynamic>.from(res['data'] as Map);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Start an offer — registers IN_PROGRESS and returns the clickUrl.
  /// Calls POST /api/offers/:id/start.
  /// Returns the clickUrl string on success, null on error.
  Future<String?> startOffer(String id) async {
    try {
      final res = await _api.post('/api/offers/$id/start', {});
      if (res is Map && res['success'] == true && res['data'] is Map) {
        final data = res['data'] as Map;
        return data['clickUrl'] as String? ??
            data['externalUrl'] as String? ??
            data['url'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}