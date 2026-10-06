import 'receipt_amount_helpers.dart';
import 'receipt_format_helpers.dart';

class ReceiptTotals {
  const ReceiptTotals({
    required this.subtotal,
    required this.isPpnActive,
    required this.ppnPercent,
    required this.ppnAmount,
    required this.roundingAmount,
    required this.grandTotal,
    required this.paid,
    required this.change,
  });

  final num subtotal;
  final bool isPpnActive;
  final num ppnPercent;
  final num ppnAmount;
  final num roundingAmount;
  final num grandTotal;
  final num paid;
  final num change;
}

ReceiptTotals buildReceiptTotals(Map<String, dynamic> order) {
  final payment = order['payment'] is Map ? order['payment'] as Map : null;
  final latestPayment =
      order['latest_payment'] is Map ? order['latest_payment'] as Map : null;

  final subtotal = receiptNum(order['total_order_value']);
  final isPpnActive = receiptToBool(order['is_ppn_active']);
  final ppnPercent = receiptNum(order['ppn']);
  final ppnAmount = isPpnActive ? (subtotal * ppnPercent / 100) : 0;
  final baseGrandTotal =
      isPpnActive ? (subtotal + ppnAmount).ceil() : subtotal.ceil();

  final roundingAmount = receiptNum(
    order['cash_rounding_amount'] ??
        payment?['rounding_amount'] ??
        latestPayment?['rounding_amount'],
  );

  final grandTotal = baseGrandTotal + roundingAmount;
  final amounts = receiptPaidChangeAmounts(order);

  return ReceiptTotals(
    subtotal: subtotal,
    isPpnActive: isPpnActive,
    ppnPercent: ppnPercent,
    ppnAmount: ppnAmount,
    roundingAmount: roundingAmount,
    grandTotal: grandTotal,
    paid: amounts.paid,
    change: amounts.change,
  );
}
