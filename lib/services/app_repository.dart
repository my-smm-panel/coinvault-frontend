import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api_config.dart';
import 'api_client.dart';

/// Repository that loads real data from the CoinVault backend.
/// Falls back to safe defaults when the API is unreachable so the
/// app never crashes on a network error.
class AppRepository {
  AppRepository._();
  static final AppRepository instance = AppRepository._();

  final ApiClient _api = ApiClient.instance;

  /// Single bootstrap call — returns all home-screen data.
  Future<Map<String, dynamic>> fetchHomeData() async {
    try {
      final res = await _api.get('/api/bootstrap', auth: false);
      if (res is Map && res['success'] == true && res['data'] is Map) {
        return res['data'] as Map<String, dynamic>;
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  /// Health check — returns true when the backend is reachable.
  Future<bool> checkHealth() async {
    try {
      final res = await _api.get('/api/health', auth: false);
      return res is Map && res['success'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Verify phone OTP via Firebase idToken (proxied by Cloudflare worker).
  Future<Map<String, dynamic>?> verifyPhone(String idToken) async {
    try {
      final uri = Uri.parse('${ApiConfig.authWorkerUrl}/api/auth/firebase');
      final res = await httpPost(uri, {'idToken': idToken});
      if (res is Map && res['success'] == true) return res;
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Fetch offers list.
  Future<List<dynamic>> fetchOffers() async {
    try {
      final res = await _api.get('/api/offers', auth: false);
      if (res is Map && res['data'] is Map) {
        final items = res['data']['items'];
        return items is List ? items : [];
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Fetch leaderboard for a period (DAILY / WEEKLY / MONTHLY).
  Future<Map<String, dynamic>> fetchLeaderboard(String period) async {
    try {
      final res = await _api.get('/api/leaderboard/$period', auth: false);
      if (res is Map && res['success'] == true && res['data'] is Map) {
        return res['data'] as Map<String, dynamic>;
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  /// Fetch withdrawal methods.
  Future<List<dynamic>> fetchWithdrawalMethods() async {
    try {
      final res = await _api.get('/api/withdrawals/methods', auth: false);
      if (res is Map && res['data'] is Map) {
        final methods = res['data']['methods'];
        return methods is List ? methods : [];
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}

/// Minimal raw POST helper for the worker call (avoids auth header).
Future<dynamic> httpPost(Uri uri, Map<String, dynamic> body) async {
  final res = await http
      .post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
  return res.body.isEmpty ? null : jsonDecode(res.body);
}
