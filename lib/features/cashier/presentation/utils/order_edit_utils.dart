import '/features/cashier/data/models/purchase_models.dart';

const editableOrderStatuses = {
  'UNPAID',
  'EXPIRED',
  'PAYMENT REQUEST',
  'OPENBILL_CONFIRMATION',
  'OPENBILL_WAITING_ORDER',
  'PROCESSED',
};

bool canEditOrder(Map<String, dynamic> order) {
  if (parseBool(order['payment_flag'])) return false;
  final status = (order['order_status'] ?? '').toString();
  return editableOrderStatuses.contains(status);
}

bool canDeleteUnpaidOrder(Map<String, dynamic> order) {
  if (!canEditOrder(order)) return false;
  final status = (order['order_status'] ?? '').toString();
  return const {
    'UNPAID',
    'EXPIRED',
    'PAYMENT REQUEST',
    'OPENBILL_CONFIRMATION',
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

bool isItemInKitchenProcess(Map<String, dynamic> item) {
  final status = (item['status'] ?? '').toString();
  if (status == 'PROCESSED_BY_CASHIER') return true;

  final rawKitchenProcessId = item['kitchen_process_id'];
  final kitchenProcessId = rawKitchenProcessId == null
      ? null
      : num.tryParse(rawKitchenProcessId.toString())?.toInt();

  return kitchenProcessId != null && kitchenProcessId > 0;
}

bool isItemAwaitingServe(Map<String, dynamic> item) {
  final status = (item['status'] ?? '').toString();
  return status != 'SERVED BY KITCHEN' && status != 'SERVED BY CASHIER';
}

String serveButtonLabelForItem(Map<String, dynamic> item) {
  if (isItemInKitchenProcess(item)) return 'Tandai Served Kitchen';
  return 'Tandai Served';
}

bool isOrderDetailLocked(Map<String, dynamic> item) {
  final rawKitchenProcessId = item['kitchen_process_id'];
  final kitchenProcessId = rawKitchenProcessId == null
      ? null
      : num.tryParse(rawKitchenProcessId.toString())?.toInt();
  final status = (item['status'] ?? '').toString();

  if (kitchenProcessId != null && kitchenProcessId > 0) return true;

  return status == 'PROCESSED_BY_CASHIER' ||
      status == 'SERVED BY KITCHEN' ||
      status == 'SERVED BY CASHIER';
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
