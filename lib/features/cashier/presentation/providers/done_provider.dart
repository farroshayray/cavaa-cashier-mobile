import 'package:flutter/foundation.dart';
import '../../data/models/orders_repository.dart';
import '/features/cashier/data/local/db/cashier_db.dart';

import 'dart:convert';
import 'package:drift/drift.dart';
import '/features/cashier/data/local/db/daos/local_orders_dao.dart';
import '/features/cashier/data/local/db/daos/cached_done_orders_dao.dart';
import '/features/cashier/data/local/db/mappers/local_order_mapper.dart';
import '/core/services/connectivity_status_provider.dart';

class DoneProvider extends ChangeNotifier {
  final OrdersRepository repo;
  final LocalOrdersDao localOrdersDao;
  final CachedDoneOrdersDao cachedDoneOrdersDao;
  final ConnectivityStatusProvider connectivity;

  DoneProvider(
    this.repo,
    this.localOrdersDao,
    this.cachedDoneOrdersDao,
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
          await _refreshDoneOrdersFromServer();
        } catch (e) {
          debugPrint('DoneProvider refresh cache failed: $e');
        }
      }

      final cachedRows = await cachedDoneOrdersDao.getAllActive();

      final remoteItems = cachedRows.map((row) {
        final cached = _decodeCachedJson(row.detailJson) ??
            _decodeCachedJson(row.latestDoneJson) ??
            _decodeCachedJson(row.doneRequestJson) ??
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
          'table': {
            'table_no': row.tableNo,
          },
          'is_synced': row.isSynced,
          'cached_at': row.syncedAt?.toIso8601String(),
          'sort_time': _extractCreatedAtFromRawJson(row.latestDoneJson) ??
              _extractCreatedAtFromRawJson(row.doneRequestJson) ??
              row.syncedAt?.toIso8601String(),
        };
      }).toList();

      if (connectivity.isOnline && remoteItems.isNotEmpty) {
        try {
          await _prefetchDoneDetails(remoteItems);
        } catch (e) {
          debugPrint('DoneProvider prefetch done details failed: $e');
        }
      }

      final localRows = await localOrdersDao.getLocalDoneOrders();
      final localItems = localRows.map((e) {
        final item = mapLocalOrderToProcessItem(e);

        return <String, dynamic>{
          ...item,
          'is_local_only': true,
          'is_synced': false,
          'pending_action': 'LOCAL_ONLY',
          'pending_sync': true,
          'sync_status': e.syncStatus,
          'last_error': e.lastError,
          'sort_time':
              item['created_at']?.toString() ?? e.createdAtLocal.toIso8601String(),
        };
      }).toList();

      final remoteIds = remoteItems
          .map((e) => int.tryParse('${e['id']}'))
          .whereType<int>()
          .toSet();
      final remoteCodes = remoteItems
          .map((e) => (e['booking_order_code'] ?? '').toString().trim())
          .where((e) => e.isNotEmpty)
          .toSet();

      final filteredLocalItems = localItems.where((e) {
        final id = e['id'];
        final code = (e['booking_order_code'] ?? '').toString().trim();

        if (id is int && id > 0 && remoteIds.contains(id)) {
          return false;
        }

        if (code.isNotEmpty && remoteCodes.contains(code)) {
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

        return aCreated.compareTo(bCreated);
      });
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
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

    await cachedDoneOrdersDao.clearAll();
    notifyListeners();
  }

  Future<void> _refreshDoneOrdersFromServer() async {
    final res = await repo.fetchOrdersData(
      tab: 'selesai',
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

      return CachedDoneOrdersCompanion(
        serverId: Value(_toId(map['id'])),
        bookingOrderCode: Value((map['booking_order_code'] ?? '').toString()),
        customerName: Value((map['customer_name'] ?? '').toString()),
        tableNo: Value(tableNo),
        doneRequestJson: Value(jsonEncode(map)),
        latestDoneJson: Value(jsonEncode(map)),
        paymentMethod: Value(map['payment_method']?.toString()),
        orderStatus: Value((map['order_status'] ?? '').toString()),
        subtotal: Value(
          double.tryParse((map['total_order_value'] ?? '0').toString()) ?? 0,
        ),
        ppnPercent: Value(
          double.tryParse((map['ppn'] ?? '0').toString()) ?? 0,
        ),
        isPpnActive: Value((map['is_ppn_active'] ?? 0) == 1),
        isSynced: const Value(true),
        deletedLocally: const Value(false),
        syncedAt: Value(DateTime.now()),
      );
    }).toList();

    await cachedDoneOrdersDao.mergeServerRows(rows);
  }

  Future<void> _prefetchDoneDetails(List<Map<String, dynamic>> items) async {
    for (final item in items) {
      final serverId = _toId(item['id']);
      if (serverId <= 0) continue;

      try {
        final existing = await cachedDoneOrdersDao.findByServerId(serverId);

        // kalau sudah ada detailJson, skip
        if (existing?.detailJson != null &&
            existing!.detailJson!.trim().isNotEmpty) {
          continue;
        }

        final detail = await repo.fetchOrderDetail(serverId);
        await cachedDoneOrdersDao.saveDetailJson(
          serverId,
          jsonEncode(detail),
        );
      } catch (e) {
        debugPrint('DoneProvider prefetch detail failed for $serverId: $e');
      }
    }
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
      final cached = await _getCachedDoneDetailMap(serverId);
      if (cached != null) return cached;
      throw Exception('Detail offline tidak tersedia di cache');
    }

    try {
      final detail = await repo.fetchOrderDetail(serverId);
      await cachedDoneOrdersDao.saveDetailJson(
        serverId,
        jsonEncode(detail),
      );
      return detail;
    } catch (_) {
      final cached = await _getCachedDoneDetailMap(serverId);
      if (cached != null) return cached;
      rethrow;
    }
  }

  Map<String, dynamic> _normalizeCachedOrderMap(Map<String, dynamic> map) {
    final normalized = Map<String, dynamic>.from(map);

    normalized['booking_order_code'] =
        normalized['booking_order_code'] ?? '-';
    normalized['customer_name'] =
        normalized['customer_name'] ?? '-';
    normalized['order_status'] =
        normalized['order_status'] ?? 'SERVED';
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

  Future<Map<String, dynamic>?> _getCachedDoneDetailMap(int serverId) async {
    final row = await cachedDoneOrdersDao.findByServerId(serverId);
    if (row == null) return null;

    final decoded = _decodeCachedJson(row.detailJson) ??
        _decodeCachedJson(row.latestDoneJson) ??
        _decodeCachedJson(row.doneRequestJson);

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
      final cached = await _getCachedDoneDetailMap(serverId);
      if (cached != null) return cached;
      throw Exception('Data print offline tidak tersedia di cache');
    }

    try {
      final detail = await repo.fetchPrintDetail(serverId);
      await cachedDoneOrdersDao.saveDetailJson(
        serverId,
        jsonEncode(detail),
      );
      return detail;
    } catch (_) {
      final cached = await _getCachedDoneDetailMap(serverId);
      if (cached != null) return cached;
      rethrow;
    }
  }

  int _toId(dynamic v) => (v is int) ? v : int.tryParse(v.toString()) ?? 0;

  bool _toBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    final s = v.toString().toLowerCase();
    return s == '1' || s == 'true';
  }

  String? _extractCreatedAtFromRawJson(String? rawJson) {
    if (rawJson == null || rawJson.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is Map) {
        final map = Map<String, dynamic>.from(decoded);
        final createdAt = map['created_at'];
        if (createdAt != null) return createdAt.toString();
      }
    } catch (_) {}
    return null;
  }
}
