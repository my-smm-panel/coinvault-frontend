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

  /// Fetch user profile from backend (real endpoint: GET /api/users/profile).
  Future<Map<String, dynamic>?> fetchUserProfile(String uid) async {
    try {
      final res = await _api.get('/api/users/profile');
      if (res is Map && res['success'] == true && res['data'] is Map) {
        return Map<String, dynamic>.from(res['data'] as Map);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Update user profile on backend
  Future<bool> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      final res = await _api.put('/api/users/$uid', data);
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
      if (res is Map && res['success'] == true) return Map<String, dynamic>.from(res);
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

  /// Fetch leaderboard for a period (DAILY / WEEKLY / MONTHLY / ALL_TIME).
  Future<Map<String, dynamic>> fetchLeaderboard(String period) async {
    try {
      final res = await _api.get('/api/leaderboard/$period');
      if (res is Map && res['success'] == true && res['data'] is Map) {
        return Map<String, dynamic>.from(res['data'] as Map);
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  /// Leaderboard prizes (public).
  Future<dynamic> leaderboardPrizes() async {
    try {
      final res = await _api.get('/api/leaderboard/prizes', auth: false);
      if (res is Map && res['success'] == true) return res['data'];
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Referral info: code, link, stats, referral list.
  Future<Map<String, dynamic>> referralInfo() async {
    try {
      final res = await _api.get('/api/referrals/info');
      if (res is Map && res['success'] == true && res['data'] is Map) {
        return Map<String, dynamic>.from(res['data'] as Map);
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  /// Notifications list.
  Future<List<dynamic>> notificationsList() async {
    try {
      final res = await _api.get('/api/notifications');
      if (res is Map && res['success'] == true && res['data'] is Map) {
        final items = res['data']['items'];
        return items is List ? items : [];
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> notifRead(String id) async {
    try {
      final res = await _api.patch('/api/notifications/$id/read', {});
      return res is Map && res['success'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> notifReadAll() async {
    try {
      final res = await _api.patch('/api/notifications/read-all', {});
      return res is Map && res['success'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Spin history (backend returns a raw list).
  Future<List<dynamic>> spinHistoryList() async {
    try {
      final res = await _api.get('/api/spin/history');
      if (res is Map && res['success'] == true) {
        final d = res['data'];
        return d is List ? d : [];
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Task history (backend returns a raw list).
  Future<List<dynamic>> taskHistoryList() async {
    try {
      final res = await _api.get('/api/tasks/history');
      if (res is Map && res['success'] == true) {
        final d = res['data'];
        return d is List ? d : [];
      }
      return [];
    } catch (_) {
      return [];
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

  /// Server-authoritative spin status (daily limit enforced by backend).
  /// Returns {canSpin, spinsUsed, dailyLimit} or null when unreachable.
  Future<Map<String, dynamic>?> spinStatus() async {
    try {
      final res = await _api.get('/api/spin/status');
      if (res is Map && res['success'] == true && res['data'] is Map) {
        return Map<String, dynamic>.from(res['data'] as Map);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Server-authoritative spin. Reward is decided + credited by the backend
  /// (Supabase ledger). Returns data {rewardType, coins, spinId, dailyLimit}.
  /// Throws ApiException when limit is over, session expired, or offline.
  Future<Map<String, dynamic>> spinNow() async {
    final res = await _api.post('/api/spin/spin', {});
    if (res is Map && res['success'] == true && res['data'] is Map) {
      return Map<String, dynamic>.from(res['data'] as Map);
    }
    throw ApiException(-1, 'Spin failed');
  }

  /// Submit withdrawal request (real endpoint: POST /api/withdrawals/request).
  /// Throws ApiException with the server message on failure.
  Future<Map<String, dynamic>> submitWithdrawal({
    required String uid,
    required int coins,
    required String method, // 'upi' or 'bank'
    required String details,
  }) async {
    final isUpi = method == 'upi';
    final body = <String, dynamic>{
      'amount': coins,
      'method': isUpi ? 'UPI' : 'BANK_TRANSFER',
      if (isUpi) 'upiId': details,
      if (!isUpi) ..._splitBankDetails(details),
    };
    final res = await _api.post('/api/withdrawals/request', body);
    if (res is Map && res['success'] == true && res['data'] is Map) {
      return Map<String, dynamic>.from(res['data'] as Map);
    }
    throw ApiException(-1, 'Withdrawal failed');
  }

  /// Best-effort split of free-text bank details into accountNumber/IFSC.
  /// Server validates strictly and returns a clear message if missing.
  Map<String, String> _splitBankDetails(String details) {
    final out = <String, String>{};
    final ifsc = RegExp(r'[A-Z]{4}0[A-Z0-9]{6}').firstMatch(details.toUpperCase());
    if (ifsc != null) out['ifscCode'] = ifsc.group(0)!;
    final ac = RegExp(r'\d{9,20}').firstMatch(details.replaceAll(' ', ''));
    if (ac != null) out['accountNumber'] = ac.group(0)!;
    out['accountHolder'] = details.length > 100 ? details.substring(0, 100) : details;
    return out;
  }

  /// Fetch withdrawal history for user (real endpoint: GET /api/withdrawals/my).
  Future<List<dynamic>> fetchWithdrawalHistory(String uid) async {
    try {
      final res = await _api.get('/api/withdrawals/my');
      if (res is Map && res['success'] == true && res['data'] is Map) {
        final items = res['data']['items'] ?? res['data']['withdrawals'] ?? res['data']['data'];
        return items is List ? items : [];
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
