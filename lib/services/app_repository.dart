import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api_config.dart';
import 'api_client.dart';
import 'balance_stream.dart';

/// Repository that loads real data from the CoinVault backend.
/// Falls back to safe defaults when the API is unreachable so the
/// app never crashes on a network error.
class AppRepository {
  AppRepository._();
  static final AppRepository instance = AppRepository._();

  final ApiClient _api = ApiClient.instance;

  /// Feed the global BalanceStream from a fresh server payload (spec R1).
  /// Handles {balance}, {coins}, {user:{coins}}, and {data:{...}} shapes.
  void _syncBalanceFrom(Map<String, dynamic> src) {
    final m = src['data'] is Map ? (src['data'] as Map) : src;
    final user = m['user'] is Map ? (m['user'] as Map) : null;
    num? c = user?['coins'];
    if (c == null) c = m['balance'] ?? m['coins'];
    BalanceStream.instance.setFromServer(c?.toInt());
  }

  /// Single bootstrap call — returns all home-screen data.
  Future<Map<String, dynamic>> fetchHomeData() async {
    try {
      final res = await _api.get('/api/bootstrap', auth: false);
      if (res is Map && res['success'] == true && res['data'] is Map) {
        final data = res['data'] as Map<String, dynamic>;
        _syncBalanceFrom(data);
        return data;
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
        final data = Map<String, dynamic>.from(res['data'] as Map);
        _syncBalanceFrom(data);
        return data;
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

  /// Fetch offers list. Returns null when the API is unreachable so the
  /// UI can show a proper error state instead of silently going empty.
  Future<List<dynamic>?> fetchOffers() async {
    try {
      final res = await _api.get('/api/offers', auth: false);
      if (res is Map && res['data'] is Map) {
        final items = res['data']['items'];
        return items is List ? items : [];
      }
      return [];
    } catch (_) {
      return null;
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

  /// Convenience: remaining spins today from the SERVER (not cached model).
  /// Returns null when unreachable so the caller can decide the fallback.
  Future<int?> spinsRemainingToday() async {
    final s = await spinStatus();
    if (s == null) return null;
    final limit = (s['dailyLimit'] ?? 2) as int;
    final used = (s['spinsUsed'] ?? 0) as int;
    return (limit - used).clamp(0, limit);
  }

  /// Server-authoritative spin. Reward is decided + credited by the backend
  /// (Supabase ledger). Returns data {rewardType, coins, spinId, dailyLimit}.
  /// Throws ApiException when limit is over, session expired, or offline.
  Future<Map<String, dynamic>> spinNow() async {
    final res = await _api.post('/api/spin/spin', {});
    if (res is Map && res['success'] == true && res['data'] is Map) {
      final data = Map<String, dynamic>.from(res['data'] as Map);
      _syncBalanceFrom(data);
      return data;
    }
    throw ApiException(-1, 'Spin failed');
  }

  /// Submit withdrawal request (real endpoint: POST /api/withdrawals/request).
  /// Throws ApiException with the server message on failure.
  /// Supports UPI, BANK_TRANSFER, PHONEPE, and VOUCHER methods.
  Future<Map<String, dynamic>> submitWithdrawal({
    required String uid,
    required int coins,
    required String method, // 'upi' | 'bank' | 'phonepe' | 'voucher'
    required String details,
  }) async {
    final m = method.toLowerCase();
    final body = <String, dynamic>{
      'amount': coins,
      'method': m == 'upi'
          ? 'UPI'
          : m == 'bank'
              ? 'BANK_TRANSFER'
              : m == 'phonepe'
                  ? 'PHONEPE'
                  : 'VOUCHER',
    };
    if (m == 'upi') {
      body['upiId'] = details;
    } else if (m == 'bank') {
      body.addAll(_splitBankDetails(details));
    } else if (m == 'phonepe') {
      // details = phone number
      final digits = details.replaceAll(RegExp(r'\D'), '');
      if (digits.length < 10 || digits.length > 12) {
        throw ApiException(-1, 'Enter a valid PhonePe number (10 digits)');
      }
      body['phone'] = digits;
      body['accountHolder'] = details;
    } else {
      // voucher: details = 'Brand|contact'
      final parts = details.split('|');
      final brand = parts[0].trim();
      final contact = parts.length > 1 ? parts[1].trim() : '';
      if (brand.isEmpty) throw ApiException(-1, 'Select a gift card brand');
      if (contact.isEmpty || contact.length < 3) {
        throw ApiException(-1, 'Enter email/mobile for voucher delivery');
      }
      body['brand'] = brand;
      body['contact'] = contact;
    }
    final res = await _api.post('/api/withdrawals/request', body);
    if (res is Map && res['success'] == true && res['data'] is Map) {
      final data = Map<String, dynamic>.from(res['data'] as Map);
      _syncBalanceFrom(data);
      return data;
    }
    final msg = (res is Map && res['error'] is String)
        ? res['error'] as String
        : 'Withdrawal failed';
    throw ApiException(-1, msg);
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

  /// Surveys list from backend (real endpoint: GET /api/surveys).
  /// Returns null when the API is unreachable (so UI can show an error state
  /// instead of silently rendering nothing).
  Future<List<dynamic>?> fetchSurveys() async {
    try {
      final res = await _api.get('/api/surveys', auth: false);
      if (res is Map && res['success'] == true) {
        final d = res['data'];
        return d is List ? d : [];
      }
      return [];
    } catch (_) {
      return null;
    }
  }

  /// Fetch user activity feed (real endpoint: GET /api/users/activity).
  Future<List<dynamic>> fetchActivity() async {
    try {
      final res = await _api.get('/api/users/activity');
      if (res is Map && res['success'] == true) {
        final d = res['data'];
        return d is List ? d : [];
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Gift cards catalogue from backend (real endpoint: GET /api/giftcards).
  /// Returns [] when empty; null when the API is unreachable.
  Future<List<dynamic>?> fetchGiftCards() async {
    try {
      final res = await _api.get('/api/giftcards', auth: false);
      if (res is Map && res['success'] == true) {
        final d = res['data'];
        return d is List ? d : [];
      }
      return [];
    } catch (_) {
      return null;
    }
  }

  /// Start a survey (registers IN_PROGRESS completion; server returns externalUrl).
  Future<Map<String, dynamic>?> startSurvey(String id) async {
    try {
      final res = await _api.post('/api/surveys/$id/start', {});
      if (res is Map && res['success'] == true && res['data'] is Map) {
        return Map<String, dynamic>.from(res['data'] as Map);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Fetch withdrawal history for user (real endpoint: GET /api/withdrawals/my).
  Future<List<dynamic>> fetchWithdrawalHistory(String uid) async {
    try {
      final res = await _api.get('/api/withdrawals/my');
      if (res is Map && res['success'] == true) {
        final items = res['data']['items'] ?? res['data']['withdrawals'] ?? res['data']['data'];
        return items is List ? items : [];
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Fetch today's daily quiz (public, no auth). Returns questions + config.
  Future<Map<String, dynamic>?> fetchQuiz() async {
    try {
      final res = await _api.get('/api/quiz', auth: false);
      if (res is Map && res['success'] == true && res['data'] is Map) {
        return Map<String, dynamic>.from(res['data'] as Map);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Submit quiz answers (auth required). Returns correctCount + coinsEarned.
  Future<Map<String, dynamic>?> submitQuiz(List<int> answers) async {
    try {
      final res = await _api.post('/api/quiz/submit', {'answers': answers});
      if (res is Map && res['success'] == true && res['data'] is Map) {
        final data = Map<String, dynamic>.from(res['data'] as Map);
        _syncBalanceFrom(data);
        return data;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Scratch card — server picks reward, credits wallet. Auth required.
  Future<Map<String, dynamic>?> scratchCard() async {
    try {
      final res = await _api.post('/api/scratch', {});
      if (res is Map && res['success'] == true && res['data'] is Map) {
        final data = Map<String, dynamic>.from(res['data'] as Map);
        _syncBalanceFrom(data);
        return data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Scratch status — remaining count + last reward. Auth required.
  Future<Map<String, dynamic>?> scratchStatus() async {
    try {
      final res = await _api.get('/api/scratch/status');
      if (res is Map && res['success'] == true && res['data'] is Map) {
        return Map<String, dynamic>.from(res['data'] as Map);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

/// Minimal raw POST helper for the worker call (avoids auth header).
Future<dynamic> httpPost(Uri uri, Map<String, dynamic> body) async {
  final res = await http
      .post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
  return res.body.isEmpty ? null : jsonDecode(res.body);
}
