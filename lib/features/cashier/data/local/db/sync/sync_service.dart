import 'package:flutter/foundation.dart';
import '/features/cashier/data/local/db/daos/local_orders_dao.dart';
import '/features/cashier/data/local/db/daos/cached_payment_orders_dao.dart';
import '/features/cashier/data/purchase_api.dart';
import '/features/cashier/data/models/orders_repository.dart';

class SyncService {
  final LocalOrdersDao localOrdersDao;
  final CachedPaymentOrdersDao cachedPaymentOrdersDao;
  final PurchaseApi purchaseApi;
  final OrdersRepository ordersRepo;

  bool _isRunning = false;

  SyncService({
    required this.localOrdersDao,
    required this.cachedPaymentOrdersDao,
    required this.purchaseApi,
    required this.ordersRepo,
  });

  bool get isRunning => _isRunning;

  Future<void> syncPendingOrders() async {
    if (_isRunning) {
      debugPrint('⏭️ sync skipped: already running');
      return;
    }

    _isRunning = true;
    try {
      final pendingOrders = await localOrdersDao.getUnsyncedOrders();
      final pendingDeletes = await localOrdersDao.getPendingDeleteOrders();
      final cachedPendingDeletes = await cachedPaymentOrdersDao.getPendingDeleteOrders();

      debugPrint('🔄 pending orders to sync: ${pendingOrders.length}');
      debugPrint('🗑️ local pending deletes to sync: ${pendingDeletes.length}');
      debugPrint('🗑️ cached pending deletes to sync: ${cachedPendingDeletes.length}');

      for (final order in pendingOrders) {
        await _syncSingleOrder(order.localId);
      }

      for (final order in pendingDeletes) {
        await _syncSingleDelete(order.localId);
      }

      for (final order in cachedPendingDeletes) {
        await _syncSingleCachedDelete(order.serverId);
      }
    } finally {
      _isRunning = false;
    }
  }

  Future<void> _syncSingleDelete(String localOrderId) async {
    final order = await localOrdersDao.getOrderByLocalId(localOrderId);
    if (order == null) {
      debugPrint('⚠️ pending delete order not found: $localOrderId');
      return;
    }

    final serverId = order.serverId;
    if (serverId == null || serverId <= 0) {
      await localOrdersDao.deleteOrderByLocalId(localOrderId);
      debugPrint('🗑️ local pending delete removed without serverId: $localOrderId');
      return;
    }

    try {
      await ordersRepo.softDeleteOrder(serverId);
      await localOrdersDao.deleteOrderByLocalId(localOrderId);

      debugPrint('✅ local pending delete synced: localId=$localOrderId serverId=$serverId');
    } catch (e) {
      debugPrint('❌ local pending delete failed for $localOrderId: $e');
    }
  }

  Future<void> _syncSingleCachedDelete(int serverId) async {
    try {
      await ordersRepo.softDeleteOrder(serverId);
      await cachedPaymentOrdersDao.deleteCachedOrderByServerId(serverId);

      debugPrint('✅ cached pending delete synced: serverId=$serverId');
    } catch (e) {
      debugPrint('❌ cached pending delete failed for serverId=$serverId: $e');
    }
  }

  Future<void> _syncSingleOrder(String localOrderId) async {
    final bundle = await localOrdersDao.getOrderBundle(localOrderId);
    if (bundle == null) {
      debugPrint('⚠️ order bundle not found: $localOrderId');
      return;
    }

    final order = bundle.order;

    if (order.syncStatus == 'SYNCED') {
      debugPrint('✅ already synced: ${order.localId}');
      return;
    }

    if (order.tableServerId == null) {
      await localOrdersDao.markOrderPending(
        order.localId,
        error: 'tableServerId kosong',
      );
      return;
    }

    try {
      await localOrdersDao.markOrderSyncing(order.localId);

      final itemsPayload = bundle.items.map((item) {
        final options = bundle.optionsByItemId[item.localId] ?? const [];
        final optionIds = options
            .map((e) => e.optionServerId)
            .whereType<int>()
            .toList();

        return <String, dynamic>{
          'product_id': item.productServerId,
          'qty': item.qty,
          'note': item.customerNote,
          'option_ids': optionIds,
          'promo_id': item.promoId,
        };
      }).toList();

      final resp = await purchaseApi.checkout(
        orderTable: order.tableServerId!,
        orderName: order.customerName,
        paymentMethod: order.paymentMethodEffective ?? order.paymentMethodSelected ?? 'CASH',
        totalAmount: order.subtotal,
        items: itemsPayload,
      );

      final serverId = _extractServerId(resp);
      final serverOrderCode = _extractServerOrderCode(resp);

      debugPrint('✅ sync success localId=${order.localId} serverId=$serverId');

      await localOrdersDao.markOrderSynced(
        localId: order.localId,
        serverId: serverId,
        serverOrderCode: serverOrderCode,
      );
    } catch (e) {
      debugPrint('❌ sync failed for ${order.localId}: $e');
      await localOrdersDao.markOrderPending(
        order.localId,
        error: e.toString(),
      );
    }
  }

  int? _extractServerId(Map<String, dynamic> resp) {
    final candidates = [
      resp['id'],
      resp['order_id'],
      resp['server_id'],
      resp['data'] is Map ? (resp['data'] as Map)['id'] : null,
      resp['data'] is Map ? (resp['data'] as Map)['order_id'] : null,
    ];

    for (final c in candidates) {
      if (c is int) return c;
      if (c is String) {
        final parsed = int.tryParse(c);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  String? _extractServerOrderCode(Map<String, dynamic> resp) {
    final candidates = [
      resp['booking_order_code'],
      resp['order_code'],
      resp['code'],
      resp['data'] is Map ? (resp['data'] as Map)['booking_order_code'] : null,
      resp['data'] is Map ? (resp['data'] as Map)['order_code'] : null,
    ];

    for (final c in candidates) {
      if (c is String && c.trim().isNotEmpty) return c;
    }
    return null;
  }
}