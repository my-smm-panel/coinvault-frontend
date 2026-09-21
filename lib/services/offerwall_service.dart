import 'api_client.dart';

/// API client for Offerwall.GG offers.
/// Wraps the backend endpoints and never throws to the UI — all errors
/// return null so the screen can show a proper error/empty state.
class OfferwallService {
  OfferwallService._();
  static final OfferwallService instance = OfferwallService._();

  final ApiClient _api = ApiClient.instance;

  /// Fetch the Offerwall.GG offer list.
  /// Calls GET /api/offers/offerwall-gg (authenticated).
  /// Returns the raw response data on success, null on network/server error.
  Future<Map<String, dynamic>?> fetchOffers() async {
    try {
      final res = await _api.get('/api/offers/offerwall-gg');
      if (res is Map) {
        return Map<String, dynamic>.from(res);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Start an offer — gets the clickUrl for redirect.
  /// Calls POST /api/offers/offerwall-gg/:id/start (authenticated).
  /// Returns the redirectUrl string on success, null on error.
  Future<String?> startOffer(String offerId) async {
    try {
      final res = await _api.post('/api/offers/offerwall-gg/$offerId/start', {});
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
  /// Calls GET /api/offers/offerwall-gg/:id (authenticated).
  /// Returns null on error.
  Future<Map<String, dynamic>?> fetchOfferDetail(String id) async {
    try {
      final res = await _api.get('/api/offers/offerwall-gg/$id');
      if (res is Map && res['data'] is Map) {
        return Map<String, dynamic>.from(res['data'] as Map);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
