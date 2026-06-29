import 'package:flutter/foundation.dart';
import '../../data/models/orders_repository.dart';
import '/features/cashier/data/local/db/daos/local_orders_dao.dart';
import '/features/cashier/data/local/db/mappers/local_order_mapper.dart';
import '/features/cashier/data/local/db/daos/cached_done_orders_dao.dart';
import '/features/cashier/data/local/db/daos/cached_payment_orders_dao.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import '/core/services/connectivity_status_provider.dart';
import '/features/cashier/data/local/db/daos/cached_process_orders_dao.dart';
import '/features/cashier/data/local/db/cashier_db.dart';
import '/features/cashier/data/local/db/daos/booking_orders_dao.dart';
import '/features/cashier/data/sync/order_tab_coordinator.dart';
import '/features/cashier/data/sync/order_stage_resolver.dart';
import '/features/cashier/data/sync/order_tab_item_mapper.dart';
import '/features/cashier/presentation/utils/order_edit_utils.dart';

class ProcessProvider extends ChangeNotifier {
  final OrdersRepository repo;
  final LocalOrdersDao localOrdersDao;
  final CachedProcessOrdersDao cachedProcessOrdersDao;
  final ConnectivityStatusProvider connectivity;
  final CachedDoneOrdersDao cachedDoneOrdersDao;
  final CachedPaymentOrdersDao cachedPaymentOrdersDao;
  final BookingOrdersDao bookingOrdersDao;
  final OrderTabCoordinator tabCoordinator;

  ProcessProvider(
    this.repo,
    this.localOrdersDao,
    this.cachedProcessOrdersDao,
    this.cachedDoneOrdersDao,
    this.cachedPaymentOrdersDao,
    this.connectivity,
    this.bookingOrdersDao,
    this.tabCoordinator,
  );

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

      final localRows = await localOrdersDao.getLocalProcessOrders();
      final localItems = localRows.map((e) {
        final item = mapLocalOrderToProcessItem(e);

        return <String, dynamic>{
          ...item,
          'processed_by_kitchen': false,
          'is_local_only': true,
          'is_synced': false,
          'pending_action': 'LOCAL_ONLY',
          'pending_sync': true,
          'sync_status': e.syncStatus,
          'last_error': e.lastError,
          'sort_time': item['created_at']?.toString() ?? e.createdAtLocal.toIso8601String(),
        };
      }).toList();

      final remoteIds = remoteItems
          .map((e) => int.tryParse('${e['id']}'))
          .whereType<int>()
          .toSet();

      final filteredLocalItems = localItems.where((e) {
        final id = e['id'];
        final code = (e['booking_order_code'] ?? '').toString().trim();
        final localId = (e['local_id'] ?? '').toString();

        if (localId.isNotEmpty && mirroredClientUuids.contains(localId)) {
          return false;
        }

        if (id is int && id > 0) {
          if (remoteIds.contains(id)) return false;
          if (doneIds.contains(id)) return false;
        }

        if (code.isNotEmpty && doneCodes.contains(code)) {
          return false;
        }

        return true;
      }).toList();

      items = [
        ...filteredLocalItems,
        ...remoteItems,
      ];

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

    final rows = raw.whereType<Map>().map((e) {
      final map = Map<String, dynamic>.from(e);

      String? tableNo;
      final table = map['table'];
      if (table is Map) {
        tableNo = table['table_no']?.toString();
      } else {
        tableNo = map['table_no_snapshot']?.toString();
      }

      return CachedProcessOrdersCompanion(
        serverId: Value(_toId(map['id'])),
        bookingOrderCode: Value((map['booking_order_code'] ?? '').toString()),
        customerName: Value((map['customer_name'] ?? '').toString()),
        tableNo: Value(tableNo),
        processRequestJson: Value(jsonEncode(map)),
        latestProcessJson: Value(jsonEncode(map)),
        paymentMethod: Value(map['payment_method']?.toString()),
        orderStatus: Value((map['order_status'] ?? '').toString()),
        subtotal: Value(
          double.tryParse((map['total_order_value'] ?? '0').toString()) ?? 0,
        ),
        ppnPercent: Value(
          double.tryParse((map['ppn'] ?? '0').toString()) ?? 0,
        ),
        isPpnActive: Value((map['is_ppn_active'] ?? 0) == 1),
        processedByKitchen: Value(_toBool(map['processed_by_kitchen'])),
        pendingAction: const Value(null),
        isSynced: const Value(true),
        deletedLocally: const Value(false),
        syncedAt: Value(DateTime.now()),
      );
    }).toList();

    await cachedProcessOrdersDao.mergeServerRows(rows);
  }

  Future<void> _prefetchProcessDetails(List<Map<String, dynamic>> items) async {
    for (final item in items) {
      final serverId = _toId(item['id']);
      if (serverId <= 0) continue;

      try {
        final existing = await cachedProcessOrdersDao.findByServerId(serverId);
        final status = item['order_status']?.toString();

        if (status != 'OPENBILL_CONFIRMATION' &&
            existing?.detailJson != null &&
            existing!.detailJson!.trim().isNotEmpty) {
          continue;
        }

        final detail = await repo.fetchOrderDetail(serverId);
        await cachedProcessOrdersDao.saveDetailJson(
          serverId,
          jsonEncode(detail),
        );
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

    await cachedProcessOrdersDao.clearAll();
    notifyListeners();
  }


  Future<Map<String, dynamic>?> _getCachedProcessDetailMap(int serverId) async {
    final row = await cachedProcessOrdersDao.findByServerId(serverId);
    if (row == null) return null;

    final decoded = _decodeCachedJson(row.detailJson) ??
        _decodeCachedJson(row.latestProcessJson) ??
        _decodeCachedJson(row.processRequestJson);

    if (decoded != null) {
      final map = _normalizeCachedOrderMap(decoded);
      map['id'] = row.serverId;
      map['booking_order_code'] = row.bookingOrderCode;
      map['customer_name'] = row.customerName;
      map['payment_method'] = row.paymentMethod;
      map['order_status'] = row.orderStatus;
      map['total_order_value'] = row.subtotal;
      map['ppn'] = row.ppnPercent;
      map['is_ppn_active'] = row.isPpnActive;
      map['table'] ??= {'table_no': row.tableNo ?? '-'};
      map['order_details'] ??= <dynamic>[];
      return map;
    }

    return {
      'id': row.serverId,
      'booking_order_code': row.bookingOrderCode,
      'customer_name': row.customerName,
      'payment_method': row.paymentMethod,
      'order_status': row.orderStatus,
      'total_order_value': row.subtotal,
      'ppn': row.ppnPercent,
      'is_ppn_active': row.isPpnActive,
      'table': {
        'table_no': row.tableNo ?? '-',
      },
      'payment': <String, dynamic>{},
      'order_details': <dynamic>[],
    };
  }

  Future<Map<String, dynamic>> getOrderDetailFromListItem(
    Map<String, dynamic> row,
  ) async {
    final isLocalOnly = row['is_local_only'] == true;

    if (isLocalOnly) {
      final localId = (row['local_id'] ?? '').toString();
      if (localId.isEmpty) {
        throw Exception('Local ID order tidak valid');
      }

      final localDetail = await localOrdersDao.getOrderDetailMapByLocalId(localId);
      if (localDetail != null) return localDetail;

      throw Exception('Detail order lokal tidak ditemukan');
    }

    final serverId = _toId(row['id']);
    if (serverId <= 0) {
      throw Exception('Order ID tidak valid');
    }

    if (!connectivity.isOnline) {
      final cached = await _getCachedProcessDetailMap(serverId);
      if (cached != null) return cached;
      throw Exception('Detail offline tidak tersedia di cache');
    }

    try {
      final detail = await repo.fetchOrderDetail(serverId);
      await cachedProcessOrdersDao.saveDetailJson(
        serverId,
        jsonEncode(detail),
      );
      return detail;
    } catch (_) {
      final cached = await _getCachedProcessDetailMap(serverId);
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPrintDetailFromListItem(
    Map<String, dynamic> row,
  ) async {
    final isLocalOnly = row['is_local_only'] == true;

    if (isLocalOnly) {
      final localId = (row['local_id'] ?? '').toString();
      if (localId.isEmpty) {
        throw Exception('Local ID order tidak valid');
      }

      final localDetail = await localOrdersDao.getOrderDetailMapByLocalId(localId);
      if (localDetail != null) return localDetail;

      throw Exception('Detail print lokal tidak ditemukan');
    }

    final serverId = _toId(row['id']);
    if (serverId <= 0) {
      throw Exception('Order ID tidak valid');
    }

    if (!connectivity.isOnline) {
      final cached = await _getCachedProcessDetailMap(serverId);
      if (cached != null) return cached;
      throw Exception('Data print offline tidak tersedia di cache');
    }

    try {
      final detail = await repo.fetchPrintDetail(serverId);
      await cachedProcessOrdersDao.saveDetailJson(
        serverId,
        jsonEncode(detail),
      );
      return detail;
    } catch (_) {
      final cached = await _getCachedProcessDetailMap(serverId);
      if (cached != null) return cached;
      rethrow;
    }
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

  Map<String, dynamic> _normalizeCachedOrderMap(Map<String, dynamic> map) {
    final normalized = Map<String, dynamic>.from(map);

    normalized['booking_order_code'] =
        normalized['booking_order_code'] ?? '-';
    normalized['customer_name'] =
        normalized['customer_name'] ?? '-';
    normalized['order_status'] =
        normalized['order_status'] ?? 'PROCESSED';
    normalized['payment_method'] = normalized['payment_method'] ??
        (_toBool(normalized['openbill_flag']) ? 'OPENBILL' : 'CASH');
    normalized['total_order_value'] =
        normalized['total_order_value'] ?? 0;
    normalized['ppn'] = normalized['ppn'] ?? 0;
    normalized['is_ppn_active'] = normalized['is_ppn_active'] ?? false;

    if (normalized['table'] == null) {
      normalized['table'] = {
        'table_no': normalized['table_no_snapshot'] ?? '-',
      };
    }

    if (normalized['payment'] == null) {
      normalized['payment'] = <String, dynamic>{};
    }

    if (normalized['order_details'] == null) {
      normalized['order_details'] = <dynamic>[];
    }

    return normalized;
  }

  final Set<int> actionLoadingIds = <int>{};

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

      if (isLocalOnly) {
        final localId = (row['local_id'] ?? '').toString();
        if (localId.isEmpty) {
          throw Exception('Local ID tidak valid');
        }

        await localOrdersDao.updateOrderStatusLocal(
          localId: localId,
          status: targetStatus,
          preserveStockConflict: isStockConflict,
        );

        if (isConfirmingOpenbill) {
          await localOrdersDao.updateBackendSyncStage(localId, 'CONFIRMED');
        }

        final idx = items.indexWhere((e) => e['local_id'] == localId);
        if (idx >= 0) {
          items[idx] = {
            ...items[idx],
            'order_status': targetStatus,
            'is_synced': false,
            'pending_action': 'LOCAL_ONLY',
            'pending_sync': true,
            'sync_status': isStockConflict ? 'STOCK_CONFLICT' : 'PENDING',
          };
          notifyListeners();
        }

        return {
          'status': 'offline_success',
          'offline': true,
          'message': 'Order lokal diubah ke $targetStatus dan tetap pending sync',
        };
      }

      final cached = await cachedProcessOrdersDao.findByServerId(id);
      final forceOffline = isStockConflict;

      if (connectivity.isOnline && !forceOffline) {
        final res = await repo.processOrder(id);

        final status = (res['status'] ?? '').toString();
        if (status == 'warning' || res['already_processed'] == true) {
          await load();
          return res;
        }

        await cachedProcessOrdersDao.markProcessedOnline(
          id,
          latestJson: cached?.latestProcessJson,
        );

        await localOrdersDao.updateOrderStatusByServerId(
          serverId: id,
          status: targetStatus,
        );

        await tabCoordinator.transitionOrderStage(
          serverId: id,
          orderStatus: targetStatus,
          syncDirty: false,
          orderSnapshot: row,
        );

        _setStatusLocal(id, targetStatus);
        return res;
      } else {
        await cachedProcessOrdersDao.markProcessedOffline(
          id,
          cached?.latestProcessJson ?? cached?.processRequestJson ?? '{}',
        );

        await tabCoordinator.transitionOrderStage(
          serverId: id,
          orderStatus: targetStatus,
          syncIntent: 'PROCESS',
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
      if (isLocalOnly) {
        final localId = (row['local_id'] ?? '').toString();
        if (localId.isEmpty) {
          throw Exception('Local ID tidak valid');
        }

        await localOrdersDao.updateOrderStatusLocal(
          localId: localId,
          status: 'PAID',
          preserveStockConflict: isStockConflict,
        );

        final idx = items.indexWhere((e) => e['local_id'] == localId);
        if (idx >= 0) {
          items[idx] = {
            ...items[idx],
            'order_status': 'PAID',
            'is_synced': false,
            'pending_action': 'LOCAL_ONLY',
            'pending_sync': true,
            'sync_status': isStockConflict ? 'STOCK_CONFLICT' : 'PENDING',
          };
          notifyListeners();
        }

        return {
          'status': 'offline_success',
          'offline': true,
          'message': 'Status lokal dikembalikan ke PAID',
        };
      }

      final cached = await cachedProcessOrdersDao.findByServerId(id);
      final forceOffline = isStockConflict;

      if (connectivity.isOnline && !forceOffline) {
        final res = await repo.cancelProcessOrder(id);

        await cachedProcessOrdersDao.markCancelProcessOnline(
          id,
          latestJson: cached?.latestProcessJson,
        );

        await localOrdersDao.updateOrderStatusByServerId(
          serverId: id,
          status: 'PAID',
        );

        _setStatusLocal(id, 'PAID');
        return res;
      } else {
        await cachedProcessOrdersDao.markCancelProcessOffline(
          id,
          cached?.latestProcessJson ?? cached?.processRequestJson ?? '{}',
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

      if (isLocalOnly) {
        final localId = (row['local_id'] ?? '').toString();
        if (localId.isEmpty) {
          throw Exception('Local ID tidak valid');
        }

        final result = await localOrdersDao.markLocalOrderItemsServed(
          localId: localId,
          detailIds: detailIds,
        );

        await load();

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

    if (isLocalOnly) {
      final localId = (row['local_id'] ?? '').toString();
      if (localId.isEmpty) {
        throw Exception('Local ID tidak valid');
      }

      final result = await localOrdersDao.markLocalOrderItemsServedByKitchen(
        localId: localId,
        detailIds: [detailId],
      );

      await load();

      return {
        'status': 'offline_success',
        'offline': true,
        'message': 'Status item berhasil diperbarui',
        ...result,
      };
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

      await cachedPaymentOrdersDao.upsertDetailFromApi(updated);
      await cachedProcessOrdersDao.saveDetailJson(id, jsonEncode(updated));
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
      if (isLocalOnly) {
        final localId = (row['local_id'] ?? '').toString();
        if (localId.isEmpty) {
          throw Exception('Local ID tidak valid');
        }

        final localOrder = await localOrdersDao.getOrderByLocalId(localId);
        final isOpenbill =
            _toBool(row['openbill_flag']) ||
            row['payment_method']?.toString() == 'OPENBILL' ||
            (row['order_status'] ?? '').toString().startsWith('OPENBILL') ||
            (localOrder?.paymentMethodSelected ?? '').toUpperCase() ==
                'OPENBILL' ||
            (localOrder?.paymentMethodEffective ?? '').toUpperCase() ==
                'OPENBILL';

        if (isOpenbill) {
          await localOrdersDao.updateOrderStatusByLocalId(
            localId: localId,
            status: 'UNPAID',
            syncStatus: isStockConflict ? 'STOCK_CONFLICT' : 'PENDING_FINISH',
          );
          await localOrdersDao.updateBackendSyncStage(localId, 'OPENBILL_SERVED');

          items.removeWhere((e) => e['local_id'] == localId);
          notifyListeners();

          return {
            'status': 'offline_success',
            'offline': true,
            'message': 'Order open bill selesai dan dipindahkan ke pembayaran',
          };
        }

        await localOrdersDao.updateOrderStatusLocal(
          localId: localId,
          status: 'SERVED',
          preserveStockConflict: isStockConflict,
        );

        final idx = items.indexWhere((e) => e['local_id'] == localId);
        if (idx >= 0) {
          items[idx] = {
            ...items[idx],
            'order_status': 'SERVED',
            'is_synced': false,
            'pending_action': 'LOCAL_ONLY',
            'pending_sync': true,
            'sync_status': isStockConflict ? 'STOCK_CONFLICT' : 'PENDING',
          };
          notifyListeners();
        }

        return {
          'status': 'offline_success',
          'offline': true,
          'message': 'Order lokal ditandai selesai dan tetap pending sync',
        };
      }

      final cached = await cachedProcessOrdersDao.findByServerId(id);
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
          orderSnapshot: {
            ...row,
            'order_status': nextStatus,
          },
        );

        await cachedProcessOrdersDao.deleteByServerId(id);
        if (nextStatus == 'SERVED') {
          await localOrdersDao.deleteOrderByServerId(id);
        }

        items.removeWhere((e) => _toId(e['id']) == id);
        notifyListeners();

        return res;
      } else {
        final rawJson =
            cached?.latestProcessJson ?? cached?.processRequestJson ?? '{}';

        await cachedProcessOrdersDao.markFinishedOffline(
          id,
          rawJson,
        );

        final isOpenbill =
            _toBool(row['openbill_flag']) ||
            row['payment_method']?.toString() == 'OPENBILL' ||
            (row['order_status'] ?? '').toString().startsWith('OPENBILL');

        if (isOpenbill) {
          Map<String, dynamic> detailMap = {};
          if (cached?.detailJson != null && cached!.detailJson!.trim().isNotEmpty) {
            try {
              detailMap = Map<String, dynamic>.from(jsonDecode(cached.detailJson!));
            } catch (_) {}
          }
          if (detailMap.isEmpty) {
            try {
              detailMap = Map<String, dynamic>.from(jsonDecode(rawJson));
            } catch (_) {}
          }

          detailMap['id'] ??= id;
          detailMap['booking_order_code'] ??= row['booking_order_code'];
          detailMap['customer_name'] ??= row['customer_name'];
          detailMap['table'] ??= row['table'] ?? {'table_no': row['table_no_snapshot'] ?? '-'};
          detailMap['payment_method'] = 'OPENBILL';
          detailMap['openbill_flag'] = true;
          detailMap['order_status'] = 'UNPAID';
          detailMap['total_order_value'] ??= row['total_order_value'] ?? 0;
          detailMap['ppn'] ??= row['ppn'] ?? 0;
          detailMap['is_ppn_active'] ??= row['is_ppn_active'] ?? 0;
          detailMap['created_at'] ??= row['created_at'] ?? row['sort_time'] ?? row['cached_at'] ?? DateTime.now().toIso8601String();

          await cachedPaymentOrdersDao.upsertDetailFromApi(detailMap);

          await tabCoordinator.transitionOrderStage(
            serverId: id,
            orderStatus: 'UNPAID',
            syncIntent: 'FINISH',
            syncDirty: true,
            orderSnapshot: detailMap,
          );

          items.removeWhere((e) => _toId(e['id']) == id);
          notifyListeners();

          return {
            'status': 'offline_success',
            'offline': true,
            'message': 'Order open bill dipindahkan ke pembayaran',
          };
        } else {
          await cachedDoneOrdersDao.upsertPendingFinishFromProcess(
            serverId: id,
            bookingOrderCode: (row['booking_order_code'] ?? '').toString(),
            customerName: (row['customer_name'] ?? '').toString(),
            tableNo: row['table'] is Map
                ? row['table']['table_no']?.toString()
                : row['table_no_snapshot']?.toString(),
            paymentMethod: row['payment_method']?.toString(),
            subtotal: _toDouble(row['total_order_value']),
            ppnPercent: _toDouble(row['ppn']),
            isPpnActive: _toBool(row['is_ppn_active']),
            rawJson: rawJson,
          );
        }

        await tabCoordinator.transitionOrderStage(
          serverId: id,
          orderStatus: 'SERVED',
          syncIntent: 'FINISH',
          syncDirty: true,
          orderSnapshot: row,
        );

        _setStatusLocal(id, 'SERVED');

        return {
          'status': 'offline_success',
          'offline': true,
          'message': 'Order ditandai selesai dan menunggu sinkronisasi',
        };
      }
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
    final detail = await _getCachedProcessDetailMap(serverId);
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

    await cachedProcessOrdersDao.markServeItemsOffline(
      serverId: serverId,
      detailJson: jsonEncode(detail),
      orderStatus: nextStatus,
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
    final detail = await _getCachedProcessDetailMap(serverId);
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

    await cachedProcessOrdersDao.markServeItemsOffline(
      serverId: serverId,
      detailJson: jsonEncode(detail),
      orderStatus: nextStatus,
      pendingAction: 'MARK_KITCHEN_SERVED',
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
    final cached = await cachedProcessOrdersDao.findByServerId(serverId);
    Map<String, dynamic> detailMap = {};

    if (cached?.detailJson != null && cached!.detailJson!.trim().isNotEmpty) {
      try {
        detailMap = Map<String, dynamic>.from(jsonDecode(cached.detailJson!));
      } catch (_) {}
    }

    if (detailMap.isEmpty) {
      final fallback = await _getCachedProcessDetailMap(serverId);
      if (fallback != null) detailMap = fallback;
    }

    detailMap['id'] ??= serverId;
    detailMap['booking_order_code'] ??= row['booking_order_code'];
    detailMap['customer_name'] ??= row['customer_name'];
    detailMap['table'] ??=
        row['table'] ?? {'table_no': row['table_no_snapshot'] ?? '-'};
    detailMap['payment_method'] = 'OPENBILL';
    detailMap['openbill_flag'] = true;
    detailMap['order_status'] = 'UNPAID';
    detailMap['total_order_value'] ??= row['total_order_value'] ?? 0;
    detailMap['ppn'] ??= row['ppn'] ?? 0;
    detailMap['is_ppn_active'] ??= row['is_ppn_active'] ?? 0;
    detailMap['created_at'] ??=
        row['created_at'] ??
        row['sort_time'] ??
        row['cached_at'] ??
        DateTime.now().toIso8601String();

    await cachedPaymentOrdersDao.upsertDetailFromApi(detailMap);
  }

  Future<void> _stageServedOrderForDoneCache(
    int serverId,
    Map<String, dynamic> row,
  ) async {
    final cached = await cachedProcessOrdersDao.findByServerId(serverId);
    final rawJson =
        cached?.detailJson ??
        cached?.latestProcessJson ??
        cached?.processRequestJson ??
        '{}';

    await cachedDoneOrdersDao.upsertPendingFinishFromProcess(
      serverId: serverId,
      bookingOrderCode: (row['booking_order_code'] ?? '').toString(),
      customerName: (row['customer_name'] ?? '').toString(),
      tableNo: row['table'] is Map
          ? row['table']['table_no']?.toString()
          : row['table_no_snapshot']?.toString(),
      paymentMethod: row['payment_method']?.toString(),
      subtotal: _toDouble(row['total_order_value']),
      ppnPercent: _toDouble(row['ppn']),
      isPpnActive: _toBool(row['is_ppn_active']),
      rawJson: rawJson,
    );
  }
}
