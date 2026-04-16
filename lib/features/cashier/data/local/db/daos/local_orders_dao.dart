import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import '/features/cashier/data/local/db/cashier_db.dart';
import '/features/cashier/data/local/db/daos/cached_payment_methods_dao.dart';

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

  Future<List<LocalOrder>> getUnsyncedOrders() async {
    final rows = await (db.select(db.localOrders)
          ..where((tbl) => tbl.syncStatus.isIn([
                'PENDING',
                'PENDING_PAYMENT',
                'PENDING_PROCESS',
                'PENDING_FINISH',
                'FAILED',
                'SYNCING',
              ]))
          ..orderBy([
            (tbl) => OrderingTerm.asc(tbl.createdAtLocal),
          ]))
        .get();

    debugPrint('📚 getUnsyncedOrders result count=${rows.length}');
    for (final row in rows) {
      debugPrint(
        '   -> localId=${row.localId} '
        'serverId=${row.serverId} '
        'orderStatus=${row.orderStatusLocal} '
        'syncStatus=${row.syncStatus} '
        'backendStage=${row.backendSyncStage} '
        'serverCode=${row.serverOrderCode} '
        'clientCode=${row.clientOrderCode}',
      );
    }

    return rows;
  }

  Future<List<LocalOrder>> getUnpaidOrders({
    String? query,
  }) async {
    final rows = await (db.select(db.localOrders)
          ..where((tbl) =>
              tbl.orderStatusLocal.equals('UNPAID') &
              (
                tbl.syncStatus.equals('PENDING') |
                tbl.syncStatus.equals('FAILED') |
                tbl.syncStatus.equals('SYNCING') |
                tbl.syncStatus.equals('PENDING_PAYMENT') |
                tbl.syncStatus.equals('PENDING_PROCESS') |
                tbl.syncStatus.equals('PENDING_FINISH')
              ))
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
    final current = await getOrderByLocalId(localId);
    if (current == null) return;

    await (db.update(db.localOrders)
          ..where((tbl) => tbl.localId.equals(localId)))
        .write(
      LocalOrdersCompanion(
        syncStatus: Value(
          current.syncStatus == 'SYNCING' ? 'FAILED' : current.syncStatus,
        ),
        lastError: Value(error),
        updatedAtLocal: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markOrderStockConflict(String localId, {String? error}) async {
    await (db.update(db.localOrders)..where((tbl) => tbl.localId.equals(localId)))
        .write(
      LocalOrdersCompanion(
        syncStatus: const Value('STOCK_CONFLICT'),
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
    debugPrint(
      '📝 markOrderSynced localId=$localId '
      'serverId=$serverId '
      'serverOrderCode=$serverOrderCode',
    );

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

  Future<void> clearAll() async {
    await db.transaction(() async {
      await db.delete(db.localOrderItemOptions).go();
      await db.delete(db.localOrderItems).go();
      await db.delete(db.localOrders).go();
    });
  }

  Future<Map<String, dynamic>?> getOrderDetailMapByLocalId(String localId) async {
    
    final bundle = await getOrderBundle(localId);
    if (bundle == null) return null;

    final order = bundle.order;

    if (order.orderSnapshotJson != null && order.orderSnapshotJson!.trim().isNotEmpty) {
      final decoded = jsonDecode(order.orderSnapshotJson!);
      if (decoded is Map) {
        final snap = Map<String, dynamic>.from(decoded);

        final rebuiltOrderDetails = bundle.items.map((item) {
          final opts = bundle.optionsByItemId[item.localId] ?? const <LocalOrderItemOption>[];

          return <String, dynamic>{
            'id': null,
            'product_id': item.productServerId,
            'quantity': item.qty,
            'base_price': item.basePrice,
            'promo_amount': item.promoAmount ?? 0,
            'product_name': item.productNameSnapshot,
            'customer_note': item.customerNote,
            'partner_product': {
              'id': item.productServerId,
              'name': item.productNameSnapshot,
              'category': {
                'id': item.categoryServerId,
                'category_name': item.categoryNameSnapshot ?? 'Tanpa Kategori',
              },
            },
            'category_name': item.categoryNameSnapshot ?? 'Tanpa Kategori',
            'order_detail_options': opts.map((o) {
              return <String, dynamic>{
                'price': o.price,
                'option': {
                  'id': o.optionServerId,
                  'name': o.optionNameSnapshot,
                  'parent': {
                    'name': o.parentNameSnapshot ?? 'Opsi',
                  },
                },
              };
            }).toList(),
          };
        }).toList();

        snap['id'] = order.serverId ?? snap['id'] ?? -1;
        snap['local_id'] = order.localId;
        snap['booking_order_code'] =
            order.serverOrderCode ?? order.clientOrderCode ?? snap['booking_order_code'];
        snap['customer_name'] = order.customerName;
        snap['order_status'] = order.orderStatusLocal;
        snap['payment_method'] =
            order.paymentMethodEffective ?? order.paymentMethodSelected ?? 'CASH';
        snap['total_order_value'] = order.subtotal;
        snap['ppn'] = order.ppnPercent;
        snap['is_ppn_active'] = order.isPpnActive;
        snap['grand_total'] = order.grandTotal;
        snap['is_local_only'] = true;
        snap['sync_status'] = order.syncStatus;
        snap['table'] ??= {
          'table_no': order.tableNoSnapshot ?? '-',
        };

        final payment = snap['payment'] is Map
            ? Map<String, dynamic>.from(snap['payment'])
            : <String, dynamic>{};

        payment['updated_at'] ??= order.paymentConfirmedAtLocal?.toIso8601String();
        payment['paid_amount'] ??= order.paidAmountLocal;
        payment['change_amount'] ??= order.changeAmountLocal;
        snap['payment'] = payment;

        snap['order_details'] = rebuiltOrderDetails;

        return snap;
      }
    }

    Map<String, dynamic>? latestPayment;
    if (order.manualPaymentRawJson != null &&
        order.manualPaymentRawJson!.trim().isNotEmpty) {
      final decoded = jsonDecode(order.manualPaymentRawJson!);
      if (decoded is Map) {
        final raw = Map<String, dynamic>.from(decoded);

        final paymentMethod =
            order.paymentMethodEffective ?? order.paymentMethodSelected ?? 'CASH';

        final cachedManual = await CachedPaymentMethodsDao(db).buildManualPaymentMap(
          serverManualPaymentId: _toInt(raw['id']),
          paymentMethod: paymentMethod,
        );
        debugPrint('manual raw = $raw');
        debugPrint('cachedManual = $cachedManual');
        debugPrint('qris_image_url = ${cachedManual?['qris_image_url']}');
        debugPrint('qris_image_local_path = ${cachedManual?['qris_image_local_path']}');

        latestPayment = {
          'owner_manual_payment': {
            'id': raw['id'] ?? cachedManual?['server_manual_payment_id'],
            'payment_type': raw['payment_type'] ?? cachedManual?['payment_type'],
            'provider_name': raw['provider_name'] ?? cachedManual?['provider_name'],
            'provider_account_name':
                raw['provider_account_name'] ?? cachedManual?['provider_account_name'],
            'provider_account_no':
                raw['provider_account_no'] ?? cachedManual?['provider_account_no'],
            'qris_image_url': raw['qris_image_url'] ?? cachedManual?['qris_image_url'],
            'qris_image_local_path':
                raw['qris_image_local_path'] ?? cachedManual?['qris_image_local_path'],
          }
        };
      }
    }

    final orderDetails = bundle.items.map((item) {
      final opts = bundle.optionsByItemId[item.localId] ?? const <LocalOrderItemOption>[];

      return <String, dynamic>{
        'id': null,
        'product_id': item.productServerId,
        'quantity': item.qty,
        'base_price': item.basePrice,
        'promo_amount': item.promoAmount ?? 0,
        'product_name': item.productNameSnapshot,
        'customer_note': item.customerNote,

        // tambahkan struktur mirip API
        'partner_product': {
          'id': item.productServerId,
          'name': item.productNameSnapshot,
          'category': {
            'id': item.categoryServerId,
            'category_name': item.categoryNameSnapshot ?? 'Tanpa Kategori',
          },
        },
        'category_name': item.categoryNameSnapshot ?? 'Tanpa Kategori',

        // optional: cadangan kalau printer baca field datar
        'category_name': item.categoryNameSnapshot ?? 'Tanpa Kategori',

        'order_detail_options': opts.map((o) {
          return <String, dynamic>{
            'price': o.price,
            'option': {
              'id': o.optionServerId,
              'name': o.optionNameSnapshot,
              'parent': {
                'name': o.parentNameSnapshot ?? 'Opsi',
              },
            },
          };
        }).toList(),
      };
    }).toList();

    return <String, dynamic>{
      'id': order.serverId ?? -1,
      'local_id': order.localId,
      'booking_order_code': order.serverOrderCode ?? order.clientOrderCode ?? '-',
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
      'payment_request': null,
      'latest_payment': latestPayment,
      'table': {
        'table_no': order.tableNoSnapshot ?? '-',
      },
      'payment': {
        'note': '',
        'updated_at': order.paymentConfirmedAtLocal?.toIso8601String(),
        'paid_amount': order.paidAmountLocal,
        'change_amount': order.changeAmountLocal,
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
        backendSyncStage: const Value('PURCHASED'),
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

  Future<List<LocalOrder>> getLocalProcessOrders() {
    return (db.select(db.localOrders)
          ..where((t) =>
              t.orderStatusLocal.isIn(['PAID', 'PROCESSED']) &
              t.syncStatus.isIn([
                'PENDING',
                'PENDING_PAYMENT',
                'PENDING_PROCESS',
                'FAILED',
                'SYNCING',
              ]))
          ..orderBy([
            (t) => OrderingTerm.asc(t.createdAtLocal),
          ]))
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
        backendSyncStage: const Value('PURCHASED'),
        createdAtLocal: Value(DateTime.now()),
        updatedAtLocal: Value(DateTime.now()),
        serverId: Value(serverId),
        serverOrderCode: Value(bookingOrderCode),
      ),
    );
  }

  Future<void> markPaymentConfirmedOffline({
    required String localId,
    required double paidAmount,
    required double changeAmount,
    String? cashierProofImageLocalPath,
    DateTime? paymentConfirmedAtLocal,
    int? latestPaymentServerId,
    String? orderSnapshotJson,
  }) async {
    await (db.update(db.localOrders)..where((t) => t.localId.equals(localId))).write(
      LocalOrdersCompanion(
        paidAmountLocal: Value(paidAmount),
        changeAmountLocal: Value(changeAmount),
        cashierProofImageLocalPath: Value(cashierProofImageLocalPath),
        paymentConfirmedAtLocal: Value(paymentConfirmedAtLocal ?? DateTime.now()),
        latestPaymentServerId: Value(latestPaymentServerId),
        orderSnapshotJson: Value(orderSnapshotJson),
        orderStatusLocal: const Value('PAID'),
        syncStatus: const Value('PENDING_PAYMENT'),
        updatedAtLocal: Value(DateTime.now()),
        lastError: const Value(null),
      ),
    );
  }

  Future<List<LocalOrder>> getLocallyAdvancedServerOrders() {
    return (db.select(db.localOrders)
          ..where((t) =>
              t.serverId.isNotNull() &
              t.orderStatusLocal.isIn(['PAID', 'PROCESSED', 'SERVED'])))
        .get();
  }

  Future<void> attachServerIdentity({
    required String localId,
    required int serverId,
    String? serverOrderCode,
  }) async {
    await (db.update(db.localOrders)
          ..where((tbl) => tbl.localId.equals(localId)))
        .write(
      LocalOrdersCompanion(
        serverId: Value(serverId),
        serverOrderCode: Value(serverOrderCode),
        updatedAtLocal: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateBackendSyncStage(String localId, String stage) async {
    await (db.update(db.localOrders)
          ..where((t) => t.localId.equals(localId)))
        .write(
      LocalOrdersCompanion(
        backendSyncStage: Value(stage),
        updatedAtLocal: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateOrderStatusLocal({
    required String localId,
    required String status,
  }) {
    String syncStatus = 'PENDING';

    if (status == 'PAID') {
      syncStatus = 'PENDING_PAYMENT';
    } else if (status == 'PROCESSED') {
      syncStatus = 'PENDING_PROCESS';
    } else if (status == 'SERVED') {
      syncStatus = 'PENDING_FINISH';
    }

    return (db.update(db.localOrders)..where((t) => t.localId.equals(localId))).write(
      LocalOrdersCompanion(
        orderStatusLocal: Value(status),
        syncStatus: Value(syncStatus),
        updatedAtLocal: Value(DateTime.now()),
        lastError: const Value(null),
      ),
    );
  }

  Future<List<LocalOrder>> getLocalDoneOrders() {
    return (db.select(db.localOrders)
          ..where((t) =>
              t.orderStatusLocal.equals('SERVED') &
              t.syncStatus.isIn([
                'PENDING_FINISH',
                'FAILED',
                'SYNCING',
              ]))
          ..orderBy([
            (t) => OrderingTerm.asc(t.createdAtLocal),
          ]))
        .get();
  }

  Future<LocalOrder?> getOrderByServerId(int serverId) {
    return (db.select(db.localOrders)
          ..where((t) => t.serverId.equals(serverId)))
        .getSingleOrNull();
  }

  Future<void> updateOrderStatusByServerId({
    required int serverId,
    required String status,
  }) async {
    String syncStatus = 'SYNCED';
    String backendStage = 'NONE';

    if (status == 'UNPAID') {
      backendStage = 'PURCHASED';
    } else if (status == 'PAID') {
      backendStage = 'PAID';
    } else if (status == 'PROCESSED') {
      backendStage = 'PROCESSED';
    } else if (status == 'SERVED') {
      backendStage = 'SERVED';
    }

    await (db.update(db.localOrders)
          ..where((t) => t.serverId.equals(serverId)))
        .write(
      LocalOrdersCompanion(
        orderStatusLocal: Value(status),
        syncStatus: Value(syncStatus),
        backendSyncStage: Value(backendStage),
        updatedAtLocal: Value(DateTime.now()),
        lastError: const Value(null),
      ),
    );
  }

  Future<void> deleteOrderByServerId(int serverId) async {
    final row = await getOrderByServerId(serverId);
    if (row == null) return;
    await deleteOrderByLocalId(row.localId);
  }

  Future<List<LocalOrder>> getAllActiveOrders() {
    return (db.select(db.localOrders)
          ..where((t) => t.syncStatus.equals('PENDING_DELETE').not())
          ..orderBy([(t) => OrderingTerm.asc(t.createdAtLocal)]))
        .get();
  }

  Future<LocalOrder?> findByServerOrderCode(String code) {
    return (db.select(db.localOrders)
          ..where((t) => t.serverOrderCode.equals(code)))
        .getSingleOrNull();
  }

  Future<void> updateOrderStatusByLocalId({
    required String localId,
    required String status,
    String? syncStatus,
    String? backendStage,
  }) async {
    await (db.update(db.localOrders)
          ..where((t) => t.localId.equals(localId)))
        .write(
      LocalOrdersCompanion(
        orderStatusLocal: Value(status),
        syncStatus: syncStatus != null ? Value(syncStatus) : const Value.absent(),
        backendSyncStage:
            backendStage != null ? Value(backendStage) : const Value.absent(),
        updatedAtLocal: Value(DateTime.now()),
        lastError: const Value(null),
      ),
    );
  }
}


int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  return int.tryParse(v.toString());
}
