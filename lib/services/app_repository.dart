import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api_config.dart';
import 'api_client.dart';
import 'balance_stream.dart';

/// Repository for CoinVault backend APIs. Missing/error responses remain
/// unavailable to callers; financial values are never replaced with defaults.
class AppRepository {
  AppRepository._();
  static final AppRepository instance = AppRepository._();

  final ApiClient _api = ApiClient.instance;

  /// Feed the global BalanceStream from a fresh server payload (spec R1).
  /// Only server wallet/action responses can update the displayed balance.
  /// `availableBalance` is the spendable balance from /api/wallet/balances;
  /// action responses use `balance`.
  int? _syncBalanceFrom(Map<String, dynamic> src) {
    final m = src['data'] is Map ? Map<String, dynamic>.from(src['data'] as Map) : src;
    final wallet = m['wallet'] is Map ? Map<String, dynamic>.from(m['wallet'] as Map) : m;
    final raw = wallet['availableBalance'] ?? wallet['balance'] ?? wallet['coins'];
    if (raw is! num || raw < 0) return null;
    final coins = raw.toInt();
    BalanceStream.instance.setFromServer(coins);
    return coins;
  }

  /// Fetch the authenticated, server-authoritative spendable wallet balance.
  /// Returns null when no valid balance was received; never substitutes a local default.
  Future<int?> fetchWalletBalance() async {
    try {
      final res = await _api.get('/api/wallet/balances');
      if (res is Map && res['success'] == true && res['data'] is Map) {
        final data = Map<String, dynamic>.from(res['data'] as Map);
        return _syncBalanceFrom(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Single bootstrap call — returns all home-screen data.
  Future<Map<String, dynamic>> fetchHomeData() async {
    try {
      final res = await _api.get('/api/bootstrap', auth: false);
      if (res is Map && res['success'] == true && res['data'] is Map) {
        final data = res['data'] as Map<String, dynamic>;
        // Bootstrap is public and may contain stale legacy user coin fields;
        // never use it as a wallet source.
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
        return Map<String, dynamic>.from(res['data'] as Map);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Update only profile fields accepted by the authenticated backend route.
  /// The server derives the user identity from the JWT; the client never picks
  /// a user id or writes balances/payment credentials through this endpoint.
  Future<bool> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      final body = <String, dynamic>{};
      final name = data['name'] ?? data['displayName'];
      final avatar = data['avatar'] ?? data['photoUrl'];
      if (name is String && name.trim().isNotEmpty) body['name'] = name.trim();
      if (avatar is String) body['avatar'] = avatar;
      if (body.isEmpty) return true;
      final res = await _api.patch('/api/auth/profile', body);
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
      if (res is Map && res['success'] == true) {
        final data = res['data'];
        if (data is List) return data;
        if (data is Map) {
          final items = data['items'] ?? data['offers'];
          if (items is List) return items;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Fetch leaderboard for a period (DAILY / WEEKLY / MONTHLY / ALL_TIME).
  Future<Map<String, dynamic>?> fetchLeaderboard(String period) async {
    try {
      final res = await _api.get('/api/leaderboard/$period');
      if (res is Map && res['success'] == true && res['data'] is Map) {
        return Map<String, dynamic>.from(res['data'] as Map);
      }
      return null;
    } catch (_) {
      return null;
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
  Future<List<dynamic>?> notificationsList() async {
    try {
      final res = await _api.get('/api/notifications');
      if (res is Map && res['success'] == true) {
        final data = res['data'];
        if (data is List) return data;
        if (data is Map && data['items'] is List) {
          return data['items'] as List<dynamic>;
        }
      }
      return null;
    } catch (_) {
      return null;
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
  Future<List<dynamic>?> spinHistoryList() async {
    try {
      final res = await _api.get('/api/spin/history');
      if (res is Map && res['success'] == true) {
        final d = res['data'];
        return d is List ? d : null;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Task history (backend returns a raw list).
  Future<List<dynamic>?> taskHistoryList() async {
    try {
      final res = await _api.get('/api/tasks/history');
      if (res is Map && res['success'] == true) {
        final d = res['data'];
        return d is List ? d : null;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Fetch withdrawal methods.
  Future<List<dynamic>> fetchWithdrawalMethods() async {
    try {
      final res = await _api.get('/api/withdrawals/methods');
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
    if (s == null || s['dailyLimit'] is! num || s['spinsUsed'] is! num) return null;
    final limit = (s['dailyLimit'] as num).toInt();
    final used = (s['spinsUsed'] as num).toInt();
    if (limit < 0 || used < 0) return null;
    return (limit - used).clamp(0, limit).toInt();
  }

  /// Server-authoritative spin. Reward is decided and credited by the backend
  /// wallet ledger. Returns data {rewardType, coins, spinId, dailyLimit}.
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

  /// Submit a coin withdrawal request. Supported methods come from the
  /// authenticated backend methods endpoint: UPI and BANK_TRANSFER.
  Future<Map<String, dynamic>> submitWithdrawal({
    required String uid,
    required int coins,
    required String method,
    required String details,
  }) async {
    final normalized = method.toUpperCase();
    final body = <String, dynamic>{'amount': coins};
    if (normalized == 'UPI') {
      body['method'] = 'UPI';
      body['upiId'] = details;
    } else if (normalized == 'BANK' || normalized == 'BANK_TRANSFER') {
      body['method'] = 'BANK_TRANSFER';
      body.addAll(_splitBankDetails(details));
    } else {
      throw ApiException(-1, 'This withdrawal method is not supported by the server');
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

  /// Redeem one backend-listed gift card. The backend validates and debits the
  /// wallet atomically; this client never estimates or deducts the cost.
  Future<Map<String, dynamic>> redeemGiftCard(String giftCardId) async {
    final res = await _api.post('/api/giftcards/redeem/$giftCardId', {});
    if (res is Map && res['success'] == true && res['data'] is Map) {
      final data = Map<String, dynamic>.from(res['data'] as Map);
      _syncBalanceFrom(data);
      await fetchWalletBalance();
      return data;
    }
    final msg = (res is Map && res['error'] is String)
        ? res['error'] as String
        : 'Gift card redemption failed';
    throw ApiException(-1, msg);
  }

  /// Start a real backend offer/task session and return its tracking URL/data.
  Future<Map<String, dynamic>> startOffer(String offerId) async {
    final id = Uri.encodeComponent(offerId);
    final res = await _api.post('/api/offers/$id/start', {});
    if (res is Map && res['success'] == true && res['data'] is Map) {
      return Map<String, dynamic>.from(res['data'] as Map);
    }
    final msg = (res is Map && res['error'] is String)
        ? res['error'] as String
        : 'Could not start this offer';
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
    // Payout name is optional in the backend schema. Never copy the entire
    // free-text account/IFSC input into a person's name field.
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
        return d is List ? d : null;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Fetch user activity feed (real endpoint: GET /api/users/activity).
  Future<List<dynamic>?> fetchActivity() async {
    try {
      final res = await _api.get('/api/users/activity');
      if (res is Map && res['success'] == true) {
        final d = res['data'];
        if (d is List) return d;
        if (d is Map && d['items'] is List) return d['items'] as List<dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Gift cards catalogue from backend (real endpoint: GET /api/giftcards).
  /// Returns [] when empty; null when the API is unreachable.
  Future<List<dynamic>?> fetchGiftCards() async {
    try {
      final res = await _api.get('/api/giftcards', auth: false);
      if (res is Map && res['success'] == true) {
        final d = res['data'];
        return d is List ? d : null;
      }
      return null;
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
  Future<List<dynamic>?> fetchWithdrawalHistory(String uid) async {
    try {
      final res = await _api.get('/api/withdrawals/my');
      if (res is Map && res['success'] == true) {
        final data = res['data'];
        if (data is List) return data;
        if (data is Map) {
          final items = data['items'] ?? data['withdrawals'] ?? data['data'];
          if (items is List) return items;
        }
        final topLevelItems = res['items'] ?? res['withdrawals'];
        return topLevelItems is List ? topLevelItems : null;
      }
      return null;
    } catch (_) {
      return null;
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
