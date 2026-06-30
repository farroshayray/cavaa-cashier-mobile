import '/core/network/api_debug_log.dart';
import '/features/cashier/data/local/db/cashier_db.dart';
import '/features/cashier/data/local/db/daos/booking_orders_dao.dart';
import '/features/cashier/data/sync/sync_api.dart';
import '/features/cashier/data/sync/sync_engine.dart';

/// Unified sync entry point for cashier tabs.
class SyncService {
  SyncService({
    required BookingOrdersDao bookingOrdersDao,
    required SyncApi syncApi,
    required CashierDb db,
  })  : _bookingOrdersDao = bookingOrdersDao,
        _engine = SyncEngine(
          bookingOrdersDao: bookingOrdersDao,
          syncApi: syncApi,
          db: db,
        );

  final BookingOrdersDao _bookingOrdersDao;
  final SyncEngine _engine;

  bool get isRunning => _engine.isRunning;

  Future<void> ensureDeviceId() => _bookingOrdersDao.ensureDeviceId();

  Future<int> countUnresolvedConflicts() =>
      _bookingOrdersDao.countUnresolvedConflicts();

  Future<bool> hasPendingData() async {
    final mirrorDirty = await _engine.hasPendingData();
    final conflicts = await _bookingOrdersDao.countUnresolvedConflicts();
    return mirrorDirty || conflicts > 0;
  }

  Future<SyncResult> syncPendingOrders() async {
    ApiDebugLog.sync('SyncService.syncPendingOrders start');
    await _bookingOrdersDao.ensureDeviceId();
    final result = await _engine.syncAll();

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

  Future<void> clearCashierSessionData() async {
    await _bookingOrdersDao.clearSessionData(keepDeviceId: true);
  }
}
