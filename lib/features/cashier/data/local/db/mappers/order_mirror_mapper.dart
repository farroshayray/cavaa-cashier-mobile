import 'dart:convert';

import '/features/cashier/data/local/db/cashier_db.dart';

class OrderMirrorMapper {
  static Map<String, dynamic> orderToUiMap(BookingOrder row) {
    final map = {
      'id': row.serverId,
      'local_client_uuid': row.clientUuid,
      'local_id': row.clientUuid,
      'booking_order_code': row.bookingOrderCode,
      'partner_id': row.partnerId,
      'partner_name': row.partnerName,
      'table_id': row.tableId,
      'table_no': row.tableNo,
      'customer_id': row.customerId,
      'employee_order_id': row.employeeOrderId,
      'order_by': row.orderBy,
      'customer_name': row.customerName,
      'order_status': row.orderStatus,
      'payment_method': row.paymentMethod,
      'openbill_flag': row.openbillFlag,
      'discount_id': row.discountId,
      'discount_value': row.discountValue,
      'total_order_value': row.totalOrderValue,
      'ppn': row.ppn,
      'is_ppn_active': row.isPpnActive,
      'customer_order_note': row.customerOrderNote,
      'employee_order_note': row.employeeOrderNote,
      'cashier_process_id': row.cashierProcessId,
      'kitchen_process_id': row.kitchenProcessId,
      'payment_id': row.paymentId,
      'payment_flag': row.paymentFlag,
      'sync_version': row.syncVersion,
      'sync_dirty': row.syncDirty,
      'sync_error': row.syncError,
      'sync_intent': row.syncIntent,
      'paid_amount_local': row.paidAmountLocal,
      'change_amount_local': row.changeAmountLocal,
      'cash_rounding_amount': row.cashRoundingAmount,
      'cash_rounding_unit': row.cashRoundingUnit,
      'created_at': row.createdAt?.toIso8601String(),
      'updated_at': row.updatedAt?.toIso8601String(),
      'is_local_only': row.serverId == null,
    };

    if (row.wifiSnapshotJson != null && row.wifiSnapshotJson!.trim().isNotEmpty) {
      map['wifi_snapshot_json'] = row.wifiSnapshotJson;
      try {
        final decoded = jsonDecode(row.wifiSnapshotJson!);
        if (decoded is Map) {
          map['wifi_snapshot'] = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }

    return hydrateReceiptPayload(
      map,
      latestPaymentJson: row.latestPaymentJson,
      fallbackUpdatedAtIso: row.updatedAt?.toIso8601String(),
    );
  }

  static Map<String, dynamic> hydrateReceiptPayload(
    Map<String, dynamic> source, {
    String? latestPaymentJson,
    String? fallbackUpdatedAtIso,
  }) {
    final map = Map<String, dynamic>.from(source);
    final latest = _resolveLatestPayment(
      map,
      latestPaymentJson: latestPaymentJson,
    );

    final paymentRaw = map['payment'];
    final payment = paymentRaw is Map
        ? Map<String, dynamic>.from(paymentRaw.cast<dynamic, dynamic>())
        : <String, dynamic>{};
    final updatedAt = payment['updated_at'] ??
        latest?['updated_at'] ??
        fallbackUpdatedAtIso ??
        map['updated_at'];

    payment['paid_amount'] ??=
        map['paid_amount_local'] ?? latest?['paid_amount'] ?? map['paid_amount'];
    payment['change_amount'] ??= map['change_amount_local'] ??
        latest?['change_amount'] ??
        map['change_amount'];
    payment['rounding_amount'] ??=
        map['cash_rounding_amount'] ?? latest?['rounding_amount'];
    if (updatedAt != null && updatedAt.toString().trim().isNotEmpty) {
      payment['updated_at'] ??= updatedAt;
    }

    if (_hasAny(payment, const ['paid_amount', 'change_amount', 'rounding_amount'])) {
      map['payment'] = payment;
    }

    if ((map['employee_name'] == null || map['employee_name'].toString().trim().isEmpty) &&
        map['order_by'] != null &&
        map['order_by'].toString().trim().isNotEmpty) {
      map['employee_name'] = map['order_by'];
    }

    return map;
  }

  static Map<String, dynamic>? _resolveLatestPayment(
    Map<String, dynamic> map, {
    String? latestPaymentJson,
  }) {
    final latestRaw = map['latest_payment'];
    if (latestRaw is Map) {
      return Map<String, dynamic>.from(latestRaw.cast<dynamic, dynamic>());
    }

    final rawJson = latestPaymentJson ??
        map['latest_payment_json']?.toString() ??
        map['latestPaymentJson']?.toString();
    if (rawJson == null || rawJson.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is Map) {
        final latest = Map<String, dynamic>.from(decoded.cast<dynamic, dynamic>());
        map['latest_payment'] = latest;
        return latest;
      }
    } catch (_) {}

    return null;
  }

  static bool _hasAny(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  static Map<String, dynamic> detailToUiMap(OrderDetail row) {
    return {
      'id': row.serverId,
      'local_detail_uuid': row.clientDetailUuid,
      'booking_order_id': row.bookingOrderServerId,
      'product_code': row.productCode,
      'product_name': row.productName,
      'partner_product_id': row.partnerProductId,
      'quantity': row.quantity,
      'base_price': row.basePrice,
      'cogs': row.cogs,
      'options_price': row.optionsPrice,
      'customer_note': row.customerNote,
      'promo_id': row.promoId,
      'promo_amount': row.promoAmount,
      'promo_type': row.promoType,
      'status': row.status,
      'cashier_process_id': row.cashierProcessId,
      'kitchen_process_id': row.kitchenProcessId,
      'sync_version': row.syncVersion,
    };
  }

  static Map<String, dynamic> optionToUiMap(OrderDetailOption row) {
    return {
      'id': row.serverId,
      'option_id': row.optionId,
      'parent_name': row.parentName,
      'partner_product_option_name': row.partnerProductOptionName,
      'price': row.price,
    };
  }
}
