import '/features/cashier/data/models/purchase_models.dart';

const editableOrderStatuses = {
  'UNPAID',
  'EXPIRED',
  'PAYMENT REQUEST',
  'OPENBILL_CONFIRMATION',
  'OPENBILL_WAITING_ORDER',
  'PROCESSED',
};

const detailServedStatuses = {
  'SERVED BY KITCHEN',
  'SERVED BY CASHIER',
};

const detailProcessingStatuses = {
  'PROCESSED_BY_CASHIER',
  'PROCESSED BY KITCHEN',
};

String detailStatusOf(Map<String, dynamic> item) =>
    (item['status'] ?? '').toString().trim();

bool isDetailServedStatus(String status) =>
    detailServedStatuses.contains(status);

bool isDetailProcessingStatus(String status) =>
    detailProcessingStatuses.contains(status);

int? detailKitchenProcessId(Map<String, dynamic> item) {
  final raw = item['kitchen_process_id'];
  if (raw == null) return null;
  return num.tryParse(raw.toString())?.toInt();
}

bool isDetailWithKitchenHands(Map<String, dynamic> item) {
  final status = detailStatusOf(item);
  if (status == 'PROCESSED BY KITCHEN') return true;
  final kitchenId = detailKitchenProcessId(item);
  return kitchenId != null && kitchenId > 0;
}

bool isDetailInKitchenProcessing(Map<String, dynamic> item) {
  final status = detailStatusOf(item);
  if (isDetailProcessingStatus(status)) return true;
  return isDetailWithKitchenHands(item);
}

bool isItemTakenByStaff(Map<String, dynamic> item) {
  final status = detailStatusOf(item);
  if (status.isEmpty) return false;
  if (isDetailServedStatus(status)) return true;
  if (isDetailProcessingStatus(status)) return true;
  if (isDetailInKitchenProcessing(item)) return true;
  return false;
}

bool isItemAwaitingCashierServe(Map<String, dynamic> item) {
  return !isItemTakenByStaff(item);
}

bool canEditOrder(Map<String, dynamic> order) {
  if (parseBool(order['payment_flag'])) return false;
  final status = (order['order_status'] ?? '').toString();
  return editableOrderStatuses.contains(status);
}

bool canDeleteUnpaidOrder(Map<String, dynamic> order) {
  if (!canEditOrder(order)) return false;
  if (parseBool(order['payment_flag'])) return false;
  final status = (order['order_status'] ?? '').toString();
  return const {
    'UNPAID',
    'EXPIRED',
    'PAYMENT REQUEST',
    'OPENBILL_CONFIRMATION',
    'OPENBILL_WAITING_ORDER',
    'PAYMENT',
  }.contains(status);
}

bool canMarkKitchenServed(Map<String, dynamic> order) {
  if (parseBool(order['payment_flag'])) return false;
  final status = (order['order_status'] ?? '').toString();
  return const {
    'UNPAID',
    'PROCESSED',
    'OPENBILL_WAITING_ORDER',
    'OPENBILL_CONFIRMATION',
    'PAYMENT REQUEST',
    'EXPIRED',
  }.contains(status);
}

bool isOpenBillOrder(Map<String, dynamic> order) {
  final status = (order['order_status'] ?? '').toString().toUpperCase();
  return parseBool(order['openbill_flag']) ||
      (order['payment_method'] ?? '').toString().toUpperCase() == 'OPENBILL' ||
      status.startsWith('OPENBILL');
}

/// Struk di tab proses hanya untuk order yang sudah tercatat bayar.
bool canPrintProcessReceipt(Map<String, dynamic> order) {
  if (parseBool(order['payment_flag'])) return true;

  if (isOpenBillOrder(order)) return false;

  final status = (order['order_status'] ?? '').toString().toUpperCase();
  return status == 'PAID' || status == 'PROCESSED';
}

bool isItemInKitchenProcess(Map<String, dynamic> item) =>
    isDetailWithKitchenHands(item);

bool isItemAwaitingServe(Map<String, dynamic> item) {
  final status = detailStatusOf(item);
  return !isDetailServedStatus(status);
}

String serveButtonLabelForItem(Map<String, dynamic> item) {
  if (isItemInKitchenProcess(item)) return 'Tandai Served Kitchen';
  return 'Tandai Served';
}

bool isOrderDetailLocked(Map<String, dynamic> item) {
  final status = detailStatusOf(item);
  if (isDetailServedStatus(status)) return true;
  return isDetailInKitchenProcessing(item);
}

String guestDisplayName(String? raw) {
  final name = (raw ?? '').trim();
  if (name.isEmpty) return '';
  final lower = name.toLowerCase();
  if (lower.startsWith('guest-')) return name.substring(6);
  return name;
}

String guestPayloadName(String displayName) {
  final cleaned = displayName.trim();
  if (cleaned.isEmpty) return 'guest';
  final lower = cleaned.toLowerCase();
  if (lower.startsWith('guest-')) return cleaned;
  return cleaned;
}

int? orderDetailId(Map<String, dynamic> item) {
  final raw = item['id'] ?? item['detail_id'];
  if (raw is int) return raw;
  return int.tryParse(raw?.toString() ?? '');
}

int orderProductId(Map<String, dynamic> item) {
  return parseInt(item['partner_product_id'] ?? item['product_id']);
}
