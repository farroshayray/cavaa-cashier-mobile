/// Validates sync intent against current order status before push.
class OrderStageSyncGuard {
  static String? validateIntent({
    required String currentStatus,
    required String syncIntent,
  }) {
    final status = currentStatus.toUpperCase();
    final intent = syncIntent.toUpperCase();

    switch (intent) {
      case 'CREATE':
        if (!{'DRAFT', 'UNPAID', 'OPENBILL_CONFIRMATION'}.contains(status)) {
          return 'CREATE tidak valid untuk status $status';
        }
        return null;
      case 'PAY':
        if (!{'UNPAID', 'EXPIRED', 'PAYMENT REQUEST'}.contains(status)) {
          return 'PAY tidak valid untuk status $status';
        }
        return null;
      case 'PROCESS':
      case 'CONFIRM_OPENBILL':
        if (!{
          'PAID',
          'OPENBILL_CONFIRMATION',
          'OPENBILL_WAITING_ORDER',
        }.contains(status)) {
          return '$intent tidak valid untuk status $status';
        }
        return null;
      case 'FINISH':
        if (status != 'PROCESSED') {
          return 'FINISH tidak valid untuk status $status';
        }
        return null;
      case 'DELETE':
        return null;
      case 'UPDATE':
        return null;
      default:
        return null;
    }
  }
}
