import '/features/cashier/data/sync/order_stage_rank.dart';

/// Decides whether a mirror row still needs push after a partial/full server apply.
class OrderCatchUpSyncPolicy {
  OrderCatchUpSyncPolicy._();

  static bool needsCatchUp({
    required String localStatus,
    required String serverStatus,
    required bool openbillFlag,
    required bool hasDirtyServedDetails,
    double? paidAmountLocal,
    String? syncIntent,
  }) {
    final server = serverStatus.trim().toUpperCase();
    if (server.isEmpty) return false;

    final local = localStatus.trim().toUpperCase();

    if (hasDirtyServedDetails) return true;

    final intent = (syncIntent ?? '').trim().toUpperCase();

    if (openbillFlag && local == 'UNPAID' && server == 'OPENBILL_WAITING_ORDER') {
      return true;
    }

    if (openbillFlag && local == 'OPENBILL_WAITING_ORDER' && server == 'UNPAID') {
      return true;
    }

    if (openbillFlag && local == 'SERVED' && server == 'UNPAID') {
      if (paidAmountLocal != null &&
          (intent == 'PAY' || intent == 'OFFLINE_CATCH_UP')) {
        return true;
      }
    }

    // Openbill serve synced: local + server both UNPAID, payment not queued yet.
    if (openbillFlag && local == 'UNPAID' && server == 'UNPAID') {
      if (intent == 'PAY' || intent == 'OFFLINE_CATCH_UP') return true;
      return false;
    }

    if (paidAmountLocal != null) {
      if (intent == 'PAY' || intent == 'OFFLINE_CATCH_UP') {
        if (openbillFlag && local == 'SERVED' && server != 'SERVED') return true;
        if (!openbillFlag && local == 'PAID' && server == 'UNPAID') return true;
      }
      if (local == 'SERVED' && server != 'SERVED') return true;
      if (local == 'UNPAID' && server == 'OPENBILL_WAITING_ORDER') return true;
      if (local == 'UNPAID' && server == 'UNPAID') {
        return intent == 'PAY' || intent == 'OFFLINE_CATCH_UP';
      }
    }

    return OrderStageRank.isLocalAheadOfServer(
      localStatus: localStatus,
      serverStatus: serverStatus,
      openbillFlag: openbillFlag,
      syncIntent: syncIntent,
      paidAmountLocal: paidAmountLocal,
    );
  }

  /// True when a dirty mirror may clear `sync_dirty` after server caught up.
  static bool shouldClearSyncDirty({
    required bool syncDirty,
    required String localStatus,
    required String serverStatus,
    required bool openbillFlag,
    required bool hasDirtyServedDetails,
    double? paidAmountLocal,
    String? syncIntent,
  }) {
    if (!syncDirty) return false;
    if (serverStatus.trim().isEmpty) return false;

    return !needsCatchUp(
      localStatus: localStatus,
      serverStatus: serverStatus,
      openbillFlag: openbillFlag,
      hasDirtyServedDetails: hasDirtyServedDetails,
      paidAmountLocal: paidAmountLocal,
      syncIntent: syncIntent,
    );
  }
}
