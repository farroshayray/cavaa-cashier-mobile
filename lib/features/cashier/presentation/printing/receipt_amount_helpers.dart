import 'receipt_format_helpers.dart';

num? receiptPickNum(Map<String, dynamic> root, List<String> path) {
  dynamic cur = root;
  for (final k in path) {
    if (cur is Map && cur[k] != null) {
      cur = cur[k];
    } else {
      return null;
    }
  }
  return (cur is num) ? cur : num.tryParse(cur.toString());
}

num receiptOrderGrandTotal(Map<String, dynamic> order) {
  if (order['grand_total_local'] != null) {
    return receiptNum(order['grand_total_local']).ceil();
  }

  final subtotal = receiptNum(order['total_order_value']);
  final isPpnActive = receiptToBool(order['is_ppn_active']);
  final ppnPercent = receiptNum(order['ppn']);

  final baseTotal = isPpnActive
      ? (subtotal + (subtotal * ppnPercent / 100))
      : subtotal;

  return baseTotal.ceil() + _receiptCashRoundingAmount(order, baseTotal: baseTotal.ceil());
}

({num paid, num change}) receiptPaidChangeAmounts(Map<String, dynamic> order) {
  final paid = receiptPickNum(order, ['payment', 'paid_amount']) ??
      receiptPickNum(order, ['latest_payment', 'paid_amount']) ??
      receiptPickNum(order, ['paid_amount']) ??
      receiptPickNum(order, ['paid_amount_local']) ??
      receiptOrderGrandTotal(order);

  final change = receiptPickNum(order, ['payment', 'change_amount']) ??
      receiptPickNum(order, ['latest_payment', 'change_amount']) ??
      receiptPickNum(order, ['change_amount']) ??
      receiptPickNum(order, ['change_amount_local']) ??
      0;

  return (paid: paid, change: change);
}

num _receiptCashRoundingAmount(Map<String, dynamic> data, {num? baseTotal}) {
  final stored = receiptPickNum(data, ['cash_rounding_amount']) ??
      receiptPickNum(data, ['rounding_amount']) ??
      receiptPickNum(data, ['payment', 'rounding_amount']) ??
      receiptPickNum(data, ['latest_payment', 'rounding_amount']);
  if (stored != null && stored > 0) return stored.ceil();

  final method = (data['payment_method'] ?? '').toString().toUpperCase();
  if (method != 'CASH') return 0;

  final effectiveBaseTotal = baseTotal ?? _receiptBaseGrandTotal(data);
  final snap = receiptNum(data['grand_total_local'] ?? data['grand_total']);
  final diff = snap.ceil() - effectiveBaseTotal.ceil();
  return diff > 0 ? diff : 0;
}

num _receiptBaseGrandTotal(Map<String, dynamic> data) {
  final subtotal = receiptNum(data['total_order_value'] ?? data['subtotal']);
  final isPpnActive = receiptToBool(data['is_ppn_active']);
  final ppnPercent = receiptNum(data['ppn']);
  return isPpnActive
      ? (subtotal + (subtotal * ppnPercent / 100)).ceil()
      : subtotal.ceil();
}
