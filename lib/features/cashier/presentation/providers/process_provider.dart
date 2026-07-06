import 'dart:convert';

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '/features/auth/presentation/auth_provider.dart';
import '../../data/models/orders_repository.dart';
import '/core/services/connectivity_status_provider.dart';
import '/features/cashier/data/local/db/daos/booking_orders_dao.dart';
import '/features/cashier/data/local/db/mappers/order_mirror_mapper.dart';
import '/features/cashier/data/local/db/sync/sync_service.dart';
import '/features/cashier/data/sync/order_tab_coordinator.dart';
import '/features/cashier/data/sync/order_detail_prefetch_policy.dart';
import '/features/cashier/data/sync/order_detail_resolver.dart';
import '/features/cashier/data/sync/order_stage_resolver.dart';
import '/features/cashier/data/sync/order_tab_item_mapper.dart';
import '/features/cashier/presentation/printing/offline_print_enricher.dart';
import '/features/cashier/presentation/utils/order_tab_sort.dart';
import '/features/cashier/presentation/utils/order_edit_utils.dart';

class ServeItemSelection {
  const ServeItemSelection({this.serverDetailId, this.clientDetailUuid});

  final int? serverDetailId;
  final String? clientDetailUuid;

  bool get isValid {
    final hasServerId = serverDetailId != null && serverDetailId! > 0;
    final hasClientUuid =
        clientDetailUuid != null && clientDetailUuid!.trim().isNotEmpty;
    return hasServerId || hasClientUuid;
  }
}

class ProcessProvider extends ChangeNotifier {
  final OrdersRepository repo;
  final ConnectivityStatusProvider connectivity;
  final BookingOrdersDao bookingOrdersDao;
  final OrderTabCoordinator tabCoordinator;
  final AuthProvider auth;
  final SyncService? syncService;

  ProcessProvider(
    this.repo,
    this.connectivity,
    this.bookingOrdersDao,
    this.tabCoordinator,
    this.auth, {
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

    List<Map<String, dynamic>> dedupedMirrorRows = [];

    try {
      await bookingOrdersDao.reconcileDuplicateMirrors();

      final mirrorRows = await bookingOrdersDao.getProcessTabOrders(
        query: query.isEmpty ? null : query,
      );

      dedupedMirrorRows = _dedupeProcessMirrorRows(mirrorRows);

      final doneRows = await bookingOrdersDao.getDoneTabOrders();
      final doneIds = doneRows
          .map((e) => _toId(e['id']))
          .where((id) => id > 0)
          .toSet();
      final doneCodes = doneRows
          .map((e) => (e['booking_order_code'] ?? '').toString().trim())
          .where((e) => e.isNotEmpty)
          .toSet();

      final remoteItems = dedupedMirrorRows
          .where((row) {
            final status = (row['order_status'] ?? '').toString();
            if (status == 'SERVED') return false;
            if (status == 'UNPAID') return false;
            final intent = (row['sync_intent'] ?? '').toString().toUpperCase();
            if (intent == 'DELETE' &&
                (row['sync_dirty'] == true || row['sync_dirty'] == 1)) {
              return false;
            }
            final id = _toId(row['id']);
            if (doneIds.contains(id)) return false;
            final code = (row['booking_order_code'] ?? '').toString().trim();
            if (code.isNotEmpty && doneCodes.contains(code)) return false;
            return true;
          })
          .map(OrderTabItemMapper.toProcessItem)
          .toList();

      items = remoteItems;

      if (query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        items = items.where((e) {
          final code = (e['booking_order_code'] ?? '').toString().toLowerCase();
          final customer = (e['customer_name'] ?? '').toString().toLowerCase();
          final tableNo =
              ((e['table'] is Map)
                      ? (e['table']['table_no'] ?? '')
                      : e['table_no_snapshot'] ?? '')
                  .toString()
                  .toLowerCase();

          return code.contains(q) ||
              customer.contains(q) ||
              tableNo.contains(q);
        }).toList();
      }

      items.sort(compareOrdersOldestFirst);
    } catch (e) {
      error = e.toString();
    } finally {
      if (!silent) {
        isLoading = false;
      }
      notifyListeners();
    }

    final hasPendingSync = items.any(
      (e) =>
          e['sync_status'] == 'PENDING' ||
          e['is_synced'] == false ||
          e['is_local_only'] == true,
    );
    if (connectivity.isOnline &&
        dedupedMirrorRows.isNotEmpty &&
        !hasPendingSync) {
      unawaited(_prefetchProcessDetailsInBackground(dedupedMirrorRows));
    }
  }

  Future<void> _prefetchProcessDetailsInBackground(
    List<Map<String, dynamic>> mirrorRows,
  ) async {
    final snapshot = OrderDetailPrefetchPolicy.selectForPrefetch(mirrorRows);
    if (snapshot.isEmpty) return;

    try {
      await _prefetchProcessDetails(snapshot);
    } catch (e) {
      debugPrint('ProcessProvider prefetch process details failed: $e');
    }
  }

  Future<void> _refreshProcessOrdersFromServer() async {
    final res = await repo.fetchOrdersData(
      tab: 'proses',
      q: query.isEmpty ? null : query,
    );

    final raw = res['items'];
    if (raw is! List) return;

    for (final item in raw) {
      if (item is! Map) continue;
      await bookingOrdersDao.upsertFromServer(Map<String, dynamic>.from(item));
    }
  }

  Future<void> _prefetchProcessDetails(
    List<Map<String, dynamic>> mirrorRows,
  ) async {
    for (final row in mirrorRows) {
      final serverId = _toId(row['id']);
      if (serverId <= 0) continue;

      try {
        final detail = await repo.fetchOrderDetail(serverId);
        await bookingOrdersDao.upsertFromServer(detail);
      } catch (e) {
        debugPrint('ProcessProvider prefetch detail failed for $serverId: $e');
      }
    }
  }

  void setQuery(String q) {
    query = q;
    notifyListeners();
  }

  Future<void> clearStateAndCache() async {
    isLoading = false;
    error = null;
    query = '';
    items = [];
    actionLoadingIds.clear();
    notifyListeners();
  }

  Future<Map<String, dynamic>?> _getMirrorDetailMap(int serverId) async {
    final order = await bookingOrdersDao.getByServerId(serverId);
    if (order == null) return null;

    final bundle = await bookingOrdersDao.getBundleByClientUuid(
      order.clientUuid,
    );
    if (bundle == null) return null;

    final map = OrderTabItemMapper.toProcessItem(
      OrderMirrorMapper.orderToUiMap(order),
    );
    map['order_details'] = bundle.details.map((d) {
      final detailMap = OrderMirrorMapper.detailToUiMap(d);
      detailMap['order_detail_options'] =
          (bundle.optionsByDetailUuid[d.clientDetailUuid] ?? [])
              .map(OrderMirrorMapper.optionToUiMap)
              .toList();
      return detailMap;
    }).toList();
    return map;
  }

  Future<Map<String, dynamic>?> _getMirrorDetailMapByClientUuid(
    String clientUuid,
  ) async {
    final bundle = await bookingOrdersDao.getBundleByClientUuid(clientUuid);
    if (bundle == null) return null;

    final map = OrderMirrorMapper.orderToUiMap(bundle.order);
    map['order_details'] = bundle.details.map((d) {
      final detailMap = OrderMirrorMapper.detailToUiMap(d);
      detailMap['order_detail_options'] =
          (bundle.optionsByDetailUuid[d.clientDetailUuid] ?? [])
              .map(OrderMirrorMapper.optionToUiMap)
              .toList();
      return detailMap;
    }).toList();
    return map;
  }

  Future<Map<String, dynamic>> _serveMirrorItemsLocally({
    required Map<String, dynamic> row,
    required String clientUuid,
    required List<int> serverDetailIds,
    required List<String> clientDetailUuids,
  }) async {
    final updatedCount = await bookingOrdersDao.markOrderDetailsServedLocally(
      detailClientUuids: clientDetailUuids,
      detailServerIds: serverDetailIds,
      cashierProcessId: auth.user?.id,
    );
    if (updatedCount == 0) {
      throw Exception('Item yang dipilih tidak ditemukan');
    }

    final detail = await _getMirrorDetailMapByClientUuid(clientUuid);
    if (detail == null) {
      throw Exception('Detail order tidak tersedia di cache offline');
    }

    final details = ((detail['order_details'] as List?) ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final allServed =
        details.isNotEmpty &&
        details.every((item) => isDetailServedStatus(detailStatusOf(item)));
    final nextStatus = OrderStageResolver.resolveAfterServeItems(
      order: {...row, ...detail, 'order_details': details},
    );
    final isOpenbill = isOpenBillOrder({...row, ...detail});
    final syncIntent = allServed
        ? (isOpenbill && nextStatus == 'UNPAID' ? 'SERVE_ITEMS' : 'FINISH')
        : 'PROCESS';

    await tabCoordinator.transitionOrderStageByClientUuid(
      clientUuid: clientUuid,
      orderStatus: nextStatus,
      syncIntent: syncIntent,
      syncDirty: true,
    );

    await load();

    return {
      'all_served': allServed,
      'order_status': nextStatus,
      'detail_count': updatedCount,
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

  final Set<int> actionLoadingIds = <int>{};

  Future<Map<String, dynamic>> getOrderDetailFromListItem(
    Map<String, dynamic> row,
  ) async {
    final clientUuid = (row['local_client_uuid'] ?? row['local_id'] ?? '')
        .toString()
        .trim();
    final serverId = _toId(row['server_id'] ?? row['id']);

    if (serverId <= 0) {
      if (clientUuid.isEmpty) {
        throw Exception('Order ID tidak valid');
      }
      final bundle = await bookingOrdersDao.getBundleByClientUuid(clientUuid);
      if (bundle == null) {
        throw Exception('Detail order offline tidak tersedia');
      }
      return _bundleToDetailMap(bundle);
    }

    if (connectivity.isOnline) {
      try {
        final detail = await repo.fetchOrderDetail(serverId);
        await bookingOrdersDao.upsertFromServer(detail);
        return detail;
      } catch (_) {
        final cached = await _getMirrorDetailMap(serverId);
        if (cached != null) return cached;
        rethrow;
      }
    }

    if (OrderDetailResolver.hasEmbeddedDetails(row)) {
      return OrderDetailResolver.detailFromListRow(row);
    }

    if (clientUuid.isNotEmpty) {
      final cached = await _getMirrorDetailMapByClientUuid(clientUuid);
      if (cached != null) return cached;
    }

    final cached = await _getMirrorDetailMap(serverId);
    if (cached != null) return cached;
    throw Exception('Detail offline tidak tersedia di cache');
  }

  Future<Map<String, dynamic>> getPrintDetailFromListItem(
    Map<String, dynamic> row,
  ) async {
    final detail = await getOrderDetailFromListItem(row);
    final serverId = _toId(row['id']);
    if (serverId > 0 && connectivity.isOnline) {
      try {
        return await repo.fetchPrintDetail(serverId);
      } catch (_) {}
    }
    return enrichOfflinePrintOrder(detail);
  }

  Map<String, dynamic> _bundleToDetailMap(BookingOrderBundle bundle) {
    final map = OrderTabItemMapper.toProcessItem(
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

  bool isActionLoading(int id) => actionLoadingIds.contains(id);

  void _setActionLoading(int id, bool v) {
    if (v) {
      actionLoadingIds.add(id);
    } else {
      actionLoadingIds.remove(id);
    }
    notifyListeners();
  }

  String? _extractCreatedAtFromRawJson(String? rawJson) {
    if (rawJson == null || rawJson.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is Map<String, dynamic>) {
        final createdAt = decoded['created_at'];
        if (createdAt != null) return createdAt.toString();
      }
      if (decoded is Map) {
        final map = Map<String, dynamic>.from(decoded);
        final createdAt = map['created_at'];
        if (createdAt != null) return createdAt.toString();
      }
    } catch (_) {}
    return null;
  }

  int _toId(dynamic v) => (v is int) ? v : int.tryParse(v.toString()) ?? 0;

  List<Map<String, dynamic>> _dedupeProcessMirrorRows(
    List<Map<String, dynamic>> rows,
  ) {
    final byKey = <String, Map<String, dynamic>>{};

    for (final row in rows) {
      final key = _processMirrorDedupeKey(row);
      final existing = byKey[key];
      if (existing == null || _preferProcessMirrorRow(row, existing)) {
        byKey[key] = row;
      }
    }

    return byKey.values.toList();
  }

  String _processMirrorDedupeKey(Map<String, dynamic> row) {
    final serverId = _toId(row['id']);
    if (serverId > 0) return 'id:$serverId';

    final clientUuid = row['local_client_uuid']?.toString().trim();
    if (clientUuid != null && clientUuid.isNotEmpty) {
      return 'uuid:$clientUuid';
    }

    final code = (row['booking_order_code'] ?? '').toString().trim();
    if (code.isNotEmpty) return 'code:$code';

    return 'row:${row.hashCode}';
  }

  bool _preferProcessMirrorRow(
    Map<String, dynamic> candidate,
    Map<String, dynamic> current,
  ) {
    final candidateServerId = _toId(candidate['id']);
    final currentServerId = _toId(current['id']);
    if (candidateServerId > 0 && currentServerId <= 0) return true;
    if (candidateServerId <= 0 && currentServerId > 0) return false;

    final candidateDirty =
        candidate['sync_dirty'] == true || candidate['sync_dirty'] == 1;
    final currentDirty =
        current['sync_dirty'] == true || current['sync_dirty'] == 1;
    if (!candidateDirty && currentDirty) return true;
    if (candidateDirty && !currentDirty) return false;

    final candidateUpdated =
        DateTime.tryParse(
          (candidate['updated_at'] ?? candidate['created_at'] ?? '').toString(),
        ) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final currentUpdated =
        DateTime.tryParse(
          (current['updated_at'] ?? current['created_at'] ?? '').toString(),
        ) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return candidateUpdated.isAfter(currentUpdated);
  }

  int _indexById(int id) {
    return items.indexWhere((e) => _toId(e['id']) == id);
  }

  void _setStatusLocal(int id, String status) {
    final idx = _indexById(id);
    if (idx < 0) return;
    items[idx] = {...items[idx], 'order_status': status};
    notifyListeners();
  }

  Future<Map<String, dynamic>> actionProcess(Map<String, dynamic> row) async {
    final isLocalOnly = row['is_local_only'] == true;
    final isStockConflict =
        (row['sync_status'] ?? '').toString() == 'STOCK_CONFLICT';
    final id = _toId(row['id']);
    final actionKey = _actionKey(row);

    _setActionLoading(actionKey, true);
    try {
      final currentStatus = row['order_status']?.toString() ?? '';
      final isConfirmingOpenbill = currentStatus == 'OPENBILL_CONFIRMATION';
      final targetStatus = isConfirmingOpenbill
          ? 'OPENBILL_WAITING_ORDER'
          : 'PROCESSED';

      final clientUuid = (row['local_client_uuid'] ?? row['local_id'] ?? '')
          .toString();
      final isMirrorOnly = clientUuid.isNotEmpty && id <= 0;

      if (isMirrorOnly) {
        await tabCoordinator.transitionOrderStageByClientUuid(
          clientUuid: clientUuid,
          orderStatus: targetStatus,
          syncIntent: isConfirmingOpenbill ? 'CONFIRM_OPENBILL' : 'PROCESS',
        );
        await load();
        return {
          'status': 'offline_success',
          'offline': true,
          'message': 'Order diubah ke $targetStatus dan menunggu sinkronisasi',
        };
      }

      final forceOffline = isStockConflict;

      if (connectivity.isOnline && !forceOffline) {
        final res = await repo.processOrder(id);

        final status = (res['status'] ?? '').toString();
        if (status == 'warning' || res['already_processed'] == true) {
          await load();
          return res;
        }

        await tabCoordinator.transitionOrderStage(
          serverId: id,
          orderStatus: targetStatus,
          syncDirty: false,
          orderSnapshot: row,
        );

        _setStatusLocal(id, targetStatus);
        return res;
      } else {
        await tabCoordinator.transitionOrderStage(
          serverId: id,
          orderStatus: targetStatus,
          syncIntent: isConfirmingOpenbill ? 'CONFIRM_OPENBILL' : 'PROCESS',
          syncDirty: true,
          orderSnapshot: row,
        );

        _setStatusLocal(id, targetStatus);

        return {
          'status': 'offline_success',
          'offline': true,
          'message': 'Order ditandai $targetStatus dan menunggu sinkronisasi',
        };
      }
    } finally {
      _setActionLoading(actionKey, false);
    }
  }

  Future<Map<String, dynamic>> actionCancelProcess(
    Map<String, dynamic> row,
  ) async {
    final isLocalOnly = row['is_local_only'] == true;
    final isStockConflict =
        (row['sync_status'] ?? '').toString() == 'STOCK_CONFLICT';
    final id = _toId(row['id']);
    final actionKey = _actionKey(row);

    _setActionLoading(actionKey, true);
    try {
      final clientUuid = (row['local_client_uuid'] ?? row['local_id'] ?? '')
          .toString();
      if (clientUuid.isNotEmpty && id <= 0) {
        await tabCoordinator.transitionOrderStageByClientUuid(
          clientUuid: clientUuid,
          orderStatus: 'PAID',
          syncIntent: 'UPDATE',
        );
        await load();
        return {
          'status': 'offline_success',
          'offline': true,
          'message': 'Status dikembalikan ke PAID',
        };
      }

      final forceOffline = isStockConflict;

      if (connectivity.isOnline && !forceOffline) {
        final res = await repo.cancelProcessOrder(id);
        await tabCoordinator.transitionOrderStage(
          serverId: id,
          orderStatus: 'PAID',
          syncDirty: false,
          orderSnapshot: row,
        );
        _setStatusLocal(id, 'PAID');
        return res;
      } else {
        await tabCoordinator.transitionOrderStage(
          serverId: id,
          orderStatus: 'PAID',
          syncIntent: 'UPDATE',
          syncDirty: true,
          orderSnapshot: row,
        );
        _setStatusLocal(id, 'PAID');
        return {
          'status': 'offline_success',
          'offline': true,
          'message': 'Pembatalan proses disimpan dan menunggu sinkronisasi',
        };
      }
    } finally {
      _setActionLoading(actionKey, false);
    }
  }

  Future<Map<String, dynamic>> actionServeItems(
    Map<String, dynamic> row, {
    List<int> detailIds = const [],
    List<ServeItemSelection> selections = const [],
  }) async {
    final resolvedSelections = selections.isNotEmpty
        ? selections.where((item) => item.isValid).toList()
        : detailIds
              .where((id) => id > 0)
              .map((id) => ServeItemSelection(serverDetailId: id))
              .toList();

    final isStockConflict =
        (row['sync_status'] ?? '').toString() == 'STOCK_CONFLICT';
    final id = _toId(row['id']);
    final actionKey = _actionKey(row);
    final clientUuid = (row['local_client_uuid'] ?? row['local_id'] ?? '')
        .toString()
        .trim();
    final serverDetailIds = resolvedSelections
        .map((item) => item.serverDetailId)
        .whereType<int>()
        .where((detailId) => detailId > 0)
        .toList();
    final clientDetailUuids = resolvedSelections
        .map((item) => item.clientDetailUuid?.trim())
        .whereType<String>()
        .where((uuid) => uuid.isNotEmpty)
        .toList();

    _setActionLoading(actionKey, true);
    try {
      if (resolvedSelections.isEmpty) {
        throw Exception('Pilih minimal satu item');
      }

      if (id <= 0) {
        if (clientUuid.isEmpty) {
          throw Exception('Order ID tidak valid');
        }

        final mirror = await bookingOrdersDao.getByClientUuid(clientUuid);
        if (mirror?.serverId != null && mirror!.serverId! > 0) {
          return actionServeItems({
            ...row,
            'id': mirror.serverId,
            'is_local_only': false,
          }, selections: resolvedSelections);
        }

        final result = await _serveMirrorItemsLocally(
          row: row,
          clientUuid: clientUuid,
          serverDetailIds: serverDetailIds,
          clientDetailUuids: clientDetailUuids,
        );

        final allServed = result['all_served'] == true;
        final isOpenbill =
            _toBool(row['openbill_flag']) ||
            row['payment_method']?.toString() == 'OPENBILL' ||
            (row['order_status'] ?? '').toString().startsWith('OPENBILL');

        return {
          'status': 'offline_success',
          'offline': true,
          'all_served': allServed,
          'message': allServed
              ? (isOpenbill
                    ? 'Semua item served, order dipindahkan ke pembayaran'
                    : 'Semua item served')
              : 'Item terpilih berhasil ditandai served',
        };
      }

      if (isStockConflict) {
        throw Exception('Served per item tidak tersedia saat ada konflik stok');
      }

      if (!connectivity.isOnline) {
        final result = await _markCachedOrderItemsServed(
          serverId: id,
          detailIds: serverDetailIds.isNotEmpty
              ? serverDetailIds
              : detailIds.where((detailId) => detailId > 0).toList(),
          detailClientUuids: clientDetailUuids,
        );

        await load();

        final allServed = result['all_served'] == true;
        final isOpenbill =
            _toBool(row['openbill_flag']) ||
            row['payment_method']?.toString() == 'OPENBILL' ||
            (row['order_status'] ?? '').toString().startsWith('OPENBILL');

        if (allServed && isOpenbill) {
          final fresh = await _getMirrorDetailMap(id);
          final stagedSnapshot = fresh != null
              ? {...fresh, 'order_status': result['order_status'] ?? 'UNPAID'}
              : {...row, 'order_status': result['order_status'] ?? 'UNPAID'};
          await _stageOpenbillForPaymentCache(
            id,
            stagedSnapshot,
            pendingServeSync: true,
          );
        } else if (allServed) {
          await _stageServedOrderForDoneCache(id, row);
        }

        return {
          'status': 'offline_success',
          'offline': true,
          'all_served': allServed,
          'message': allServed
              ? (isOpenbill
                    ? 'Semua item served, order dipindahkan ke pembayaran'
                    : 'Semua item served')
              : 'Item terpilih berhasil ditandai served',
        };
      }

      try {
        final onlineDetailIds = serverDetailIds.isNotEmpty
            ? serverDetailIds
            : detailIds.where((detailId) => detailId > 0).toList();
        final res = await repo.serveOrderItems(
          id: id,
          detailIds: onlineDetailIds,
        );
        final status = (res['status'] ?? '').toString();

        if (status == 'warning' || res['already_processed'] == true) {
          await _syncServeResultToMirror(
            serverId: id,
            row: row,
            apiResponse: res,
          );
          await load();
          return res;
        }

        await _syncServeResultToMirror(
          serverId: id,
          row: row,
          apiResponse: res,
        );
        await load();
        return res;
      } on DioException catch (e) {
        final responseData = e.response?.data;
        if (responseData is Map) {
          final mapped = Map<String, dynamic>.from(responseData);
          await load();
          return mapped;
        }

        rethrow;
      }
    } finally {
      _setActionLoading(actionKey, false);
    }
  }

  Future<Map<String, dynamic>> actionMarkKitchenServed(
    Map<String, dynamic> row, {
    required int detailId,
  }) async {
    final isLocalOnly = row['is_local_only'] == true;
    final isStockConflict =
        (row['sync_status'] ?? '').toString() == 'STOCK_CONFLICT';
    final id = _toId(row['id']);

    if (detailId <= 0) {
      throw Exception('Item tidak valid');
    }

    if (isLocalOnly || id <= 0) {
      final clientUuid = (row['local_client_uuid'] ?? row['local_id'] ?? '')
          .toString();
      final mirror = clientUuid.isNotEmpty
          ? await bookingOrdersDao.getByClientUuid(clientUuid)
          : null;
      if (mirror?.serverId != null) {
        return actionMarkKitchenServed({
          ...row,
          'id': mirror!.serverId,
          'is_local_only': false,
        }, detailId: detailId);
      }
      throw Exception('Sinkronkan order terlebih dahulu');
    }

    if (isStockConflict) {
      throw Exception('Update served tidak tersedia saat ada konflik stok');
    }

    if (!connectivity.isOnline) {
      final result = await _markCachedKitchenItemsServed(
        serverId: id,
        detailIds: [detailId],
      );

      await load();

      final allServed = result['all_served'] == true;
      final isOpenbill =
          _toBool(row['openbill_flag']) ||
          row['payment_method']?.toString() == 'OPENBILL' ||
          (row['order_status'] ?? '').toString().startsWith('OPENBILL');

      if (allServed && isOpenbill) {
        final fresh = await _getMirrorDetailMap(id);
        final stagedSnapshot = fresh != null
            ? {...fresh, 'order_status': result['order_status'] ?? 'UNPAID'}
            : {...row, 'order_status': result['order_status'] ?? 'UNPAID'};
        await _stageOpenbillForPaymentCache(
          id,
          stagedSnapshot,
          pendingServeSync: true,
        );
      } else if (allServed) {
        await _stageServedOrderForDoneCache(id, row);
      }

      return {
        'status': 'offline_success',
        'offline': true,
        'message': 'Status item berhasil diperbarui',
        ...result,
      };
    }

    if (id <= 0) {
      throw Exception('Order server tidak valid');
    }

    try {
      final updated = await repo.markServedByKitchen(
        id: id,
        detailIds: [detailId],
      );

      await bookingOrdersDao.upsertFromServer(updated);
      await load();

      return {
        'status': 'ok',
        'message': 'Status item berhasil diperbarui',
        'data': updated,
      };
    } on DioException catch (e) {
      final responseData = e.response?.data;
      if (responseData is Map) {
        final mapped = Map<String, dynamic>.from(responseData);
        await load();
        return mapped;
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> actionFinish(Map<String, dynamic> row) async {
    final isLocalOnly = row['is_local_only'] == true;
    final isStockConflict =
        (row['sync_status'] ?? '').toString() == 'STOCK_CONFLICT';
    final id = _toId(row['id']);
    final actionKey = _actionKey(row);

    _setActionLoading(actionKey, true);
    try {
      if (id <= 0) {
        final clientUuid = (row['local_client_uuid'] ?? row['local_id'] ?? '')
            .toString();
        if (clientUuid.isEmpty) {
          throw Exception('Local ID tidak valid');
        }
        final nextStatus = OrderStageResolver.resolveAfterFinish(order: row);
        await _markCashDetailsServedBeforeOfflineFinish(row);
        await tabCoordinator.transitionOrderStageByClientUuid(
          clientUuid: clientUuid,
          orderStatus: nextStatus,
          syncIntent: 'FINISH',
        );
        await load();
        return {
          'status': 'offline_success',
          'offline': true,
          'message': 'Order ditandai selesai dan menunggu sinkronisasi',
        };
      }

      final forceOffline = isStockConflict;

      if (connectivity.isOnline && !forceOffline) {
        final res = await repo.finishOrder(id);
        final nextStatus = OrderStageResolver.resolveAfterFinish(
          order: row,
          apiResponse: res,
        );
        await tabCoordinator.transitionOrderStage(
          serverId: id,
          orderStatus: nextStatus,
          syncIntent: 'FINISH',
          syncDirty: false,
          orderSnapshot: {...row, 'order_status': nextStatus},
        );
        await load();
        return res;
      }

      final nextStatus = OrderStageResolver.resolveAfterFinish(order: row);
      await _markCashDetailsServedBeforeOfflineFinish(row);
      await tabCoordinator.transitionOrderStage(
        serverId: id,
        orderStatus: nextStatus,
        syncIntent: 'FINISH',
        syncDirty: true,
        orderSnapshot: {...row, 'order_status': nextStatus},
      );
      _setStatusLocal(id, nextStatus);
      return {
        'status': 'offline_success',
        'offline': true,
        'message': 'Order ditandai selesai dan menunggu sinkronisasi',
      };
    } finally {
      _setActionLoading(actionKey, false);
    }
  }

  Future<void> _markCashDetailsServedBeforeOfflineFinish(
    Map<String, dynamic> row,
  ) async {
    if (isOpenBillOrder(row)) return;

    final clientUuid = (row['local_client_uuid'] ?? row['local_id'] ?? '')
        .toString()
        .trim();
    final serverId = _toId(row['id'] ?? row['server_id']);

    var bundle = clientUuid.isNotEmpty
        ? await bookingOrdersDao.getBundleByClientUuid(clientUuid)
        : null;
    if (bundle == null && serverId > 0) {
      final order = await bookingOrdersDao.getByServerId(serverId);
      if (order != null) {
        bundle = await bookingOrdersDao.getBundleByClientUuid(order.clientUuid);
      }
    }
    if (bundle == null || bundle.details.isEmpty) return;

    await bookingOrdersDao.markOrderDetailsServedLocally(
      detailClientUuids: bundle.details
          .map((detail) => detail.clientDetailUuid)
          .toList(),
      detailServerIds: bundle.details
          .map((detail) => detail.serverId)
          .whereType<int>()
          .where((id) => id > 0)
          .toList(),
      cashierProcessId: auth.user?.id,
    );
  }

  int _actionKey(Map<String, dynamic> row) {
    final id = _toId(row['id']);
    if (id > 0) return id;

    final localId = (row['local_id'] ?? '').toString();
    if (localId.isNotEmpty) return localId.hashCode;

    return row.hashCode;
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  bool _toBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    final s = v.toString().toLowerCase();
    return s == '1' || s == 'true';
  }

  Future<Map<String, dynamic>> _markCachedOrderItemsServed({
    required int serverId,
    required List<int> detailIds,
    List<String> detailClientUuids = const [],
  }) async {
    final updatedCount = await bookingOrdersDao.markOrderDetailsServedLocally(
      detailServerIds: detailIds,
      detailClientUuids: detailClientUuids,
    );
    if (updatedCount == 0) {
      throw Exception('Item yang dipilih tidak ditemukan');
    }

    final detail = await _getMirrorDetailMap(serverId);
    if (detail == null) {
      throw Exception('Detail order tidak tersedia di cache offline');
    }

    final details = ((detail['order_details'] as List?) ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final allServed =
        details.isNotEmpty &&
        details.every((item) => isDetailServedStatus(detailStatusOf(item)));
    final nextStatus = OrderStageResolver.resolveAfterServeItems(
      order: {...detail, 'order_details': details},
    );

    detail['order_details'] = details;
    detail['order_status'] = nextStatus;

    final isOpenbill = isOpenBillOrder(detail);
    final syncIntent = allServed
        ? (isOpenbill && nextStatus == 'UNPAID' ? 'SERVE_ITEMS' : 'FINISH')
        : 'PROCESS';

    await tabCoordinator.transitionOrderStage(
      serverId: serverId,
      orderStatus: nextStatus,
      syncIntent: syncIntent,
      syncDirty: true,
      orderSnapshot: detail,
    );

    return {
      'all_served': allServed,
      'order_status': nextStatus,
      'detail_count': updatedCount,
    };
  }

  Future<Map<String, dynamic>> _markCachedKitchenItemsServed({
    required int serverId,
    required List<int> detailIds,
  }) async {
    final detail = await _getMirrorDetailMap(serverId);
    if (detail == null) {
      throw Exception('Detail order tidak tersedia di cache offline');
    }

    final details = ((detail['order_details'] as List?) ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    var updatedCount = 0;

    for (final item in details) {
      final itemId = orderDetailId(item);
      if (itemId == null || !detailIds.contains(itemId)) continue;
      if (isDetailServedStatus(detailStatusOf(item))) continue;

      final inKitchen = isDetailInKitchenProcessing(item);
      final servedStatus = inKitchen
          ? 'SERVED BY KITCHEN'
          : 'SERVED BY CASHIER';
      item['status'] = servedStatus;
      if (!inKitchen) {
        item['cashier_process_id'] = item['cashier_process_id'] ?? -1;
      }
      updatedCount += await bookingOrdersDao.markOrderDetailsServedLocally(
        detailServerIds: [itemId],
        servedStatus: servedStatus,
      );
    }

    if (updatedCount == 0) {
      throw Exception('Item yang dipilih tidak ditemukan');
    }

    final allServed = details.every(
      (item) => isDetailServedStatus(detailStatusOf(item)),
    );
    final isOpenbill = isOpenBillOrder(detail);
    final nextStatus = allServed
        ? (isOpenbill ? 'UNPAID' : 'SERVED')
        : (detail['order_status'] ?? 'PROCESSED').toString();

    detail['order_details'] = details;
    detail['order_status'] = nextStatus;

    await tabCoordinator.transitionOrderStage(
      serverId: serverId,
      orderStatus: nextStatus,
      syncIntent: 'MARK_KITCHEN_SERVED',
      syncDirty: true,
      orderSnapshot: detail,
    );

    return {
      'all_served': allServed,
      'order_status': nextStatus,
      'detail_count': updatedCount,
    };
  }

  Future<void> _stageOpenbillForPaymentCache(
    int serverId,
    Map<String, dynamic> row, {
    bool pendingServeSync = false,
  }) async {
    await tabCoordinator.transitionOrderStage(
      serverId: serverId,
      orderStatus: 'UNPAID',
      syncIntent: pendingServeSync ? 'SERVE_ITEMS' : null,
      syncDirty: pendingServeSync,
      orderSnapshot: row,
    );
  }

  Future<void> _stageServedOrderForDoneCache(
    int serverId,
    Map<String, dynamic> row,
  ) async {
    await tabCoordinator.transitionOrderStage(
      serverId: serverId,
      orderStatus: 'SERVED',
      syncIntent: 'FINISH',
      syncDirty: true,
      orderSnapshot: row,
    );
  }

  Future<void> _syncServeResultToMirror({
    required int serverId,
    required Map<String, dynamic> row,
    Map<String, dynamic>? apiResponse,
  }) async {
    Map<String, dynamic> detail = Map<String, dynamic>.from(row);

    try {
      final fresh = await repo.fetchOrderDetail(serverId);
      await bookingOrdersDao.upsertFromServer(fresh);
      detail = fresh;
    } catch (e) {
      debugPrint('ProcessProvider serve mirror fetch failed for $serverId: $e');
      final cached = await _getMirrorDetailMap(serverId);
      if (cached != null) {
        detail = cached;
      }
    }

    final nextStatus = OrderStageResolver.resolveAfterServeItems(
      order: detail,
      apiResponse: apiResponse,
    );
    final isOpenbill = isOpenBillOrder(detail);
    final openbillReadyForPayment = isOpenbill && nextStatus == 'UNPAID';
    final allServed =
        OrderStageResolver.movesToDoneTab(nextStatus) ||
        openbillReadyForPayment;

    if (openbillReadyForPayment) {
      await _stageOpenbillForPaymentCache(serverId, {
        ...detail,
        'order_status': nextStatus,
      });
      return;
    }

    await tabCoordinator.transitionOrderStage(
      serverId: serverId,
      orderStatus: nextStatus,
      syncIntent: allServed ? 'FINISH' : 'PROCESS',
      syncDirty: false,
      orderSnapshot: {...detail, 'order_status': nextStatus},
    );
  }
}
