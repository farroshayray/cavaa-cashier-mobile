import '/features/cashier/data/local/db/cashier_db.dart';

/// Decides when a dirty mirror should push OFFLINE_CATCH_UP instead of step intents.
class OfflineCatchUpPolicy {
  OfflineCatchUpPolicy._();

  static Future<bool> shouldUseOfflineCatchUp({
    required BookingOrder order,
    required Future<bool> Function(String clientUuid) hasDirtyServedDetails,
  }) async {
    if (!order.syncDirty) return false;

    final intent = (order.syncIntent ?? '').trim().toUpperCase();
    if (intent == 'OFFLINE_CATCH_UP') return true;
    if (intent == 'DELETE') return false;

    final status = order.orderStatus.trim().toUpperCase();
    final neverSynced = order.serverId == null || order.serverId! <= 0;

    if (neverSynced && intent == 'CREATE') {
      if (order.openbillFlag && status == 'OPENBILL_WAITING_ORDER') {
        final hasServe = await hasDirtyServedDetails(order.clientUuid);
        if (order.paidAmountLocal == null && !hasServe) {
          return false;
        }
      } else if (!order.openbillFlag && status == 'UNPAID') {
        if (order.paidAmountLocal == null) {
          return false;
        }
      } else if (status == 'DRAFT' || status == 'OPENBILL_CONFIRMATION') {
        return false;
      }
    }

    if (intent == 'PAY' ||
        intent == 'SERVE_ITEMS' ||
        intent == 'FINISH' ||
        intent == 'PROCESS' ||
        intent == 'CONFIRM_OPENBILL') {
      return true;
    }

    if (order.paidAmountLocal != null) return true;
    if (await hasDirtyServedDetails(order.clientUuid)) return true;

    return {
      'UNPAID',
      'SERVED',
      'PAID',
      'PROCESSED',
    }.contains(status);
  }
}
