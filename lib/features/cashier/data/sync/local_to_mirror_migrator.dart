import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '/core/network/api_debug_log.dart';
import '/features/cashier/data/local/db/cashier_db.dart';
import '/features/cashier/data/local/db/daos/booking_orders_dao.dart';
import '/features/cashier/data/local/db/daos/cached_process_orders_dao.dart';
import '/features/cashier/data/local/db/daos/local_orders_dao.dart';

/// Copies legacy local/pending rows into booking_orders before unified sync.
class LocalToMirrorMigrator {
  LocalToMirrorMigrator({
    required this.db,
    required this.bookingOrdersDao,
    required this.localOrdersDao,
    required this.cachedProcessOrdersDao,
  });

  final CashierDb db;
  final BookingOrdersDao bookingOrdersDao;
  final LocalOrdersDao localOrdersDao;
  final CachedProcessOrdersDao cachedProcessOrdersDao;

  Future<void> mirrorPendingToBookingOrders() async {
    await _mirrorLocalOrders();
    await _mirrorPendingProcessActions();
  }

  Future<void> _mirrorLocalOrders() async {
    final unsynced = await localOrdersDao.getUnsyncedOrders();
    ApiDebugLog.sync('migrator: unsynced local_orders=${unsynced.length}');

    for (final order in unsynced) {
      final existing = order.serverId != null
          ? await bookingOrdersDao.getByServerId(order.serverId!)
          : await bookingOrdersDao.getByClientUuid(order.localId);

      final clientUuid = existing?.clientUuid ?? order.localId;
      final paymentForCheckout =
          order.paymentMethodSelected ?? order.paymentMethodEffective;

      ApiDebugLog.sync(
        'migrator: mirror order',
        'localId=${order.localId} intent=${_intentFromLegacy(order)} '
        'tableId=${order.tableServerId} payment=$paymentForCheckout '
        'items pending sync',
      );

      await db.into(db.bookingOrders).insertOnConflictUpdate(
            BookingOrdersCompanion(
              clientUuid: Value(clientUuid),
              serverId: Value(order.serverId),
              bookingOrderCode: Value(order.serverOrderCode),
              partnerId: Value(order.partnerId),
              partnerName: Value(order.partnerName),
              tableId: Value(order.tableServerId),
              tableNo: Value(order.tableNoSnapshot),
              customerName: Value(order.customerName),
              paymentMethod: Value(paymentForCheckout),
              openbillFlag: Value(
                order.paymentMethodSelected == 'OPENBILL' ||
                    order.paymentMethodEffective == 'OPENBILL' ||
                    order.orderStatusLocal.startsWith('OPENBILL'),
              ),
              // Mirrors booking_orders.total_order_value: subtotal before PPN.
              totalOrderValue: Value(order.subtotal),
              ppn: Value(order.ppnPercent),
              isPpnActive: Value(order.isPpnActive),
              orderStatus: Value(order.orderStatusLocal),
              paidAmountLocal: Value(order.paidAmountLocal),
              changeAmountLocal: Value(order.changeAmountLocal),
              cashRoundingAmount: Value(order.cashRoundingAmount),
              cashRoundingUnit: Value(order.cashRoundingUnit),
              latestPaymentServerId: Value(order.latestPaymentServerId),
              syncDirty: const Value(true),
              syncIntent: Value(_intentFromLegacy(order)),
              createdAt: Value(order.createdAtLocal),
              updatedAt: Value(order.updatedAtLocal),
            ),
          );

      final items = await localOrdersDao.getItemsByOrderLocalId(order.localId);
      for (final item in items) {
        final detailUuid = item.localId;

        await db.into(db.orderDetails).insertOnConflictUpdate(
              OrderDetailsCompanion(
                clientDetailUuid: Value(detailUuid),
                serverId: Value(item.serverOrderDetailId),
                bookingOrderClientUuid: Value(clientUuid),
                bookingOrderServerId: Value(order.serverId),
                partnerProductId: Value(item.productServerId),
                productName: Value(item.productNameSnapshot),
                basePrice: Value(item.basePrice),
                quantity: Value(item.qty),
                optionsPrice: Value(item.optionsPrice),
                customerNote: Value(item.customerNote),
                promoId: Value(item.promoId),
                promoType: Value(item.promoType),
                promoAmount: Value(item.promoAmount),
                syncDirty: const Value(true),
                createdAt: Value(item.createdAtLocal),
                updatedAt: Value(DateTime.now()),
              ),
            );

        final options =
            await localOrdersDao.getOptionsByOrderItemLocalId(item.localId);
        for (final opt in options) {
          await db.into(db.orderDetailOptions).insertOnConflictUpdate(
                OrderDetailOptionsCompanion(
                  clientOptionUuid: Value(opt.localId),
                  orderDetailClientUuid: Value(detailUuid),
                  orderDetailServerId: Value(item.serverOrderDetailId),
                  optionId: Value(opt.optionServerId),
                  partnerProductOptionName: Value(opt.optionNameSnapshot),
                  parentName: Value(opt.parentNameSnapshot),
                  price: Value(opt.price),
                  createdAt: Value(DateTime.now()),
                  updatedAt: Value(DateTime.now()),
                ),
              );
        }
      }
    }
  }

  Future<void> _mirrorPendingProcessActions() async {
    final pending = await cachedProcessOrdersDao.getPendingProcessActions();
    for (final row in pending) {
      final order = await bookingOrdersDao.getByServerId(row.serverId);
      if (order == null) continue;

      final intent = (row.pendingAction ?? 'PROCESS').toUpperCase();
      await bookingOrdersDao.markIntent(order.clientUuid, intent);
    }
  }

  String _intentFromLegacy(dynamic order) {
    final syncStatus = order.syncStatus?.toString() ?? '';
    final status = order.orderStatusLocal?.toString() ?? '';

    if (syncStatus == 'PENDING_UPDATE') return 'UPDATE';
    if (syncStatus == 'PENDING_PAYMENT') return 'PAY';
    if (syncStatus == 'PENDING_PROCESS') return 'PROCESS';
    if (syncStatus == 'PENDING_FINISH') return 'FINISH';
    if (syncStatus == 'PENDING_DELETE') return 'DELETE';
    // CONFIRM_OPENBILL is only for existing server orders (e.g. customer add-more).
    // Brand-new cashier checkout must CREATE first.
    if (status == 'OPENBILL_CONFIRMATION' &&
        order.serverId != null &&
        order.serverId! > 0) {
      return 'CONFIRM_OPENBILL';
    }
    if (status == 'PAID' || status == 'PROCESSED') return 'PROCESS';
    if (status == 'SERVED') return 'FINISH';

    return order.serverId == null ? 'CREATE' : 'UPDATE';
  }
}
