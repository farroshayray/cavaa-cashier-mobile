/// Resolves the next sync intent after a partial offline apply.
class OrderSyncIntentChain {
  OrderSyncIntentChain._();

  static String? resolveNext({
    required String localStatus,
    required String? storedIntent,
    required String appliedIntent,
    bool openbillFlag = false,
    double? paidAmountLocal,
    String? orderBy,
    String? serverStatusAfterApply,
    bool hasDirtyServedDetails = false,
  }) {
    final status = localStatus.toUpperCase();
    final intent = (storedIntent ?? '').toUpperCase();
    final applied = appliedIntent.toUpperCase();

    switch (applied) {
      case 'CREATE':
        return firstIntentAfterCreate(
          localStatus: status,
          storedIntent: intent,
          openbillFlag: openbillFlag,
          paidAmountLocal: paidAmountLocal,
          orderBy: orderBy,
          serverStatusAfterCreate: serverStatusAfterApply,
          hasDirtyServedDetails: hasDirtyServedDetails,
        );
      case 'CONFIRM_OPENBILL':
        if (openbillFlag && status == 'OPENBILL_WAITING_ORDER') {
          return null;
        }
        if (status == 'OPENBILL_WAITING_ORDER' || intent == 'PROCESS') {
          return 'PROCESS';
        }
        return null;
      case 'SERVE_ITEMS':
        if (openbillFlag &&
            paidAmountLocal != null &&
            {'UNPAID', 'SERVED'}.contains(status)) {
          final server = (serverStatusAfterApply ?? '').trim().toUpperCase();
          if (server == 'UNPAID') {
            return intent == 'PAY' ? null : 'PAY';
          }
        }
        return null;
      case 'PAY':
        if (status == 'SERVED') {
          return 'PROCESS';
        }
        if (intent == 'FINISH') {
          return 'FINISH';
        }
        if (intent == 'PROCESS' || status == 'PROCESSED') {
          return 'PROCESS';
        }
        return null;
      case 'PROCESS':
        if (intent == 'FINISH' || status == 'SERVED') {
          return 'FINISH';
        }
        return null;
      default:
        return null;
    }
  }

  static String? firstIntentAfterCreate({
    required String localStatus,
    required String storedIntent,
    bool openbillFlag = false,
    double? paidAmountLocal,
    String? orderBy,
    String? serverStatusAfterCreate,
    bool hasDirtyServedDetails = false,
  }) {
    final server = (serverStatusAfterCreate ?? '').trim().toUpperCase();

    if (localStatus == 'OPENBILL_CONFIRMATION') {
      return 'CONFIRM_OPENBILL';
    }

    if (localStatus == 'OPENBILL_WAITING_ORDER') {
      if (_isCashierOrder(orderBy)) {
        if (server == 'OPENBILL_WAITING_ORDER') {
          return null;
        }
        if (storedIntent == 'CONFIRM_OPENBILL') return null;
        return 'CONFIRM_OPENBILL';
      }
      return 'CONFIRM_OPENBILL';
    }

    if (openbillFlag && hasDirtyServedDetails) {
      return storedIntent == 'SERVE_ITEMS' ? null : 'SERVE_ITEMS';
    }

    if (openbillFlag && localStatus == 'SERVED' && paidAmountLocal != null) {
      if (server == 'OPENBILL_WAITING_ORDER') {
        return 'SERVE_ITEMS';
      }
      if (server == 'UNPAID' || server.isEmpty) {
        return storedIntent == 'PAY' ? null : 'PAY';
      }
      return null;
    }

    if (openbillFlag && localStatus == 'UNPAID' && paidAmountLocal != null) {
      if (server == 'OPENBILL_WAITING_ORDER') {
        return 'SERVE_ITEMS';
      }
      if (server == 'UNPAID' || server.isEmpty) {
        return storedIntent == 'PAY' ? null : 'PAY';
      }
      return null;
    }

    if (localStatus == 'PAID' || (paidAmountLocal != null && !openbillFlag)) {
      return 'PAY';
    }

    if (!openbillFlag &&
        (localStatus == 'PROCESSED' || localStatus == 'SERVED')) {
      return 'PAY';
    }

    return null;
  }

  static bool _isCashierOrder(String? orderBy) =>
      (orderBy ?? '').trim().toUpperCase() == 'CASHIER';
}
