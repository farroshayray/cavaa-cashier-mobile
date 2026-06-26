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

        debugPrint(
          '✅ STEP PURCHASE done '
          'localId=$localOrderId '
          'serverId=$serverId '
          'serverOrderCode=$serverOrderCode',
        );

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

      final isOpenbill =
          (order.paymentMethodSelected ?? order.paymentMethodEffective) ==
          'OPENBILL';

      if (isOpenbill) {
        debugPrint(
          '🔹 STEP OPENBILL check '
          'localId=$localOrderId '
          'orderStatus=${order.orderStatusLocal} '
          'stage=$stage '
          'serverId=$serverId',
        );

        if ((order.orderStatusLocal == 'OPENBILL_WAITING_ORDER' ||
                order.orderStatusLocal == 'UNPAID' ||
                order.orderStatusLocal == 'SERVED') &&
            stage == 'PURCHASED') {
          await ordersRepo.processOrder(serverId!);
          await localOrdersDao.updateBackendSyncStage(localOrderId, 'CONFIRMED');
          stage = 'CONFIRMED';

          debugPrint(
            '✅ STEP OPENBILL CONFIRM done '
            'localId=$localOrderId '
            'serverId=$serverId',
          );

          order = await localOrdersDao.getOrderByLocalId(localOrderId);
          if (order == null) {
            throw Exception('Order hilang setelah sync confirm');
          }
        }

        if ((order.orderStatusLocal == 'UNPAID' ||
                order.orderStatusLocal == 'SERVED') &&
            stage == 'CONFIRMED') {
          await ordersRepo.finishOrder(serverId!);
          await localOrdersDao.updateBackendSyncStage(
            localOrderId,
            'OPENBILL_SERVED',
          );
          stage = 'OPENBILL_SERVED';

          debugPrint(
            '✅ STEP OPENBILL FINISH done '
            'localId=$localOrderId '
            'serverId=$serverId',
          );

          order = await localOrdersDao.getOrderByLocalId(localOrderId);
          if (order == null) {
            throw Exception('Order hilang setelah sync finish');
          }
        }

        if (order.orderStatusLocal == 'SERVED' && stage == 'OPENBILL_SERVED') {
          await _syncPayment(order, serverId!);
          await localOrdersDao.updateBackendSyncStage(localOrderId, 'SERVED');
          stage = 'SERVED';

          debugPrint(
            '✅ STEP OPENBILL PAYMENT done '
            'localId=$localOrderId '
            'serverId=$serverId',
          );

          order = await localOrdersDao.getOrderByLocalId(localOrderId);
          if (order == null) {
            throw Exception('Order hilang setelah sync payment');
          }
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

      // final
      final completed =
          (order.orderStatusLocal == 'UNPAID' && !isOpenbill && stage == 'PURCHASED') ||
          (order.orderStatusLocal == 'OPENBILL_CONFIRMATION' && stage == 'PURCHASED') ||
          (order.orderStatusLocal == 'OPENBILL_WAITING_ORDER' && stage == 'CONFIRMED') ||
          (order.orderStatusLocal == 'UNPAID' && isOpenbill && stage == 'OPENBILL_SERVED') ||
          (order.orderStatusLocal == 'PAID' && stage == 'PAID') ||
          (order.orderStatusLocal == 'PROCESSED' && stage == 'PROCESSED') ||
          (order.orderStatusLocal == 'SERVED' && stage == 'SERVED');

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
      await localOrdersDao.markOrderPending(
        localOrderId,
        error: e.toString(),
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
      orderName: order.customerName,
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
      orderName: order.customerName,
      paymentMethod: paymentMethodForBackend,
      totalAmount: order.subtotal,
      items: itemsPayload,
    );

    debugPrint('🧾 purchase sync raw response for ${order.localId}: $resp');

    return resp;
  }

  Future<void> clearCashierSessionData() async {
    await cachedPaymentOrdersDao.clearAll();
    await cachedProcessOrdersDao.clearAll();
    await cachedDoneOrdersDao.clearAll();
    await localOrdersDao.clearAll();
  }

  Future<void> _syncPayment(LocalOrder order, int serverId) async {
    final paymentMethod =
        order.paymentMethodEffective ?? order.paymentMethodSelected ?? 'CASH';

    Map<String, dynamic>? detail;
    int? resolvedLatestPaymentId;

    try {
      detail = await ordersRepo.fetchOrderDetail(serverId);
      final latest = detail['latest_payment'];
      if (latest is Map) {
        final status = (latest['payment_status'] ?? '').toString().toUpperCase();
        if (status == 'PENDING' || status == 'PAYMENT REQUEST') {
          final id = latest['id'];
          if (id != null) {
            resolvedLatestPaymentId = int.tryParse(id.toString());
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ fetch detail before payment sync failed for serverId=$serverId: $e');
    }

    final expectedPayable = detail != null
        ? CashRoundingHelpers.expectedPayableFromServerDetail(
            detail,
            paymentMethod,
          )
        : CashRoundingHelpers.expectedPayable(
            subtotal: order.subtotal,
            isPpnActive: order.isPpnActive,
            ppn: order.ppnPercent,
            paymentType: paymentMethod,
            cashRoundingUnit: order.cashRoundingUnit ?? 0,
            storedRoundingAmount: order.cashRoundingAmount,
          );

    num paidAmount = order.paidAmountLocal ?? order.grandTotal;
    if (order.paymentConfirmedAtLocal != null) {
      if (paidAmount < expectedPayable) {
        paidAmount = order.grandTotal >= expectedPayable
            ? order.grandTotal
            : expectedPayable;
      }
    } else if (paidAmount < expectedPayable) {
      paidAmount = expectedPayable;
    }

    num changeAmount = order.changeAmountLocal ?? 0;
    if (paidAmount > expectedPayable) {
      changeAmount = paidAmount - expectedPayable;
    } else {
      changeAmount = 0;
    }

    debugPrint(
      '💳 sync payment request '
      'localId=${order.localId} '
      'serverId=$serverId '
      'paid=$paidAmount '
      'expected=$expectedPayable '
      'change=$changeAmount '
      'lastPaymentId=$resolvedLatestPaymentId '
      'proof=${order.cashierProofImageLocalPath}',
    );

    await ordersRepo.paymentOrder(
      id: serverId,
      paidAmount: paidAmount,
      changeAmount: changeAmount,
      paymentMethod: paymentMethod,
      lastPaymentId: resolvedLatestPaymentId?.toString(),
      cashierProofImagePath: order.cashierProofImageLocalPath,
    );
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
