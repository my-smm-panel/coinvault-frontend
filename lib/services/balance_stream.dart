import 'package:flutter/foundation.dart';

/// In-memory view of the latest balance fetched from the authenticated backend.
/// It is deliberately not persisted or updated by client-side reward logic.
class BalanceStream extends ValueNotifier<int?> {
  BalanceStream._() : super(null);
  static final BalanceStream instance = BalanceStream._();

  DateTime? lastServerUpdate;
  int _sessionRevision = 0;

  /// Changes whenever a balance must be invalidated (sign-out/account switch).
  int get sessionRevision => _sessionRevision;

  /// Replace the value only when a response includes a real server balance and
  /// still belongs to the active session revision.
  void setFromServer(int? coins, {int? expectedRevision}) {
    if (expectedRevision != null && expectedRevision != _sessionRevision) return;
    if (coins == null || coins < 0) return;
    lastServerUpdate = DateTime.now();
    value = coins;
  }

  /// Forget another account's balance on sign-out or account switch.
  void clear() {
    _sessionRevision++;
    lastServerUpdate = null;
    value = null;
  }

  bool get isEmpty => value == null;
}
