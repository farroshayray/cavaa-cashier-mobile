import '/core/network/api_debug_log.dart';
import '/features/cashier/data/local/db/cashier_db.dart';
import '/features/cashier/data/local/db/daos/booking_orders_dao.dart';
import '/features/cashier/data/local/db/daos/cached_done_orders_dao.dart';
import '/features/cashier/data/local/db/daos/cached_payment_orders_dao.dart';
import '/features/cashier/data/local/db/daos/cached_process_orders_dao.dart';
import '/features/cashier/data/local/db/daos/local_orders_dao.dart';
import '/features/cashier/data/sync/legacy_cache_bridge.dart';
import '/features/cashier/data/sync/local_to_mirror_migrator.dart';
import '/features/cashier/data/sync/sync_api.dart';
import '/features/cashier/data/sync/sync_engine.dart';

/// Backward-compatible sync entry point used by UI tabs.
class SyncService {
  SyncService({
    required LocalOrdersDao localOrdersDao,
    required CachedPaymentOrdersDao cachedPaymentOrdersDao,
    required CachedProcessOrdersDao cachedProcessOrdersDao,
    required CachedDoneOrdersDao cachedDoneOrdersDao,
    required BookingOrdersDao bookingOrdersDao,
    required SyncApi syncApi,
    required CashierDb db,
  })  : _localOrdersDao = localOrdersDao,
        _cachedPaymentOrdersDao = cachedPaymentOrdersDao,
        _cachedProcessOrdersDao = cachedProcessOrdersDao,
        _cachedDoneOrdersDao = cachedDoneOrdersDao,
        _engine = SyncEngine(
          bookingOrdersDao: bookingOrdersDao,
          syncApi: syncApi,
          db: db,
        ),
        _bridge = LegacyCacheBridge(db: db, bookingOrdersDao: bookingOrdersDao),
        _migrator = LocalToMirrorMigrator(
          db: db,
          bookingOrdersDao: bookingOrdersDao,
          localOrdersDao: localOrdersDao,
          cachedProcessOrdersDao: cachedProcessOrdersDao,
        );

  final LocalOrdersDao _localOrdersDao;
  final CachedPaymentOrdersDao _cachedPaymentOrdersDao;
  final CachedProcessOrdersDao _cachedProcessOrdersDao;
  final CachedDoneOrdersDao _cachedDoneOrdersDao;
  final SyncEngine _engine;
  final LegacyCacheBridge _bridge;
  final LocalToMirrorMigrator _migrator;

  bool get isRunning => _engine.isRunning;

  Future<bool> hasPendingData() async {
    final legacy = await _localOrdersDao.getUnsyncedOrders();
    final legacyDeletes = await _localOrdersDao.getPendingDeleteOrders();
    final cachedDeletes = await _cachedPaymentOrdersDao.getPendingDeleteOrders();
    final pendingProcess = await _cachedProcessOrdersDao.getPendingProcessActions();
    final mirrorDirty = await _engine.hasPendingData();

    return legacy.isNotEmpty ||
        legacyDeletes.isNotEmpty ||
        cachedDeletes.isNotEmpty ||
        pendingProcess.isNotEmpty ||
        mirrorDirty;
  }

  Future<SyncResult> syncPendingOrders() async {
    ApiDebugLog.sync('SyncService.syncPendingOrders start');
    await _migrator.mirrorPendingToBookingOrders();
    final result = await _engine.syncAll();
    await _applyLocalSyncResults(result.rawResponse);
    await _bridge.refreshAll();

    if (!result.success && result.message != 'skipped') {
      ApiDebugLog.syncError('sync finished with issues', result.message);
    }

    ApiDebugLog.sync(
      'SyncService.syncPendingOrders done',
      'success=${result.success} applied=${result.appliedCount} '
      'conflicts=${result.conflictCount} errors=${result.errorCount}',
    );

    return result;
  }

  Future<void> _applyLocalSyncResults(Map<String, dynamic>? response) async {
    if (response == null) return;

    final applied = (response['applied'] as List?) ?? [];
    for (final raw in applied) {
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);
      final clientUuid = map['client_uuid']?.toString();
      if (clientUuid == null || clientUuid.isEmpty) continue;

      final serverId = (map['server_id'] as num?)?.toInt();
      final code = map['booking_order_code']?.toString();

      await _localOrdersDao.markOrderSynced(
        localId: clientUuid,
        serverId: serverId,
        serverOrderCode: code,
      );

      ApiDebugLog.sync(
        'local_orders marked SYNCED',
        'clientUuid=$clientUuid serverId=$serverId code=$code',
      );
    }

    final errors = (response['errors'] as List?) ?? [];
    for (final raw in errors) {
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);
      final clientUuid = map['client_uuid']?.toString();
      final message = map['message']?.toString() ?? 'Sync gagal';
      if (clientUuid == null || clientUuid.isEmpty) continue;

      await _localOrdersDao.markOrderPending(
        clientUuid,
        error: message,
      );

      ApiDebugLog.syncError(
        'local_orders marked PENDING',
        'clientUuid=$clientUuid error=$message',
      );
    }
  }

  Future<void> clearCashierSessionData() async {
    await _cachedPaymentOrdersDao.clearAll();
    await _cachedProcessOrdersDao.clearAll();
    await _cachedDoneOrdersDao.clearAll();
    await _localOrdersDao.clearAll();
  }
}
