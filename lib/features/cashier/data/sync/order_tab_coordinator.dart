import '/core/network/api_debug_log.dart';
import '/features/cashier/data/local/db/daos/booking_orders_dao.dart';
import '/features/cashier/data/sync/legacy_cache_bridge.dart';
import '/features/cashier/presentation/providers/done_provider.dart';
import '/features/cashier/presentation/providers/payment_provider.dart';
import '/features/cashier/presentation/providers/process_provider.dart';

/// Keeps booking_orders mirror, legacy tab caches, and UI providers in sync
/// after a local stage transition (pay / process / finish).
class OrderTabCoordinator {
  OrderTabCoordinator({
    required this.bookingOrdersDao,
    required this.bridge,
  });

  final BookingOrdersDao bookingOrdersDao;
  final LegacyCacheBridge bridge;

  Future<void> transitionOrderStage({
    required int serverId,
    required String orderStatus,
    String? syncIntent,
    bool syncDirty = false,
    Map<String, dynamic>? extras,
    Map<String, dynamic>? orderSnapshot,
  }) async {
    if (orderSnapshot != null) {
      await bookingOrdersDao.ensureFromUiMap(orderSnapshot, serverId: serverId);
    }

    final updated = await bookingOrdersDao.applyLocalStageByServerId(
      serverId: serverId,
      orderStatus: orderStatus,
      syncIntent: syncIntent,
      syncDirty: syncDirty,
      extras: extras,
    );

    if (!updated && orderSnapshot != null) {
      await bookingOrdersDao.ensureFromUiMap(
        {
          ...orderSnapshot,
          'order_status': orderStatus,
        },
        serverId: serverId,
      );
      await bookingOrdersDao.applyLocalStageByServerId(
        serverId: serverId,
        orderStatus: orderStatus,
        syncIntent: syncIntent,
        syncDirty: syncDirty,
        extras: extras,
      );
    }

    await bridge.refreshAll();
    ApiDebugLog.sync(
      'OrderTabCoordinator stage transition',
      'serverId=$serverId status=$orderStatus syncDirty=$syncDirty intent=$syncIntent',
    );
  }

  Future<void> reloadAllTabs({
    required PaymentProvider payment,
    required ProcessProvider process,
    required DoneProvider done,
    bool silent = true,
  }) async {
    await payment.load(silent: silent);
    await Future.wait([
      process.load(silent: silent),
      done.load(silent: silent),
    ]);
  }

  Future<void> transitionAndReload({
    required int serverId,
    required String orderStatus,
    required PaymentProvider payment,
    required ProcessProvider process,
    required DoneProvider done,
    String? syncIntent,
    bool syncDirty = false,
    Map<String, dynamic>? extras,
    Map<String, dynamic>? orderSnapshot,
    bool silent = true,
  }) async {
    await transitionOrderStage(
      serverId: serverId,
      orderStatus: orderStatus,
      syncIntent: syncIntent,
      syncDirty: syncDirty,
      extras: extras,
      orderSnapshot: orderSnapshot,
    );
    await reloadAllTabs(
      payment: payment,
      process: process,
      done: done,
      silent: silent,
    );
  }
}
