import 'package:flutter/foundation.dart';
import '../../data/models/orders_repository.dart';
import '/features/cashier/data/local/db/daos/local_orders_dao.dart';
import '/features/cashier/data/local/db/mappers/local_order_mapper.dart';
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

  ProcessProvider(
    this.repo,
    this.localOrdersDao,
    this.cachedProcessOrdersDao,
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

      final remoteItems = cachedRows.map((row) {
        return <String, dynamic>{
          'id': row.serverId,
          'booking_order_code': row.bookingOrderCode,
          'customer_name': row.customerName,
          'payment_method': row.paymentMethod,
          'order_status': row.orderStatus,
          'total_order_value': row.subtotal,
          'ppn': row.ppnPercent,
          'is_ppn_active': row.isPpnActive ? 1 : 0,
          'table': {
            'table_no': row.tableNo,
          },
          'is_synced': row.isSynced,
          'pending_action': row.pendingAction,
          'cached_at': row.syncedAt?.toIso8601String(),
        };
      }).toList();

      final localRows = await localOrdersDao.getLocalProcessOrders();
      final localItems = localRows.map(mapLocalOrderToProcessItem).toList();

      final remoteIds = remoteItems
          .map((e) => int.tryParse('${e['id']}'))
          .whereType<int>()
          .toSet();

      final filteredLocalItems = localItems.where((e) {
        final id = e['id'];
        if (id is! int) return true;
        if (id <= 0) return true;
        return !remoteIds.contains(id);
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
          (a['created_at'] ?? a['cached_at'] ?? a['updated_at_local'] ?? '')
              .toString(),
        );
        final bCreated = DateTime.tryParse(
          (b['created_at'] ?? b['cached_at'] ?? b['updated_at_local'] ?? '')
              .toString(),
        );

        if (aCreated == null && bCreated == null) return 0;
        if (aCreated == null) return -1;
        if (bCreated == null) return 1;

        return aCreated.compareTo(bCreated);
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
        pendingAction: const Value(null),
        isSynced: const Value(true),
        deletedLocally: const Value(false),
        syncedAt: Value(DateTime.now()),
      );
    }).toList();

    await cachedProcessOrdersDao.mergeServerRows(rows);
  }

  void setQuery(String q) {
    query = q;
    notifyListeners();
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

    return repo.fetchOrderDetail(serverId);
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

    return repo.fetchPrintDetail(serverId);
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

  Future<Map<String, dynamic>> actionProcess(int id) async {
    _setActionLoading(id, true);
    try {
      final row = await cachedProcessOrdersDao.findByServerId(id);

      if (connectivity.isOnline) {
        final res = await repo.processOrder(id);

        final status = (res['status'] ?? '').toString();
        if (status == 'warning' || res['already_processed'] == true) {
          await load();
          return res;
        }

        await cachedProcessOrdersDao.markProcessedOnline(
          id,
          latestJson: row?.latestProcessJson,
        );

        _setStatusLocal(id, 'PROCESSED');

        return res;
      } else {
        await cachedProcessOrdersDao.markProcessedOffline(
          id,
          row?.latestProcessJson ?? row?.processRequestJson ?? '{}',
        );

        _setStatusLocal(id, 'PROCESSED');

        return {
          'status': 'offline_success',
          'offline': true,
          'message': 'Order ditandai diproses dan menunggu sinkronisasi',
        };
      }
    } finally {
      _setActionLoading(id, false);
    }
  }

  Future<Map<String, dynamic>> actionCancelProcess(int id) async {
    _setActionLoading(id, true);
    try {
      final row = await cachedProcessOrdersDao.findByServerId(id);

      if (connectivity.isOnline) {
        final res = await repo.cancelProcessOrder(id);

        await cachedProcessOrdersDao.markCancelProcessOnline(
          id,
          latestJson: row?.latestProcessJson,
        );

        _setStatusLocal(id, 'PAID');
        return res;
      } else {
        await cachedProcessOrdersDao.markCancelProcessOffline(
          id,
          row?.latestProcessJson ?? row?.processRequestJson ?? '{}',
        );

        _setStatusLocal(id, 'PAID');

        return {
          'status': 'offline_success',
          'offline': true,
          'message': 'Pembatalan proses disimpan dan menunggu sinkronisasi',
        };
      }
    } finally {
      _setActionLoading(id, false);
    }
  }

  Future<Map<String, dynamic>> actionFinish(int id, {String? note}) async {
    _setActionLoading(id, true);
    try {
      final row = await cachedProcessOrdersDao.findByServerId(id);

      if (connectivity.isOnline) {
        final res = await repo.finishOrder(id, note: note);

        await cachedProcessOrdersDao.markFinishedOnline(
          id,
          latestJson: row?.latestProcessJson,
        );

        _setStatusLocal(id, 'SERVED');
        return res;
      } else {
        await cachedProcessOrdersDao.markFinishedOffline(
          id,
          row?.latestProcessJson ?? row?.processRequestJson ?? '{}',
        );

        _setStatusLocal(id, 'SERVED');

        return {
          'status': 'offline_success',
          'offline': true,
          'message': 'Order ditandai selesai dan menunggu sinkronisasi',
        };
      }
    } finally {
      _setActionLoading(id, false);
    }
  }
}