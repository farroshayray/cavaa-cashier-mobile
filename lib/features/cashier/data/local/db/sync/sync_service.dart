import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '/features/cashier/data/local/db/daos/local_orders_dao.dart';
import '/features/cashier/data/local/db/daos/cached_payment_orders_dao.dart';
import '/features/cashier/data/models/checkout_exceptions.dart';
import '/features/cashier/data/purchase_api.dart';
import '/features/cashier/data/models/orders_repository.dart';
import '/features/cashier/data/local/db/cashier_db.dart';
import '/features/cashier/data/local/db/daos/cached_process_orders_dao.dart';
import '/features/cashier/data/local/db/sync/local_reconciliation_service.dart';
import '/features/cashier/data/local/db/daos/cached_done_orders_dao.dart';
import '/features/cashier/presentation/utils/order_edit_utils.dart';
import '/features/cashier/utils/cash_rounding_helpers.dart';

class SyncService {
  final LocalOrdersDao localOrdersDao;
  final CachedPaymentOrdersDao cachedPaymentOrdersDao;
  final PurchaseApi purchaseApi;
  final OrdersRepository ordersRepo;
  final CachedProcessOrdersDao cachedProcessOrdersDao;
  final LocalReconciliationService reconciliationService;
  final CachedDoneOrdersDao cachedDoneOrdersDao;

  bool _isRunning = false;

  SyncService({
    required this.localOrdersDao,
    required this.cachedPaymentOrdersDao,
    required this.purchaseApi,
    required this.ordersRepo,
    required this.cachedProcessOrdersDao,
    required this.cachedDoneOrdersDao,
    required this.reconciliationService,
  });

  bool get isRunning => _isRunning;

  Future<bool> hasPendingData() async {
    final pendingOrders = await localOrdersDao.getUnsyncedOrders();
    final pendingDeletes = await localOrdersDao.getPendingDeleteOrders();
    final cachedPendingDeletes =
        await cachedPaymentOrdersDao.getPendingDeleteOrders();
    final pendingProcessActions =
        await cachedProcessOrdersDao.getPendingProcessActions();

    return pendingOrders.isNotEmpty ||
        pendingDeletes.isNotEmpty ||
        cachedPendingDeletes.isNotEmpty ||
        pendingProcessActions.isNotEmpty;
  }

  Future<void> syncPendingOrders() async {
    if (_isRunning) {
      debugPrint('⏭️ sync skipped: already running');
      return;
    }

    _isRunning = true;
    try {
      final pendingOrders = await localOrdersDao.getUnsyncedOrders();
      final pendingDeletes = await localOrdersDao.getPendingDeleteOrders();
      final cachedPendingDeletes =
          await cachedPaymentOrdersDao.getPendingDeleteOrders();

      debugPrint('🔄 pending orders to sync: ${pendingOrders.length}');
      debugPrint('🗑️ local pending deletes to sync: ${pendingDeletes.length}');
      debugPrint('🗑️ cached pending deletes to sync: ${cachedPendingDeletes.length}');

      for (final order in pendingOrders) {
        debugPrint(
          '📦 pending order '
          'localId=${order.localId} '
          'serverId=${order.serverId} '
          'status=${order.orderStatusLocal} '
          'syncStatus=${order.syncStatus} '
          'backendStage=${order.backendSyncStage} '
          'serverCode=${order.serverOrderCode} '
          'clientCode=${order.clientOrderCode}',
        );

        await _syncOrderLifecycle(order.localId);
      }

      for (final order in pendingDeletes) {
        await _syncSingleDelete(order.localId);
      }

      for (final order in cachedPendingDeletes) {
        await _syncSingleCachedDelete(order.serverId);
      }

      await syncPendingProcessOrders();
      await reconciliationService.reconcileAll();
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
      if (_isRemoteOrderGone(e)) {
        await _discardRemoteOrder(
          serverId: serverId,
          localOrderId: localOrderId,
          reason: 'pending local delete target already gone',
        );
        return;
      }

      debugPrint('❌ local pending delete failed for $localOrderId: $e');
    }
  }

  Future<void> _syncSingleCachedDelete(int serverId) async {
    try {
      await ordersRepo.softDeleteOrder(serverId);
      await cachedPaymentOrdersDao.deleteCachedOrderByServerId(serverId);

      debugPrint('✅ cached pending delete synced: serverId=$serverId');
    } catch (e) {
      if (_isRemoteOrderGone(e)) {
        await _discardRemoteOrder(
          serverId: serverId,
          reason: 'pending cached delete target already gone',
        );
        return;
      }

      debugPrint('❌ cached pending delete failed for serverId=$serverId: $e');
    }
  }

  int? _extractServerId(Map<String, dynamic> resp) {
    for (final key in const [
      'id',
      'order_id',
      'server_id',
      'booking_order_id',
    ]) {
      final parsed = _readPositiveInt(resp[key]);
      if (parsed != null) return parsed;
    }

    final data = resp['data'];
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      for (final key in const [
        'id',
        'order_id',
        'server_id',
        'booking_order_id',
      ]) {
        final parsed = _readPositiveInt(map[key]);
        if (parsed != null) return parsed;
      }
    }

    final raw = _findFirstByKeys(resp, [
      'id',
      'order_id',
      'server_id',
      'booking_order_id',
    ]);

    return _readPositiveInt(raw);
  }

  int? _readPositiveInt(dynamic raw) {
    if (raw is int) return raw > 0 ? raw : null;
    if (raw is num) return raw.toInt() > 0 ? raw.toInt() : null;
    if (raw is String) {
      final parsed = int.tryParse(raw);
      return parsed != null && parsed > 0 ? parsed : null;
    }
    return null;
  }

  String _resolveCheckoutPaymentMethod(LocalOrder order) {
    String? normalize(String? value) {
      if (value == null) return null;
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;

      final upper = trimmed.toUpperCase();
      if (upper == 'CASH' || upper == 'QRIS' || upper == 'OPENBILL') {
        return upper;
      }
      if (RegExp(r'^\d+$').hasMatch(trimmed)) {
        return trimmed;
      }
      return null;
    }

    return normalize(order.paymentMethodSelected) ??
        normalize(order.paymentMethodEffective) ??
        'CASH';
  }

  String? _extractServerOrderCode(Map<String, dynamic> resp) {
    final raw = _findFirstByKeys(resp, [
      'booking_order_code',
      'order_code',
      'code',
      'booking_code',
    ]);

    if (raw is String && raw.trim().isNotEmpty) {
      return raw.trim();
    }

    return null;
  }

  Future<void> _syncOrderLifecycle(String localOrderId) async {
    final initialOrder = await localOrdersDao.getOrderByLocalId(localOrderId);
    if (initialOrder == null) return;

    try {
      await localOrdersDao.markOrderSyncing(localOrderId);

      var order = await localOrdersDao.getOrderByLocalId(localOrderId);
      if (order == null) {
        throw Exception('Order hilang setelah mark syncing');
      }

      debugPrint(
        '🚀 start lifecycle sync '
        'localId=${order.localId} '
        'serverId=${order.serverId} '
        'orderStatus=${order.orderStatusLocal} '
        'syncStatus=${order.syncStatus} '
        'backendStage=${order.backendSyncStage} '
        'paid=${order.paidAmountLocal} '
        'change=${order.changeAmountLocal}',
      );

      int? serverId = order.serverId;
      String? serverOrderCode = order.serverOrderCode;
      String stage = order.backendSyncStage;

      if (serverId != null && serverId > 0 && stage == 'NONE') {
        debugPrint(
          '🛠️ fixing backend stage to PURCHASED because serverId already exists '
          'localId=$localOrderId serverId=$serverId',
        );
        await localOrdersDao.updateBackendSyncStage(localOrderId, 'PURCHASED');
        stage = 'PURCHASED';

        order = await localOrdersDao.getOrderByLocalId(localOrderId);
        if (order == null) {
          throw Exception('Order hilang setelah auto-fix backend stage');
        }
      }

      debugPrint(
        '🔹 STEP PURCHASE check '
        'localId=$localOrderId '
        'serverId=$serverId '
        'stage=$stage',
      );

      // STEP 1: purchase
      if (serverId == null || stage == 'NONE') {
        final createResp = await _createOrderOnBackend(order);
        serverId = _extractServerId(createResp);
        serverOrderCode = _extractServerOrderCode(createResp);

        debugPrint(
          '🧩 extracted from purchase response '
          'localId=$localOrderId '
          'serverId=$serverId '
          'serverOrderCode=$serverOrderCode',
        );

        if (serverId == null || serverId <= 0) {
          final message = createResp['message']?.toString();
          throw Exception(
            message != null && message.trim().isNotEmpty
                ? message.trim()
                : 'Gagal mendapatkan serverId dari purchase sync',
          );
        }

        await localOrdersDao.attachServerIdentity(
          localId: localOrderId,
          serverId: serverId,
          serverOrderCode: serverOrderCode,
        );

        await localOrdersDao.updateBackendSyncStage(localOrderId, 'PURCHASED');
        stage = 'PURCHASED';

        final advancedStage = initialOrder.backendSyncStage;
        if (advancedStage != 'NONE' &&
            advancedStage != 'PURCHASED' &&
            advancedStage != stage) {
          await localOrdersDao.updateBackendSyncStage(localOrderId, advancedStage);
          stage = advancedStage;
          debugPrint(
            '🛠️ restored advanced backend stage after purchase '
            'localId=$localOrderId stage=$stage',
          );
        }

        debugPrint(
          '✅ STEP PURCHASE done '
          'localId=$localOrderId '
          'serverId=$serverId '
          'serverOrderCode=$serverOrderCode',
        );

        await _remapLocalDetailIdsFromServer(localOrderId, serverId);

        order = await localOrdersDao.getOrderByLocalId(localOrderId);
        if (order == null) {
          throw Exception('Order hilang setelah attach server identity');
        }
      }

      if (order.syncStatus == 'PENDING_UPDATE' &&
          serverId != null &&
          serverId > 0) {
        debugPrint(
          '🔹 STEP UPDATE check localId=$localOrderId serverId=$serverId',
        );
        await _syncOrderUpdate(order);
        await localOrdersDao.markOrderUpdateSynced(localOrderId);

        if (localOrderId.startsWith('shadow_edit_')) {
          await localOrdersDao.deleteOrderByLocalId(localOrderId);
          await reconciliationService.reconcileAll();
          return;
        }

        order = await localOrdersDao.getOrderByLocalId(localOrderId);
        if (order == null) {
          throw Exception('Order hilang setelah sync update');
        }
      }

      debugPrint(
        '🔹 STEP PAYMENT check '
        'localId=$localOrderId '
        'orderStatus=${order.orderStatusLocal} '
        'stage=$stage '
        'serverId=$serverId',
      );

      var isOpenbill = _isOpenbillOrder(order);

      if (isOpenbill) {
        debugPrint(
          '🔹 STEP OPENBILL check '
          'localId=$localOrderId '
          'orderStatus=${order.orderStatusLocal} '
          'stage=$stage '
          'serverId=$serverId',
        );

        stage = await _replayOpenbillOnServer(
          localOrderId: localOrderId,
          order: order,
          serverId: serverId!,
        );

        order = await localOrdersDao.getOrderByLocalId(localOrderId);
        if (order == null) {
          throw Exception('Order hilang setelah replay openbill');
        }

        stage = await _ensureOpenbillPaymentSynced(
          localOrderId: localOrderId,
          order: order,
          serverId: serverId!,
          stage: stage,
        );

        order = await localOrdersDao.getOrderByLocalId(localOrderId);
        if (order == null) {
          throw Exception('Order hilang setelah sync pembayaran openbill');
        }
      } else {
        // STEP 2: payment
        if ((order.orderStatusLocal == 'PAID' ||
                order.orderStatusLocal == 'PROCESSED' ||
                order.orderStatusLocal == 'SERVED') &&
            stage == 'PURCHASED') {
          await _syncPayment(order, serverId!);
          await localOrdersDao.updateBackendSyncStage(localOrderId, 'PAID');
          stage = 'PAID';

          debugPrint(
            '✅ STEP PAYMENT done '
            'localId=$localOrderId '
            'serverId=$serverId',
          );

          order = await localOrdersDao.getOrderByLocalId(localOrderId);
          if (order == null) {
            throw Exception('Order hilang setelah sync payment');
          }
        }

        debugPrint(
          '🔹 STEP PROCESS check '
          'localId=$localOrderId '
          'orderStatus=${order.orderStatusLocal} '
          'stage=$stage '
          'serverId=$serverId',
        );

        if ((order.orderStatusLocal == 'PROCESSED' ||
                order.orderStatusLocal == 'SERVED') &&
            stage == 'PAID') {
          await ordersRepo.processOrder(serverId!);
          await localOrdersDao.updateBackendSyncStage(localOrderId, 'PROCESSED');
          stage = 'PROCESSED';

          debugPrint(
            '✅ STEP PROCESS done '
            'localId=$localOrderId '
            'serverId=$serverId',
          );

          order = await localOrdersDao.getOrderByLocalId(localOrderId);
          if (order == null) {
            throw Exception('Order hilang setelah sync process');
          }
        }

        debugPrint(
          '🔹 STEP FINISH check '
          'localId=$localOrderId '
          'orderStatus=${order.orderStatusLocal} '
          'stage=$stage '
          'serverId=$serverId',
        );

        if (order.orderStatusLocal == 'SERVED' && stage == 'PROCESSED') {
          await ordersRepo.finishOrder(serverId!);
          await localOrdersDao.updateBackendSyncStage(localOrderId, 'SERVED');
          stage = 'SERVED';

          debugPrint(
            '✅ STEP FINISH done '
            'localId=$localOrderId '
            'serverId=$serverId',
          );

          order = await localOrdersDao.getOrderByLocalId(localOrderId);
          if (order == null) {
            throw Exception('Order hilang setelah sync finish');
          }
        }
      }

      stage = await _forcePaymentSyncIfNeeded(
        localOrderId: localOrderId,
        order: order,
        serverId: serverId,
        stage: stage,
      );

      order = await localOrdersDao.getOrderByLocalId(localOrderId);
      if (order == null) {
        throw Exception('Order hilang setelah force payment sync');
      }

      isOpenbill = _isOpenbillOrder(order);

      // final
      final completed =
          (order.orderStatusLocal == 'UNPAID' && !isOpenbill && stage == 'PURCHASED') ||
          (isOpenbill &&
              order.orderStatusLocal == 'UNPAID' &&
              stage == 'OPENBILL_SERVED' &&
              !_localNeedsPaymentSync(order)) ||
          (isOpenbill &&
              (order.orderStatusLocal == 'SERVED' ||
                  order.orderStatusLocal == 'PAID') &&
              stage == 'SERVED') ||
          (!isOpenbill && order.orderStatusLocal == 'PAID' && stage == 'PAID') ||
          (!isOpenbill && order.orderStatusLocal == 'PROCESSED' && stage == 'PROCESSED') ||
          (!isOpenbill && order.orderStatusLocal == 'SERVED' && stage == 'SERVED');

      debugPrint(
        '🏁 final completion check '
        'localId=$localOrderId '
        'orderStatus=${order.orderStatusLocal} '
        'stage=$stage '
        'completed=$completed',
      );

      if (completed) {
        await localOrdersDao.markOrderSynced(
          localId: localOrderId,
          serverId: serverId,
          serverOrderCode: serverOrderCode,
        );

        await reconciliationService.reconcileAll();

        final after = await localOrdersDao.getOrderByLocalId(localOrderId);
        debugPrint(
          '🟢 markOrderSynced result '
          'localId=${after?.localId} '
          'serverId=${after?.serverId} '
          'syncStatus=${after?.syncStatus} '
          'backendStage=${after?.backendSyncStage}',
        );
      } else if (order.syncStatus == 'SYNCING') {
        final pendingStatus = _pendingSyncStatusFor(order, initialOrder);
        final paymentStillPending =
            _localNeedsPaymentSync(order) && serverId != null && serverId > 0;
        String? incompleteReason;

        if (paymentStillPending) {
          try {
            final serverDetail = await ordersRepo.fetchOrderDetail(serverId!);
            final serverStatus = _serverOrderStatus(serverDetail);
            incompleteReason = _serverReadyForPayment(serverStatus)
                ? 'Pembayaran offline belum tersinkron ke server'
                : 'Order server belum siap dibayar (status: $serverStatus)';
          } catch (e) {
            incompleteReason = 'Gagal memeriksa status pembayaran: $e';
          }
        }

        await localOrdersDao.markOrderPending(
          localOrderId,
          error: incompleteReason,
          restoreSyncStatus: pendingStatus,
        );
      }
    } on StockInsufficientException catch (e) {
      debugPrint('stock conflict while syncing $localOrderId: ${e.message}');
      final details = e.allItems.map((item) => item.label).join('\n');
      await localOrdersDao.markOrderStockConflict(
        localOrderId,
        error: details.isNotEmpty ? details : e.message,
      );
    } catch (e) {
      final current = await localOrdersDao.getOrderByLocalId(localOrderId);
      final serverId = current?.serverId ?? initialOrder.serverId;

      if (serverId != null && serverId > 0 && _isRemoteOrderGone(e)) {
        await _discardRemoteOrder(
          serverId: serverId,
          localOrderId: localOrderId,
          reason: 'pending lifecycle target already gone',
        );
        return;
      }

      debugPrint('sync lifecycle failed for $localOrderId: $e');
      final pendingStatus = _pendingSyncStatusFor(
        current ?? initialOrder,
        initialOrder,
      );
      await localOrdersDao.markOrderPending(
        localOrderId,
        error: e.toString(),
        restoreSyncStatus: pendingStatus,
      );
    }
  }

  Future<void> syncPendingProcessOrders() async {
    final pending = await cachedProcessOrdersDao.getPendingProcessActions();

    for (final row in pending) {
      try {
        switch (row.pendingAction) {
          case 'PROCESS':
            final kitchenWaiting =
                row.orderStatus == 'OPENBILL_WAITING_ORDER';
            await ordersRepo.processOrder(
              row.serverId,
              sendToKitchenWaiting: kitchenWaiting,
            );
            await cachedProcessOrdersDao.markProcessedOnline(
              row.serverId,
              latestJson: row.latestProcessJson,
              orderStatus: kitchenWaiting
                  ? 'OPENBILL_WAITING_ORDER'
                  : 'PROCESSED',
            );
            break;

          case 'CANCEL_PROCESS':
            await ordersRepo.cancelProcessOrder(row.serverId);
            await cachedProcessOrdersDao.markCancelProcessOnline(
              row.serverId,
              latestJson: row.latestProcessJson,
            );
            break;

          case 'FINISH':
            debugPrint('🔄 [SYNC] Started FINISH action for serverId=${row.serverId}, paymentMethod=${row.paymentMethod}');
            await ordersRepo.finishOrder(row.serverId);
            debugPrint('✅ [SYNC] finishOrder api success for serverId=${row.serverId}');

            final isOpenbill =
                row.paymentMethod == 'OPENBILL' ||
                row.orderStatus.startsWith('OPENBILL');
            if (isOpenbill) {
              debugPrint('🔄 [SYNC] Fetching updated OPENBILL order detail for serverId=${row.serverId}');
              final detail = await ordersRepo.fetchOrderDetail(row.serverId);
              debugPrint('🔄 [SYNC] Upserting detail to cachedPaymentOrdersDao for serverId=${row.serverId}');
              await cachedPaymentOrdersDao.upsertDetailFromApi(detail);
              debugPrint('🔄 [SYNC] Cleaning up process & done caches for serverId=${row.serverId}');
              await cachedProcessOrdersDao.deleteByServerId(row.serverId);
              await cachedDoneOrdersDao.deleteByServerId(row.serverId);
              debugPrint('✅ [SYNC] Completed OPENBILL finish sync for serverId=${row.serverId}');
            } else {
              debugPrint('🔄 [SYNC] Marking non-OPENBILL order as synced in done cache for serverId=${row.serverId}');
              await cachedDoneOrdersDao.markSyncedByServerId(
                row.serverId,
                latestDoneJson: row.latestProcessJson,
              );
              await cachedProcessOrdersDao.deleteByServerId(row.serverId);
              debugPrint('✅ [SYNC] Completed non-OPENBILL finish sync for serverId=${row.serverId}');
            }
            break;

          case 'SERVE_ITEMS':
            await _syncServeItemsPending(row);
            break;

          case 'MARK_KITCHEN_SERVED':
            await _syncMarkKitchenServedPending(row);
            break;
        }
      } catch (e) {
        if (_isRemoteOrderGone(e)) {
          await _discardRemoteOrder(
            serverId: row.serverId,
            reason: 'pending process action target already gone',
          );
          continue;
        }

        debugPrint('syncPendingProcessOrders failed for ${row.serverId}: $e');
      }
    }
    await reconciliationService.reconcileAll();
  }

  Future<void> _syncOrderUpdate(LocalOrder order) async {
    final serverId = order.serverId;
    if (serverId == null || serverId <= 0) {
      throw Exception('serverId kosong untuk sync update');
    }

    final bundle = await localOrdersDao.getOrderBundle(order.localId);
    if (bundle == null) {
      throw Exception('order bundle not found: ${order.localId}');
    }

    final itemsPayload = bundle.items.map((item) {
      final options = bundle.optionsByItemId[item.localId] ?? const [];
      final optionIds = options.map((e) => e.optionServerId).toList();

      return <String, dynamic>{
        if (item.serverOrderDetailId != null)
          'detail_id': item.serverOrderDetailId,
        'product_id': item.productServerId,
        'qty': item.qty,
        'note': item.customerNote,
        'option_ids': optionIds,
        if (item.promoId != null) 'promo_id': item.promoId,
      };
    }).toList();

    final updated = await ordersRepo.updateOrder(
      id: serverId,
      orderTable: order.tableServerId,
      orderName: guestPayloadName(order.customerName),
      items: itemsPayload,
    );

    await cachedPaymentOrdersDao.upsertDetailFromApi(updated);
    await cachedProcessOrdersDao.saveDetailJson(serverId, jsonEncode(updated));
  }

  Future<Map<String, dynamic>> _createOrderOnBackend(LocalOrder order) async {
    final bundle = await localOrdersDao.getOrderBundle(order.localId);
    if (bundle == null) {
      throw Exception('order bundle not found: ${order.localId}');
    }

    if (order.tableServerId == null) {
      throw Exception('tableServerId kosong');
    }

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

    if (itemsPayload.isEmpty) {
      throw Exception('Item order lokal kosong, tidak bisa sync checkout');
    }

    for (final item in itemsPayload) {
      final productId = item['product_id'];
      if (productId is! int || productId <= 0) {
        throw Exception(
          'Produk pada order lokal tidak valid (product_id=$productId). Refresh data produk lalu coba lagi.',
        );
      }
    }

    final paymentMethodForBackend = _resolveCheckoutPaymentMethod(order);

    final resp = await purchaseApi.checkout(
      orderTable: order.tableServerId!,
      orderName: guestPayloadName(order.customerName),
      paymentMethod: paymentMethodForBackend,
      totalAmount: order.subtotal,
      items: itemsPayload,
    );

    debugPrint('🧾 purchase sync raw response for ${order.localId}: $resp');

    return resp;
  }

  Map<String, dynamic> _decodeCachedDetail(String? raw) {
    if (raw == null || raw.trim().isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return {};
  }

  List<Map<String, dynamic>> _detailRows(Map<String, dynamic> detail) {
    return ((detail['order_details'] as List?) ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Map<int, Map<String, dynamic>> _detailMapById(
    List<Map<String, dynamic>> details,
  ) {
    final map = <int, Map<String, dynamic>>{};
    for (final item in details) {
      final id = orderDetailId(item);
      if (id != null) map[id] = item;
    }
    return map;
  }

  bool _isOpenbillOrder(LocalOrder order) {
    final selected = (order.paymentMethodSelected ?? '').toUpperCase();
    final effective = (order.paymentMethodEffective ?? '').toUpperCase();
    final status = order.orderStatusLocal.toUpperCase();
    if (selected == 'OPENBILL' ||
        effective == 'OPENBILL' ||
        status.startsWith('OPENBILL')) {
      return true;
    }

    final snapshot = _decodeCachedDetail(order.orderSnapshotJson);
    final openbillFlag = snapshot['openbill_flag'];
    if (openbillFlag == true || openbillFlag == 1) return true;
    if (openbillFlag?.toString().toLowerCase() == 'true') return true;

    return false;
  }

  String _serverOrderStatus(Map<String, dynamic> detail) {
    return (detail['order_status'] ?? '').toString().toUpperCase();
  }

  bool _serverOpenbillNeedsFinish(String status) {
    return status == 'OPENBILL_WAITING_ORDER' ||
        status == 'OPENBILL_CONFIRMATION' ||
        status == 'PROCESSED';
  }

  bool _serverReadyForPayment(String status) {
    return status == 'UNPAID' || status == 'PAYMENT REQUEST';
  }

  Future<String> _replayOpenbillOnServer({
    required String localOrderId,
    required LocalOrder order,
    required int serverId,
  }) async {
    var stage = order.backendSyncStage;

    if (_localOpenbillPastConfirmation(order)) {
      var serverDetail = await ordersRepo.fetchOrderDetail(serverId);
      var serverStatus = _serverOrderStatus(serverDetail);

      if (serverStatus == 'OPENBILL_CONFIRMATION') {
        await ordersRepo.processOrder(serverId);
        await localOrdersDao.updateBackendSyncStage(localOrderId, 'CONFIRMED');
        stage = 'CONFIRMED';
        serverDetail = await ordersRepo.fetchOrderDetail(serverId);
        serverStatus = _serverOrderStatus(serverDetail);

        debugPrint(
          '✅ STEP OPENBILL CONFIRM done '
          'localId=$localOrderId '
          'serverId=$serverId '
          'serverStatus=$serverStatus',
        );
      }
    }

    if (_localOpenbillNeedsServeReplay(order)) {
      var serverDetail = await ordersRepo.fetchOrderDetail(serverId);
      if (!_allServerDetailsServed(serverDetail)) {
        await _syncOpenbillServeItems(order, serverId);
        serverDetail = await ordersRepo.fetchOrderDetail(serverId);
      }

      if (!_allServerDetailsServed(serverDetail) &&
          _localHasCashierServedItems(order)) {
        await _syncOpenbillServeItems(order, serverId);
      }

      await localOrdersDao.updateBackendSyncStage(localOrderId, 'ITEMS_SERVED');
      stage = 'ITEMS_SERVED';

      debugPrint(
        '✅ STEP OPENBILL SERVE done '
        'localId=$localOrderId '
        'serverId=$serverId',
      );
    }

    if (_localOpenbillReadyForFinish(order)) {
      var serverDetail = await ordersRepo.fetchOrderDetail(serverId);
      var serverStatus = _serverOrderStatus(serverDetail);

      if (_serverOpenbillNeedsFinish(serverStatus)) {
        if (!_allServerDetailsServed(serverDetail)) {
          await _syncOpenbillServeItems(order, serverId);
          serverDetail = await ordersRepo.fetchOrderDetail(serverId);
        }

        await ordersRepo.finishOrder(serverId);
        await localOrdersDao.updateBackendSyncStage(
          localOrderId,
          'OPENBILL_SERVED',
        );
        stage = 'OPENBILL_SERVED';
        serverStatus = _serverOrderStatus(
          await ordersRepo.fetchOrderDetail(serverId),
        );

        debugPrint(
          '✅ STEP OPENBILL FINISH done '
          'localId=$localOrderId '
          'serverId=$serverId '
          'serverStatus=$serverStatus',
        );
      }
    }

    if (_localNeedsPaymentSync(order)) {
      var paymentOrder =
          await localOrdersDao.getOrderByLocalId(localOrderId) ?? order;

      var serverDetail = await ordersRepo.fetchOrderDetail(serverId);
      var serverStatus = _serverOrderStatus(serverDetail);

      if (!_serverReadyForPayment(serverStatus) &&
          _localOpenbillReadyForFinish(paymentOrder) &&
          _serverOpenbillNeedsFinish(serverStatus)) {
        if (!_allServerDetailsServed(serverDetail)) {
          await _syncOpenbillServeItems(paymentOrder, serverId);
          serverDetail = await ordersRepo.fetchOrderDetail(serverId);
        }

        await ordersRepo.finishOrder(serverId);
        await localOrdersDao.updateBackendSyncStage(
          localOrderId,
          'OPENBILL_SERVED',
        );
        stage = 'OPENBILL_SERVED';
        serverDetail = await ordersRepo.fetchOrderDetail(serverId);
        serverStatus = _serverOrderStatus(serverDetail);
      }

      if (_serverReadyForPayment(serverStatus)) {
        await _syncPayment(paymentOrder, serverId);
        await localOrdersDao.updateBackendSyncStage(localOrderId, 'SERVED');
        stage = 'SERVED';

        debugPrint(
          '✅ STEP OPENBILL PAYMENT done '
          'localId=$localOrderId '
          'serverId=$serverId',
        );
      } else {
        debugPrint(
          '⚠️ OPENBILL payment skipped '
          'localId=$localOrderId '
          'serverId=$serverId '
          'serverStatus=$serverStatus',
        );
      }
    }

    if (!_localNeedsPaymentSync(order)) {
      final serverDetail = await ordersRepo.fetchOrderDetail(serverId);
      final serverStatus = _serverOrderStatus(serverDetail);
      if (serverStatus == 'UNPAID' && order.orderStatusLocal == 'UNPAID') {
        await localOrdersDao.updateBackendSyncStage(
          localOrderId,
          'OPENBILL_SERVED',
        );
        stage = 'OPENBILL_SERVED';

        debugPrint(
          '✅ STEP OPENBILL aligned to UNPAID on server '
          'localId=$localOrderId '
          'serverId=$serverId',
        );
      }
    }

    return stage;
  }

  String _pendingSyncStatusFor(LocalOrder order, LocalOrder initialOrder) {
    final initial = initialOrder.syncStatus.trim();
    if (initial.isNotEmpty && initial != 'SYNCING') {
      return initial;
    }

    if (_localNeedsPaymentSync(order)) return 'PENDING_PAYMENT';
    if (order.syncStatus == 'PENDING_FINISH') return 'PENDING_FINISH';
    if (order.syncStatus == 'PENDING_PROCESS') return 'PENDING_PROCESS';
    return 'PENDING';
  }

  Future<String> _ensureOpenbillPaymentSynced({
    required String localOrderId,
    required LocalOrder order,
    required int serverId,
    required String stage,
  }) async {
    if (!_localNeedsPaymentSync(order) || stage == 'SERVED') {
      return stage;
    }

    var currentStage = stage;
    var currentOrder = order;
    var serverDetail = await ordersRepo.fetchOrderDetail(serverId);
    var serverStatus = _serverOrderStatus(serverDetail);

    if (!_serverReadyForPayment(serverStatus) &&
        _localOpenbillReadyForFinish(currentOrder) &&
        _serverOpenbillNeedsFinish(serverStatus)) {
      if (!_allServerDetailsServed(serverDetail)) {
        await _syncOpenbillServeItems(currentOrder, serverId);
        serverDetail = await ordersRepo.fetchOrderDetail(serverId);
      }

      await ordersRepo.finishOrder(serverId);
      await localOrdersDao.updateBackendSyncStage(
        localOrderId,
        'OPENBILL_SERVED',
      );
      currentStage = 'OPENBILL_SERVED';
      serverDetail = await ordersRepo.fetchOrderDetail(serverId);
      serverStatus = _serverOrderStatus(serverDetail);
    }

    if (_serverReadyForPayment(serverStatus)) {
      currentOrder =
          await localOrdersDao.getOrderByLocalId(localOrderId) ?? currentOrder;
      await _syncPayment(currentOrder, serverId);
      await localOrdersDao.updateBackendSyncStage(localOrderId, 'SERVED');
      currentStage = 'SERVED';

      debugPrint(
        '✅ STEP OPENBILL PAYMENT fallback done '
        'localId=$localOrderId '
        'serverId=$serverId',
      );
    }

    return currentStage;
  }

  bool _localOpenbillPastConfirmation(LocalOrder order) {
    final status = order.orderStatusLocal.toUpperCase();
    return status == 'OPENBILL_WAITING_ORDER' ||
        status == 'UNPAID' ||
        status == 'SERVED' ||
        status == 'PAID' ||
        status == 'PROCESSED';
  }

  bool _localOpenbillNeedsServeReplay(LocalOrder order) {
    if (order.syncStatus == 'PENDING_PAYMENT' &&
        (order.backendSyncStage == 'OPENBILL_SERVED' ||
            order.backendSyncStage == 'SERVED')) {
      return false;
    }

    final status = order.orderStatusLocal.toUpperCase();
    if (status == 'UNPAID' || status == 'SERVED' || status == 'PAID') {
      return true;
    }
    if (status == 'OPENBILL_WAITING_ORDER') {
      return _localHasCashierServedItems(order);
    }
    return false;
  }

  bool _localOpenbillReadyForFinish(LocalOrder order) {
    final status = order.orderStatusLocal.toUpperCase();
    return status == 'UNPAID' ||
        status == 'SERVED' ||
        status == 'PAID' ||
        order.syncStatus == 'PENDING_FINISH' ||
        order.syncStatus == 'PENDING_PAYMENT';
  }

  bool _localNeedsPaymentSync(LocalOrder order) {
    if (order.syncStatus == 'PENDING_PAYMENT') return true;
    if (order.paymentConfirmedAtLocal != null) return true;
    if ((order.paidAmountLocal ?? 0) > 0) return true;

    // Openbill: sudah dibayar lokal (SERVED) tapi flag sync masih tahap finish
    if (_isOpenbillOrder(order) &&
        order.orderStatusLocal == 'SERVED' &&
        (order.syncStatus == 'PENDING_FINISH' ||
            order.backendSyncStage == 'OPENBILL_SERVED')) {
      return true;
    }

    return false;
  }

  Future<String> _forcePaymentSyncIfNeeded({
    required String localOrderId,
    required LocalOrder order,
    required int? serverId,
    required String stage,
  }) async {
    if (serverId == null || serverId <= 0) return stage;
    if (!_localNeedsPaymentSync(order)) return stage;
    if (stage == 'SERVED' || stage == 'PAID') return stage;

    var currentOrder = order;
    var serverDetail = await ordersRepo.fetchOrderDetail(serverId);
    var serverStatus = _serverOrderStatus(serverDetail);

    debugPrint(
      '💰 force payment sync check '
      'localId=$localOrderId '
      'serverId=$serverId '
      'localStatus=${order.orderStatusLocal} '
      'syncStatus=${order.syncStatus} '
      'stage=$stage '
      'serverStatus=$serverStatus '
      'paid=${order.paidAmountLocal}',
    );

    if (!_serverReadyForPayment(serverStatus)) {
      final isOpenbill = _isOpenbillOrder(currentOrder);
      if (isOpenbill && _serverOpenbillNeedsFinish(serverStatus)) {
        if (!_allServerDetailsServed(serverDetail)) {
          await _syncOpenbillServeItems(currentOrder, serverId);
          serverDetail = await ordersRepo.fetchOrderDetail(serverId);
        }

        await ordersRepo.finishOrder(serverId);
        await localOrdersDao.updateBackendSyncStage(
          localOrderId,
          'OPENBILL_SERVED',
        );
        serverDetail = await ordersRepo.fetchOrderDetail(serverId);
        serverStatus = _serverOrderStatus(serverDetail);
      }
    }

    if (!_serverReadyForPayment(serverStatus)) {
      throw Exception(
        'Order server belum siap dibayar (status: $serverStatus)',
      );
    }

    currentOrder =
        await localOrdersDao.getOrderByLocalId(localOrderId) ?? currentOrder;
    await _syncPayment(currentOrder, serverId);

    final paymentStage =
        _isOpenbillOrder(currentOrder) ? 'SERVED' : 'PAID';
    await localOrdersDao.updateBackendSyncStage(localOrderId, paymentStage);

    debugPrint(
      '✅ force payment sync done '
      'localId=$localOrderId '
      'serverId=$serverId '
      'stage=$paymentStage',
    );

    return paymentStage;
  }

  bool _localHasCashierServedItems(LocalOrder order) {
    final snapshot = _decodeCachedDetail(order.orderSnapshotJson);
    if (snapshot.isEmpty) return false;
    return _detailRows(snapshot).any(
      (item) => detailStatusOf(item) == 'SERVED BY CASHIER',
    );
  }

  bool _allServerDetailsServed(Map<String, dynamic> serverDetail) {
    final details = _detailRows(serverDetail);
    if (details.isEmpty) return false;
    return details.every((item) => isDetailServedStatus(detailStatusOf(item)));
  }

  List<int> _optionIdsFromDetail(Map<String, dynamic> item) {
    final opts = (item['order_detail_options'] as List?) ?? [];
    final ids = <int>[];
    for (final raw in opts.whereType<Map>()) {
      final option = raw['option'];
      if (option is Map) {
        final id = int.tryParse(option['id']?.toString() ?? '');
        if (id != null) ids.add(id);
      }
    }
    ids.sort();
    return ids;
  }

  int? _productIdFromDetail(Map<String, dynamic> item) {
    final direct = item['product_id'];
    if (direct != null) return int.tryParse(direct.toString());
    final partner = item['partner_product'];
    if (partner is Map) {
      return int.tryParse(partner['id']?.toString() ?? '');
    }
    return null;
  }

  int _qtyFromDetail(Map<String, dynamic> item) {
    final raw = item['quantity'] ?? item['qty'] ?? 1;
    return int.tryParse(raw.toString()) ?? 1;
  }

  bool _detailsMatchForRemap(
    Map<String, dynamic> local,
    Map<String, dynamic> server,
  ) {
    final localProductId = _productIdFromDetail(local);
    final serverProductId = _productIdFromDetail(server);
    if (localProductId == null ||
        serverProductId == null ||
        localProductId != serverProductId) {
      return false;
    }
    if (_qtyFromDetail(local) != _qtyFromDetail(server)) return false;
    final localOpts = _optionIdsFromDetail(local);
    final serverOpts = _optionIdsFromDetail(server);
    if (localOpts.length != serverOpts.length) return false;
    for (var i = 0; i < localOpts.length; i++) {
      if (localOpts[i] != serverOpts[i]) return false;
    }
    return true;
  }

  Future<void> _remapLocalDetailIdsFromServer(
    String localOrderId,
    int serverId,
  ) async {
    final localDetail = await localOrdersDao.getOrderDetailMapByLocalId(localOrderId);
    if (localDetail == null) return;

    Map<String, dynamic> serverDetail;
    try {
      serverDetail = await ordersRepo.fetchOrderDetail(serverId);
    } catch (e) {
      debugPrint('⚠️ remap detail ids failed fetch serverId=$serverId: $e');
      return;
    }

    final localDetails = _detailRows(localDetail);
    final serverPool = _detailRows(serverDetail)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    var remapped = 0;
    for (final localItem in localDetails) {
      for (var i = 0; i < serverPool.length; i++) {
        if (!_detailsMatchForRemap(localItem, serverPool[i])) continue;
        final serverItem = serverPool.removeAt(i);
        final serverDetailId = orderDetailId(serverItem);
        if (serverDetailId != null) {
          localItem['id'] = serverDetailId;
          remapped++;
        }
        break;
      }
    }

    if (remapped == 0) return;

    final snapshot = Map<String, dynamic>.from(localDetail)
      ..['order_details'] = localDetails;
    await localOrdersDao.saveOrderSnapshotJson(
      localId: localOrderId,
      orderSnapshotJson: jsonEncode(snapshot),
    );

    debugPrint(
      '🔗 remapped $remapped local detail ids for localId=$localOrderId serverId=$serverId',
    );
  }

  Future<void> _syncOpenbillServeItems(LocalOrder order, int serverId) async {
    final localDetail = await localOrdersDao.getOrderDetailMapByLocalId(order.localId);
    if (localDetail == null) return;

    final serverDetail = await ordersRepo.fetchOrderDetail(serverId);
    final localDetails = _detailRows(localDetail);
    final serverById = _detailMapById(_detailRows(serverDetail));

    final idsToServe = <int>[];
    for (final localItem in localDetails) {
      if (detailStatusOf(localItem) != 'SERVED BY CASHIER') continue;
      final id = orderDetailId(localItem);
      if (id == null) continue;

      final serverItem = serverById[id];
      if (serverItem == null) continue;
      if (isDetailServedStatus(detailStatusOf(serverItem))) continue;
      if (!isItemAwaitingCashierServe(serverItem)) continue;
      idsToServe.add(id);
    }

    if (idsToServe.isEmpty) return;

    try {
      await ordersRepo.serveOrderItems(
        id: serverId,
        detailIds: idsToServe,
      );
    } on DioException catch (e) {
      if (!_isServeWarning(e)) rethrow;
    }
  }

  bool _isServeWarning(DioException error) {
    final data = error.response?.data;
    final status = data is Map ? data['status']?.toString() : null;
    return status == 'warning' || error.response?.statusCode == 409;
  }

  Future<void> _finalizeServeItemsSync(
    CachedProcessOrder row,
    Map<String, dynamic> updated,
  ) async {
    final updatedStatus = (updated['order_status'] ?? '').toString();
    final isOpenbill = isOpenBillOrder(updated);

    if (isOpenbill && updatedStatus == 'UNPAID') {
      await cachedPaymentOrdersDao.upsertDetailFromApi(updated);
      await cachedProcessOrdersDao.deleteByServerId(row.serverId);
      return;
    }

    if (updatedStatus == 'SERVED') {
      await cachedDoneOrdersDao.markSyncedByServerId(
        row.serverId,
        latestDoneJson: jsonEncode(updated),
      );
      await cachedProcessOrdersDao.deleteByServerId(row.serverId);
      return;
    }

    await cachedProcessOrdersDao.markServeItemsSynced(
      serverId: row.serverId,
      detailJson: jsonEncode(updated),
      orderStatus: updatedStatus.isNotEmpty ? updatedStatus : row.orderStatus,
    );
  }

  Future<void> _syncServeItemsPending(CachedProcessOrder row) async {
    final localDetail = _decodeCachedDetail(row.detailJson);
    final serverDetail = await ordersRepo.fetchOrderDetail(row.serverId);
    final localDetails = _detailRows(localDetail);
    final serverById = _detailMapById(_detailRows(serverDetail));

    final idsToServe = <int>[];
    for (final localItem in localDetails) {
      final id = orderDetailId(localItem);
      if (id == null) continue;
      if (detailStatusOf(localItem) != 'SERVED BY CASHIER') continue;

      final serverItem = serverById[id];
      if (serverItem == null) continue;
      if (isDetailServedStatus(detailStatusOf(serverItem))) continue;
      if (!isItemAwaitingCashierServe(serverItem)) continue;

      idsToServe.add(id);
    }

    if (idsToServe.isNotEmpty) {
      try {
        await ordersRepo.serveOrderItems(
          id: row.serverId,
          detailIds: idsToServe,
        );
      } on DioException catch (e) {
        if (!_isServeWarning(e)) rethrow;
      }
    }

    final updated = await ordersRepo.fetchOrderDetail(row.serverId);
    await _finalizeServeItemsSync(row, updated);
  }

  Future<void> _syncMarkKitchenServedPending(CachedProcessOrder row) async {
    final localDetail = _decodeCachedDetail(row.detailJson);
    final serverDetail = await ordersRepo.fetchOrderDetail(row.serverId);
    final localDetails = _detailRows(localDetail);
    final serverById = _detailMapById(_detailRows(serverDetail));

    final idsToMark = <int>[];
    for (final localItem in localDetails) {
      final id = orderDetailId(localItem);
      if (id == null) continue;
      if (!isDetailServedStatus(detailStatusOf(localItem))) continue;

      final serverItem = serverById[id];
      if (serverItem == null) continue;
      if (isDetailServedStatus(detailStatusOf(serverItem))) continue;

      idsToMark.add(id);
    }

    if (idsToMark.isNotEmpty) {
      try {
        await ordersRepo.markServedByKitchen(
          id: row.serverId,
          detailIds: idsToMark,
        );
      } on DioException catch (e) {
        if (!_isServeWarning(e)) rethrow;
      }
    }

    final updated = await ordersRepo.fetchOrderDetail(row.serverId);
    await _finalizeServeItemsSync(row, updated);
  }

  Future<void> clearCashierSessionData() async {
    await cachedPaymentOrdersDao.clearAll();
    await cachedProcessOrdersDao.clearAll();
    await cachedDoneOrdersDao.clearAll();
    await localOrdersDao.clearAll();
  }

  String _resolvePaymentMethodForSync(LocalOrder order) {
    String? normalizeBackendMethod(String? raw) {
      if (raw == null) return null;
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return null;

      final upper = trimmed.toUpperCase();
      if (upper == 'OPENBILL') return null;
      if (upper == 'CASH' || upper == 'QRIS') return upper;
      if (RegExp(r'^\d+$').hasMatch(trimmed)) return trimmed;
      return null;
    }

    final fromEffective = normalizeBackendMethod(order.paymentMethodEffective);
    if (fromEffective != null) return fromEffective;

    final fromSelected = normalizeBackendMethod(order.paymentMethodSelected);
    if (fromSelected != null) return fromSelected;

    final manualJson = order.manualPaymentRawJson;
    if (manualJson != null && manualJson.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(manualJson);
        if (decoded is Map) {
          final id = decoded['id'];
          if (id != null) {
            final idStr = id.toString().trim();
            if (RegExp(r'^\d+$').hasMatch(idStr)) return idStr;
          }
        }
      } catch (_) {}
    }

    return 'CASH';
  }

  String? _paymentTypeForExpectedPayable(
    LocalOrder order,
    String paymentMethod,
    Map<String, dynamic>? detail,
  ) {
    final upper = paymentMethod.toUpperCase();
    if (upper == 'CASH' || upper == 'QRIS') return upper;
    if (RegExp(r'^\d+$').hasMatch(paymentMethod)) {
      final manualJson = order.manualPaymentRawJson;
      if (manualJson != null && manualJson.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(manualJson);
          if (decoded is Map) {
            final id = decoded['id']?.toString();
            if (id == paymentMethod) {
              final type = decoded['payment_type']?.toString().trim();
              if (type != null && type.isNotEmpty) return type;
            }
          }
        } catch (_) {}
      }

      final latest = detail?['latest_payment'];
      if (latest is Map) {
        final type = latest['payment_type']?.toString().trim();
        if (type != null && type.isNotEmpty) return type;
      }
    }

    return paymentMethod;
  }

  Future<void> _syncPayment(LocalOrder order, int serverId) async {
    final paymentMethod = _resolvePaymentMethodForSync(order);

    Map<String, dynamic>? detail;
    int? resolvedLatestPaymentId;

    try {
      detail = await ordersRepo.fetchOrderDetail(serverId);
      final latest = detail['latest_payment'];
      if (latest is Map) {
        final status = (latest['payment_status'] ?? '').toString().toUpperCase();
        final paymentType =
            (latest['payment_type'] ?? '').toString().toUpperCase();
        final methodUpper = paymentMethod.toUpperCase();
        final completingPendingQris =
            methodUpper == 'QRIS' && paymentType == 'QRIS';
        final completingPendingManual =
            RegExp(r'^\d+$').hasMatch(paymentMethod) &&
            paymentType.startsWith('MANUAL_');

        if ((status == 'PENDING' || status == 'PAYMENT REQUEST') &&
            (completingPendingQris || completingPendingManual)) {
          final id = latest['id'];
          if (id != null) {
            resolvedLatestPaymentId = int.tryParse(id.toString());
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ fetch detail before payment sync failed for serverId=$serverId: $e');
    }

    final paymentTypeForExpected = _paymentTypeForExpectedPayable(
      order,
      paymentMethod,
      detail,
    );

    final expectedPayable = detail != null
        ? CashRoundingHelpers.expectedPayableFromServerDetail(
            detail,
            paymentTypeForExpected,
          )
        : CashRoundingHelpers.expectedPayable(
            subtotal: order.subtotal,
            isPpnActive: order.isPpnActive,
            ppn: order.ppnPercent,
            paymentType: paymentTypeForExpected,
            cashRoundingUnit: order.cashRoundingUnit ?? 0,
            storedRoundingAmount: order.cashRoundingAmount,
          );

    num paidAmount = order.paidAmountLocal ?? order.grandTotal;
    if (order.paymentConfirmedAtLocal != null) {
      if (paidAmount < expectedPayable) {
        paidAmount = expectedPayable;
      }
    } else if (paidAmount < expectedPayable) {
      paidAmount = expectedPayable;
    }

    final changeAmount = paidAmount > expectedPayable
        ? paidAmount - expectedPayable
        : 0;

    debugPrint(
      '💳 sync payment request '
      'localId=${order.localId} '
      'serverId=$serverId '
      'method=$paymentMethod '
      'paid=$paidAmount '
      'expected=$expectedPayable '
      'change=$changeAmount '
      'lastPaymentId=$resolvedLatestPaymentId '
      'proof=${order.cashierProofImageLocalPath}',
    );

    final response = await ordersRepo.paymentOrder(
      id: serverId,
      paidAmount: paidAmount,
      changeAmount: changeAmount,
      paymentMethod: paymentMethod,
      lastPaymentId: resolvedLatestPaymentId?.toString(),
      cashierProofImagePath: order.cashierProofImageLocalPath,
    );

    final status = response['status'];
    final accepted = status == true || status == 'true' || status == 1;
    if (!accepted) {
      final message = response['message']?.toString().trim();
      throw Exception(
        message != null && message.isNotEmpty
            ? message
            : 'Pembayaran ditolak server',
      );
    }
  }

  dynamic _findFirstByKeys(dynamic source, List<String> keys) {
    if (source == null) return null;

    if (source is Map) {
      for (final key in keys) {
        if (source.containsKey(key) && source[key] != null) {
          return source[key];
        }
      }

      for (final value in source.values) {
        final found = _findFirstByKeys(value, keys);
        if (found != null) return found;
      }
    }

    if (source is List) {
      for (final item in source) {
        final found = _findFirstByKeys(item, keys);
        if (found != null) return found;
      }
    }

    return null;
  }

  bool _isRemoteOrderGone(Object error) {
    if (error is DioException) {
      final code = error.response?.statusCode;
      if (code == 404 || code == 410) return true;

      final data = error.response?.data;
      final message = data is Map
          ? (data['message'] ?? data['error'] ?? '').toString().toLowerCase()
          : data?.toString().toLowerCase() ?? '';

      return message.contains('not found') ||
          message.contains('tidak ditemukan') ||
          message.contains('no query results');
    }

    final message = error.toString().toLowerCase();
    return message.contains('404') &&
        (message.contains('not found') ||
            message.contains('tidak ditemukan') ||
            message.contains('no query results'));
  }

  Future<void> _discardRemoteOrder({
    required int serverId,
    String? localOrderId,
    required String reason,
  }) async {
    debugPrint(
      'discard remote-gone order '
      'serverId=$serverId '
      'localId=$localOrderId '
      'reason=$reason',
    );

    await cachedPaymentOrdersDao.deleteCachedOrderByServerId(serverId);
    await cachedProcessOrdersDao.deleteByServerId(serverId);
    await cachedDoneOrdersDao.deleteByServerId(serverId);

    if (localOrderId != null && localOrderId.trim().isNotEmpty) {
      await localOrdersDao.deleteOrderByLocalId(localOrderId);
    } else {
      await localOrdersDao.deleteOrderByServerId(serverId);
    }
  }
}
