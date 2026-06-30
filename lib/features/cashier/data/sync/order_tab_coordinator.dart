import '/core/network/api_debug_log.dart';
import '/features/cashier/data/local/db/daos/booking_orders_dao.dart';
import '/features/cashier/presentation/providers/done_provider.dart';
import '/features/cashier/presentation/providers/payment_provider.dart';
import '/features/cashier/presentation/providers/process_provider.dart';

/// Keeps booking_orders mirror and UI providers in sync after stage transitions.
class OrderTabCoordinator {
  OrderTabCoordinator({
    required this.bookingOrdersDao,
  });

  final BookingOrdersDao bookingOrdersDao;

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

    ApiDebugLog.sync(
      'OrderTabCoordinator stage transition',
      'serverId=$serverId status=$orderStatus syncDirty=$syncDirty intent=$syncIntent',
    );
  }

  Future<void> transitionOrderStageByClientUuid({
    required String clientUuid,
    required String orderStatus,
    String? syncIntent,
    bool syncDirty = true,
    Map<String, dynamic>? extras,
  }) async {
    await bookingOrdersDao.markIntent(
      clientUuid,
      syncIntent ?? 'UPDATE',
      extras: {
        ...?extras,
        'order_status': orderStatus,
      },
    );
    ApiDebugLog.sync(
      'OrderTabCoordinator client transition',
      'clientUuid=$clientUuid status=$orderStatus syncDirty=$syncDirty intent=$syncIntent',
    );
  }

  Future<void> markOrderDeleted({
    int? serverId,
    String? clientUuid,
    bool hardRemove = false,
    DateTime? deletedAt,
  }) async {
    if (hardRemove && clientUuid != null && clientUuid.isNotEmpty) {
      await bookingOrdersDao.removeOrderMirrorByClientUuid(clientUuid);
    } else if (serverId != null && serverId > 0) {
      await bookingOrdersDao.markDeletedByServerId(serverId, deletedAt: deletedAt);
    } else if (clientUuid != null && clientUuid.isNotEmpty) {
      await bookingOrdersDao.removeOrderMirrorByClientUuid(clientUuid);
    }

    ApiDebugLog.sync(
      'OrderTabCoordinator order deleted',
      'serverId=$serverId clientUuid=$clientUuid hardRemove=$hardRemove',
    );
  }

  Future<void> markOrderPendingDelete({
    required int serverId,
  }) async {
    final mirror = await bookingOrdersDao.getByServerId(serverId);
    if (mirror != null) {
      await bookingOrdersDao.markIntent(mirror.clientUuid, 'DELETE');
    }
  }

  Future<void> markOrderPendingDeleteByClientUuid(String clientUuid) async {
    await bookingOrdersDao.markIntent(clientUuid, 'DELETE');
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
