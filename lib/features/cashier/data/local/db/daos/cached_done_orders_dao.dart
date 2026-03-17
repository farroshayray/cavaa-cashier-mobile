import 'package:drift/drift.dart';
import '../cashier_db.dart';
import '../tables/cached_done_orders_table.dart';

part 'cached_done_orders_dao.g.dart';

@DriftAccessor(tables: [CachedDoneOrders])
class CachedDoneOrdersDao extends DatabaseAccessor<CashierDb>
    with _$CachedDoneOrdersDaoMixin {
  CachedDoneOrdersDao(super.db);

  Future<List<CachedDoneOrder>> getAllActive() {
    return (select(cachedDoneOrders)
          ..where((t) => t.deletedLocally.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.serverId)]))
        .get();
  }

  Future<CachedDoneOrder?> findByServerId(int serverId) {
    return (select(cachedDoneOrders)
          ..where((t) => t.serverId.equals(serverId)))
        .getSingleOrNull();
  }

  Stream<List<CachedDoneOrder>> watchAllActive() {
    return (select(cachedDoneOrders)
          ..where((t) => t.deletedLocally.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.serverId)]))
        .watch();
  }

  Future<void> upsertRow(CachedDoneOrdersCompanion row) {
    return into(cachedDoneOrders).insert(
      row,
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> mergeServerRows(List<CachedDoneOrdersCompanion> rows) async {
    await transaction(() async {
      for (final row in rows) {
        final serverId = row.serverId.value;
        if (serverId == null) continue;

        final existing = await findByServerId(serverId);

        await into(cachedDoneOrders).insert(
          CachedDoneOrdersCompanion(
            serverId: row.serverId,
            bookingOrderCode: row.bookingOrderCode,
            customerName: row.customerName,
            tableNo: row.tableNo,
            doneRequestJson: row.doneRequestJson,
            latestDoneJson: row.latestDoneJson,
            paymentMethod: row.paymentMethod,
            orderStatus: row.orderStatus,
            detailJson: existing != null
                ? Value(existing.detailJson)
                : const Value.absent(),
            subtotal: row.subtotal,
            ppnPercent: row.ppnPercent,
            isPpnActive: row.isPpnActive,
            isSynced: row.isSynced,
            deletedLocally: row.deletedLocally,
            syncedAt: row.syncedAt,
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> deleteByServerId(int serverId) {
    return (delete(cachedDoneOrders)
          ..where((t) => t.serverId.equals(serverId)))
        .go();
  }

  Future<void> clearAll() {
    return delete(cachedDoneOrders).go();
  }

  Future<void> saveDetailJson(int serverId, String detailJson) {
    return (update(cachedDoneOrders)
          ..where((t) => t.serverId.equals(serverId)))
        .write(
      CachedDoneOrdersCompanion(
        detailJson: Value(detailJson),
        syncedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> upsertPendingFinishFromProcess({
    required int serverId,
    required String bookingOrderCode,
    required String customerName,
    String? tableNo,
    String? paymentMethod,
    required double subtotal,
    required double ppnPercent,
    required bool isPpnActive,
    String? rawJson,
  }) {
    return into(cachedDoneOrders).insert(
      CachedDoneOrdersCompanion(
        serverId: Value(serverId),
        bookingOrderCode: Value(bookingOrderCode),
        customerName: Value(customerName),
        tableNo: Value(tableNo),
        doneRequestJson: Value(rawJson),
        latestDoneJson: Value(rawJson),
        paymentMethod: Value(paymentMethod),
        orderStatus: const Value('SERVED'),
        subtotal: Value(subtotal),
        ppnPercent: Value(ppnPercent),
        isPpnActive: Value(isPpnActive),
        isSynced: const Value(false),
        deletedLocally: const Value(false),
        syncedAt: Value(DateTime.now()),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> markSyncedByServerId(
    int serverId, {
    String? latestDoneJson,
  }) {
    return (update(cachedDoneOrders)
          ..where((t) => t.serverId.equals(serverId)))
        .write(
      CachedDoneOrdersCompanion(
        orderStatus: const Value('SERVED'),
        isSynced: const Value(true),
        latestDoneJson: latestDoneJson != null
            ? Value(latestDoneJson)
            : const Value.absent(),
        syncedAt: Value(DateTime.now()),
      ),
    );
  }
}