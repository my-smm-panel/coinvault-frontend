import 'package:flutter/foundation.dart';

/// In-memory view of the latest balance fetched from the authenticated backend.
/// It is deliberately not persisted or updated by client-side reward logic.
class BalanceStream extends ValueNotifier<int?> {
  BalanceStream._() : super(null);
  static final BalanceStream instance = BalanceStream._();

  DateTime? lastServerUpdate;

  /// Replace the value only when a response includes a real server balance.
  void setFromServer(int? coins) {
    if (coins == null || coins < 0) return;
    lastServerUpdate = DateTime.now();
    value = coins;
  }

  /// Forget another account's balance on sign-out or account switch.
  void clear() {
    lastServerUpdate = null;
    value = null;
  }

  bool get isEmpty => value == null;
}
