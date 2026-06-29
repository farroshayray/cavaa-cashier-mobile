import '/features/cashier/presentation/utils/order_edit_utils.dart';

/// Maps unified `booking_orders` mirror rows to tab list item shape.
class OrderTabItemMapper {
  static Map<String, dynamic> toPaymentItem(Map<String, dynamic> row) {
    final serverId = _toInt(row['id']);
    final tableNo = row['table_no']?.toString() ??
        (row['table'] is Map ? row['table']['table_no']?.toString() : null) ??
        '-';
    final subtotal = _toNum(row['total_order_value']);
    final ppnPercent = _toNum(row['ppn']);
    final isPpnActive = _toBool(row['is_ppn_active']);
    final grandTotal = isPpnActive
        ? (subtotal + (subtotal * ppnPercent / 100)).ceilToDouble()
        : subtotal.ceilToDouble();

    return {
      ...row,
      'id': serverId,
      'server_id': serverId,
      'booking_order_code': row['booking_order_code'] ?? '-',
      'customer_name': guestDisplayName(row['customer_name']?.toString()),
      'customer': guestDisplayName(row['customer_name']?.toString()),
      'order_name': guestDisplayName(row['customer_name']?.toString()),
      'table': {'table_no': tableNo},
      'table_no': tableNo,
      'table_name': tableNo,
      'subtotal': subtotal,
      'grand_total': grandTotal,
      'total_amount': grandTotal,
      'openbill_flag': _toBool(row['openbill_flag']) ||
          row['payment_method']?.toString() == 'OPENBILL' ||
          (row['order_status'] ?? '').toString().startsWith('OPENBILL'),
      'is_local_only': false,
      'is_cached_server': true,
      'sync_status': row['sync_dirty'] == true ? 'PENDING' : 'SYNCED',
      'sort_time': row['created_at']?.toString() ?? row['updated_at']?.toString(),
    };
  }

  static Map<String, dynamic> toProcessItem(Map<String, dynamic> row) {
    final serverId = _toInt(row['id']);
    final tableNo = row['table_no']?.toString() ??
        (row['table'] is Map ? row['table']['table_no']?.toString() : null) ??
        '-';
    final details = (row['order_details'] as List?) ?? [];
    final processedByKitchen = details.isNotEmpty &&
        details.every((d) {
          if (d is! Map) return false;
          final status = (d['status'] ?? '').toString().toUpperCase();
          return status == 'SERVED' || status == 'PROCESSED';
        });

    return {
      ...row,
      'id': serverId,
      'booking_order_code': row['booking_order_code'] ?? '',
      'customer_name': row['customer_name'] ?? '',
      'payment_method': row['payment_method'],
      'order_status': row['order_status'] ?? '',
      'total_order_value': _toNum(row['total_order_value']),
      'ppn': _toNum(row['ppn']),
      'is_ppn_active': _toBool(row['is_ppn_active']) ? 1 : 0,
      'processed_by_kitchen': processedByKitchen,
      'table': {'table_no': tableNo},
      'is_synced': row['sync_dirty'] != true,
      'pending_action': row['sync_dirty'] == true ? row['sync_intent'] : null,
      'is_local_only': false,
      'sort_time': row['created_at']?.toString() ?? row['updated_at']?.toString(),
    };
  }

  static Map<String, dynamic> toDoneItem(Map<String, dynamic> row) {
    final serverId = _toInt(row['id']);
    final tableNo = row['table_no']?.toString() ??
        (row['table'] is Map ? row['table']['table_no']?.toString() : null) ??
        '-';

    return {
      ...row,
      'id': serverId,
      'booking_order_code': row['booking_order_code'] ?? '',
      'customer_name': row['customer_name'] ?? '',
      'payment_method': row['payment_method'],
      'order_status': row['order_status'] ?? 'SERVED',
      'total_order_value': _toNum(row['total_order_value']),
      'ppn': _toNum(row['ppn']),
      'is_ppn_active': _toBool(row['is_ppn_active']) ? 1 : 0,
      'table': {'table_no': tableNo},
      'is_synced': row['sync_dirty'] != true,
      'is_local_only': false,
      'sort_time': row['created_at']?.toString() ?? row['updated_at']?.toString(),
    };
  }

  static int? _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static num _toNum(dynamic v) {
    if (v is num) return v;
    if (v is String) return num.tryParse(v) ?? 0;
    return 0;
  }

  static bool _toBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v?.toString().toLowerCase();
    return s == '1' || s == 'true';
  }
}
