/// Resolves the next sync intent after a partial offline apply.
class OrderSyncIntentChain {
  OrderSyncIntentChain._();

  static String? resolveNext({
    required String localStatus,
    required String? storedIntent,
    required String appliedIntent,
    bool openbillFlag = false,
    double? paidAmountLocal,
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
        );
      case 'CONFIRM_OPENBILL':
        if (status == 'OPENBILL_WAITING_ORDER' || intent == 'PROCESS') {
          return 'PROCESS';
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
  }) {
    if (localStatus == 'OPENBILL_CONFIRMATION' ||
        localStatus == 'OPENBILL_WAITING_ORDER') {
      return 'CONFIRM_OPENBILL';
    }

    if (openbillFlag &&
        localStatus == 'UNPAID' &&
        (storedIntent == 'PAY' || paidAmountLocal != null)) {
      return 'PAY';
    }

    if (localStatus == 'PAID' || paidAmountLocal != null) {
      return 'PAY';
    }

    if (localStatus == 'PROCESSED' || localStatus == 'SERVED') {
      return 'PAY';
    }

    return null;
  }
}
