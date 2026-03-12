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
}