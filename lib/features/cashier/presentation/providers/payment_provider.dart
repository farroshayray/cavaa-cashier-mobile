import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';
import 'package:drift/drift.dart';
import '../../data/models/orders_repository.dart';
import '/features/cashier/data/local/db/daos/cached_payment_methods_dao.dart';
import '/features/cashier/data/local/db/daos/booking_orders_dao.dart';
import '/features/cashier/data/local/db/daos/cache_dao.dart';
import '/features/cashier/data/local/db/mappers/order_mirror_mapper.dart';
import '/features/cashier/data/sync/manual_payment_image_cache.dart';
import '/features/cashier/data/sync/order_detail_resolver.dart';
import '/features/cashier/data/sync/order_stage_resolver.dart';
import '/features/cashier/data/sync/order_tab_coordinator.dart';
import '/features/cashier/data/sync/order_tab_item_mapper.dart';
import '/features/cashier/presentation/utils/order_tab_sort.dart';
import '/features/cashier/data/local/db/sync/sync_service.dart';
import '/features/cashier/presentation/providers/done_provider.dart';
import '/features/cashier/presentation/providers/process_provider.dart';
import '/core/services/connectivity_status_provider.dart';
import '/features/cashier/presentation/utils/order_edit_utils.dart';
import '/features/cashier/utils/cash_rounding_helpers.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '/core/config/env.dart';

class PaymentProvider extends ChangeNotifier {
  final OrdersRepository repo;
  final CachedPaymentMethodsDao cachedPaymentMethodsDao;
  final ConnectivityStatusProvider connectivity;
  final BookingOrdersDao bookingOrdersDao;
  final OrderTabCoordinator tabCoordinator;
  final SyncService? syncService;

  PaymentProvider({
    required this.repo,
    required this.cachedPaymentMethodsDao,
    required this.connectivity,
    required this.bookingOrdersDao,
    required this.tabCoordinator,
    this.syncService,
  });

  bool isLoading = false;
  String? error;

  String query = '';
  List<Map<String, dynamic>> items = [];
  Future<void>? _loadInFlight;
  bool _loadInFlightSilent = true;

  Future<void> load({bool silent = false}) {
    if (_loadInFlight != null) {
      if (!silent) _loadInFlightSilent = false;
      return _loadInFlight!;
    }

    _loadInFlightSilent = silent;
    _loadInFlight = _loadImpl(silent: _loadInFlightSilent).whenComplete(() {
      _loadInFlight = null;
      _loadInFlightSilent = true;
    });
    return _loadInFlight!;
  }

  Future<void> _loadImpl({bool silent = false}) async {
    if (!silent) {
      isLoading = true;
      error = null;
      notifyListeners();
    }

    try {
      await bookingOrdersDao.reconcileDuplicateMirrors();
      if (connectivity.isOnline) {
        unawaited(
          ManualPaymentImageCache.prefetchMissingFromCache(bookingOrdersDao.db),
        );
      }

      final processRows = await bookingOrdersDao.getProcessTabOrders();
      final doneRows = await bookingOrdersDao.getDoneTabOrders();

      final pendingFinishServerIds = processRows
          .where((e) =>
              (e['sync_dirty'] == true || e['sync_dirty'] == 1) &&
              (e['sync_intent']?.toString() ?? '').toUpperCase() == 'FINISH')
          .map((e) => _toInt(e['id']))
          .whereType<int>()
          .toSet();

      final processServerIds = processRows
          .where((e) {
            final status = (e['order_status'] ?? '').toString();
            if ((e['payment_method'] ?? '').toString() == 'OPENBILL' ||
                status.startsWith('OPENBILL')) {
              if (status == 'UNPAID' ||
                  (e['sync_intent']?.toString() ?? '').toUpperCase() == 'FINISH' ||
                  status == 'SERVED') {
                return false;
              }
            }
            const activeProcessStatuses = {
              'PROCESSED',
              'PAID',
              'OPENBILL_WAITING_ORDER',
              'OPENBILL_CONFIRMATION',
            };
            return activeProcessStatuses.contains(status);
          })
          .map((e) => _toInt(e['id']))
          .whereType<int>()
          .toSet();

      final doneServerIds = doneRows
          .map((e) => _toInt(e['id']))
          .whereType<int>()
          .toSet();

      final doneOrderCodes = doneRows
          .map((e) => (e['booking_order_code'] ?? '').toString().trim())
          .where((e) => e.isNotEmpty)
          .toSet();

      var mirrorOrders = await bookingOrdersDao.getPaymentTabOrders(
        query: query.isEmpty ? null : query,
      );

      var dedupedMirrorOrders = _dedupePaymentMirrorRows(mirrorOrders);

      if (connectivity.isOnline &&
          await _reconcileOpenbillPaymentReadyFromServer(dedupedMirrorOrders)) {
        mirrorOrders = await bookingOrdersDao.getPaymentTabOrders(
          query: query.isEmpty ? null : query,
        );
        dedupedMirrorOrders = _dedupePaymentMirrorRows(mirrorOrders);
      }

      items = dedupedMirrorOrders
          .map((o) => _normalizeMirrorPaymentItem(o, pendingFinishServerIds))
          .where((e) {
            final sid = _toInt(e['server_id'] ?? e['id']);
            final code = (e['booking_order_code'] ?? e['client_order_code'] ?? '')
                .toString()
                .trim();

            final hiddenBecauseAlreadyInProcess =
                !_isOpenbillReadyForPayment(e) &&
                sid != null &&
                sid > 0 &&
                processServerIds.contains(sid);

            final hiddenBecauseAlreadyInDone =
                (sid != null && sid > 0 && doneServerIds.contains(sid)) ||
                (code.isNotEmpty && doneOrderCodes.contains(code));

            return !(hiddenBecauseAlreadyInProcess || hiddenBecauseAlreadyInDone);
          })
          .toList();

      items.sort(compareOrdersOldestFirst);
    } catch (e) {
      error = e.toString();
    } finally {
      if (!silent) {
        isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<void> clearStateAndCache() async {
    isLoading = false;
    error = null;
    query = '';
    items = [];
    notifyListeners();
  }

  bool _isOpenbillReadyForPayment(Map<String, dynamic> e) {
    final status = (e['order_status'] ?? '').toString();
    final isOpenbill =
        _toBool(e['openbill_flag']) ||
        (e['payment_method'] ?? '').toString() == 'OPENBILL' ||
        status.startsWith('OPENBILL');
    return isOpenbill && status == 'UNPAID';
  }

  /// When customer adds items on web, server regresses to OPENBILL_CONFIRMATION
  /// while local mirror may still be payment-ready UNPAID.
  Future<bool> _reconcileOpenbillPaymentReadyFromServer(
    List<Map<String, dynamic>> mirrorRows,
  ) async {
    var changed = false;

    for (final row in mirrorRows) {
      if (!_isOpenbillReadyForPayment(row)) continue;

      final serverId = _toInt(row['id']);
      if (serverId == null || serverId <= 0) continue;

      try {
        final detail = await repo.fetchOrderDetail(serverId);
        final serverStatus = (detail['order_status'] ?? '').toString().toUpperCase();
        if (serverStatus != 'OPENBILL_CONFIRMATION' &&
            serverStatus != 'OPENBILL_WAITING_ORDER') {
          continue;
        }

        await bookingOrdersDao.upsertFromServer(detail);
        changed = true;
      } catch (e) {
        debugPrint('PaymentProvider openbill reconcile failed for $serverId: $e');
      }
    }

    return changed;
  }

  List<Map<String, dynamic>> _dedupePaymentMirrorRows(
    List<Map<String, dynamic>> rows,
  ) {
    final byKey = <String, Map<String, dynamic>>{};

    for (final row in rows) {
      final key = _paymentMirrorDedupeKey(row);
      final existing = byKey[key];
      if (existing == null || _preferPaymentMirrorRow(row, existing)) {
        byKey[key] = row;
      }
    }

    return byKey.values.toList();
  }

  String _paymentMirrorDedupeKey(Map<String, dynamic> row) {
    final serverId = _toInt(row['id']);
    if (serverId != null && serverId > 0) return 'id:$serverId';

    final clientUuid = row['local_client_uuid']?.toString().trim();
    if (clientUuid != null && clientUuid.isNotEmpty) {
      return 'uuid:$clientUuid';
    }

    final code = (row['booking_order_code'] ?? '').toString().trim();
    if (code.isNotEmpty) return 'code:$code';

    final name = (row['customer_name'] ?? '').toString().trim().toLowerCase();
    final table = (row['table_id'] ?? row['table_no'] ?? '').toString();
    return 'name:$name|$table';
  }

  bool _preferPaymentMirrorRow(
    Map<String, dynamic> candidate,
    Map<String, dynamic> current,
  ) {
    final candidateServerId = _toInt(candidate['id']) ?? 0;
    final currentServerId = _toInt(current['id']) ?? 0;
    if (candidateServerId > 0 && currentServerId <= 0) return true;
    if (candidateServerId <= 0 && currentServerId > 0) return false;

    final candidateDirty =
        candidate['sync_dirty'] == true || candidate['sync_dirty'] == 1;
    final currentDirty = current['sync_dirty'] == true || current['sync_dirty'] == 1;
    if (candidateDirty && !currentDirty) return true;
    if (!candidateDirty && currentDirty) return false;

    final candidateDetails =
        ((candidate['order_details'] as List?) ?? []).length;
    final currentDetails = ((current['order_details'] as List?) ?? []).length;
    return candidateDetails > currentDetails;
  }

  Map<String, dynamic> _normalizeMirrorPaymentItem(
    Map<String, dynamic> row,
    Set<int> pendingFinishServerIds,
  ) {
    final item = OrderTabItemMapper.toPaymentItem(row);
    final serverId = _toInt(item['id']);
    final isPendingFinish =
        serverId != null && pendingFinishServerIds.contains(serverId);
    if (isPendingFinish) {
      item['sync_status'] = 'PENDING_FINISH';
    }
    return item;
  }

  /// Moves order to the correct tab after payment (PAID vs open-bill SERVED).
  Future<void> afterPaymentSuccess({
    required int serverId,
    Map<String, dynamic>? orderSnapshot,
    Map<String, dynamic>? apiResponse,
    bool offline = false,
    ProcessProvider? process,
    DoneProvider? done,
    num? paidAmount,
    num? changeAmount,
    String? paymentMethod,
    bool reloadTabs = true,
    bool backgroundSync = true,
  }) async {
    final snapshot = orderSnapshot ?? <String, dynamic>{};
    final nextStatus = OrderStageResolver.resolveAfterPayment(
      orderBeforePay: snapshot,
      apiResponse: apiResponse,
    );

    final resolvedPaymentMethod = paymentMethod ??
        snapshot['payment_method']?.toString();

    final extras = <String, dynamic>{
      if (paidAmount != null) 'paid_amount': paidAmount,
      if (changeAmount != null) 'change_amount': changeAmount,
      if (resolvedPaymentMethod != null && resolvedPaymentMethod.isNotEmpty)
        'payment_method': resolvedPaymentMethod,
    };

    final updatedSnapshot = {
      ...snapshot,
      'order_status': nextStatus,
      if (resolvedPaymentMethod != null) 'payment_method': resolvedPaymentMethod,
      if (isOpenBillOrder(snapshot)) 'openbill_flag': true,
    };

    debugPrint(
      'afterPaymentSuccess resolved_status=$nextStatus '
      'openbill=${isOpenBillOrder(snapshot)} serverId=$serverId '
      'reloadTabs=$reloadTabs backgroundSync=$backgroundSync',
    );

    final clientUuid = (snapshot['local_client_uuid'] ??
            snapshot['local_id'] ??
            '')
        .toString()
        .trim();
    final useClientUuid = serverId <= 0 && clientUuid.isNotEmpty;

    Future<void> applyTransition() async {
      if (useClientUuid) {
        await tabCoordinator.transitionOrderStageByClientUuid(
          clientUuid: clientUuid,
          orderStatus: nextStatus,
          syncIntent: offline ? 'PAY' : null,
          syncDirty: offline,
          extras: extras.isEmpty ? null : extras,
        );
        return;
      }

      if (serverId <= 0) {
        debugPrint(
          'afterPaymentSuccess skipped transition: no serverId or clientUuid',
        );
        return;
      }

      await tabCoordinator.transitionOrderStage(
        serverId: serverId,
        orderStatus: nextStatus,
        syncIntent: offline ? 'PAY' : null,
        syncDirty: offline,
        extras: extras.isEmpty ? null : extras,
        orderSnapshot: updatedSnapshot,
      );
    }

    if (reloadTabs && process != null && done != null) {
      if (useClientUuid) {
        await applyTransition();
        await bookingOrdersDao.reconcileDuplicateMirrors();
        await tabCoordinator.reloadAllTabs(
          payment: this,
          process: process,
          done: done,
        );
      } else if (serverId > 0) {
        await tabCoordinator.transitionAndReload(
          serverId: serverId,
          orderStatus: nextStatus,
          syncIntent: offline ? 'PAY' : null,
          syncDirty: offline,
          extras: extras.isEmpty ? null : extras,
          orderSnapshot: updatedSnapshot,
          payment: this,
          process: process,
          done: done,
        );
      } else {
        await tabCoordinator.reloadAllTabs(
          payment: this,
          process: process,
          done: done,
        );
      }
    } else {
      await applyTransition();
      if (useClientUuid) {
        await bookingOrdersDao.reconcileDuplicateMirrors();
      }
      if (reloadTabs) {
        await load(silent: true);
      } else {
        debugPrint('afterPaymentSuccess mirrorOnly serverId=$serverId status=$nextStatus');
      }
    }

    if (!offline && backgroundSync) {
      unawaited(_backgroundSyncAndReload(
        process: reloadTabs ? process : null,
        done: reloadTabs ? done : null,
      ));
    }
  }

  Future<void> _backgroundSyncAndReload({
    ProcessProvider? process,
    DoneProvider? done,
  }) async {
    final sync = syncService;
    if (sync == null) return;

    try {
      await sync.syncPendingOrders();
      if (process != null && done != null) {
        await tabCoordinator.reloadAllTabs(
          payment: this,
          process: process,
          done: done,
        );
      } else {
        await load(silent: true);
      }
    } catch (e) {
      debugPrint('background sync after payment failed: $e');
    }
  }

  void setQuery(String q) {
    query = q;
    notifyListeners();
  }

  Future<Map<String, dynamic>> getOrderDetail(int id) async {
    return repo.fetchOrderDetail(id);
  }

  Future<void> confirmPaymentFromRow({
    required Map<String, dynamic> row,
    required num paidAmount,
    required num changeAmount,
    String? paymentMethod,
    String? cashierProofImagePath,
    String? lastPaymentId,
  }) async {
    final isStockConflict =
        (row['sync_status'] ?? '').toString() == 'STOCK_CONFLICT';
    final isOnline = connectivity.isOnline && !isStockConflict;

    if (isOnline) {
      final serverId = _toInt(row['server_id'] ?? row['id']);
      if (serverId == null || serverId <= 0) {
        throw Exception('ID order tidak valid untuk pembayaran online');
      }

      final payResp = await repo.paymentOrder(
        id: serverId,
        paidAmount: paidAmount,
        changeAmount: changeAmount,
        paymentMethod: paymentMethod,
        lastPaymentId: lastPaymentId,
        cashierProofImagePath: cashierProofImagePath,
      );

      await afterPaymentSuccess(
        serverId: serverId,
        orderSnapshot: row,
        apiResponse: payResp,
        offline: false,
        paidAmount: paidAmount,
        changeAmount: changeAmount,
        paymentMethod: paymentMethod,
      );
      return;
    }

    await confirmPaymentOffline(
      order: row,
      paidAmount: paidAmount,
      changeAmount: changeAmount,
      selectedPaymentMethod: paymentMethod,
      cashierProofImagePath: cashierProofImagePath,
      lastPaymentId: lastPaymentId,
    );

    final serverId = _toInt(row['server_id'] ?? row['id']);
    if (serverId != null && serverId > 0) {
      await afterPaymentSuccess(
        serverId: serverId,
        orderSnapshot: row,
        offline: true,
        paidAmount: paidAmount,
        changeAmount: changeAmount,
        paymentMethod: paymentMethod,
      );
    } else {
      await load();
    }
  }

  Future<void> confirmPaymentOffline({
    required Map<String, dynamic> order,
    required num paidAmount,
    required num changeAmount,
    String? selectedPaymentMethod,
    String? cashierProofImagePath,
    String? lastPaymentId,
  }) async {
    final clientUuid = (order['local_client_uuid'] ??
            order['local_id'] ??
            '')
        .toString();
    final serverId = _toInt(order['server_id'] ?? order['id']);
    final paymentMethod =
        (selectedPaymentMethod ?? order['payment_method'] ?? 'CASH').toString();

    if (clientUuid.isNotEmpty) {
      Map<String, dynamic>? localFilePaths;
      if (cashierProofImagePath != null && cashierProofImagePath.trim().isNotEmpty) {
        final persisted = await bookingOrdersDao.persistCashierProofImage(
          clientUuid: clientUuid,
          sourcePath: cashierProofImagePath,
        );
        if (persisted != null) {
          localFilePaths = {'cashier_proof': persisted};
        }
      }

      await bookingOrdersDao.markIntent(
        clientUuid,
        'PAY',
        extras: {
          'paid_amount': paidAmount,
          'change_amount': changeAmount,
          'payment_method': paymentMethod,
          'order_status': OrderStageResolver.resolveAfterPayment(
            orderBeforePay: order,
          ),
          if (localFilePaths != null) 'local_file_paths': localFilePaths,
        },
      );
      return;
    }

    if (serverId != null && serverId > 0) {
      await tabCoordinator.transitionOrderStage(
        serverId: serverId,
        orderStatus: OrderStageResolver.resolveAfterPayment(
          orderBeforePay: order,
        ),
        syncIntent: 'PAY',
        syncDirty: true,
        orderSnapshot: order,
        extras: {
          'paid_amount': paidAmount,
          'change_amount': changeAmount,
          'payment_method': paymentMethod,
        },
      );
    }
  }
  

  Future<Map<String, dynamic>> getPrintDetail(int id) async {
    return repo.fetchPrintDetail(id);
  }

  Future<void> deleteOrder(int id) async {
    try {
      await repo.softDeleteOrder(id);
      await tabCoordinator.markOrderDeleted(serverId: id);
      await load();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteOrderItem(Map<String, dynamic> item, {required bool isOnline}) async {
    final clientUuid =
        (item['local_client_uuid'] ?? item['local_id'] ?? '').toString();
    final serverId = _toInt(item['server_id']) ?? _toInt(item['id']);

    try {
      if (clientUuid.isNotEmpty && (serverId == null || serverId <= 0)) {
        await tabCoordinator.markOrderDeleted(
          clientUuid: clientUuid,
          hardRemove: true,
        );
        await load();
        return;
      }

      if (serverId == null || serverId <= 0) {
        throw Exception('ID order tidak valid');
      }

      if (!isOnline) {
        await tabCoordinator.markOrderPendingDelete(serverId: serverId);
        await load();
        return;
      }

      await repo.softDeleteOrder(serverId);
      await tabCoordinator.markOrderDeleted(serverId: serverId);
      await load();
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> payOrder({
    required int id,
    required num paidAmount,
    required num changeAmount,
    String? note,
    String? email,
    String? lastPaymentId,
    String? cashierProofImagePath,
  }) async {
    final row = <String, dynamic>{'id': id, 'server_id': id};

    await confirmPaymentOffline(
      order: row,
      paidAmount: paidAmount,
      changeAmount: changeAmount,
      selectedPaymentMethod: note,
      cashierProofImagePath: cashierProofImagePath,
      lastPaymentId: lastPaymentId,
    );

    return {
      'status': true,
      'message': 'Pembayaran diantrekan untuk sinkronisasi',
      'saved_local': true,
    };
  }

  Future<Map<String, dynamic>> getOrderDetailFromListItem(
    Map<String, dynamic> row,
  ) async {
    final clientUuid = (row['local_client_uuid'] ?? row['local_id'] ?? '')
        .toString();
    final serverId = _toInt(row['server_id'] ?? row['id']);

    if (serverId == null || serverId <= 0) {
      if (clientUuid.isEmpty) {
        throw Exception('Order ID tidak valid');
      }
      final bundle = await bookingOrdersDao.getBundleByClientUuid(clientUuid);
      if (bundle == null) {
        throw Exception('Detail order offline tidak tersedia');
      }
      final map = await _bundleToDetailMap(bundle);
      return _enrichOrderDetailPaymentData(map);
    }

    if (connectivity.isOnline) {
      try {
        final detail = await repo.fetchOrderDetail(serverId);
        await bookingOrdersDao.upsertFromServer(detail);
        await _cacheManualPaymentMethodFromDetail(detail);
        return _enrichOrderDetailPaymentData(detail);
      } catch (_) {
        final mirror = await bookingOrdersDao.getByServerId(serverId);
        if (mirror != null) {
          final bundle = await bookingOrdersDao.getBundleByClientUuid(
            mirror.clientUuid,
          );
          if (bundle != null) {
            return _enrichOrderDetailPaymentData(
              await _bundleToDetailMap(bundle),
            );
          }
        }
        rethrow;
      }
    }

    if (OrderDetailResolver.hasEmbeddedDetails(row)) {
      return _enrichOrderDetailPaymentData(
        OrderDetailResolver.detailFromListRow(row),
      );
    }

    if (clientUuid.isNotEmpty) {
      final bundle = await bookingOrdersDao.getBundleByClientUuid(clientUuid);
      if (bundle != null) {
        return _enrichOrderDetailPaymentData(await _bundleToDetailMap(bundle));
      }
    }

    final mirror = await bookingOrdersDao.getByServerId(serverId);
    if (mirror != null) {
      final bundle = await bookingOrdersDao.getBundleByClientUuid(
        mirror.clientUuid,
      );
      if (bundle != null) {
        return _enrichOrderDetailPaymentData(await _bundleToDetailMap(bundle));
      }
    }

    throw Exception('Detail order offline tidak tersedia');
  }

  Future<Map<String, dynamic>> _bundleToDetailMap(
    BookingOrderBundle bundle,
  ) async {
    final map = OrderTabItemMapper.toPaymentItem(
      OrderMirrorMapper.orderToUiMap(bundle.order),
    );
    map['order_details'] = bundle.details.map((d) {
      final detailMap = OrderMirrorMapper.detailToUiMap(d);
      detailMap['order_detail_options'] =
          (bundle.optionsByDetailUuid[d.clientDetailUuid] ?? [])
              .map(OrderMirrorMapper.optionToUiMap)
              .toList();
      return detailMap;
    }).toList();
    return OrderDetailResolver.detailFromListRow(map);
  }

  /// Order detail dari API tetap dipakai untuk status/items,
  /// tapi daftar metode pembayaran + gambar QRIS diambil dari cache lokal
  /// (hasil sync `GET /products` di tab Pembelian).
  Future<Map<String, dynamic>> _enrichOrderDetailPaymentData(
    Map<String, dynamic> detail,
  ) async {
    final cloned = Map<String, dynamic>.from(detail);

    final cachedMethods =
        await cachedPaymentMethodsDao.buildAvailablePaymentMethodsList();
    if (cachedMethods.isNotEmpty) {
      cloned['available_payment_methods'] = cachedMethods;
    }

    await _applyCashRoundingFields(cloned);

    final method = (cloned['payment_method'] ?? '').toString();

    if (method != 'manual_qris' &&
        method != 'manual_tf' &&
        method != 'manual_ewallet') {
      return cloned;
    }

    int? serverManualPaymentId;

    final latestRaw = cloned['latest_payment'];
    if (latestRaw is Map) {
      serverManualPaymentId = _toInt(
        latestRaw['owner_manual_payment_id'] ??
        (latestRaw['owner_manual_payment'] is Map
            ? latestRaw['owner_manual_payment']['id']
            : null),
      );
    }

    final manual = await cachedPaymentMethodsDao.buildManualPaymentMap(
      serverManualPaymentId: serverManualPaymentId,
      paymentMethod: method,
    );

    if (manual == null) return cloned;

    final latest = latestRaw is Map
        ? Map<String, dynamic>.from(latestRaw)
        : <String, dynamic>{};

    final ownerManualRaw = latest['owner_manual_payment'];
    final ownerManual = ownerManualRaw is Map
        ? Map<String, dynamic>.from(ownerManualRaw)
        : <String, dynamic>{};

    ownerManual['id'] ??= manual['server_manual_payment_id'];
    ownerManual['payment_type'] ??= manual['payment_type'];
    ownerManual['provider_name'] ??= manual['provider_name'];
    ownerManual['provider_account_name'] ??= manual['provider_account_name'];
    ownerManual['provider_account_no'] ??= manual['provider_account_no'];
    ownerManual['qris_image_url'] ??= manual['qris_image_url'];
    ownerManual['qris_image_local_path'] ??= manual['qris_image_local_path'];

    latest['owner_manual_payment'] = ownerManual;
    cloned['latest_payment'] = latest;

    return cloned;
  }

  Future<void> _applyCashRoundingFields(Map<String, dynamic> detail) async {
    final partnerUnit = await CacheDao(cachedPaymentMethodsDao.db)
        .getPartnerCashRoundingUnit();
    final unit = CashRoundingHelpers.resolveCashRoundingUnit(
      detail,
      partnerCashRoundingUnit: partnerUnit,
    );
    if (unit > 0) {
      detail['cash_rounding_unit'] = unit;
    }
  }

  Future<Map<String, dynamic>> enrichPaymentMethodInstruction(
    Map<String, dynamic> raw,
  ) async {
    final type = (raw['payment_type'] ?? raw['type'] ?? '').toString();
    final normalized = <String, dynamic>{
      'payment_type': type,
      'provider_name': raw['provider_name'],
      'provider_account_name': raw['provider_account_name'],
      'provider_account_no': raw['provider_account_no'],
      'qris_image_url': raw['qris_image_url'],
      'qris_image_local_path': raw['qris_image_local_path'],
      'additional_info': raw['additional_info'],
      'value': raw['value'],
      'label': raw['label'],
    };

    final manualId = _toInt(raw['value']);
    if (manualId == null || manualId <= 0) return normalized;

    final cached = await cachedPaymentMethodsDao.buildManualPaymentMap(
      serverManualPaymentId: manualId,
    );
    if (cached == null) return normalized;

    String? pickString(dynamic primary, dynamic fallback) {
      final p = primary?.toString().trim();
      if (p != null && p.isNotEmpty) return p;
      final f = fallback?.toString().trim();
      if (f != null && f.isNotEmpty) return f;
      return null;
    }

    normalized['payment_type'] = pickString(normalized['payment_type'], cached['payment_type']) ?? type;
    normalized['provider_name'] = pickString(normalized['provider_name'], cached['provider_name']);
    normalized['provider_account_name'] =
        pickString(normalized['provider_account_name'], cached['provider_account_name']);
    normalized['provider_account_no'] =
        pickString(normalized['provider_account_no'], cached['provider_account_no']);
    normalized['qris_image_url'] =
        pickString(normalized['qris_image_url'], cached['qris_image_url']);
    normalized['qris_image_local_path'] =
        pickString(cached['qris_image_local_path'], normalized['qris_image_local_path']);

    return normalized;
  }

  String _manualTypeLabelForCache(String method) {
    if (method == 'manual_tf') return 'Transfer Manual';
    if (method == 'manual_ewallet') return 'E-Wallet';
    if (method == 'manual_qris') return 'QR Statis';
    return method;
  }

  Future<void> _cacheManualPaymentMethodFromDetail(Map<String, dynamic> detail) async {
    final method = (detail['payment_method'] ?? '').toString();

    if (method != 'manual_qris' &&
        method != 'manual_tf' &&
        method != 'manual_ewallet') {
      return;
    }

    Map<String, dynamic>? source;
    int? serverManualPaymentId;

    if (detail['latest_payment'] is Map &&
        detail['latest_payment']['owner_manual_payment'] is Map) {
      final op = Map<String, dynamic>.from(detail['latest_payment']['owner_manual_payment']);

      serverManualPaymentId = _toInt(op['id']);

      source = {
        'provider_name': op['provider_name'],
        'provider_account_name': op['provider_account_name'],
        'provider_account_no': op['provider_account_no'],
        'qris_image_url': op['qris_image_url'],
      };
    } else if (detail['payment_request'] is Map) {
      final pr = Map<String, dynamic>.from(detail['payment_request']);

      source = {
        'provider_name': pr['manual_provider_name'],
        'provider_account_name': pr['manual_provider_account_name'],
        'provider_account_no': pr['manual_provider_account_no'],
        'qris_image_url': pr['manual_payment_image'],
      };
    }

    if (source == null) return;

    final rawImagePath = source['qris_image_url']?.toString();
    String? localImagePath;

    if (rawImagePath != null && rawImagePath.trim().isNotEmpty) {
      localImagePath = await _downloadManualPaymentImageToLocal(rawImagePath);
    }

    final cacheKey = serverManualPaymentId != null
        ? 'manual_method_$serverManualPaymentId'
        : '${method}_${source['provider_name']}_${source['provider_account_name']}';

    await cachedPaymentMethodsDao.upsertManualPaymentMethod(
      localKey: cacheKey,
      kind: method,
      label: _manualTypeLabelForCache(method),
      providerName: source['provider_name']?.toString(),
      providerAccountName: source['provider_account_name']?.toString(),
      providerAccountNo: source['provider_account_no']?.toString(),
      qrisImageUrl: source['qris_image_url']?.toString(),
      qrisImageLocalPath: localImagePath,
      serverManualPaymentId: serverManualPaymentId,
      raw: source,
    );

    debugPrint('✅ manual payment method cached: $cacheKey');
  }

  Future<String?> _downloadManualPaymentImageToLocal(String rawPath) {
    return ManualPaymentImageCache.downloadToLocal(rawPath);
  }

  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  num _toNum(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v;
    return num.tryParse(v.toString()) ?? 0;
  }

  bool _toBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    final s = v.toString().toLowerCase();
    return s == '1' || s == 'true';
  }
}
