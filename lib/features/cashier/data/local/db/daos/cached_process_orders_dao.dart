import 'package:drift/drift.dart';
import '../cashier_db.dart';
import '../tables/cached_process_orders_table.dart';

part 'cached_process_orders_dao.g.dart';

@DriftAccessor(tables: [CachedProcessOrders])
class CachedProcessOrdersDao extends DatabaseAccessor<CashierDb>
    with _$CachedProcessOrdersDaoMixin {
  CachedProcessOrdersDao(super.db);

  Future<List<CachedProcessOrder>> getAllActive() {
    return (select(cachedProcessOrders)
          ..where((t) => t.deletedLocally.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.serverId)]))
        .get();
  }

  Stream<List<CachedProcessOrder>> watchAllActive() {
    return (select(cachedProcessOrders)
          ..where((t) => t.deletedLocally.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.serverId)]))
        .watch();
  }

  Future<void> replaceAll(List<CachedProcessOrdersCompanion> rows) async {
    await transaction(() async {
      await delete(cachedProcessOrders).go();
      await batch((b) {
        b.insertAll(
          cachedProcessOrders,
          rows,
          mode: InsertMode.insertOrReplace,
        );
      });
    });
  }

  Future<void> upsertRow(CachedProcessOrdersCompanion row) {
    return into(cachedProcessOrders).insert(
      row,
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<CachedProcessOrder?> findByServerId(int serverId) {
    return (select(cachedProcessOrders)
          ..where((t) => t.serverId.equals(serverId)))
        .getSingleOrNull();
  }

  Future<List<CachedProcessOrder>> getPendingProcessActions() {
    return (select(cachedProcessOrders)
          ..where((t) =>
              t.pendingAction.isNotNull() & t.isSynced.equals(false)))
        .get();
  }

  Future<void> markProcessedOffline(int serverId, String latestJson) {
    return (update(cachedProcessOrders)
          ..where((t) => t.serverId.equals(serverId)))
        .write(
      CachedProcessOrdersCompanion(
        orderStatus: const Value('PROCESSED'),
        latestProcessJson: Value(latestJson),
        pendingAction: const Value('PROCESS'),
        isSynced: const Value(false),
        syncedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markSynced(int serverId, {String? latestJson}) {
    return (update(cachedProcessOrders)
          ..where((t) => t.serverId.equals(serverId)))
        .write(
      CachedProcessOrdersCompanion(
        pendingAction: const Value(null),
        isSynced: const Value(true),
        latestProcessJson:
            latestJson != null ? Value(latestJson) : const Value.absent(),
      ),
    );
  }

  Future<void> mergeServerRows(List<CachedProcessOrdersCompanion> rows) async {
    await transaction(() async {
      for (final row in rows) {
        final serverIdValue = row.serverId.value;
        if (serverIdValue == null) continue;

        final existing = await findByServerId(serverIdValue);

        // kalau ada perubahan lokal yang belum sync, jangan ditimpa server
        if (existing != null && existing.isSynced == false) {
          continue;
        }

        await into(cachedProcessOrders).insert(
          CachedProcessOrdersCompanion(
            serverId: row.serverId,
            bookingOrderCode: row.bookingOrderCode,
            customerName: row.customerName,
            tableNo: row.tableNo,
            processRequestJson: row.processRequestJson,
            latestProcessJson: row.latestProcessJson,
            detailJson: existing != null
                ? Value(existing.detailJson)
                : const Value.absent(),
            paymentMethod: row.paymentMethod,
            orderStatus: row.orderStatus,
            subtotal: row.subtotal,
            ppnPercent: row.ppnPercent,
            isPpnActive: row.isPpnActive,
            processedByKitchen: row.processedByKitchen,
            pendingAction: row.pendingAction,
            isSynced: row.isSynced,
            deletedLocally: row.deletedLocally,
            syncedAt: row.syncedAt,
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> markProcessedOnline(int serverId, {String? latestJson}) {
    return (update(cachedProcessOrders)
          ..where((t) => t.serverId.equals(serverId)))
        .write(
      CachedProcessOrdersCompanion(
        orderStatus: const Value('PROCESSED'),
        pendingAction: const Value(null),
        isSynced: const Value(true),
        latestProcessJson:
            latestJson != null ? Value(latestJson) : const Value.absent(),
        syncedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markCancelProcessOnline(int serverId, {String? latestJson}) {
    return (update(cachedProcessOrders)
          ..where((t) => t.serverId.equals(serverId)))
        .write(
      CachedProcessOrdersCompanion(
        orderStatus: const Value('PAID'),
        pendingAction: const Value(null),
        isSynced: const Value(true),
        latestProcessJson:
            latestJson != null ? Value(latestJson) : const Value.absent(),
        syncedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markFinishedOnline(int serverId, {String? latestJson}) {
    return (update(cachedProcessOrders)
          ..where((t) => t.serverId.equals(serverId)))
        .write(
      CachedProcessOrdersCompanion(
        orderStatus: const Value('SERVED'),
        pendingAction: const Value(null),
        isSynced: const Value(true),
        latestProcessJson:
            latestJson != null ? Value(latestJson) : const Value.absent(),
        syncedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markCancelProcessOffline(int serverId, String latestJson) {
    return (update(cachedProcessOrders)
          ..where((t) => t.serverId.equals(serverId)))
        .write(
      CachedProcessOrdersCompanion(
        orderStatus: const Value('PAID'),
        latestProcessJson: Value(latestJson),
        pendingAction: const Value('CANCEL_PROCESS'),
        isSynced: const Value(false),
        syncedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markFinishedOffline(int serverId, String latestJson) {
    return (update(cachedProcessOrders)
          ..where((t) => t.serverId.equals(serverId)))
        .write(
      CachedProcessOrdersCompanion(
        orderStatus: const Value('SERVED'),
        latestProcessJson: Value(latestJson),
        pendingAction: const Value('FINISH'),
        isSynced: const Value(false),
        syncedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteByServerId(int serverId) {
    return (delete(cachedProcessOrders)
          ..where((t) => t.serverId.equals(serverId)))
        .go();
  }

  Future<void> saveDetailJson(int serverId, String detailJson) {
    return (update(cachedProcessOrders)
          ..where((t) => t.serverId.equals(serverId)))
        .write(
      CachedProcessOrdersCompanion(
        detailJson: Value(detailJson),
        syncedAt: Value(DateTime.now()),
      ),
    );
  }
}