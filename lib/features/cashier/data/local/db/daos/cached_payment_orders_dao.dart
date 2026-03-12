import 'package:drift/drift.dart';
import '/features/cashier/data/local/db/cashier_db.dart';

class CachedPaymentOrdersDao {
  final CashierDb db;

  CachedPaymentOrdersDao(this.db);

  Future<void> replaceAllOrders({
    required List<CachedPaymentOrdersCompanion> orders,
  }) async {
    await db.transaction(() async {
      await db.delete(db.cachedPaymentOrderItemOptions).go();
      await db.delete(db.cachedPaymentOrderItems).go();
      await db.delete(db.cachedPaymentOrders).go();

      if (orders.isNotEmpty) {
        await db.batch((batch) {
          batch.insertAll(db.cachedPaymentOrders, orders);
        });
      }
    });
  }

  Future<List<CachedPaymentOrder>> getCachedOrders({
    String? query,
  }) async {
    final rows = await (db.select(db.cachedPaymentOrders)
          ..orderBy([
            (tbl) => OrderingTerm.desc(tbl.createdAt),
            (tbl) => OrderingTerm.desc(tbl.cachedAt),
          ]))
        .get();

    if (query == null || query.trim().isEmpty) return rows;

    final q = query.trim().toLowerCase();

    return rows.where((e) {
      return e.customerName.toLowerCase().contains(q) ||
          e.bookingOrderCode.toLowerCase().contains(q) ||
          (e.tableNo ?? '').toLowerCase().contains(q);
    }).toList();
  }

  Future<void> deleteCachedOrderByServerId(int serverId) async {
    await db.transaction(() async {
      await (db.delete(db.cachedPaymentOrderItemOptions)
            ..where((tbl) => tbl.orderDetailServerId.isInQuery(
                  db.selectOnly(db.cachedPaymentOrderItems)
                    ..addColumns([db.cachedPaymentOrderItems.serverDetailId])
                    ..where(db.cachedPaymentOrderItems.orderServerId.equals(serverId)),
                )))
          .go();

      await (db.delete(db.cachedPaymentOrderItems)
            ..where((tbl) => tbl.orderServerId.equals(serverId)))
          .go();

      await (db.delete(db.cachedPaymentOrders)
            ..where((tbl) => tbl.serverId.equals(serverId)))
          .go();
    });
  }

  Future<void> deleteByServerId(int serverId) async {
    await (db.delete(db.cachedPaymentOrders)
          ..where((tbl) => tbl.serverId.equals(serverId)))
        .go();
  }

  Future<void> markPendingDelete(int serverId) async {
    await (db.update(db.cachedPaymentOrders)
          ..where((tbl) => tbl.serverId.equals(serverId)))
        .write(
      const CachedPaymentOrdersCompanion(
        isPendingDelete: Value(true),
      ),
    );
  }

  Future<List<CachedPaymentOrder>> getPendingDeleteOrders() {
    return (db.select(db.cachedPaymentOrders)
          ..where((tbl) => tbl.isPendingDelete.equals(true))
          ..orderBy([
            (tbl) => OrderingTerm.asc(tbl.cachedAt),
          ]))
        .get();
  }
}