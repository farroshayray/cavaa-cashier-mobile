import '/features/cashier/data/local/db/cashier_db.dart';
import '/features/cashier/data/local/db/daos/booking_orders_dao.dart';

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
    if (intent == 'UPDATE') return false;

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

    // Cash order already on server: finish lifecycle with step intents.
    if (!order.openbillFlag && !neverSynced) {
      if (status == 'SERVED' || status == 'PROCESSED') {
        if (intent == 'PAY' || intent == 'PROCESS' || intent == 'FINISH') {
          return false;
        }
      }
    }

    // Open bill serve-only on server-known order → native step intent + detail_ids.
    if (order.openbillFlag && !neverSynced) {
      if ((intent == 'SERVE_ITEMS' || intent == 'MARK_KITCHEN_SERVED') &&
          order.paidAmountLocal == null) {
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

    if (order.paidAmountLocal != null) {
      if (!order.openbillFlag &&
          !neverSynced &&
          (status == 'SERVED' || status == 'PROCESSED')) {
        return false;
      }
      return true;
    }
    if (await hasDirtyServedDetails(order.clientUuid)) return true;

    return {'UNPAID', 'SERVED', 'PAID', 'PROCESSED'}.contains(status);
  }

  /// Openbill catch-up target must reflect whether new kitchen lines are still pending.
  static String resolveCatchUpTargetStatus({
    required BookingOrder order,
    BookingOrderBundle? bundle,
  }) {
    final status = order.orderStatus.trim().toUpperCase();
    if (!order.openbillFlag || bundle == null) return status;

    if (status != 'OPENBILL_WAITING_ORDER' &&
        status != 'OPENBILL_CONFIRMATION') {
      return status;
    }

    final details = bundle.details;
    if (details.isEmpty) return status;

    final hasUnserved = details.any((detail) {
      final served = (detail.status ?? '').trim().toUpperCase();
      return served.isEmpty || !served.contains('SERVED');
    });

    if (hasUnserved) {
      return status;
    }

    return 'UNPAID';
  }
}
