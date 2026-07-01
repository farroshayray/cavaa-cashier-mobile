import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../data/models/orders_repository.dart';
import '/features/cashier/data/local/db/daos/booking_orders_dao.dart';
import '/features/cashier/data/local/db/mappers/order_mirror_mapper.dart';
import '/features/cashier/data/sync/order_tab_item_mapper.dart';
import '/features/cashier/presentation/utils/order_tab_sort.dart';
import '/core/services/connectivity_status_provider.dart';

class DoneProvider extends ChangeNotifier {
  final OrdersRepository repo;
  final ConnectivityStatusProvider connectivity;
  final BookingOrdersDao bookingOrdersDao;

  DoneProvider(
    this.repo,
    this.connectivity,
    this.bookingOrdersDao,
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
      await bookingOrdersDao.reconcileDuplicateMirrors();

      final mirrorRows = await bookingOrdersDao.getDoneTabOrders();
      items = mirrorRows.map(OrderTabItemMapper.toDoneItem).toList();

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
      (e) => e['sync_status'] == 'PENDING' || e['is_synced'] == false,
    );
    if (connectivity.isOnline && items.isNotEmpty && !hasPendingSync) {
      unawaited(_prefetchDoneDetailsInBackground());
    }
  }

  Future<void> _prefetchDoneDetailsInBackground() async {
    final snapshot = List<Map<String, dynamic>>.from(items);
    try {
      await _prefetchDoneDetails(snapshot);
    } catch (e) {
      debugPrint('DoneProvider prefetch done details failed: $e');
    }
  }

  Future<void> _prefetchDoneDetails(List<Map<String, dynamic>> items) async {
    for (final item in items) {
      final serverId = int.tryParse('${item['id']}');
      if (serverId == null || serverId <= 0) continue;
      try {
        final detail = await repo.fetchOrderDetail(serverId);
        await bookingOrdersDao.upsertFromServer(detail);
      } catch (e) {
        debugPrint('DoneProvider prefetch failed for $serverId: $e');
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
    notifyListeners();
  }

  Future<Map<String, dynamic>> getOrderDetailFromListItem(
    Map<String, dynamic> row,
  ) async {
    final serverId = int.tryParse('${row['id']}');
    if (serverId == null || serverId <= 0) {
      throw Exception('Order ID tidak valid');
    }

    if (connectivity.isOnline) {
      final detail = await repo.fetchOrderDetail(serverId);
      await bookingOrdersDao.upsertFromServer(detail);
      return detail;
    }

    final mirror = await bookingOrdersDao.getByServerId(serverId);
    if (mirror == null) {
      throw Exception('Detail offline tidak tersedia');
    }

    final bundle = await bookingOrdersDao.getBundleByClientUuid(mirror.clientUuid);
    if (bundle == null) {
      throw Exception('Detail offline tidak tersedia');
    }

    final map = OrderTabItemMapper.toDoneItem(
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

  Future<Map<String, dynamic>> getPrintDetailFromListItem(
    Map<String, dynamic> row,
  ) =>
      getOrderDetailFromListItem(row);
}
