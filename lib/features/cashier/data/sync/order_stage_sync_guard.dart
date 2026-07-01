/// Validates sync intent against current order status before push.
class OrderStageSyncGuard {
  static String? validateIntent({
    required String currentStatus,
    required String syncIntent,
    bool neverSynced = false,
    bool offlineCatchUp = false,
  }) {
    final status = currentStatus.toUpperCase();
    final intent = syncIntent.toUpperCase();
    final catchUp = offlineCatchUp || neverSynced;

    switch (intent) {
      case 'CREATE':
        if (neverSynced) {
          return null;
        }
        if (!{'DRAFT', 'UNPAID', 'OPENBILL_CONFIRMATION'}.contains(status)) {
          return 'CREATE tidak valid untuk status $status';
        }
        return null;
      case 'PAY':
        if (catchUp && {'PAID', 'PROCESSED', 'SERVED'}.contains(status)) {
          return null;
        }
        if (!{'UNPAID', 'EXPIRED', 'PAYMENT REQUEST'}.contains(status)) {
          return 'PAY tidak valid untuk status $status';
        }
        return null;
      case 'PROCESS':
      case 'CONFIRM_OPENBILL':
        if (catchUp && {'PROCESSED', 'SERVED'}.contains(status)) {
          return null;
        }
        if (!{
          'PAID',
          'OPENBILL_CONFIRMATION',
          'OPENBILL_WAITING_ORDER',
        }.contains(status)) {
          return '$intent tidak valid untuk status $status';
        }
        return null;
      case 'FINISH':
        if (catchUp && {'PROCESSED', 'SERVED'}.contains(status)) {
          return null;
        }
        if (status != 'PROCESSED') {
          return 'FINISH tidak valid untuk status $status';
        }
        return null;
      case 'SERVE_ITEMS':
        if (catchUp && status == 'SERVED') {
          return null;
        }
        if (!{
          'OPENBILL_WAITING_ORDER',
          'OPENBILL_CONFIRMATION',
          'PROCESSED',
          'UNPAID',
        }.contains(status)) {
          return 'SERVE_ITEMS tidak valid untuk status $status';
        }
        return null;
      case 'DELETE':
        return null;
      case 'UPDATE':
        return null;
      case 'OFFLINE_CATCH_UP':
        return null;
      default:
        return null;
    }
  }

  /// Resolves which intent to push next for a dirty mirror row.
  static String resolvePushIntent({
    required String? storedIntent,
    required String orderStatus,
    required int? serverId,
  }) {
    if (serverId == null || serverId <= 0) {
      return 'CREATE';
    }

    final intent = (storedIntent ?? 'UPDATE').toUpperCase();
    if (intent == 'OFFLINE_CATCH_UP') return 'OFFLINE_CATCH_UP';
    if (intent.isEmpty) return 'UPDATE';
    return intent;
  }
}
