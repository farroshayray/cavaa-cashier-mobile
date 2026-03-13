import 'package:drift/drift.dart';
import '/features/cashier/data/local/db/cashier_db.dart';

class LocalOrderBundle {
  final LocalOrder order;
  final List<LocalOrderItem> items;
  final Map<String, List<LocalOrderItemOption>> optionsByItemId;

  LocalOrderBundle({
    required this.order,
    required this.items,
    required this.optionsByItemId,
  });
}

class LocalOrdersDao {
  final CashierDb db;

  LocalOrdersDao(this.db);

  Future<void> createOrder(LocalOrdersCompanion order) {
    return db.into(db.localOrders).insert(order);
  }

  Future<void> createItem(LocalOrderItemsCompanion item) {
    return db.into(db.localOrderItems).insert(item);
  }

  Future<void> createOption(LocalOrderItemOptionsCompanion option) {
    return db.into(db.localOrderItemOptions).insert(option);
  }

  Future<void> createOrderWithItems({
    required LocalOrdersCompanion order,
    required List<LocalOrderItemsCompanion> items,
    required Map<String, List<LocalOrderItemOptionsCompanion>> itemOptions,
  }) async {
    await db.transaction(() async {
      await createOrder(order);

      for (final item in items) {
        await createItem(item);

        final itemLocalId = item.localId.value;
        if (itemLocalId == null) continue;

        final options = itemOptions[itemLocalId] ?? const [];
        for (final opt in options) {
          await createOption(opt);
        }
      }
    });
  }

  Future<List<LocalOrder>> getPendingOrders() {
    return (db.select(db.localOrders)
          ..where((tbl) => tbl.orderStatusLocal.equals('UNPAID')))
        .get();
  }

  Future<List<LocalOrder>> getUnsyncedOrders() {
    return (db.select(db.localOrders)
          ..where((tbl) => tbl.syncStatus.equals('PENDING'))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAtLocal)]))
        .get();
  }

  Future<List<LocalOrder>> getUnpaidOrders({
    String? query,
  }) async {
    final rows = await (db.select(db.localOrders)
          ..where((tbl) => tbl.orderStatusLocal.equals('UNPAID'))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAtLocal)]))
        .get();

    if (query == null || query.trim().isEmpty) return rows;

    final q = query.trim().toLowerCase();
    return rows.where((e) {
      return e.customerName.toLowerCase().contains(q) ||
          e.clientOrderCode.toLowerCase().contains(q) ||
          (e.tableNoSnapshot ?? '').toLowerCase().contains(q);
    }).toList();
  }

  Future<List<LocalOrderItem>> getItemsByOrderLocalId(String orderLocalId) {
    return (db.select(db.localOrderItems)
          ..where((tbl) => tbl.orderLocalId.equals(orderLocalId)))
        .get();
  }

  Future<List<LocalOrderItemOption>> getOptionsByOrderItemLocalId(String itemLocalId) {
    return (db.select(db.localOrderItemOptions)
          ..where((tbl) => tbl.orderItemLocalId.equals(itemLocalId)))
        .get();
  }

  Future<LocalOrderBundle?> getOrderBundle(String localOrderId) async {
    final order = await (db.select(db.localOrders)
          ..where((tbl) => tbl.localId.equals(localOrderId)))
        .getSingleOrNull();

    if (order == null) return null;

    final items = await getItemsByOrderLocalId(localOrderId);

    final optionsByItemId = <String, List<LocalOrderItemOption>>{};
    for (final item in items) {
      final opts = await getOptionsByOrderItemLocalId(item.localId);
      optionsByItemId[item.localId] = opts;
    }

    return LocalOrderBundle(
      order: order,
      items: items,
      optionsByItemId: optionsByItemId,
    );
  }

  Future<void> markOrderSyncing(String localId) async {
    await (db.update(db.localOrders)
          ..where((tbl) => tbl.localId.equals(localId)))
        .write(
      LocalOrdersCompanion(
        syncStatus: const Value('SYNCING'),
        lastError: const Value(null),
        updatedAtLocal: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markOrderPending(String localId, {String? error}) async {
    await (db.update(db.localOrders)
          ..where((tbl) => tbl.localId.equals(localId)))
        .write(
      LocalOrdersCompanion(
        syncStatus: const Value('PENDING'),
        lastError: Value(error),
        updatedAtLocal: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markOrderSynced({
    required String localId,
    int? serverId,
    String? serverOrderCode,
  }) async {
    await (db.update(db.localOrders)
          ..where((tbl) => tbl.localId.equals(localId)))
        .write(
      LocalOrdersCompanion(
        serverId: Value(serverId),
        serverOrderCode: Value(serverOrderCode),
        syncStatus: const Value('SYNCED'),
        syncedAt: Value(DateTime.now()),
        updatedAtLocal: Value(DateTime.now()),
        lastError: const Value(null),
      ),
    );
  }

  Future<void> deleteOrderByLocalId(String localId) async {
    await db.transaction(() async {
      final itemRows = await (db.select(db.localOrderItems)
            ..where((tbl) => tbl.orderLocalId.equals(localId)))
          .get();

      for (final item in itemRows) {
        await (db.delete(db.localOrderItemOptions)
              ..where((tbl) => tbl.orderItemLocalId.equals(item.localId)))
            .go();
      }

      await (db.delete(db.localOrderItems)
            ..where((tbl) => tbl.orderLocalId.equals(localId)))
          .go();

      await (db.delete(db.localOrders)
            ..where((tbl) => tbl.localId.equals(localId)))
          .go();
    });
  }

  Future<void> markOrderPendingDelete(String localId) async {
    await (db.update(db.localOrders)
          ..where((tbl) => tbl.localId.equals(localId)))
        .write(
      LocalOrdersCompanion(
        syncStatus: const Value('PENDING_DELETE'),
        updatedAtLocal: Value(DateTime.now()),
      ),
    );
  }

  Future<LocalOrder?> getOrderByLocalId(String localId) {
    return (db.select(db.localOrders)
          ..where((tbl) => tbl.localId.equals(localId)))
        .getSingleOrNull();
  }

  Future<List<LocalOrder>> getPendingDeleteOrders() {
    return (db.select(db.localOrders)
          ..where((tbl) => tbl.syncStatus.equals('PENDING_DELETE'))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.updatedAtLocal)]))
        .get();
  }

  Future<void> clearPendingDeleteOrder(String localId) async {
    await deleteOrderByLocalId(localId);
  }

  Future<Map<String, dynamic>?> getOrderDetailMapByLocalId(String localId) async {
    final bundle = await getOrderBundle(localId);
    if (bundle == null) return null;

    final order = bundle.order;

    final orderDetails = bundle.items.map((item) {
      final opts = bundle.optionsByItemId[item.localId] ?? const <LocalOrderItemOption>[];

      return <String, dynamic>{
        'id': null,
        'product_id': item.productServerId,
        'quantity': item.qty,
        'base_price': 0,
        'promo_amount': 0,
        'product_name': 'Produk',
        'customer_note': item.customerNote,
        'order_detail_options': opts.map((o) {
          return <String, dynamic>{
            'price': 0,
            'option': {
              'id': o.optionServerId,
              'name': 'Opsi',
              'parent': {
                'name': 'Opsi',
              },
            },
          };
        }).toList(),
      };
    }).toList();

    return <String, dynamic>{
      'id': order.serverId ?? -1,
      'local_id': order.localId,
      'booking_order_code': order.serverOrderCode ?? order.clientOrderCode,
      'customer_name': order.customerName,
      'order_status': order.orderStatusLocal,
      'payment_method':
          order.paymentMethodEffective ?? order.paymentMethodSelected ?? 'CASH',
      'total_order_value': order.subtotal,
      'ppn': order.ppnPercent,
      'is_ppn_active': order.isPpnActive,
      'grand_total': order.grandTotal,
      'is_local_only': true,
      'sync_status': order.syncStatus,
      'table': {
        'table_no': order.tableNoSnapshot ?? '-',
      },
      'payment': {
        'note': '',
      },
      'order_details': orderDetails,
    };
  }

  Future<void> markOrderPaidOffline({
    required String localId,
    required num paidAmount,
    required num changeAmount,
    String? cashierProofImagePath,
    String? lastPaymentId,
  }) async {
    await (db.update(db.localOrders)
          ..where((tbl) => tbl.localId.equals(localId)))
        .write(
      LocalOrdersCompanion(
        orderStatusLocal: const Value('PAID'),
        syncStatus: const Value('PENDING_PAYMENT'),
        updatedAtLocal: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markOrderProcessedOffline(String localId) async {
    await (db.update(db.localOrders)
          ..where((tbl) => tbl.localId.equals(localId)))
        .write(
      LocalOrdersCompanion(
        orderStatusLocal: const Value('PROCESSED'),
        syncStatus: const Value('PENDING_PROCESS'),
        updatedAtLocal: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markOrderFinishedOffline(String localId) async {
    await (db.update(db.localOrders)
          ..where((tbl) => tbl.localId.equals(localId)))
        .write(
      LocalOrdersCompanion(
        orderStatusLocal: const Value('SERVED'),
        syncStatus: const Value('PENDING_FINISH'),
        updatedAtLocal: Value(DateTime.now()),
      ),
    );
  }

  Future<List<LocalOrder>> getOrdersBySyncStatus(String syncStatus) {
    return (db.select(db.localOrders)
          ..where((tbl) => tbl.syncStatus.equals(syncStatus))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.updatedAtLocal)]))
        .get();
  }

  Future<void> createShadowOrderFromServerPayment({
    required int serverId,
    required String bookingOrderCode,
    required String customerName,
    required String tableNoSnapshot,
    required String paymentMethodEffective,
    required double subtotal,
    required double grandTotal,
    required bool isPpnActive,
    required double ppnPercent,
    required double paidAmount,
    required double changeAmount,
    String? cashierProofImagePath,
    String? lastPaymentId,
  }) async {
    final localId = 'shadow_pay_$serverId';

    final existing = await getOrderByLocalId(localId);
    if (existing != null) {
      await markOrderPaidOffline(
        localId: localId,
        paidAmount: paidAmount,
        changeAmount: changeAmount,
        cashierProofImagePath: cashierProofImagePath,
        lastPaymentId: lastPaymentId,
      );
      return;
    }

    await createOrder(
      LocalOrdersCompanion(
        localId: Value(localId),
        clientOrderCode: Value(bookingOrderCode),
        customerName: Value(customerName),
        partnerName: const Value(''),
        tableNoSnapshot: Value(tableNoSnapshot),
        tableServerId: const Value(null),
        paymentMethodSelected: Value(paymentMethodEffective),
        paymentMethodEffective: Value(paymentMethodEffective),
        subtotal: Value(subtotal),
        grandTotal: Value(grandTotal),
        isPpnActive: Value(isPpnActive),
        ppnPercent: Value(ppnPercent),
        orderStatusLocal: const Value('PAID'),
        syncStatus: const Value('PENDING_PAYMENT'),
        createdAtLocal: Value(DateTime.now()),
        updatedAtLocal: Value(DateTime.now()),
        serverId: Value(serverId),
        serverOrderCode: Value(bookingOrderCode),
      ),
    );
  }
}