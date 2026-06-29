import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:drift/drift.dart';
import '../../data/models/orders_repository.dart';
import '/features/cashier/data/local/db/daos/local_orders_dao.dart';
import '/features/cashier/data/local/db/daos/cached_payment_orders_dao.dart';
import '/features/cashier/data/local/db/cashier_db.dart';
import '/core/services/connectivity_status_provider.dart';
import '/features/cashier/data/local/db/daos/cached_payment_methods_dao.dart';
import '/features/cashier/data/local/db/daos/cached_process_orders_dao.dart';
import '/features/cashier/data/local/db/daos/cached_done_orders_dao.dart';
import 'dart:convert';
import '/features/cashier/utils/cash_rounding_helpers.dart';
import '/features/cashier/data/local/db/daos/booking_orders_dao.dart';
import '/features/cashier/data/sync/order_stage_resolver.dart';
import '/features/cashier/data/sync/order_tab_coordinator.dart';
import '/features/cashier/data/sync/order_tab_item_mapper.dart';
import '/features/cashier/data/local/db/sync/sync_service.dart';
import '/features/cashier/presentation/providers/done_provider.dart';
import '/features/cashier/presentation/providers/process_provider.dart';
import '/features/cashier/presentation/utils/order_edit_utils.dart';

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '/core/config/env.dart';

class PaymentProvider extends ChangeNotifier {
  final OrdersRepository repo;
  final LocalOrdersDao localOrdersDao;
  final CachedPaymentOrdersDao cachedPaymentOrdersDao;
  final CachedPaymentMethodsDao cachedPaymentMethodsDao;
  final ConnectivityStatusProvider connectivity;
  final CachedProcessOrdersDao cachedProcessOrdersDao;
  final CachedDoneOrdersDao cachedDoneOrdersDao;
  final BookingOrdersDao bookingOrdersDao;
  final OrderTabCoordinator tabCoordinator;
  final SyncService? syncService;

  PaymentProvider({
    required this.repo,
    required this.localOrdersDao,
    required this.cachedPaymentOrdersDao,
    required this.cachedPaymentMethodsDao,
    required this.cachedProcessOrdersDao,
    required this.cachedDoneOrdersDao,
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
      final mergedItems = <Map<String, dynamic>>[];
      bool gotServer = false;

      final advancedLocalOrders =
          await localOrdersDao.getLocallyAdvancedServerOrders();

      final hiddenServerIds = advancedLocalOrders
          .map((e) => e.serverId)
          .whereType<int>()
          .toSet();

      final hiddenOrderCodes = advancedLocalOrders
          .map((e) => e.serverOrderCode ?? e.clientOrderCode)
          .where((e) => e.trim().isNotEmpty)
          .toSet();

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

      final mirrorOrders = await bookingOrdersDao.getPaymentTabOrders(
        query: query.isEmpty ? null : query,
      );

      mergedItems.addAll(
        mirrorOrders.map((o) => _normalizeMirrorPaymentItem(o, pendingFinishServerIds)),
      );
      gotServer = mirrorOrders.isNotEmpty;

      final localOrders = await localOrdersDao.getUnpaidOrders(
        query: query.isEmpty ? null : query,
      );

      final pendingLocalServerIds = <int>{};
      final pendingLocalBookingCodes = <String>{};
      for (final o in localOrders) {
        if (o.syncStatus == 'SYNCED') continue;
        final sid = o.serverId;
        if (sid != null && sid > 0) {
          pendingLocalServerIds.add(sid);
        }
        final code = (o.serverOrderCode ?? o.clientOrderCode).trim();
        if (code.isNotEmpty) {
          pendingLocalBookingCodes.add(code);
        }
      }

      final visibleLocalOrders = localOrders.where((o) {
        final alreadyMirroredOnServer =
            o.syncStatus == 'SYNCED' &&
            o.serverId != null &&
            o.serverId! > 0;

        final hiddenByProcess =
            o.serverId != null && processServerIds.contains(o.serverId);

        final hiddenByDoneId =
            o.serverId != null && doneServerIds.contains(o.serverId);

        final code = (o.serverOrderCode ?? o.clientOrderCode).trim();
        final hiddenByDoneCode =
            code.isNotEmpty && doneOrderCodes.contains(code);

        return !(alreadyMirroredOnServer ||
            hiddenByProcess ||
            hiddenByDoneId ||
            hiddenByDoneCode);
      }).toList();

      final localItems = visibleLocalOrders.map((o) {
        final tableNo = o.tableNoSnapshot ?? '-';
        final roundingFields = CashRoundingHelpers.roundingFieldsFromLocalOrder(
          subtotal: o.subtotal,
          grandTotal: o.grandTotal,
          isPpnActive: o.isPpnActive,
          ppnPercent: o.ppnPercent,
          cashRoundingAmount: o.cashRoundingAmount,
          cashRoundingUnit: o.cashRoundingUnit,
        );

        return <String, dynamic>{
          'id': -1,
          'local_id': o.localId,
          'client_order_code': o.clientOrderCode,
          'booking_order_code': o.serverOrderCode ?? o.clientOrderCode,
          'customer_name': guestDisplayName(o.customerName),
          'customer': guestDisplayName(o.customerName),
          'order_name': guestDisplayName(o.customerName),
          'table': {
            'table_no': tableNo,
          },
          'table_no': tableNo,
          'table_name': tableNo,
          'partner_name': o.partnerName,
          'total_order_value': o.subtotal,
          'subtotal': o.subtotal,
          'grand_total': o.grandTotal,
          'total_amount': o.grandTotal,
          ...roundingFields,
          'is_ppn_active': o.isPpnActive,
          'ppn': o.ppnPercent,
          'openbill_flag':
              (o.paymentMethodSelected ?? o.paymentMethodEffective) ==
                  'OPENBILL' ||
              o.orderStatusLocal.startsWith('OPENBILL'),
          'payment_method': o.paymentMethodEffective,
          'order_status': o.orderStatusLocal,
          'sync_status': o.syncStatus,
          'last_error': o.lastError,
          'server_id': o.serverId,
          'server_order_code': o.serverOrderCode,
          'is_local_only': true,
          'is_cached_server': false,
          'created_at': o.createdAtLocal.toIso8601String(),
        };
      }).toList();

      final filteredMergedItems = mergedItems.where((e) {
        final sid = _toInt(e['server_id'] ?? e['id']);
        final code = (e['booking_order_code'] ?? e['client_order_code'] ?? '')
            .toString()
            .trim();
        final syncStatus = (e['sync_status'] ?? '').toString();

        final hiddenById = sid != null && sid > 0 && hiddenServerIds.contains(sid);
        final hiddenByCode = code.isNotEmpty && hiddenOrderCodes.contains(code);

        final hiddenBecauseAlreadyInProcess =
            !_isOpenbillReadyForPayment(e) &&
            sid != null &&
            sid > 0 &&
            processServerIds.contains(sid);

        final hiddenBecauseAlreadyInDone =
            (sid != null && sid > 0 && doneServerIds.contains(sid)) ||
            (code.isNotEmpty && doneOrderCodes.contains(code));

        final hiddenBecausePendingDelete = syncStatus == 'PENDING_DELETE';

        final hiddenBecausePendingLocalMirror =
            (sid != null && sid > 0 && pendingLocalServerIds.contains(sid)) ||
            (code.isNotEmpty && pendingLocalBookingCodes.contains(code));

        return !(hiddenById ||
            hiddenByCode ||
            hiddenBecauseAlreadyInProcess ||
            hiddenBecauseAlreadyInDone ||
            hiddenBecausePendingDelete ||
            hiddenBecausePendingLocalMirror);
      }).toList();

      items = [
        ...filteredMergedItems,
        ...localItems,
      ];

      items.sort((a, b) {
        final aCreated = DateTime.tryParse((a['created_at'] ?? '').toString());
        final bCreated = DateTime.tryParse((b['created_at'] ?? '').toString());

        if (aCreated == null && bCreated == null) return 0;
        if (aCreated == null) return 1;
        if (bCreated == null) return -1;

        return aCreated.compareTo(bCreated);
      });
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

    await cachedPaymentOrdersDao.clearAll();
    notifyListeners();
  }

  CachedPaymentOrdersCompanion _mapServerItemToCachedCompanion(
    Map<String, dynamic> item,
  ) {
    final serverId = _toInt(item['id']) ?? 0;
    final bookingOrderCode = (item['booking_order_code'] ?? '-').toString();
    final customerName = (item['customer_name'] ?? '-').toString();

    final tableNo = (item['table'] is Map)
        ? ((item['table']['table_no'] ?? '-').toString())
        : ((item['table_no'] ?? '-').toString());

    final paymentMethod = item['payment_method']?.toString();
    final orderStatus = (item['order_status'] ?? 'UNPAID').toString();

    final subtotal = _toNum(item['total_order_value']);
    final ppnPercent = _toNum(item['ppn']);
    final isPpnActive = _toBool(item['is_ppn_active']);
    final grandTotal = isPpnActive
        ? (subtotal + (subtotal * ppnPercent / 100)).ceilToDouble()
        : subtotal.ceilToDouble();
    final roundingAmount = _toNum(item['cash_rounding_amount'] ??
        item['rounding_amount'] ??
        (item['payment'] is Map ? item['payment']['rounding_amount'] : null) ??
        (item['latest_payment'] is Map ? item['latest_payment']['rounding_amount'] : null));

    final createdAt = DateTime.tryParse((item['created_at'] ?? '').toString());
    final updatedAt = DateTime.tryParse((item['updated_at'] ?? '').toString());

    Map<String, dynamic>? paymentRequestJson;
    if (item['payment_request'] is Map) {
      paymentRequestJson = Map<String, dynamic>.from(item['payment_request']);
    }

    Map<String, dynamic>? latestPaymentJson;
    if (item['latest_payment'] is Map) {
      latestPaymentJson = Map<String, dynamic>.from(item['latest_payment']);
    }

    return CachedPaymentOrdersCompanion(
      serverId: Value(serverId),
      bookingOrderCode: Value(bookingOrderCode),
      customerName: Value(customerName),
      cachedAt: Value(DateTime.now()),
      tableNo: Value(tableNo),
      paymentMethod: Value(paymentMethod),
      orderStatus: Value(orderStatus),
      subtotal: Value(subtotal.toDouble()),
      ppnPercent: Value(ppnPercent.toDouble()),
      isPpnActive: Value(isPpnActive),
      grandTotal: Value(grandTotal + roundingAmount.toDouble()),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),

      paymentRequestJson: Value(
        paymentRequestJson == null ? null : jsonEncode(paymentRequestJson),
      ),
      latestPaymentJson: Value(
        latestPaymentJson == null ? null : jsonEncode(latestPaymentJson),
      ),
    );
  }

  bool _isOpenbillReadyForPayment(Map<String, dynamic> e) {
    final status = (e['order_status'] ?? '').toString();
    final isOpenbill =
        _toBool(e['openbill_flag']) ||
        (e['payment_method'] ?? '').toString() == 'OPENBILL' ||
        status.startsWith('OPENBILL');
    return isOpenbill && status == 'UNPAID';
  }

  Map<String, dynamic> _normalizeServerItem(Map<String, dynamic> e) {
    final subtotal = _toNum(e['total_order_value']);
    final ppnPercent = _toNum(e['ppn']);
    final isPpnActive = _toBool(e['is_ppn_active']);
    final baseTotal = isPpnActive
        ? (subtotal + (subtotal * ppnPercent / 100)).ceil()
        : subtotal.ceil();
    final roundingAmount = _toNum(e['cash_rounding_amount'] ??
        e['rounding_amount'] ??
        (e['payment'] is Map ? e['payment']['rounding_amount'] : null) ??
        (e['latest_payment'] is Map ? e['latest_payment']['rounding_amount'] : null));

    return <String, dynamic>{
      ...e,
      'customer_name': guestDisplayName(
        (e['customer_name'] ?? e['customer'] ?? e['order_name'])?.toString(),
      ),
      'customer': guestDisplayName(
        (e['customer'] ?? e['customer_name'] ?? e['order_name'])?.toString(),
      ),
      'order_name': guestDisplayName(
        (e['order_name'] ?? e['customer_name'] ?? e['customer'])?.toString(),
      ),
      'subtotal': subtotal,
      'grand_total': baseTotal + roundingAmount,
      'cash_rounding_amount': roundingAmount,
      'openbill_flag': _toBool(e['openbill_flag']) ||
          (e['payment_method'] ?? '').toString() == 'OPENBILL' ||
          (e['order_status'] ?? '').toString().startsWith('OPENBILL'),
      'is_local_only': false,
      'is_cached_server': false,
      'sync_status': 'SYNCED',
    };
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
      'openbill=${isOpenBillOrder(snapshot)} serverId=$serverId',
    );

    if (process != null && done != null) {
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
      await tabCoordinator.transitionOrderStage(
        serverId: serverId,
        orderStatus: nextStatus,
        syncIntent: offline ? 'PAY' : null,
        syncDirty: offline,
        extras: extras.isEmpty ? null : extras,
        orderSnapshot: updatedSnapshot,
      );
      await load(silent: true);
    }

    if (!offline) {
      unawaited(_backgroundSyncAndReload(process: process, done: done));
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

  Map<String, dynamic> _normalizeCachedServerItem(
    CachedPaymentOrder o,
    Set<int> pendingFinishServerIds,
  ) {
    final tableNo = o.tableNo ?? '-';
    final detail = _decodeCachedJson(o.detailJson);
    final latestPayment = _decodeCachedJson(o.latestPaymentJson);
    final paymentRequest = _decodeCachedJson(o.paymentRequestJson);
    final roundingAmount = _toNum(
      detail?['cash_rounding_amount'] ??
          detail?['rounding_amount'] ??
          (detail?['payment'] is Map ? detail!['payment']['rounding_amount'] : null) ??
          (detail?['latest_payment'] is Map ? detail!['latest_payment']['rounding_amount'] : null) ??
          latestPayment?['rounding_amount'] ??
          paymentRequest?['rounding_amount'],
    );

    final isPendingFinish = pendingFinishServerIds.contains(o.serverId);

    return <String, dynamic>{
      'id': o.serverId,
      'server_id': o.serverId,
      'booking_order_code': o.bookingOrderCode,
      'customer_name': guestDisplayName(o.customerName),
      'customer': guestDisplayName(o.customerName),
      'order_name': guestDisplayName(o.customerName),

      'table': {
        'table_no': tableNo,
      },
      'table_no': tableNo,
      'table_name': tableNo,

      'payment_method': o.paymentMethod,
      'openbill_flag':
          (detail?['openbill_flag'] == true) ||
          o.paymentMethod == 'OPENBILL' ||
          o.orderStatus.startsWith('OPENBILL'),
      'order_status': o.orderStatus,

      'total_order_value': o.subtotal,
      'subtotal': o.subtotal,
      'grand_total': o.grandTotal,
      'cash_rounding_amount': roundingAmount,
      'payment': detail?['payment'],
      'latest_payment': latestPayment ?? detail?['latest_payment'],
      'payment_request': paymentRequest ?? detail?['payment_request'],
      'total_amount': o.grandTotal,

      'is_ppn_active': o.isPpnActive,
      'ppn': o.ppnPercent,

      'is_local_only': false,
      'is_cached_server': true,
      'sync_status': o.isPendingDelete
          ? 'PENDING_DELETE'
          : (isPendingFinish ? 'PENDING_FINISH' : 'SYNCED'),

      'created_at': o.createdAt?.toIso8601String(),
      'cached_at': o.cachedAt.toIso8601String(),
    };
  }

  Map<String, dynamic>? _decodeCachedJson(String? rawJson) {
    if (rawJson == null || rawJson.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return null;
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
    final now = DateTime.now();

    String localId = (order['local_id'] ?? '').toString();
    final isLocalOnly = order['is_local_only'] == true;
    final isStockConflict =
        (order['sync_status'] ?? '').toString() == 'STOCK_CONFLICT';

    // =========================
    // A. Kalau order berasal dari server/cache
    // buat shadow local order dulu
    // =========================
    if (!isLocalOnly || localId.isEmpty) {
      final serverId = _toInt(order['server_id'] ?? order['id']);
      if (serverId == null || serverId <= 0) {
        throw Exception('ID server order tidak valid untuk offline payment');
      }

      final bookingOrderCode =
          (order['booking_order_code'] ?? order['client_order_code'] ?? '-')
              .toString();

      final customerName = (order['customer_name'] ?? '-').toString();

      final tableNoSnapshot = (order['table'] is Map)
          ? ((order['table']['table_no'] ?? '-').toString())
          : ((order['table_no'] ?? '-').toString());

      final paymentMethodEffective =
          (selectedPaymentMethod ??
                  order['payment_method'] ??
                  'CASH')
              .toString();
      final paymentMethodSelected =
          (_toBool(order['openbill_flag']) ||
                  (order['order_status'] ?? '').toString().startsWith('OPENBILL'))
              ? 'OPENBILL'
              : paymentMethodEffective;

      final subtotal = _toNum(order['total_order_value']).toDouble();
      final ppnPercent = _toNum(order['ppn']).toDouble();
      final isPpnActive = _toBool(order['is_ppn_active']);
      final grandTotal = isPpnActive
          ? (subtotal + (subtotal * ppnPercent / 100)).ceilToDouble()
          : subtotal;

      await localOrdersDao.createShadowOrderFromServerPayment(
        serverId: serverId,
        bookingOrderCode: bookingOrderCode,
        customerName: customerName,
        tableNoSnapshot: tableNoSnapshot,
        paymentMethodSelected: paymentMethodSelected,
        paymentMethodEffective: paymentMethodEffective,
        subtotal: subtotal,
        grandTotal: grandTotal,
        isPpnActive: isPpnActive,
        ppnPercent: ppnPercent,
        paidAmount: paidAmount.toDouble(),
        changeAmount: changeAmount.toDouble(),
        cashierProofImagePath: cashierProofImagePath,
        lastPaymentId: lastPaymentId,
      );

      localId = 'shadow_pay_$serverId';
    }

    // =========================
    // B. Simpan snapshot payment offline
    // =========================
    final existingDetail = await localOrdersDao.getOrderDetailMapByLocalId(localId);
    final snapshot = Map<String, dynamic>.from(existingDetail ?? order);
    snapshot.addAll(Map<String, dynamic>.from(order));
    snapshot['is_local_only'] = true;
    snapshot['local_id'] = localId;
    if (selectedPaymentMethod != null && selectedPaymentMethod.trim().isNotEmpty) {
      snapshot['payment_method'] = selectedPaymentMethod.trim();
    }
    snapshot['openbill_flag'] =
        _toBool(order['openbill_flag']) ||
        (order['payment_method'] ?? '').toString().toUpperCase() == 'OPENBILL' ||
        (order['order_status'] ?? '').toString().toUpperCase().startsWith('OPENBILL');
    snapshot['payment'] = {
      'updated_at': now.toIso8601String(),
      'paid_amount': paidAmount,
      'change_amount': changeAmount,
    };
    snapshot.remove('sync_status');
    snapshot.remove('pending_sync');

    final billTotal = (paidAmount - changeAmount) > 0
        ? (paidAmount - changeAmount).toDouble()
        : paidAmount.toDouble();
    final subtotal = _toNum(
      snapshot['total_order_value'] ?? snapshot['subtotal'] ?? 0,
    ).toDouble();
    final isPpnActive = _toBool(snapshot['is_ppn_active']);
    final ppnPercent = _toNum(snapshot['ppn']).toDouble();
    final basePayable = CashRoundingHelpers.basePayable(
      subtotal,
      isPpnActive,
      ppnPercent,
    );
    final cashRoundingAmount =
        billTotal > basePayable ? billTotal - basePayable : 0.0;

    await localOrdersDao.markPaymentConfirmedOffline(
      localId: localId,
      paidAmount: paidAmount.toDouble(),
      changeAmount: changeAmount.toDouble(),
      selectedPaymentMethod: selectedPaymentMethod,
      cashierProofImageLocalPath: cashierProofImagePath,
      paymentConfirmedAtLocal: now,
      latestPaymentServerId: int.tryParse(lastPaymentId ?? ''),
      orderSnapshotJson: jsonEncode(snapshot),
      preserveStockConflict: isStockConflict,
      billTotalLocal: billTotal,
      cashRoundingAmount: cashRoundingAmount,
    );

    final serverId = _toInt(order['server_id'] ?? order['id']);
    if (serverId != null && serverId > 0) {
      await cachedPaymentOrdersDao.markPendingDelete(serverId);
    }
  }
  

  Future<Map<String, dynamic>> getPrintDetail(int id) async {
    return repo.fetchPrintDetail(id);
  }

  Future<void> deleteOrder(int id) async {
    try {
      await repo.softDeleteOrder(id);
      await load();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteOrderItem(Map<String, dynamic> item, {required bool isOnline}) async {
    final isLocalOnly = item['is_local_only'] == true;
    final isCachedServer = item['is_cached_server'] == true;

    final localId = (item['local_id'] ?? '').toString();
    final syncStatus = (item['sync_status'] ?? '').toString();

    final serverId = _toInt(item['server_id']) ?? _toInt(item['id']);

    try {
      // =========================
      // A. ORDER LOKAL
      // =========================
      if (isLocalOnly && localId.isNotEmpty) {
        // belum pernah sync ke server -> hapus langsung
        if (serverId == null || serverId <= 0) {
          await localOrdersDao.deleteOrderByLocalId(localId);
          await load();
          return;
        }

        // sudah pernah sync ke server
        if (!isOnline) {
          await localOrdersDao.markOrderPendingDelete(localId);
          await load();
          return;
        }

        // online + sudah ada serverId -> delete backend lalu hapus lokal
        await repo.softDeleteOrder(serverId);
        await cachedProcessOrdersDao.deleteByServerId(serverId);
        await localOrdersDao.deleteOrderByLocalId(localId);
        await load();
        return;
      }

      // =========================
      // B. ORDER SERVER / CACHED SERVER
      // =========================
      if (serverId == null || serverId <= 0) {
        throw Exception('ID order tidak valid');
      }

      if (!isOnline) {
        // saat offline: tandai pending delete di cache
        await cachedPaymentOrdersDao.markPendingDelete(serverId);
        await load();
        return;
      }

      // saat online: langsung delete backend
      await repo.softDeleteOrder(serverId);
      await cachedPaymentOrdersDao.deleteCachedOrderByServerId(serverId);
      await cachedProcessOrdersDao.deleteByServerId(serverId);
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
    final cached = await cachedPaymentOrdersDao.getCachedOrderDetailMap(id);
    final row = cached ?? <String, dynamic>{'id': id, 'server_id': id};

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
    final isLocalOnly = row['is_local_only'] == true;
    final isOnline = connectivity.isOnline;

    if (isLocalOnly) {
      final localId = (row['local_id'] ?? '').toString();
      if (localId.isEmpty) {
        throw Exception('Local ID order tidak valid');
      }

      final localDetail = await localOrdersDao.getOrderDetailMapByLocalId(localId);

      // ✅ TARUH DI SINI
      if (localDetail != null) {
        return _enrichOrderDetailPaymentData(localDetail);
      }

      throw Exception('Detail order lokal tidak ditemukan');
    }

    final serverId = _toInt(row['server_id'] ?? row['id']);
    if (serverId == null || serverId <= 0) {
      throw Exception('Order ID tidak valid');
    }

    if (isOnline) {
      try {
        final detail = await repo.fetchOrderDetail(serverId);

        debugPrint('method detail = ${detail['payment_method']}');
        debugPrint('payment_request = ${detail['payment_request']}');
        debugPrint('latest_payment = ${detail['latest_payment']}');

        await cachedPaymentOrdersDao.upsertDetailFromApi(detail);
        await _cacheManualPaymentMethodFromDetail(detail);

        return _enrichOrderDetailPaymentData(detail);
      } catch (_) {
        final cached = await cachedPaymentOrdersDao.getCachedOrderDetailMap(serverId);
        if (cached != null) {
          return _enrichOrderDetailPaymentData(cached);
        }
        rethrow;
      }
    }

    final cached = await cachedPaymentOrdersDao.getCachedOrderDetailMap(serverId);

    if (cached != null) {
      return _enrichOrderDetailPaymentData(cached);
    }

    throw Exception('Detail order offline tidak tersedia');
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

  Future<void> _prefetchAndCacheDetails(List<Map<String, dynamic>> serverItems) async {
    for (final item in serverItems) {
      try {
        final id = _toInt(item['id']);
        if (id == null || id <= 0) continue;

        final detail = await repo.fetchOrderDetail(id);

        debugPrint('==== PREFETCH DETAIL $id ====');
        debugPrint('method detail = ${detail['payment_method']}');
        debugPrint('payment_request = ${detail['payment_request']}');
        debugPrint('latest_payment = ${detail['latest_payment']}');

        await cachedPaymentOrdersDao.upsertDetailFromApi(detail);
        await _cacheManualPaymentMethodFromDetail(detail);

        debugPrint('✅ cached payment detail: $id');
      } catch (e) {
        debugPrint('⚠️ prefetch detail failed for payment order: $e');
      }
    }
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

  Future<String?> _downloadManualPaymentImageToLocal(String rawPath) async {
    try {
      if (rawPath.trim().isEmpty) return null;

      final imageUrl = rawPath.startsWith('http')
          ? rawPath
          : '${Env.baseUrl}/storage/${rawPath.replaceFirst(RegExp(r'^\/?storage\/?'), '')}';

      final dir = await getApplicationDocumentsDirectory();
      final folder = Directory(p.join(dir.path, 'manual_payment_images'));
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }

      final ext = p.extension(Uri.parse(imageUrl).path);
      final safeExt = ext.isEmpty ? '.jpg' : ext;
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${rawPath.hashCode}$safeExt';

      final filePath = p.join(folder.path, fileName);

      final dio = Dio();
      await dio.download(imageUrl, filePath);

      final file = File(filePath);
      if (await file.exists()) {
        return file.path;
      }

      return null;
    } catch (e) {
      debugPrint('❌ download manual payment image failed: $e');
      return null;
    }
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
