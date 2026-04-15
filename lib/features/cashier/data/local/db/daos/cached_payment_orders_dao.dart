import 'package:drift/drift.dart';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '/core/config/env.dart';
import '/features/cashier/data/local/db/cashier_db.dart';

class CachedPaymentOrdersDao {
  final CashierDb db;

  CachedPaymentOrdersDao(this.db);

  Future<void> replaceAllOrders({
    required List<CachedPaymentOrdersCompanion> orders,
  }) async {
    await db.transaction(() async {
      for (final row in orders) {
        final serverId = row.serverId.value;
        if (serverId == null) continue;

        final existing = await (db.select(db.cachedPaymentOrders)
              ..where((t) => t.serverId.equals(serverId)))
            .getSingleOrNull();

        await db.into(db.cachedPaymentOrders).insert(
          CachedPaymentOrdersCompanion(
            serverId: row.serverId,
            bookingOrderCode: row.bookingOrderCode,
            customerName: row.customerName,
            tableNo: row.tableNo,

            // pertahankan data detail lama kalau row baru belum punya
            paymentRequestJson: row.paymentRequestJson.present
                ? row.paymentRequestJson
                : Value(existing?.paymentRequestJson),

            latestPaymentJson: row.latestPaymentJson.present
                ? row.latestPaymentJson
                : Value(existing?.latestPaymentJson),

            detailJson: Value(existing?.detailJson),

            paymentMethod: row.paymentMethod,
            orderStatus: row.orderStatus,
            subtotal: row.subtotal,
            ppnPercent: row.ppnPercent,
            isPpnActive: row.isPpnActive,
            isPendingDelete: Value(existing?.isPendingDelete ?? false),
            grandTotal: row.grandTotal,
            createdAt: row.createdAt,
            updatedAt: row.updatedAt,
            cachedAt: row.cachedAt,
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<List<CachedPaymentOrder>> getCachedOrders({
    String? query,
  }) async {
    final rows = await (db.select(db.cachedPaymentOrders)
          ..orderBy([
            (tbl) => OrderingTerm.desc(tbl.createdAt),
            (tbl) => OrderingTerm.desc(tbl.cachedAt),
          ]))
        .get();

    if (query == null || query.trim().isEmpty) return rows;

    final q = query.trim().toLowerCase();

    return rows.where((e) {
      return e.customerName.toLowerCase().contains(q) ||
          e.bookingOrderCode.toLowerCase().contains(q) ||
          (e.tableNo ?? '').toLowerCase().contains(q);
    }).toList();
  }

  Future<void> deleteCachedOrderByServerId(int serverId) async {
    await db.transaction(() async {
      await (db.delete(db.cachedPaymentOrderItemOptions)
            ..where((tbl) => tbl.orderDetailServerId.isInQuery(
                  db.selectOnly(db.cachedPaymentOrderItems)
                    ..addColumns([db.cachedPaymentOrderItems.serverDetailId])
                    ..where(db.cachedPaymentOrderItems.orderServerId.equals(serverId)),
                )))
          .go();

      await (db.delete(db.cachedPaymentOrderItems)
            ..where((tbl) => tbl.orderServerId.equals(serverId)))
          .go();

      await (db.delete(db.cachedPaymentOrders)
            ..where((tbl) => tbl.serverId.equals(serverId)))
          .go();
    });
  }

  Future<void> deleteByServerId(int serverId) async {
    await (db.delete(db.cachedPaymentOrders)
          ..where((tbl) => tbl.serverId.equals(serverId)))
        .go();
  }

  Future<void> markPendingDelete(int serverId) async {
    await (db.update(db.cachedPaymentOrders)
          ..where((tbl) => tbl.serverId.equals(serverId)))
        .write(
      const CachedPaymentOrdersCompanion(
        isPendingDelete: Value(true),
      ),
    );
  }

  Future<List<CachedPaymentOrder>> getPendingDeleteOrders() {
    return (db.select(db.cachedPaymentOrders)
          ..where((tbl) => tbl.isPendingDelete.equals(true))
          ..orderBy([
            (tbl) => OrderingTerm.asc(tbl.cachedAt),
          ]))
        .get();
  }

  Future<void> clearAll() async {
    await db.transaction(() async {
      await db.delete(db.cachedPaymentOrderItemOptions).go();
      await db.delete(db.cachedPaymentOrderItems).go();
      await db.delete(db.cachedPaymentOrders).go();
    });
  }

  Future<void> _deleteDetailOnlyByServerId(int serverId) async {
    await db.transaction(() async {
      await (db.delete(db.cachedPaymentOrderItemOptions)
            ..where((tbl) => tbl.orderDetailServerId.isInQuery(
                  db.selectOnly(db.cachedPaymentOrderItems)
                    ..addColumns([db.cachedPaymentOrderItems.serverDetailId])
                    ..where(db.cachedPaymentOrderItems.orderServerId.equals(serverId)),
                )))
          .go();

      await (db.delete(db.cachedPaymentOrderItems)
            ..where((tbl) => tbl.orderServerId.equals(serverId)))
          .go();
    });
  }

  Future<void> upsertDetailFromApi(Map<String, dynamic> detail) async {
    final serverIdRaw = detail['id'];
    final serverId = serverIdRaw is int
        ? serverIdRaw
        : int.tryParse(serverIdRaw.toString());

    if (serverId == null || serverId <= 0) {
      throw Exception('serverId detail tidak valid');
    }

    final bookingOrderCode = (detail['booking_order_code'] ?? '-').toString();
    final customerName = (detail['customer_name'] ?? '-').toString();

    final tableNo = (detail['table'] is Map)
        ? ((detail['table']['table_no'] ?? '-').toString())
        : ((detail['table_no'] ?? '-').toString());

    final paymentMethod = detail['payment_method']?.toString();
    final orderStatus = (detail['order_status'] ?? 'UNPAID').toString();

    final subtotal = _toNum(detail['total_order_value']).toDouble();
    final ppnPercent = _toNum(detail['ppn']).toDouble();
    final isPpnActive = _toBool(detail['is_ppn_active']);
    final grandTotal = isPpnActive
        ? (subtotal + (subtotal * ppnPercent / 100))
        : subtotal;

    final createdAt = DateTime.tryParse((detail['created_at'] ?? '').toString());
    final updatedAt = DateTime.tryParse((detail['updated_at'] ?? '').toString());

    final rawPaymentRequest = detail['payment_request'];
    final rawLatestPayment = detail['latest_payment'];

    final rawDetails = (detail['order_details'] as List?) ?? [];

    Map<String, dynamic>? paymentRequestForCache;
    if (rawPaymentRequest is Map) {
      paymentRequestForCache = Map<String, dynamic>.from(rawPaymentRequest);

      final proofRaw =
          (paymentRequestForCache['manual_payment_image'] ?? '').toString().trim();

      if (proofRaw.isNotEmpty) {
        final localPath = await _downloadProofImageToLocal(proofRaw);
        if (localPath != null && localPath.isNotEmpty) {
          paymentRequestForCache['manual_payment_image_local_path'] = localPath;
        }
      }
    }

    Map<String, dynamic>? latestPaymentForCache;
    if (rawLatestPayment is Map) {
      latestPaymentForCache = Map<String, dynamic>.from(rawLatestPayment);
    }

    await db.transaction(() async {
      await db.into(db.cachedPaymentOrders).insertOnConflictUpdate(
        CachedPaymentOrdersCompanion(
          serverId: Value(serverId),
          bookingOrderCode: Value(bookingOrderCode),
          customerName: Value(customerName),
          tableNo: Value(tableNo),
          paymentMethod: Value(paymentMethod),
          orderStatus: Value(orderStatus),
          subtotal: Value(subtotal),
          ppnPercent: Value(ppnPercent),
          isPpnActive: Value(isPpnActive),
          grandTotal: Value(grandTotal),
          paymentRequestJson: Value(
            paymentRequestForCache == null ? null : jsonEncode(paymentRequestForCache),
          ),
          latestPaymentJson: Value(
            latestPaymentForCache == null ? null : jsonEncode(latestPaymentForCache),
          ),
          detailJson: Value(jsonEncode(detail)),
          createdAt: Value(createdAt),
          updatedAt: Value(updatedAt),
          cachedAt: Value(DateTime.now()),
          isPendingDelete: const Value(false),
        ),
      );

      await _deleteDetailOnlyByServerId(serverId);

      for (final row in rawDetails) {
        final m = Map<String, dynamic>.from(row as Map);

        final detailIdRaw = m['id'];
        final detailId = detailIdRaw is int
            ? detailIdRaw
            : int.tryParse(detailIdRaw.toString());

        if (detailId == null || detailId <= 0) continue;

        final productIdRaw = m['product_id'];
        final productId = productIdRaw is int
            ? productIdRaw
            : int.tryParse(productIdRaw.toString());

        final productName = (m['product_name'] ??
                (m['partner_product'] is Map
                    ? (m['partner_product']['name'] ?? 'Produk')
                    : 'Produk'))
            .toString();

        final basePrice = _toNum(m['base_price']).toDouble();
        final promoAmount = _toNum(m['promo_amount']).toDouble();
        final qty = _toInt(m['quantity']) ?? 1;
        final customerNote = m['customer_note']?.toString();

        await db.into(db.cachedPaymentOrderItems).insertOnConflictUpdate(
              CachedPaymentOrderItemsCompanion(
                serverDetailId: Value(detailId),
                orderServerId: Value(serverId),
                productServerId: Value(productId),
                productName: Value(productName),
                basePrice: Value(basePrice),
                promoAmount: Value(promoAmount),
                qty: Value(qty),
                customerNote: Value(customerNote),
              ),
            );

        final opts = (m['order_detail_options'] as List?) ?? [];
        for (final optRow in opts) {
          final om = Map<String, dynamic>.from(optRow as Map);

          final optIdRaw = om['id'];
          final optId = optIdRaw is int
              ? optIdRaw
              : int.tryParse(optIdRaw.toString());

          if (optId == null || optId <= 0) continue;

          final optionMap = (om['option'] is Map)
              ? Map<String, dynamic>.from(om['option'] as Map)
              : <String, dynamic>{};

          final parentMap = (optionMap['parent'] is Map)
              ? Map<String, dynamic>.from(optionMap['parent'] as Map)
              : <String, dynamic>{};

          await db.into(db.cachedPaymentOrderItemOptions).insertOnConflictUpdate(
                CachedPaymentOrderItemOptionsCompanion(
                  serverDetailOptionId: Value(optId),
                  orderDetailServerId: Value(detailId),
                  parentName: Value(parentMap['name']?.toString()),
                  optionName: Value((optionMap['name'] ?? '-').toString()),
                  price: Value(_toNum(om['price']).toDouble()),
                ),
              );
        }
      }
    });
  }

  Future<Map<String, dynamic>?> getCachedOrderDetailMap(int serverId) async {
    final order = await (db.select(db.cachedPaymentOrders)
          ..where((tbl) => tbl.serverId.equals(serverId)))
        .getSingleOrNull();

    if (order == null) return null;

    Map<String, dynamic>? paymentRequest;
    if (order.paymentRequestJson != null &&
        order.paymentRequestJson!.trim().isNotEmpty) {
      final decoded = jsonDecode(order.paymentRequestJson!);
      if (decoded is Map) {
        paymentRequest = Map<String, dynamic>.from(decoded);
      }
    }

    Map<String, dynamic>? latestPayment;
    if (order.latestPaymentJson != null &&
        order.latestPaymentJson!.trim().isNotEmpty) {
      final decoded = jsonDecode(order.latestPaymentJson!);
      if (decoded is Map) {
        latestPayment = Map<String, dynamic>.from(decoded);
      }
    }

    // =========================================================
    // PRIORITAS 1: pakai detailJson utuh supaya category tetap ada
    // =========================================================
    if (order.detailJson != null && order.detailJson!.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(order.detailJson!);
        if (decoded is Map) {
          final detail = Map<String, dynamic>.from(decoded);

          detail['id'] = order.serverId;
          detail['server_id'] = order.serverId;
          detail['booking_order_code'] = order.bookingOrderCode;
          detail['customer_name'] = order.customerName;
          detail['order_status'] = order.orderStatus;
          detail['payment_method'] = order.paymentMethod;
          detail['total_order_value'] = order.subtotal;
          detail['ppn'] = order.ppnPercent;
          detail['is_ppn_active'] = order.isPpnActive;
          detail['grand_total'] = order.grandTotal;

          if (paymentRequest != null) {
            final current = detail['payment_request'] is Map
                ? Map<String, dynamic>.from(detail['payment_request'])
                : <String, dynamic>{};

            detail['payment_request'] = {
              ...current,
              ...paymentRequest,
            };
          }

          if (latestPayment != null) {
            final current = detail['latest_payment'] is Map
                ? Map<String, dynamic>.from(detail['latest_payment'])
                : <String, dynamic>{};

            // merge owner_manual_payment juga kalau ada
            final currentOwner = current['owner_manual_payment'] is Map
                ? Map<String, dynamic>.from(current['owner_manual_payment'])
                : <String, dynamic>{};

            final cachedOwner = latestPayment['owner_manual_payment'] is Map
                ? Map<String, dynamic>.from(latestPayment['owner_manual_payment'])
                : <String, dynamic>{};

            detail['latest_payment'] = {
              ...current,
              ...latestPayment,
              'owner_manual_payment': {
                ...currentOwner,
                ...cachedOwner,
              },
            };
          }

          detail['table'] ??= {
            'table_no': order.tableNo ?? '-',
          };

          detail['payment'] ??= {
            'note': '',
          };

          detail['order_details'] ??= <dynamic>[];

          return detail;
        }
      } catch (e) {
        debugPrint('⚠️ decode payment detailJson failed: $e');
      }
    }

    // =========================================================
    // PRIORITAS 2: fallback lama kalau detailJson belum ada
    // =========================================================
    final itemRows = await (db.select(db.cachedPaymentOrderItems)
          ..where((tbl) => tbl.orderServerId.equals(serverId)))
        .get();

    final detailIds = itemRows.map((e) => e.serverDetailId).toList();

    final optionRows = detailIds.isEmpty
        ? <CachedPaymentOrderItemOption>[]
        : await (db.select(db.cachedPaymentOrderItemOptions)
              ..where((tbl) => tbl.orderDetailServerId.isIn(detailIds)))
            .get();

    final optionsByDetailId = <int, List<CachedPaymentOrderItemOption>>{};
    for (final opt in optionRows) {
      optionsByDetailId.putIfAbsent(opt.orderDetailServerId, () => []).add(opt);
    }

    return <String, dynamic>{
      'id': order.serverId,
      'server_id': order.serverId,
      'booking_order_code': order.bookingOrderCode,
      'customer_name': order.customerName,
      'order_status': order.orderStatus,
      'payment_method': order.paymentMethod,
      'total_order_value': order.subtotal,
      'ppn': order.ppnPercent,
      'is_ppn_active': order.isPpnActive,
      'grand_total': order.grandTotal,
      'is_local_only': false,
      'is_cached_server': true,
      'payment_request': paymentRequest,
      'latest_payment': latestPayment,
      'table': {
        'table_no': order.tableNo ?? '-',
      },
      'payment': {
        'note': '',
      },
      'order_details': itemRows.map((item) {
        final opts =
            optionsByDetailId[item.serverDetailId] ?? const <CachedPaymentOrderItemOption>[];

        return <String, dynamic>{
          'id': item.serverDetailId,
          'product_id': item.productServerId,
          'product_name': item.productName,
          'quantity': item.qty,
          'base_price': item.basePrice,
          'promo_amount': item.promoAmount,
          'customer_note': item.customerNote,
          'order_detail_options': opts.map((o) {
            return <String, dynamic>{
              'id': o.serverDetailOptionId,
              'price': o.price,
              'option': {
                'name': o.optionName,
                'parent': {
                  'name': o.parentName ?? 'Opsi',
                },
              },
            };
          }).toList(),
        };
      }).toList(),
    };
  }

  Future<String?> _downloadProofImageToLocal(String rawPath) async {
    try {
      if (rawPath.trim().isEmpty) return null;

      final imageUrl = rawPath.startsWith('http')
          ? rawPath
          : '${Env.baseUrl}/storage/${rawPath.replaceFirst(RegExp(r'^\/?storage\/?'), '')}';

      final dir = await getApplicationDocumentsDirectory();
      final folder = Directory(p.join(dir.path, 'payment_request_proofs'));
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
      debugPrint('❌ download payment proof failed: $e');
      return null;
    }
  }

  Future<List<CachedPaymentOrder>> getAllActiveOrders() {
    return (db.select(db.cachedPaymentOrders)
          ..where((t) => t.isPendingDelete.equals(false))
          ..orderBy([
            (t) => OrderingTerm.desc(t.createdAt),
            (t) => OrderingTerm.desc(t.cachedAt),
          ]))
        .get();
  }

  Future<CachedPaymentOrder?> findByServerId(int serverId) {
    return (db.select(db.cachedPaymentOrders)
          ..where((t) => t.serverId.equals(serverId)))
        .getSingleOrNull();
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

