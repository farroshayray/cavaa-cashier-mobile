import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:drift/drift.dart';
import '../../data/models/orders_repository.dart';
import '/features/cashier/data/local/db/daos/local_orders_dao.dart';
import '/features/cashier/data/local/db/daos/cached_payment_orders_dao.dart';
import '/features/cashier/data/local/db/cashier_db.dart';
import '/core/services/connectivity_status_provider.dart';
import '/features/cashier/data/local/db/daos/cached_payment_methods_dao.dart';
import 'dart:convert';

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
  

  PaymentProvider({
    required this.repo,
    required this.localOrdersDao,
    required this.cachedPaymentOrdersDao,
    required this.cachedPaymentMethodsDao,
    required this.connectivity,
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
          unawaited(_prefetchAndCacheDetails(serverItems));
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

      final filteredMergedItems = mergedItems.where((e) {
        final sid = _toInt(e['server_id'] ?? e['id']);
        final code = (e['booking_order_code'] ?? e['client_order_code'] ?? '')
            .toString()
            .trim();

        final hiddenById = sid != null && sid > 0 && hiddenServerIds.contains(sid);
        final hiddenByCode = code.isNotEmpty && hiddenOrderCodes.contains(code);

        return !(hiddenById || hiddenByCode);
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

  Future<void> confirmPaymentFromRow({
    required Map<String, dynamic> row,
    required num paidAmount,
    required num changeAmount,
    String? cashierProofImagePath,
    String? lastPaymentId,
  }) async {
    final isOnline = connectivity.isOnline;

    if (isOnline) {
      final serverId = _toInt(row['server_id'] ?? row['id']);
      if (serverId == null || serverId <= 0) {
        throw Exception('ID order tidak valid untuk pembayaran online');
      }

      await repo.paymentOrder(
        id: serverId,
        paidAmount: paidAmount,
        changeAmount: changeAmount,
        lastPaymentId: lastPaymentId,
        cashierProofImagePath: cashierProofImagePath,
      );

      await load();
      return;
    }

    await confirmPaymentOffline(
      order: row,
      paidAmount: paidAmount,
      changeAmount: changeAmount,
      cashierProofImagePath: cashierProofImagePath,
      lastPaymentId: lastPaymentId,
    );

    await load();
  }

  Future<void> confirmPaymentOffline({
    required Map<String, dynamic> order,
    required num paidAmount,
    required num changeAmount,
    String? cashierProofImagePath,
    String? lastPaymentId,
  }) async {
    final now = DateTime.now();

    String localId = (order['local_id'] ?? '').toString();
    final isLocalOnly = order['is_local_only'] == true;

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
          (order['payment_method'] ?? 'CASH').toString();

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
    final snapshot = Map<String, dynamic>.from(order);
    snapshot['is_local_only'] = true;
    snapshot['local_id'] = localId;
    snapshot['payment'] = {
      'updated_at': now.toIso8601String(),
      'paid_amount': paidAmount,
      'change_amount': changeAmount,
    };
    snapshot.remove('sync_status');
    snapshot.remove('pending_sync');

    await localOrdersDao.markPaymentConfirmedOffline(
      localId: localId,
      paidAmount: paidAmount.toDouble(),
      changeAmount: changeAmount.toDouble(),
      cashierProofImageLocalPath: cashierProofImagePath,
      paymentConfirmedAtLocal: now,
      latestPaymentServerId: int.tryParse(lastPaymentId ?? ''),
      orderSnapshotJson: jsonEncode(snapshot),
    );

    // kalau source-nya cached server, tandai agar tidak tampil lagi di tab pembayaran
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
        return _enrichOfflinePaymentMethod(localDetail);
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

        return detail;
      } catch (_) {
        final cached = await cachedPaymentOrdersDao.getCachedOrderDetailMap(serverId);
        if (cached != null) {
          return _enrichOfflinePaymentMethod(cached);
        }
        rethrow;
      }
    }

    final cached = await cachedPaymentOrdersDao.getCachedOrderDetailMap(serverId);

    // ✅ TARUH DI SINI
    if (cached != null) {
      return _enrichOfflinePaymentMethod(cached);
    }

    throw Exception('Detail order offline tidak tersedia');
  }

  Future<Map<String, dynamic>> _enrichOfflinePaymentMethod(
    Map<String, dynamic> detail,
  ) async {
    final method = (detail['payment_method'] ?? '').toString();

    if (method != 'manual_qris' &&
        method != 'manual_tf' &&
        method != 'manual_ewallet') {
      return detail;
    }

    int? serverManualPaymentId;

    final latestRaw = detail['latest_payment'];
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

    if (manual == null) return detail;

    final cloned = Map<String, dynamic>.from(detail);

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