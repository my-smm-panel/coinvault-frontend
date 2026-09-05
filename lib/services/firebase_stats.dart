import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../models/app_models.dart';

/// Firebase Realtime Database mirror for coins + spins.
/// RTDB: https://coinvault-be301-default-rtdb.firebaseio.com
/// Node: users/{uid} -> { coins, totalEarned, spinsUsed, lastSpinDate, updatedAt }
///
/// NOTE: RTDB is the FAST UI counter only. Withdrawal decisions must always
/// come from the backend (Supabase ledger). Required RTDB rules:
/// { "rules": { "users": { "$uid": {
///   ".read": "auth != null && auth.uid == $uid",
///   ".write": "auth != null && auth.uid == $uid" } } } }
class FirebaseStats {
  static const int dailySpinLimit = 2;

  static FirebaseDatabase get _db {
    try {
      return FirebaseDatabase.instance;
    } catch (_) {
      return FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://coinvault-be301-default-rtdb.firebaseio.com',
      );
    }
  }

  static DatabaseReference _userRef(String uid) => _db.ref('users/$uid');

  static String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Create RTDB node on first login (set-if-null, never overwrites).
  static Future<void> syncUser(UserModel model) async {
    try {
      final ref = _userRef(model.uid);
      await ref.runTransaction((Object? current) {
        if (current != null) return Transaction.abort();
        return Transaction.success({
          'coins': model.coins,
          'totalEarned': model.coins,
          'spinsUsed': model.dailySpinsUsed,
          'lastSpinDate': _today(),
          'updatedAt': ServerValue.timestamp,
        });
      });
    } catch (e) {
      debugPrint('FirebaseStats.syncUser error: $e');
    }
  }

  /// Delta coins (+earn / -spend). Transaction-safe, never negative.
  static Future<void> addCoinsDelta(String uid, int delta) async {
    if (delta == 0) return;
    try {
      await _userRef(uid).runTransaction((Object? current) {
        final map = (current as Map?)?.map((k, v) => MapEntry(k.toString(), v)) ?? {};
        final coins = ((map['coins'] ?? 0) as num).toInt();
        final earned = ((map['totalEarned'] ?? 0) as num).toInt();
        map['coins'] = (coins + delta).clamp(0, 999999999);
        if (delta > 0) map['totalEarned'] = earned + delta;
        map['updatedAt'] = ServerValue.timestamp;
        return Transaction.success(map);
      });
    } catch (e) {
      debugPrint('FirebaseStats.addCoinsDelta error: $e');
    }
  }

  /// Record one spin. Returns true if counted, false if daily limit over.
  static Future<bool> recordSpin(String uid) async {
    try {
      final res = await _userRef(uid).runTransaction((Object? current) {
        final map = (current as Map?)?.map((k, v) => MapEntry(k.toString(), v)) ?? {};
        final today = _today();
        var used = ((map['spinsUsed'] ?? 0) as num).toInt();
        if (map['lastSpinDate'] != today) {
          used = 0;
          map['lastSpinDate'] = today;
        }
        if (used >= dailySpinLimit) return Transaction.abort();
        map['spinsUsed'] = used + 1;
        map['updatedAt'] = ServerValue.timestamp;
        return Transaction.success(map);
      });
      return res.committed;
    } catch (e) {
      debugPrint('FirebaseStats.recordSpin error: $e');
      return true; // don't block UI on tracking failure
    }
  }

  /// Realtime coin balance stream for UI.
  static Stream<int> coinsStream(String uid) {
    try {
      return _userRef(uid).child('coins').onValue.map((e) {
        final v = e.snapshot.value;
        if (v is num) return v.toInt();
        return 0;
      });
    } catch (_) {
      return Stream.value(0);
    }
  }

  /// Remaining spins today (reads RTDB once).
  static Future<int> remainingSpins(String uid) async {
    try {
      final snap = await _userRef(uid).get();
      final map = (snap.value as Map?)?.map((k, v) => MapEntry(k.toString(), v));
      if (map == null) return dailySpinLimit;
      if (map['lastSpinDate'] != _today()) return dailySpinLimit;
      final used = ((map['spinsUsed'] ?? 0) as num).toInt();
      return (dailySpinLimit - used).clamp(0, dailySpinLimit);
    } catch (_) {
      return dailySpinLimit;
    }
  }
}
