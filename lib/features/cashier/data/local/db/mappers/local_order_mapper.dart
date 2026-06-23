import 'package:drift/drift.dart';
import 'dart:convert';
import '/features/cashier/data/local/db/cashier_db.dart';

class LocalOrderMapper {
  static LocalOrdersCompanion toLocalOrder({
    required String localId,
    required String clientOrderCode,
    required String customerName,
    required int? partnerId,
    required String? partnerName,
    required int? tableServerId,
    required String? tableNoSnapshot,
    required String paymentMethodSelected,
    required String paymentMethodEffective,
    required double subtotal,
    required double discountValue,
    required double ppnPercent,
    required bool isPpnActive,
    required double grandTotal,
    String orderStatusLocal = 'UNPAID',
    String syncStatus = 'PENDING',
    String? manualPaymentRawJson,
  }) {
    final now = DateTime.now();

    return LocalOrdersCompanion.insert(
      localId: localId,
      clientOrderCode: clientOrderCode,
      customerName: customerName,
      createdAtLocal: now,
      updatedAtLocal: now,

      partnerId: Value(partnerId),
      partnerName: Value(partnerName),
      tableServerId: Value(tableServerId),
      tableNoSnapshot: Value(tableNoSnapshot),

      paymentMethodSelected: Value(paymentMethodSelected),
      paymentMethodEffective: Value(paymentMethodEffective),

      subtotal: Value(subtotal),
      discountValue: Value(discountValue),
      ppnPercent: Value(ppnPercent),
      isPpnActive: Value(isPpnActive),
      grandTotal: Value(grandTotal),

      orderStatusLocal: Value(orderStatusLocal),
      syncStatus: Value(syncStatus),

      manualPaymentRawJson: Value(manualPaymentRawJson),
    );
  }

  static LocalOrderItemsCompanion toLocalItem({
    required String localId,
    required String orderLocalId,
    required int productServerId,
    required String productNameSnapshot,
    required double basePrice,
    required int qty,
    required String? customerNote,
    required double optionsPrice,
    required double lineTotal,
    int? promoId,
    String? promoType,
    double? promoAmount,
    int? categoryServerId,
    String? categoryNameSnapshot,
  }) {
    return LocalOrderItemsCompanion.insert(
      localId: localId,
      orderLocalId: orderLocalId,
      productServerId: productServerId,
      productNameSnapshot: productNameSnapshot,
      basePrice: Value(basePrice),
      qty: qty,
      createdAtLocal: DateTime.now(),
      customerNote: Value(customerNote),
      optionsPrice: Value(optionsPrice),
      lineTotal: Value(lineTotal),
      promoId: Value(promoId),
      promoType: Value(promoType),
      promoAmount: Value(promoAmount),
      categoryServerId: Value(categoryServerId),
      categoryNameSnapshot: Value(categoryNameSnapshot),
    );
  }

  static LocalOrderItemOptionsCompanion toLocalOption({
    required String localId,
    required String orderItemLocalId,
    required int optionServerId,
    required String optionNameSnapshot,
    required double price,
    String? parentNameSnapshot,
  }) {
    return LocalOrderItemOptionsCompanion.insert(
      localId: localId,
      orderItemLocalId: orderItemLocalId,
      optionServerId: optionServerId,
      optionNameSnapshot: optionNameSnapshot,
      price: Value(price),
      createdAtLocal: DateTime.now(),
      parentNameSnapshot: Value(parentNameSnapshot),
    );
  }
}

Map<String, dynamic> mapLocalOrderToProcessItem(LocalOrder row) {
  final snapshot =
      row.orderSnapshotJson != null && row.orderSnapshotJson!.isNotEmpty
          ? Map<String, dynamic>.from(jsonDecode(row.orderSnapshotJson!))
          : <String, dynamic>{};

  final merged = <String, dynamic>{
    ...snapshot,
    'id': row.serverId ?? snapshot['id'] ?? -DateTime.now().millisecondsSinceEpoch,
    'local_id': row.localId,
    'is_local_only': true,
    'has_backend_record': row.serverId != null,
    'booking_order_code':
        row.serverOrderCode ?? row.clientOrderCode ?? snapshot['booking_order_code'],
    'customer_name': row.customerName,
    'payment_method': row.paymentMethodEffective ?? row.paymentMethodSelected,
    'openbill_flag': (row.paymentMethodSelected ?? row.paymentMethodEffective) == 'OPENBILL',
    'order_status': row.orderStatusLocal,
    'total_order_value': row.subtotal,
    'ppn': row.ppnPercent,
    'is_ppn_active': row.isPpnActive,
    'grand_total_local': row.grandTotal,
    'payment_confirmed_at_local':
        row.paymentConfirmedAtLocal?.toIso8601String(),
    'created_at': snapshot['created_at'] ?? row.createdAtLocal.toIso8601String(),
    'updated_at_local': row.updatedAtLocal.toIso8601String(),
    'sync_status': row.syncStatus,
    'last_error': row.lastError,
    'pending_sync': row.syncStatus != 'SYNCED',
  };

  return merged;
}
