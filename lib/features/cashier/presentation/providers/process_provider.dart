import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/orders_repository.dart';
import '/core/services/connectivity_status_provider.dart';
import '/features/cashier/data/local/db/daos/booking_orders_dao.dart';
import '/features/cashier/data/local/db/mappers/order_mirror_mapper.dart';
import '/features/cashier/data/local/db/sync/sync_service.dart';
import '/features/cashier/data/sync/order_tab_coordinator.dart';
import '/features/cashier/data/sync/order_stage_resolver.dart';
import '/features/cashier/data/sync/order_tab_item_mapper.dart';
import '/features/cashier/presentation/utils/order_edit_utils.dart';

class ProcessProvider extends ChangeNotifier {
  final OrdersRepository repo;
  final ConnectivityStatusProvider connectivity;
  final BookingOrdersDao bookingOrdersDao;
  final OrderTabCoordinator tabCoordinator;
  final SyncService? syncService;

  ProcessProvider(
    this.repo,
    this.connectivity,
    this.bookingOrdersDao,
    this.tabCoordinator, {
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
      final mirrorRows = await bookingOrdersDao.getProcessTabOrders(
        query: query.isEmpty ? null : query,
      );

      final mirroredClientUuids = mirrorRows
          .map((o) => o['local_client_uuid']?.toString())
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .toSet();

      final doneRows = await bookingOrdersDao.getDoneTabOrders();
      final doneIds = doneRows
          .map((e) => _toId(e['id']))
          .where((id) => id > 0)
          .toSet();
      final doneCodes = doneRows
          .map((e) => (e['booking_order_code'] ?? '').toString().trim())
          .where((e) => e.isNotEmpty)
          .toSet();

      final remoteItems = mirrorRows
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

      if (connectivity.isOnline && remoteItems.isNotEmpty) {
        try {
          await _prefetchProcessDetails(remoteItems);
        } catch (e) {
          debugPrint('ProcessProvider prefetch process details failed: $e');
        }
      }

      items = remoteItems;

      if (query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        items = items.where((e) {
          final code = (e['booking_order_code'] ?? '').toString().toLowerCase();
          final customer = (e['customer_name'] ?? '').toString().toLowerCase();
          final tableNo = ((e['table'] is Map)
                  ? (e['table']['table_no'] ?? '')
                  : e['table_no_snapshot'] ?? '')
              .toString()
              .toLowerCase();

          return code.contains(q) ||
              customer.contains(q) ||
              tableNo.contains(q);
        }).toList();
      }

      items.sort((a, b) {
        final aCreated = DateTime.tryParse(
          (a['sort_time'] ?? a['created_at'] ?? a['updated_at_local'] ?? '')
              .toString(),
        );
        final bCreated = DateTime.tryParse(
          (b['sort_time'] ?? b['created_at'] ?? b['updated_at_local'] ?? '')
              .toString(),
        );

        if (aCreated == null && bCreated == null) return 0;
        if (aCreated == null) return -1;
        if (bCreated == null) return 1;

        return aCreated.compareTo(bCreated); // lama -> baru, terbaru di bawah
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

  Future<void> _prefetchProcessDetails(List<Map<String, dynamic>> items) async {
    for (final item in items) {
      final serverId = _toId(item['id']);
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

    final bundle = await bookingOrdersDao.getBundleByClientUuid(order.clientUuid);
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
    final clientUuid =
        (row['local_client_uuid'] ?? row['local_id'] ?? '').toString();
    if (clientUuid.isNotEmpty) {
      final bundle = await bookingOrdersDao.getBundleByClientUuid(clientUuid);
      if (bundle != null) {
        return _bundleToDetailMap(bundle);
      }
    }

    final serverId = _toId(row['id']);
    if (serverId <= 0) {
      throw Exception('Order ID tidak valid');
    }

    if (!connectivity.isOnline) {
      final cached = await _getMirrorDetailMap(serverId);
      if (cached != null) return cached;
      throw Exception('Detail offline tidak tersedia di cache');
    }

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
    return detail;
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
    return map;
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
      final targetStatus = isConfirmingOpenbill ? 'OPENBILL_WAITING_ORDER' : 'PROCESSED';

      final clientUuid =
          (row['local_client_uuid'] ?? row['local_id'] ?? '').toString();
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

  Future<Map<String, dynamic>> actionCancelProcess(Map<String, dynamic> row) async {
    final isLocalOnly = row['is_local_only'] == true;
    final isStockConflict =
        (row['sync_status'] ?? '').toString() == 'STOCK_CONFLICT';
    final id = _toId(row['id']);
    final actionKey = _actionKey(row);

    _setActionLoading(actionKey, true);
    try {
      final clientUuid =
          (row['local_client_uuid'] ?? row['local_id'] ?? '').toString();
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
    required List<int> detailIds,
  }) async {
    final isLocalOnly = row['is_local_only'] == true;
    final isStockConflict =
        (row['sync_status'] ?? '').toString() == 'STOCK_CONFLICT';
    final id = _toId(row['id']);
    final actionKey = _actionKey(row);

    _setActionLoading(actionKey, true);
    try {
      if (detailIds.isEmpty) {
        throw Exception('Pilih minimal satu item');
      }

      if (isLocalOnly || id <= 0) {
        final clientUuid =
            (row['local_client_uuid'] ?? row['local_id'] ?? '').toString();
        final mirror = clientUuid.isNotEmpty
            ? await bookingOrdersDao.getByClientUuid(clientUuid)
            : null;
        if (mirror?.serverId != null) {
          return actionServeItems(
            {...row, 'id': mirror!.serverId, 'is_local_only': false},
            detailIds: detailIds,
          );
        }
        throw Exception('Sinkronkan order terlebih dahulu sebelum serve item');
      }

      if (isStockConflict) {
        throw Exception('Served per item tidak tersedia saat ada konflik stok');
      }

      if (!connectivity.isOnline) {
        final result = await _markCachedOrderItemsServed(
          serverId: id,
          detailIds: detailIds,
        );

        await load();

        final allServed = result['all_served'] == true;
        final isOpenbill =
            _toBool(row['openbill_flag']) ||
            row['payment_method']?.toString() == 'OPENBILL' ||
            (row['order_status'] ?? '').toString().startsWith('OPENBILL');

        if (allServed && isOpenbill) {
          await _stageOpenbillForPaymentCache(id, row);
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
        final res = await repo.serveOrderItems(id: id, detailIds: detailIds);
        final status = (res['status'] ?? '').toString();

        if (status == 'warning' || res['already_processed'] == true) {
          await load();
          return res;
        }

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
      final clientUuid =
          (row['local_client_uuid'] ?? row['local_id'] ?? '').toString();
      final mirror = clientUuid.isNotEmpty
          ? await bookingOrdersDao.getByClientUuid(clientUuid)
          : null;
      if (mirror?.serverId != null) {
        return actionMarkKitchenServed(
          {...row, 'id': mirror!.serverId, 'is_local_only': false},
          detailId: detailId,
        );
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
        await _stageOpenbillForPaymentCache(id, row);
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
        final clientUuid =
            (row['local_client_uuid'] ?? row['local_id'] ?? '').toString();
        if (clientUuid.isEmpty) {
          throw Exception('Local ID tidak valid');
        }
        final nextStatus = OrderStageResolver.resolveAfterFinish(order: row);
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
        items.removeWhere((e) => _toId(e['id']) == id);
        notifyListeners();
        return res;
      }

      final nextStatus = OrderStageResolver.resolveAfterFinish(order: row);
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
      if (!isItemAwaitingCashierServe(item)) continue;

      item['status'] = 'SERVED BY CASHIER';
      item['cashier_process_id'] = item['cashier_process_id'] ?? -1;
      updatedCount++;
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
      syncIntent: allServed ? 'FINISH' : 'PROCESS',
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
      item['status'] = inKitchen ? 'SERVED BY KITCHEN' : 'SERVED BY CASHIER';
      if (!inKitchen) {
        item['cashier_process_id'] = item['cashier_process_id'] ?? -1;
      }
      updatedCount++;
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
      syncIntent: allServed ? 'FINISH' : 'PROCESS',
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
    Map<String, dynamic> row,
  ) async {
    await tabCoordinator.transitionOrderStage(
      serverId: serverId,
      orderStatus: 'UNPAID',
      syncIntent: 'FINISH',
      syncDirty: true,
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
}
