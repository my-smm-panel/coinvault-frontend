import 'package:flutter/foundation.dart';

/// Global, single source of truth for the user's coin balance.
///
/// Spec Rule R1: MONEY NEVER FROM CACHE ALONE. This stream only ever updates
/// from a FRESH server-returned value (bootstrap, profile, or an action
/// response like spin/scratch/quiz/withdraw that carries `balance`).
/// Home, Wallet, Spin, Withdraw all listen to the SAME stream, so one update
/// is correct everywhere.
class BalanceStream extends ValueNotifier<int?> {
  BalanceStream._() : super(null);
  static final BalanceStream instance = BalanceStream._();

  /// When the balance was last refreshed from the server (for the grey
  /// "offline — last updated HH:MM" caption, spec section 10).
  DateTime? lastServerUpdate;

  /// Replace with a FRESH server value only. Ignored when null so we never
  /// clear a good balance with a failed response.
  void setFromServer(int? coins) {
    if (coins == null) return;
    lastServerUpdate = DateTime.now();
    value = coins;
  }

  /// True until the first fresh server value arrives → UI shows a skeleton,
  /// never a fabricated "0" or a stale number.
  bool get isEmpty => value == null;
}
