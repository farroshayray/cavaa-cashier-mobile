/// Mirrors Laravel `App\Support\CashRounding` for offline/sync parity.
class CashRoundingHelpers {
  static const allowedUnits = [0, 100, 500, 1000];

  static int normalizeUnit(int? unit) {
    final u = unit ?? 0;
    return allowedUnits.contains(u) ? u : 0;
  }

  static int basePayable(num subtotal, bool isPpnActive, num ppn) {
    final s = subtotal.toDouble();
    if (isPpnActive) {
      return (s + (s * ppn / 100)).ceil();
    }
    return s.ceil();
  }

  static int roundedPayable(
    num subtotal,
    bool isPpnActive,
    num ppn,
    int unit,
  ) {
    final base = basePayable(subtotal, isPpnActive, ppn);
    final normalizedUnit = normalizeUnit(unit);
    if (normalizedUnit <= 0 || base <= 0) return base;
    return ((base / normalizedUnit).ceil() * normalizedUnit).toInt();
  }

  static int roundingAmount(num subtotal, bool isPpnActive, num ppn, int unit) {
    final base = basePayable(subtotal, isPpnActive, ppn);
    return roundedPayable(subtotal, isPpnActive, ppn, unit) - base;
  }

  static int paymentRoundingAmount(
    String? paymentType,
    num subtotal,
    bool isPpnActive,
    num ppn,
    int unit,
  ) {
    if ((paymentType ?? 'CASH').toUpperCase() != 'CASH') return 0;
    return roundingAmount(subtotal, isPpnActive, ppn, unit);
  }

  static int expectedPayable({
    required num subtotal,
    required bool isPpnActive,
    required num ppn,
    required String? paymentType,
    required int cashRoundingUnit,
    num? storedRoundingAmount,
  }) {
    final base = basePayable(subtotal, isPpnActive, ppn);
    final rounding = storedRoundingAmount?.round() ??
        paymentRoundingAmount(
          paymentType,
          subtotal,
          isPpnActive,
          ppn,
          cashRoundingUnit,
        );
    return base + rounding;
  }

  static int resolveCashRoundingUnit(
    Map<String, dynamic> order, {
    int? partnerCashRoundingUnit,
  }) {
    final fromOrder = normalizeUnit(_num(order['cash_rounding_unit']).toInt());
    if (fromOrder > 0) return fromOrder;

    final partnerData = order['partner_data'];
    if (partnerData is Map) {
      final fromPartnerData =
          normalizeUnit(_num(partnerData['cash_rounding_unit']).toInt());
      if (fromPartnerData > 0) return fromPartnerData;
    }

    if (partnerCashRoundingUnit != null) {
      final fromPartner = normalizeUnit(partnerCashRoundingUnit);
      if (fromPartner > 0) return fromPartner;
    }

    return 0;
  }

  static int cashRoundingAmountForOrder(
    Map<String, dynamic> order,
    num baseTotal, {
    int? partnerCashRoundingUnit,
  }) {
    final stored = _num(order['cash_rounding_amount']);
    if (stored > 0) return stored.ceil();

    final unit = resolveCashRoundingUnit(
      order,
      partnerCashRoundingUnit: partnerCashRoundingUnit,
    );
    if (unit <= 0) return 0;

    return paymentRoundingAmount(
      'CASH',
      _num(order['total_order_value']),
      _toBool(order['is_ppn_active']),
      _num(order['ppn']),
      unit,
    );
  }

  static Map<String, dynamic> roundingFieldsFromLocalOrder({
    required double subtotal,
    required double grandTotal,
    required bool isPpnActive,
    required double ppnPercent,
    double? cashRoundingAmount,
    int? cashRoundingUnit,
  }) {
    final base = basePayable(subtotal, isPpnActive, ppnPercent);
    final rounding = cashRoundingAmount ??
        (grandTotal > base ? grandTotal - base : 0).toDouble();
    return {
      'grand_total_local': grandTotal,
      'cash_rounding_amount': rounding,
      'cash_rounding_unit': cashRoundingUnit ?? 0,
    };
  }

  static int expectedPayableFromServerDetail(
    Map<String, dynamic> detail,
    String? paymentType,
  ) {
    final subtotal = _num(detail['total_order_value']);
    final isPpnActive = _toBool(detail['is_ppn_active']);
    final ppn = _num(detail['ppn']);
    final unit = _num(detail['cash_rounding_unit']).toInt();
    final resolvedType = paymentType ?? detail['payment_method']?.toString();
    final isCashPayment = (resolvedType ?? 'CASH').toUpperCase() == 'CASH';

    // Open bill UNPAID returns cash_rounding_amount=0 until a method is chosen.
    // For CASH payment sync, always derive rounding from unit (matches Laravel validation).
    num? storedRounding;
    if (!isCashPayment) {
      final rawStored = detail['cash_rounding_amount'];
      if (rawStored != null) {
        storedRounding = _num(rawStored);
      }
    }

    return expectedPayable(
      subtotal: subtotal,
      isPpnActive: isPpnActive,
      ppn: ppn,
      paymentType: resolvedType,
      cashRoundingUnit: unit,
      storedRoundingAmount: storedRounding,
    );
  }

  static num _num(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final s = value?.toString().toLowerCase() ?? '';
    return s == '1' || s == 'true';
  }
}

/// User-visible message for local orders with unsynced changes.
String? localSyncStatusMessage(Map<String, dynamic> data) {
  final syncStatus = (data['sync_status'] ?? '').toString();
  final lastError = (data['last_error'] ?? '').toString().trim();
  final isUnsynced = data['is_synced'] == false ||
      data['pending_sync'] == true ||
      syncStatus == 'FAILED' ||
      syncStatus == 'PENDING' ||
      syncStatus == 'PENDING_PAYMENT' ||
      syncStatus == 'PENDING_PROCESS' ||
      syncStatus == 'PENDING_FINISH' ||
      syncStatus == 'PENDING_UPDATE' ||
      syncStatus == 'STOCK_CONFLICT';

  if (!isUnsynced && syncStatus != 'FAILED') return null;

  if (syncStatus == 'STOCK_CONFLICT') {
    return 'Konflik stok: ${lastError.isNotEmpty ? lastError : 'stok tidak cukup di server'}';
  }

  if (const {
    'FAILED',
    'PENDING_PAYMENT',
    'PENDING_PROCESS',
    'PENDING_FINISH',
  }.contains(syncStatus)) {
    if (lastError.isNotEmpty) return 'Gagal sinkron: $lastError';
    return 'Perubahan lokal belum tersinkron';
  }

  if (syncStatus == 'PENDING' || syncStatus == 'PENDING_UPDATE') {
    if (lastError.isNotEmpty) return 'Menunggu sinkron: $lastError';
    if (syncStatus == 'PENDING_UPDATE') {
      return 'Perubahan menu belum tersinkron';
    }
    return 'Perubahan lokal belum tersinkron';
  }

  final pendingAction = (data['pending_action'] ?? '').toString();
  if (pendingAction.isNotEmpty) return 'Perubahan lokal: $pendingAction';

  if (data['is_synced'] == false || data['pending_sync'] == true) {
    return 'Perubahan lokal belum tersinkron';
  }

  return null;
}

bool localSyncStatusMessageIsError(String? message, Map<String, dynamic> data) {
  final syncStatus = (data['sync_status'] ?? '').toString();
  return syncStatus == 'STOCK_CONFLICT' || syncStatus == 'FAILED';
}
