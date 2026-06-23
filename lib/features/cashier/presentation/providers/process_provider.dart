import 'package:flutter/foundation.dart';
import '../../data/models/orders_repository.dart';
import '/features/cashier/data/local/db/daos/local_orders_dao.dart';
import '/features/cashier/data/local/db/mappers/local_order_mapper.dart';
import '/features/cashier/data/local/db/daos/cached_done_orders_dao.dart';
import '/features/cashier/data/local/db/daos/cached_payment_orders_dao.dart';
import 'dart:convert';
import 'package:drift/drift.dart';
import '/core/services/connectivity_status_provider.dart';
import '/features/cashier/data/local/db/daos/cached_process_orders_dao.dart';
import '/features/cashier/data/local/db/cashier_db.dart';

class ProcessProvider extends ChangeNotifier {
  final OrdersRepository repo;
  final LocalOrdersDao localOrdersDao;
  final CachedProcessOrdersDao cachedProcessOrdersDao;
  final ConnectivityStatusProvider connectivity;
  final CachedDoneOrdersDao cachedDoneOrdersDao;
  final CachedPaymentOrdersDao cachedPaymentOrdersDao;

  ProcessProvider(
    this.repo,
    this.localOrdersDao,
    this.cachedProcessOrdersDao,
    this.cachedDoneOrdersDao,
    this.cachedPaymentOrdersDao,
    this.connectivity,
  );

  bool isLoading = false;
  String? error;

  String query = '';
  List<Map<String, dynamic>> items = [];

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      if (connectivity.isOnline) {
        try {
          await _refreshProcessOrdersFromServer();
        } catch (e) {
          debugPrint('ProcessProvider refresh cache failed: $e');
        }
      }

      final cachedRows = await cachedProcessOrdersDao.getAllActive();
      final doneRows = await cachedDoneOrdersDao.getAllActive();
      final doneIds = doneRows.map((e) => e.serverId).toSet();
      final doneCodes = doneRows
          .map((e) => e.bookingOrderCode.trim())
          .where((e) => e.isNotEmpty)
          .toSet();

      final remoteItems = cachedRows
        .where((row) {
          if (row.orderStatus == 'SERVED') return false;
          if (doneIds.contains(row.serverId)) return false;
          if (row.bookingOrderCode.trim().isNotEmpty &&
              doneCodes.contains(row.bookingOrderCode.trim())) {
            return false;
          }
          return true;
        })
        .map((row) {
        final cached = _decodeCachedJson(row.detailJson) ??
            _decodeCachedJson(row.latestProcessJson) ??
            _decodeCachedJson(row.processRequestJson) ??
            <String, dynamic>{};

        return <String, dynamic>{
          ..._normalizeCachedOrderMap(cached),
          'id': row.serverId,
          'booking_order_code': row.bookingOrderCode,
          'customer_name': row.customerName,
          'payment_method': row.paymentMethod,
          'order_status': row.orderStatus,
          'total_order_value': row.subtotal,
          'ppn': row.ppnPercent,
          'is_ppn_active': row.isPpnActive ? 1 : 0,
          'processed_by_kitchen': row.processedByKitchen,
          'table': {
            'table_no': row.tableNo,
          },
          'is_synced': row.isSynced,
          'pending_action': row.pendingAction,
          'cached_at': row.syncedAt?.toIso8601String(),
          'sort_time': _extractCreatedAtFromRawJson(row.latestProcessJson) ??
              _extractCreatedAtFromRawJson(row.processRequestJson) ??
              row.syncedAt?.toIso8601String(),
        };
      }).toList();

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
      isLoading = false;
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

        if (existing?.detailJson != null &&
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
    normalized['payment_method'] =
        normalized['payment_method'] ?? 'CASH';
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

        _setStatusLocal(id, targetStatus);
        return res;
      } else {
        await cachedProcessOrdersDao.markProcessedOffline(
          id,
          cached?.latestProcessJson ?? cached?.processRequestJson ?? '{}',
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

        await cachedProcessOrdersDao.deleteByServerId(id);
        await localOrdersDao.deleteOrderByServerId(id);

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

        final isOpenbill = row['payment_method']?.toString() == 'OPENBILL';

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
          detailMap['order_status'] = 'UNPAID';
          detailMap['total_order_value'] ??= row['total_order_value'] ?? 0;
          detailMap['ppn'] ??= row['ppn'] ?? 0;
          detailMap['is_ppn_active'] ??= row['is_ppn_active'] ?? 0;
          detailMap['created_at'] ??= row['created_at'] ?? row['sort_time'] ?? row['cached_at'] ?? DateTime.now().toIso8601String();

          await cachedPaymentOrdersDao.upsertDetailFromApi(detailMap);
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
}
