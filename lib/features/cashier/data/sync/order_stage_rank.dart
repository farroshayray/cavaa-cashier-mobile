/// Compares local vs server order lifecycle stages during sync pull merge.
class OrderStageRank {
  OrderStageRank._();

  static const _cashRanks = <String, int>{
    'DRAFT': 0,
    'UNPAID': 10,
    'EXPIRED': 10,
    'PAYMENT REQUEST': 10,
    'PAID': 20,
    'PROCESSED': 30,
    'SERVED': 40,
    'DONE': 40,
    'FINISHED': 40,
  };

  static const _openbillRanks = <String, int>{
    'DRAFT': 0,
    'UNPAID': 10,
    'EXPIRED': 10,
    'PAYMENT REQUEST': 10,
    'OPENBILL_CONFIRMATION': 15,
    'OPENBILL_WAITING_ORDER': 18,
    'PAID': 20,
    'PROCESSED': 30,
    'SERVED': 40,
    'DONE': 40,
    'FINISHED': 40,
  };

  static int rankFor({
    required String status,
    bool openbillFlag = false,
    String? syncIntent,
    double? paidAmountLocal,
  }) {
    final normalized = status.trim().toUpperCase();
    final table = openbillFlag ? _openbillRanks : _cashRanks;
    var rank = table[normalized] ?? 0;

    if (openbillFlag && normalized == 'UNPAID') {
      // Openbill UNPAID after serve = payment-ready, ahead of WAITING_ORDER (18).
      rank = 35;
    }

    return rank;
  }

  static bool isLocalAheadOfServer({
    required String localStatus,
    required String serverStatus,
    bool openbillFlag = false,
    String? syncIntent,
    double? paidAmountLocal,
  }) {
    final local = localStatus.trim().toUpperCase();
    final server = serverStatus.trim().toUpperCase();

    // Customer added items on web: server returns OPENBILL_CONFIRMATION and
    // must override local payment-ready open bill UNPAID.
    if (openbillFlag && local == 'UNPAID' && server == 'OPENBILL_CONFIRMATION') {
      return false;
    }

    // Cashier added items and sent order back to kitchen.
    if (openbillFlag && local == 'UNPAID' && server == 'OPENBILL_WAITING_ORDER') {
      return false;
    }

    final localRank = rankFor(
      status: localStatus,
      openbillFlag: openbillFlag,
      syncIntent: syncIntent,
      paidAmountLocal: paidAmountLocal,
    );
    final serverRank = rankFor(
      status: serverStatus,
      openbillFlag: openbillFlag,
    );
    return localRank > serverRank;
  }

  static bool isTerminalStatus(String status) {
    return {'SERVED', 'DONE', 'FINISHED'}.contains(status.trim().toUpperCase());
  }
}
