import '/features/cashier/presentation/utils/order_edit_utils.dart';

/// Resolves next `booking_orders.order_status` after tab actions.
/// Mirrors backend rules in CashierMobileOrderController.
class OrderStageResolver {
  OrderStageResolver._();

  static String? _statusFromApi(Map<String, dynamic>? apiResponse) {
    if (apiResponse == null) return null;

    final direct = apiResponse['order_status']?.toString();
    if (direct != null && direct.isNotEmpty) return direct;

    final data = apiResponse['data'];
    if (data is Map) {
      final nested = data['order_status']?.toString();
      if (nested != null && nested.isNotEmpty) return nested;
    }

    return null;
  }

  /// Open bill UNPAID (after kitchen) → SERVED; regular UNPAID → PAID.
  static String resolveAfterPayment({
    required Map<String, dynamic> orderBeforePay,
    Map<String, dynamic>? apiResponse,
  }) {
    final fromApi = _statusFromApi(apiResponse);
    if (fromApi != null) return fromApi;

    final status = (orderBeforePay['order_status'] ?? '').toString();
    if (isOpenBillOrder(orderBeforePay) && status == 'UNPAID') {
      return 'SERVED';
    }
    return 'PAID';
  }

  /// Open bill finish → UNPAID (payment tab); regular finish → SERVED (done tab).
  static String resolveAfterFinish({
    required Map<String, dynamic> order,
    Map<String, dynamic>? apiResponse,
  }) {
    final fromApi = _statusFromApi(apiResponse);
    if (fromApi != null) return fromApi;

    if (isOpenBillOrder(order)) return 'UNPAID';
    return 'SERVED';
  }

  /// Process / confirm open bill.
  static String resolveAfterProcess({
    required Map<String, dynamic> order,
    Map<String, dynamic>? apiResponse,
    bool confirmingOpenbill = false,
  }) {
    final fromApi = _statusFromApi(apiResponse);
    if (fromApi != null) return fromApi;

    final status = (order['order_status'] ?? '').toString();
    if (confirmingOpenbill || status == 'OPENBILL_CONFIRMATION') {
      return 'OPENBILL_WAITING_ORDER';
    }
    return 'PROCESSED';
  }

  static bool movesToDoneTab(String status) => status == 'SERVED';

  static bool movesToProcessTab(String status) {
    const processStatuses = {
      'PAID',
      'PROCESSED',
      'OPENBILL_CONFIRMATION',
      'OPENBILL_WAITING_ORDER',
    };
    return processStatuses.contains(status);
  }

  static bool movesToPaymentTab(String status) {
    const paymentStatuses = {'UNPAID', 'EXPIRED', 'PAYMENT REQUEST'};
    return paymentStatuses.contains(status);
  }
}
