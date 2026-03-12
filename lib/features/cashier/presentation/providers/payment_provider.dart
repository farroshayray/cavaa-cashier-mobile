import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import '../../data/models/orders_repository.dart';
import '/features/cashier/data/local/db/daos/local_orders_dao.dart';
import '/features/cashier/data/local/db/daos/cached_payment_orders_dao.dart';
import '/features/cashier/data/local/db/cashier_db.dart';

class PaymentProvider extends ChangeNotifier {
  final OrdersRepository repo;
  final LocalOrdersDao localOrdersDao;
  final CachedPaymentOrdersDao cachedPaymentOrdersDao;

  PaymentProvider({
    required this.repo,
    required this.localOrdersDao,
    required this.cachedPaymentOrdersDao,
  });

  bool isLoading = false;
  String? error;

  String query = '';
  List<Map<String, dynamic>> items = [];

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final mergedItems = <Map<String, dynamic>>[];
      bool gotServer = false;

      try {
        final res = await repo.fetchOrdersData(
          tab: 'pembayaran',
          q: query.isEmpty ? null : query,
        );

        final raw = res['items'];
        if (raw is List) {
          final serverItems = raw
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();

          mergedItems.addAll(serverItems.map(_normalizeServerItem));
          gotServer = true;

          final cachedRows = serverItems
              .map(_mapServerItemToCachedCompanion)
              .toList();

          await cachedPaymentOrdersDao.replaceAllOrders(
            orders: cachedRows,
          );
        }
      } catch (e) {
        debugPrint('PaymentProvider server load failed: $e');
      }

      if (!gotServer) {
        final cachedOrders = await cachedPaymentOrdersDao.getCachedOrders(
          query: query.isEmpty ? null : query,
        );

        mergedItems.addAll(
          cachedOrders.map(_normalizeCachedServerItem),
        );
      }

      final localOrders = await localOrdersDao.getUnpaidOrders(
        query: query.isEmpty ? null : query,
      );

      final localItems = localOrders.map((o) {
        final tableNo = o.tableNoSnapshot ?? '-';

        return <String, dynamic>{
          'id': -1,
          'local_id': o.localId,
          'client_order_code': o.clientOrderCode,
          'booking_order_code': o.clientOrderCode,

          'customer_name': o.customerName,
          'customer': o.customerName,
          'order_name': o.customerName,

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

          'is_ppn_active': o.isPpnActive,
          'ppn': o.ppnPercent,

          'payment_method': o.paymentMethodEffective,
          'order_status': o.orderStatusLocal,
          'sync_status': o.syncStatus,
          'server_id': o.serverId,
          'server_order_code': o.serverOrderCode,
          'is_local_only': true,
          'is_cached_server': false,

          'created_at': o.createdAtLocal.toIso8601String(),
        };
      }).toList();

      items = [
        ...mergedItems,
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
      isLoading = false;
      notifyListeners();
    }
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
        : subtotal.toDouble();

    final createdAt = DateTime.tryParse((item['created_at'] ?? '').toString());

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
      grandTotal: Value(grandTotal),
      createdAt: Value(createdAt),
    );
  }

  Map<String, dynamic> _normalizeServerItem(Map<String, dynamic> e) {
    final subtotal = _toNum(e['total_order_value']);
    final ppnPercent = _toNum(e['ppn']);
    final isPpnActive = _toBool(e['is_ppn_active']);
    final grandTotal = isPpnActive
        ? (subtotal + (subtotal * ppnPercent / 100)).ceil()
        : subtotal.ceil();

    return <String, dynamic>{
      ...e,
      'subtotal': subtotal,
      'grand_total': grandTotal,
      'is_local_only': false,
      'is_cached_server': false,
      'sync_status': 'SYNCED',
    };
  }

  Map<String, dynamic> _normalizeCachedServerItem(CachedPaymentOrder o) {
    final tableNo = o.tableNo ?? '-';

    return <String, dynamic>{
      'id': o.serverId,
      'server_id': o.serverId,
      'booking_order_code': o.bookingOrderCode,
      'customer_name': o.customerName,
      'customer': o.customerName,
      'order_name': o.customerName,

      'table': {
        'table_no': tableNo,
      },
      'table_no': tableNo,
      'table_name': tableNo,

      'payment_method': o.paymentMethod,
      'order_status': o.orderStatus,

      'total_order_value': o.subtotal,
      'subtotal': o.subtotal,
      'grand_total': o.grandTotal,
      'total_amount': o.grandTotal,

      'is_ppn_active': o.isPpnActive,
      'ppn': o.ppnPercent,

      'is_local_only': false,
      'is_cached_server': true,
      'sync_status': o.isPendingDelete ? 'PENDING_DELETE' : 'SYNCED',

      'created_at': o.createdAt?.toIso8601String(),
      'cached_at': o.cachedAt.toIso8601String(),
    };
  }

  void setQuery(String q) {
    query = q;
    notifyListeners();
  }

  Future<Map<String, dynamic>> getOrderDetail(int id) async {
    return repo.fetchOrderDetail(id);
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
    return repo.paymentOrder(
      id: id,
      paidAmount: paidAmount,
      changeAmount: changeAmount,
      note: note,
      email: email,
      lastPaymentId: lastPaymentId,
      cashierProofImagePath: cashierProofImagePath,
    );
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