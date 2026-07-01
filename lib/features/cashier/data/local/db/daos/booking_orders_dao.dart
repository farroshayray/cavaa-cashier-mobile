import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '/features/cashier/data/local/db/cashier_db.dart';
import '/features/cashier/data/local/db/mappers/order_mirror_mapper.dart';
import '/features/cashier/data/local/db/daos/cache_dao.dart';
import '/features/cashier/data/local/db/local_date_utils.dart';
import '/features/cashier/data/sync/order_catch_up_sync_policy.dart';
import '/features/cashier/data/sync/order_edit_conflict_detector.dart';
import '/features/cashier/data/sync/order_stage_rank.dart';
import '/features/cashier/data/sync/order_sync_intent_chain.dart';
import '/features/cashier/presentation/utils/order_edit_utils.dart';

const _uuid = Uuid();

class MirrorPendingStockLine {
  const MirrorPendingStockLine({
    required this.productId,
    required this.qty,
    required this.optionIds,
  });

  final int productId;
  final int qty;
  final List<int> optionIds;
}

class BookingOrderBundle {
  final BookingOrder order;
  final List<OrderDetail> details;
  final Map<String, List<OrderDetailOption>> optionsByDetailUuid;

  BookingOrderBundle({
    required this.order,
    required this.details,
    required this.optionsByDetailUuid,
  });
}

class BookingOrdersDao {
  BookingOrdersDao(this.db);

  final CashierDb db;

  Future<String> createDraftOrder({
    required String customerName,
    required int tableId,
    String? tableNo,
    required String paymentMethod,
    required bool openbillFlag,
    required double totalOrderValue,
    double? ppn,
    bool isPpnActive = false,
    int? partnerId,
    String? partnerName,
  }) async {
    final clientUuid = _uuid.v4();
    final now = DateTime.now();
    final status = openbillFlag ? 'OPENBILL_CONFIRMATION' : 'DRAFT';

    await db.into(db.bookingOrders).insert(
          BookingOrdersCompanion.insert(
            clientUuid: clientUuid,
            customerName: customerName,
            tableId: Value(tableId),
            tableNo: Value(tableNo),
            paymentMethod: Value(openbillFlag ? null : paymentMethod),
            openbillFlag: Value(openbillFlag),
            orderStatus: Value(status),
            totalOrderValue: Value(totalOrderValue),
            ppn: Value(ppn),
            isPpnActive: Value(isPpnActive),
            partnerId: Value(partnerId),
            partnerName: Value(partnerName),
            syncDirty: const Value(true),
            syncIntent: Value(openbillFlag ? 'CREATE' : 'CREATE'),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    return clientUuid;
  }

  Future<void> addDetail({
    required String bookingOrderClientUuid,
    required int partnerProductId,
    required String productName,
    required double basePrice,
    required int quantity,
    double optionsPrice = 0,
    String? customerNote,
    int? promoId,
    String? promoType,
    double? promoAmount,
    List<Map<String, dynamic>> options = const [],
  }) async {
    final detailUuid = _uuid.v4();
    final now = DateTime.now();

    await db.into(db.orderDetails).insert(
          OrderDetailsCompanion.insert(
            clientDetailUuid: detailUuid,
            bookingOrderClientUuid: bookingOrderClientUuid,
            partnerProductId: partnerProductId,
            productName: Value(productName),
            basePrice: Value(basePrice),
            quantity: Value(quantity),
            optionsPrice: Value(optionsPrice),
            customerNote: Value(customerNote),
            promoId: Value(promoId),
            promoType: Value(promoType),
            promoAmount: Value(promoAmount),
            syncDirty: const Value(true),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    for (final opt in options) {
      await db.into(db.orderDetailOptions).insert(
            OrderDetailOptionsCompanion.insert(
              clientOptionUuid: _uuid.v4(),
              orderDetailClientUuid: detailUuid,
              optionId: opt['option_id'] as int,
              parentName: Value(opt['parent_name']?.toString()),
              partnerProductOptionName:
                  Value(opt['name']?.toString() ?? opt['partner_product_option_name']?.toString()),
              price: Value((opt['price'] as num?)?.toDouble() ?? 0),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
    }

    await _markOrderDirty(bookingOrderClientUuid, 'CREATE');
  }

  Future<void> markIntent(String clientUuid, String syncIntent, {Map<String, dynamic>? extras}) async {
    Value<String?> localFilePaths = const Value.absent();
    if (extras?['local_file_paths'] is Map) {
      final existing = await getByClientUuid(clientUuid);
      final merged = <String, dynamic>{};
      if (existing?.localFilePathsJson != null &&
          existing!.localFilePathsJson!.trim().isNotEmpty) {
        final decoded = jsonDecode(existing.localFilePathsJson!);
        if (decoded is Map) {
          merged.addAll(Map<String, dynamic>.from(decoded));
        }
      }
      merged.addAll(Map<String, dynamic>.from(extras!['local_file_paths'] as Map));
      localFilePaths = Value(jsonEncode(merged));
    }

    final companion = BookingOrdersCompanion(
      syncDirty: const Value(true),
      syncIntent: Value(syncIntent),
      updatedAt: Value(DateTime.now()),
      paidAmountLocal: extras?['paid_amount'] != null
          ? Value((extras!['paid_amount'] as num).toDouble())
          : const Value.absent(),
      changeAmountLocal: extras?['change_amount'] != null
          ? Value((extras!['change_amount'] as num).toDouble())
          : const Value.absent(),
      paymentMethod: extras?['payment_method'] != null
          ? Value(extras!['payment_method'].toString())
          : const Value.absent(),
      orderStatus: extras?['order_status'] != null
          ? Value(extras!['order_status'].toString())
          : const Value.absent(),
      localFilePathsJson: localFilePaths,
    );

    await (db.update(db.bookingOrders)..where((t) => t.clientUuid.equals(clientUuid)))
        .write(companion);
  }

  Future<String?> persistCashierProofImage({
    required String clientUuid,
    required String sourcePath,
  }) async {
    final source = File(sourcePath);
    if (!await source.exists()) return null;

    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(dir.path, 'payment_proofs'));
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    final destPath = p.join(folder.path, '$clientUuid.jpg');
    await source.copy(destPath);
    return destPath;
  }

  String? readCashierProofPath(BookingOrder order) {
    final raw = order.localFilePathsJson;
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final path = decoded['cashier_proof']?.toString().trim();
      if (path == null || path.isEmpty) return null;
      return path;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearCashierProofPath(String clientUuid) async {
    final existing = await getByClientUuid(clientUuid);
    if (existing == null) return;

    Map<String, dynamic> merged = {};
    if (existing.localFilePathsJson != null &&
        existing.localFilePathsJson!.trim().isNotEmpty) {
      final decoded = jsonDecode(existing.localFilePathsJson!);
      if (decoded is Map) {
        merged = Map<String, dynamic>.from(decoded);
      }
    }
    merged.remove('cashier_proof');

    await (db.update(db.bookingOrders)..where((t) => t.clientUuid.equals(clientUuid)))
        .write(
      BookingOrdersCompanion(
        localFilePathsJson: Value(merged.isEmpty ? null : jsonEncode(merged)),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<List<BookingOrder>> getOrdersWithPendingCashierProof() async {
    final rows = await (db.select(db.bookingOrders)
          ..where((t) => t.deletedAt.isNull())
          ..where((t) => t.localFilePathsJson.isNotNull()))
        .get();

    return rows.where((row) {
      final path = readCashierProofPath(row);
      if (path == null || path.isEmpty) return false;
      return File(path).existsSync();
    }).toList();
  }

  int? _resolveLatestPaymentServerId(
    Map<String, dynamic> row,
    BookingOrder? existing,
  ) {
    final paymentId = _toIntOrNull(row['payment_id']);
    if (paymentId != null && paymentId > 0) {
      return paymentId;
    }
    return existing?.latestPaymentServerId ?? existing?.paymentId;
  }

  /// Ensures a mirror row exists for a server order shown in tab UI.
  Future<void> ensureFromUiMap(
    Map<String, dynamic> order, {
    required int serverId,
  }) async {
    if (serverId <= 0) {
      final localUuid = order['local_client_uuid']?.toString().trim();
      if (localUuid != null && localUuid.isNotEmpty) {
        final existing = await getByClientUuid(localUuid);
        if (existing != null) return;
      }
      return;
    }

    var existing = await getByServerId(serverId);
    if (existing != null) return;

    final localUuid = order['local_client_uuid']?.toString().trim();
    if (localUuid != null && localUuid.isNotEmpty) {
      existing = await getByClientUuid(localUuid);
      if (existing != null) {
        if (existing.serverId == null) {
          await (db.update(db.bookingOrders)
                ..where((t) => t.clientUuid.equals(localUuid)))
              .write(
            BookingOrdersCompanion(
              serverId: Value(serverId),
              updatedAt: Value(DateTime.now()),
            ),
          );
        }
        return;
      }
    }

    final code = order['booking_order_code']?.toString().trim();
    if (code != null && code.isNotEmpty) {
      final byCode = await (db.select(db.bookingOrders)
            ..where((t) => t.bookingOrderCode.equals(code))
            ..where((t) => t.deletedAt.isNull()))
          .get();
      if (byCode.isNotEmpty) {
        final keeper = byCode.firstWhere(
          (row) => row.clientUuid == localUuid,
          orElse: () => byCode.first,
        );
        if (keeper.serverId == null) {
          await (db.update(db.bookingOrders)
                ..where((t) => t.clientUuid.equals(keeper.clientUuid)))
              .write(
            BookingOrdersCompanion(
              serverId: Value(serverId),
              updatedAt: Value(DateTime.now()),
            ),
          );
        }
        return;
      }
    }

    final offlineMatch = await _findOfflineMirrorForServerRow({
      'customer_name': order['customer_name'],
      'order_name': order['order_name'],
      'table_id': order['table_id'],
      'openbill_flag': order['openbill_flag'],
      'created_at': order['created_at'],
    });
    if (offlineMatch != null) {
      await (db.update(db.bookingOrders)
            ..where((t) => t.clientUuid.equals(offlineMatch.clientUuid)))
          .write(
        BookingOrdersCompanion(
          serverId: Value(serverId),
          bookingOrderCode: order['booking_order_code'] != null
              ? Value(order['booking_order_code'].toString())
              : const Value.absent(),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return;
    }

    final clientUuid = _uuid.v4();
    final now = DateTime.now();
    final tableNo = order['table'] is Map
        ? order['table']['table_no']?.toString()
        : order['table_no']?.toString();

    await db.into(db.bookingOrders).insert(
          BookingOrdersCompanion.insert(
            clientUuid: clientUuid,
            customerName: order['customer_name']?.toString() ?? 'guest',
            serverId: Value(serverId),
            bookingOrderCode: Value(order['booking_order_code']?.toString()),
            tableId: Value(_toIntOrNull(order['table_id'])),
            tableNo: Value(tableNo),
            orderStatus: Value(order['order_status']?.toString() ?? 'UNPAID'),
            paymentMethod: Value(order['payment_method']?.toString()),
            openbillFlag: Value(_toBool(order['openbill_flag'])),
            totalOrderValue: Value(_toDouble(order['total_order_value'])),
            ppn: Value(_toDouble(order['ppn'])),
            isPpnActive: Value(_toBool(order['is_ppn_active'])),
            paidAmountLocal: Value(_toDouble(order['paid_amount_local'] ?? order['paid_amount'])),
            changeAmountLocal: Value(_toDouble(order['change_amount_local'] ?? order['change_amount'])),
            syncDirty: const Value(false),
            createdAt: Value(_parseDate(order['created_at']) ?? now),
            updatedAt: Value(now),
          ),
        );
  }

  /// Updates mirror status after a tab action so all tabs stay consistent.
  Future<bool> applyLocalStageByServerId({
    required int serverId,
    required String orderStatus,
    String? syncIntent,
    bool syncDirty = false,
    Map<String, dynamic>? extras,
  }) async {
    final existing = await getByServerId(serverId);
    if (existing == null) return false;

    final now = DateTime.now();
    await (db.update(db.bookingOrders)..where((t) => t.serverId.equals(serverId))).write(
          BookingOrdersCompanion(
            orderStatus: Value(orderStatus),
            updatedAt: Value(now),
            syncDirty: Value(syncDirty),
            syncIntent: Value(syncIntent),
            syncError: syncDirty ? const Value.absent() : const Value(null),
            paidAmountLocal: extras?['paid_amount'] != null
                ? Value(_toDouble(extras!['paid_amount']))
                : const Value.absent(),
            changeAmountLocal: extras?['change_amount'] != null
                ? Value(_toDouble(extras!['change_amount']))
                : const Value.absent(),
            paymentMethod: extras?['payment_method'] != null
                ? Value(extras!['payment_method'].toString())
                : const Value.absent(),
          ),
        );
    return true;
  }

  Future<List<Map<String, dynamic>>> getPaymentTabOrders({String? query}) {
    return _queryTabOrders(
      statuses: const ['UNPAID', 'EXPIRED', 'PAYMENT REQUEST'],
      query: query,
    );
  }

  Future<List<Map<String, dynamic>>> getProcessTabOrders({String? query, int? employeeId}) {
    return _queryTabOrders(
      statuses: const [
        'PROCESSED',
        'PAID',
        'OPENBILL_WAITING_ORDER',
        'OPENBILL_CONFIRMATION',
      ],
      query: query,
      employeeId: employeeId,
    );
  }

  Future<List<Map<String, dynamic>>> getDoneTabOrders({String? query}) async {
    final now = DateTime.now();

    final rows = await (db.select(db.bookingOrders)
          ..where((t) => t.orderStatus.equals('SERVED'))
          ..where((t) => t.deletedAt.isNull()))
        .get();

    final todayRows = rows.where((row) {
      final updated = row.updatedAt;
      if (updated == null) return false;
      return isSameLocalDay(updated, now);
    }).toList();

    return _mapRowsWithDetails(todayRows, query: query);
  }

  Future<List<Map<String, dynamic>>> getDirtyOrders() async {
    final rows = await (db.select(db.bookingOrders)..where((t) => t.syncDirty.equals(true)))
        .get();
    return rows.map(OrderMirrorMapper.orderToUiMap).toList();
  }

  Future<List<BookingOrder>> getAllDirtyBookingOrders() {
    return (db.select(db.bookingOrders)..where((t) => t.syncDirty.equals(true))).get();
  }

  Future<List<OrderDetail>> getDirtyDetailsForOrder(String clientUuid) {
    return (db.select(db.orderDetails)
          ..where((t) => t.bookingOrderClientUuid.equals(clientUuid))
          ..where((t) => t.syncDirty.equals(true)))
        .get();
  }

  Future<BookingOrder?> getByClientUuid(String clientUuid) {
    return (db.select(db.bookingOrders)..where((t) => t.clientUuid.equals(clientUuid)))
        .getSingleOrNull();
  }

  Future<BookingOrder?> getByServerId(int serverId) {
    return (db.select(db.bookingOrders)..where((t) => t.serverId.equals(serverId)))
        .getSingleOrNull();
  }

  Future<BookingOrderBundle?> getBundleByClientUuid(String clientUuid) async {
    final order = await getByClientUuid(clientUuid);
    if (order == null) return null;

    final details = await (db.select(db.orderDetails)
          ..where((t) => t.bookingOrderClientUuid.equals(clientUuid)))
        .get();

    final dedupedDetails = _dedupeDetailRows(details);

    final optionsByDetailUuid = <String, List<OrderDetailOption>>{};
    for (final detail in dedupedDetails) {
      final opts = await (db.select(db.orderDetailOptions)
            ..where((t) => t.orderDetailClientUuid.equals(detail.clientDetailUuid)))
          .get();
      optionsByDetailUuid[detail.clientDetailUuid] = opts;
    }

    return BookingOrderBundle(
      order: order,
      details: dedupedDetails,
      optionsByDetailUuid: optionsByDetailUuid,
    );
  }

  Future<void> upsertFromServer(Map<String, dynamic> row) async {
    final serverId = _toIntOrNull(row['id']);
    if (serverId == null) return;

    var existing = await getByServerId(serverId);
    existing ??= await _findOfflineMirrorForServerRow(row);
    final clientUuid = existing?.clientUuid ?? _uuid.v4();
    final now = DateTime.now();
    final serverStatus = row['order_status']?.toString() ?? 'UNPAID';

    final localAhead = existing != null &&
        OrderStageRank.isLocalAheadOfServer(
          localStatus: existing.orderStatus,
          serverStatus: serverStatus,
          openbillFlag: existing.openbillFlag,
          syncIntent: existing.syncIntent,
          paidAmountLocal: existing.paidAmountLocal,
        );
    final terminalMatch = existing != null &&
        existing.orderStatus.toUpperCase() == serverStatus.toUpperCase() &&
        OrderStageRank.isTerminalStatus(serverStatus);
    final preserveLocalLifecycle = existing != null &&
        (existing.syncDirty || localAhead);
    final clearSyncFlags = existing != null &&
        await shouldClearSyncDirtyFlag(
          local: existing,
          serverStatus: serverStatus,
        );

    final companion = BookingOrdersCompanion(
      clientUuid: Value(clientUuid),
      serverId: Value(serverId),
      bookingOrderCode: Value(row['booking_order_code']?.toString()),
      partnerId: Value(_toIntOrNull(row['partner_id'])),
      partnerName: Value(row['partner_name']?.toString()),
      tableId: Value(_toIntOrNull(row['table_id'])),
      tableNo: Value(row['table_no']?.toString() ?? row['table']?['table_no']?.toString()),
      customerId: Value(_toIntOrNull(row['customer_id'])),
      employeeOrderId: Value(_toIntOrNull(row['employee_order_id'])),
      orderBy: Value(row['order_by']?.toString()),
      customerName: Value(row['customer_name']?.toString() ?? 'guest'),
      orderStatus: preserveLocalLifecycle
          ? Value(existing!.orderStatus)
          : Value(serverStatus),
      paymentMethod: preserveLocalLifecycle && existing!.paymentMethod != null
          ? Value(existing.paymentMethod)
          : Value(row['payment_method']?.toString()),
      openbillFlag: Value(_toBool(row['openbill_flag']) || (existing?.openbillFlag ?? false)),
      discountId: Value(_toIntOrNull(row['discount_id'])),
      discountValue: Value(_toDouble(row['discount_value'])),
      totalOrderValue: Value(_toDouble(row['total_order_value'])),
      ppn: Value(_toDouble(row['ppn'])),
      isPpnActive: Value(_toBool(row['is_ppn_active'])),
      customerOrderNote: Value(row['customer_order_note']?.toString()),
      employeeOrderNote: Value(row['employee_order_note']?.toString()),
      cashierProcessId: Value(_toIntOrNull(row['cashier_process_id'])),
      kitchenProcessId: Value(_toIntOrNull(row['kitchen_process_id'])),
      paymentId: Value(_toIntOrNull(row['payment_id'])),
      latestPaymentServerId: Value(_resolveLatestPaymentServerId(row, existing)),
      paymentFlag: Value(_toBool(row['payment_flag'])),
      cashRoundingAmount: Value(_toDouble(row['cash_rounding_amount'])),
      cashRoundingUnit: Value(
        await _resolveCashRoundingUnitForRow(row),
      ),
      wifiSnapshotJson: Value(row['wifi_snapshot'] != null ? jsonEncode(row['wifi_snapshot']) : null),
      paymentRequestJson:
          Value(row['payment_request'] != null ? jsonEncode(row['payment_request']) : null),
      latestPaymentJson:
          Value(row['latest_payment'] != null ? jsonEncode(row['latest_payment']) : null),
      syncVersion: Value(_toInt(row['sync_version'])),
      syncDirty: clearSyncFlags
          ? const Value(false)
          : preserveLocalLifecycle
              ? Value(existing!.syncDirty)
              : const Value(false),
      syncIntent: clearSyncFlags
          ? const Value(null)
          : preserveLocalLifecycle
              ? Value(existing!.syncIntent)
              : const Value(null),
      syncError: clearSyncFlags
          ? const Value(null)
          : preserveLocalLifecycle && existing!.syncError != null
              ? Value(existing.syncError)
              : const Value(null),
      paidAmountLocal: preserveLocalLifecycle
          ? Value(existing!.paidAmountLocal)
          : const Value.absent(),
      changeAmountLocal: preserveLocalLifecycle
          ? Value(existing!.changeAmountLocal)
          : const Value.absent(),
      createdAt: Value(_parseDate(row['created_at']) ?? now),
      updatedAt: preserveLocalLifecycle
          ? Value(existing!.updatedAt)
          : Value(_parseDate(row['updated_at']) ?? now),
      deletedAt: Value(_parseDate(row['deleted_at'])),
      syncedAt: Value(now),
    );

    await db.into(db.bookingOrders).insertOnConflictUpdate(companion);

    final details = (row['order_details'] as List?) ?? [];
    final incomingServerIds = <int>{};
    for (final raw in details) {
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);
      final detailServerId = _detailServerIdFromRow(map);
      if (detailServerId != null) incomingServerIds.add(detailServerId);
      await _upsertDetailFromServer(map, clientUuid, serverId);
    }

    if (incomingServerIds.isNotEmpty) {
      await _pruneOrderDetailsAfterServerUpsert(
        bookingClientUuid: clientUuid,
        keepServerIds: incomingServerIds,
      );
    }
    await _deduplicateOrderDetailsByServerId(clientUuid);

    if (clearSyncFlags && terminalMatch && existing?.openbillFlag != true) {
      await _clearDetailSyncDirty(clientUuid);
    }

    if (preserveLocalLifecycle && !clearSyncFlags) {
      await detectEditDivergenceAfterPull(
        clientUuid: clientUuid,
        serverRow: row,
      );
    }
  }

  /// Upsert satu baris order_details dari pull (tanpa parent row di batch yang sama).
  Future<void> upsertDetailFromServerRow(Map<String, dynamic> row) async {
    final bookingOrderServerId = _toIntOrNull(row['booking_order_id']);
    if (bookingOrderServerId == null) return;

    final parent = await getByServerId(bookingOrderServerId);
    if (parent == null) return;

    await _upsertDetailFromServer(row, parent.clientUuid, bookingOrderServerId);
    await _deduplicateOrderDetailsByServerId(parent.clientUuid);
  }

  Future<void> markSyncErrorByClientUuid(String clientUuid, String message) async {
    if (clientUuid.isEmpty) return;

    await (db.update(db.bookingOrders)..where((t) => t.clientUuid.equals(clientUuid))).write(
          BookingOrdersCompanion(
            syncError: Value(message),
          ),
        );
  }

  /// Sets header dirty + SERVE_ITEMS when served details are still pending sync.
  Future<int> ensureHeaderDirtyForPendingDetails() async {
    final rows = await (db.select(db.bookingOrders)
          ..where((t) => t.deletedAt.isNull())
          ..where((t) => t.syncDirty.equals(false)))
        .get();

    var fixed = 0;
    for (final order in rows) {
      if (!await hasDirtyServedDetails(order.clientUuid)) continue;

      await markIntent(
        order.clientUuid,
        'SERVE_ITEMS',
        extras: {
          'order_status': order.orderStatus,
          if (order.paidAmountLocal != null) 'paid_amount': order.paidAmountLocal,
          if (order.changeAmountLocal != null) 'change_amount': order.changeAmountLocal,
          if (order.paymentMethod != null) 'payment_method': order.paymentMethod,
        },
      );
      fixed++;
    }

    return fixed;
  }

  Future<bool> hasDirtyServedDetails(String clientUuid) async {
    final dirty = await getDirtyDetailsForOrder(clientUuid);
    return dirty.any((detail) {
      final status = (detail.status ?? '').trim().toUpperCase();
      return status.contains('SERVED');
    });
  }

  Future<bool> orderNeedsCatchUpSync({
    required BookingOrder local,
    String? serverStatus,
  }) async {
    return OrderCatchUpSyncPolicy.needsCatchUp(
      localStatus: local.orderStatus,
      serverStatus: serverStatus ?? '',
      openbillFlag: local.openbillFlag,
      hasDirtyServedDetails: await hasDirtyServedDetails(local.clientUuid),
      paidAmountLocal: local.paidAmountLocal,
      syncIntent: local.syncIntent,
    );
  }

  Future<bool> shouldClearSyncDirtyFlag({
    required BookingOrder local,
    required String serverStatus,
  }) async {
    return OrderCatchUpSyncPolicy.shouldClearSyncDirty(
      syncDirty: local.syncDirty,
      localStatus: local.orderStatus,
      serverStatus: serverStatus,
      openbillFlag: local.openbillFlag,
      hasDirtyServedDetails: await hasDirtyServedDetails(local.clientUuid),
      paidAmountLocal: local.paidAmountLocal,
      syncIntent: local.syncIntent,
    );
  }

  /// Clears header sync flags when mirror already matches server lifecycle.
  Future<int> healMirrorsSyncedWithServer({
    Map<int, String> serverStatusById = const {},
  }) async {
    var healed = 0;
    final dirty = await getAllDirtyBookingOrders();

    for (final order in dirty) {
      final serverId = order.serverId;
      if (serverId == null || serverId <= 0) continue;

      final serverStatus = serverStatusById[serverId] ?? order.orderStatus;
      if (!await shouldClearSyncDirtyFlag(
        local: order,
        serverStatus: serverStatus,
      )) {
        continue;
      }

      await _clearMirrorSyncState(
        order.clientUuid,
        clearDetails: !order.openbillFlag &&
            OrderStageRank.isTerminalStatus(order.orderStatus),
      );
      healed++;
    }

    return healed;
  }

  /// Links offline dirty mirrors to an existing server row for the same checkout.
  Future<int> linkDirtyMirrorsToKnownServerRows() async {
    final dirty = await getAllDirtyBookingOrders();
    var fixed = 0;

    for (final order in dirty) {
      if (order.serverId != null && order.serverId! > 0) continue;

      final siblings = await (db.select(db.bookingOrders)
            ..where((t) => t.deletedAt.isNull())
            ..where((t) => t.serverId.isNotNull())
            ..where((t) => t.customerName.equals(order.customerName))
            ..where((t) => t.openbillFlag.equals(order.openbillFlag)))
          .get();

      BookingOrder? keeper;
      for (final sibling in siblings) {
        if (order.tableId != null &&
            sibling.tableId != null &&
            order.tableId != sibling.tableId) {
          continue;
        }
        keeper = sibling;
        break;
      }
      if (keeper == null) continue;

      await (db.update(db.bookingOrders)
            ..where((t) => t.clientUuid.equals(order.clientUuid)))
          .write(
        BookingOrdersCompanion(
          serverId: Value(keeper.serverId),
          bookingOrderCode: keeper.bookingOrderCode != null
              ? Value(keeper.bookingOrderCode!)
              : const Value.absent(),
          syncError: const Value(null),
        ),
      );
      fixed++;
    }

    return fixed;
  }

  /// Rewrites or clears redundant cashier openbill PROCESS intents before push.
  Future<int> healStuckCashierOpenbillSyncIntents() async {
    var healed = 0;

    final dirty = await getAllDirtyBookingOrders();

    for (final order in dirty) {
      if (_isStuckCashierOpenbillProcessError(order)) {
        await (db.update(db.bookingOrders)
              ..where((t) => t.clientUuid.equals(order.clientUuid)))
            .write(
          const BookingOrdersCompanion(
            syncIntent: Value('CONFIRM_OPENBILL'),
            syncError: Value(null),
            syncDirty: Value(true),
          ),
        );
        healed++;
        continue;
      }

      if (await _shouldDowngradePayToServeItems(order)) {
        await markIntent(
          order.clientUuid,
          'OFFLINE_CATCH_UP',
          extras: {'order_status': order.orderStatus},
        );
        healed++;
        continue;
      }

      if (_isPrematureOpenbillPayIntent(order)) {
        await markIntent(
          order.clientUuid,
          'OFFLINE_CATCH_UP',
          extras: {'order_status': order.orderStatus},
        );
        healed++;
        continue;
      }

      if (!_isRedundantCashierOpenbillProcessIntent(order)) {
        continue;
      }

      await (db.update(db.bookingOrders)
            ..where((t) => t.clientUuid.equals(order.clientUuid)))
          .write(
        const BookingOrdersCompanion(
          syncDirty: Value(false),
          syncIntent: Value(null),
          syncError: Value(null),
        ),
      );
      healed++;
    }

    return healed;
  }

  /// Queues PROCESS/FINISH for cash orders stuck dirty after partial server sync.
  Future<int> healStuckCashTerminalSyncIntents() async {
    var healed = 0;

    final dirty = await getAllDirtyBookingOrders();

    for (final order in dirty) {
      if (order.openbillFlag) continue;
      if (order.serverId == null || order.serverId! <= 0) continue;

      final intent = (order.syncIntent ?? '').trim().toUpperCase();
      if (intent.isNotEmpty) continue;

      final status = order.orderStatus.trim().toUpperCase();
      final nextIntent = switch (status) {
        'SERVED' => 'PROCESS',
        'PROCESSED' => 'FINISH',
        _ => null,
      };
      if (nextIntent == null) continue;

      await markIntent(
        order.clientUuid,
        nextIntent,
        extras: {'order_status': order.orderStatus},
      );
      healed++;
    }

    return healed;
  }

  Future<bool> _shouldDowngradePayToServeItems(BookingOrder order) async {
    if (!order.openbillFlag) return false;
    if ((order.syncIntent ?? '').trim().toUpperCase() != 'PAY') return false;

    final local = order.orderStatus.trim().toUpperCase();
    if (!{'UNPAID', 'SERVED'}.contains(local)) return false;

    if (await hasDirtyServedDetails(order.clientUuid)) {
      return true;
    }

    final error = (order.syncError ?? '').toUpperCase();
    if (error.contains('OPENBILL_WAITING_ORDER')) return true;
    if (error.contains('PAID AMOUNT') && local == 'UNPAID') return true;

    return false;
  }

  bool _isPrematureOpenbillPayIntent(BookingOrder order) {
    if (!order.openbillFlag) return false;
    if (order.orderStatus.trim().toUpperCase() != 'UNPAID') return false;
    if ((order.syncIntent ?? '').trim().toUpperCase() != 'PAY') return false;
    return order.paidAmountLocal == null;
  }

  bool _isRedundantCashierOpenbillProcessIntent(BookingOrder order) {
    if (!order.openbillFlag) return false;
    if ((order.orderBy ?? '').trim().toUpperCase() != 'CASHIER') return false;
    if (order.orderStatus.trim().toUpperCase() != 'OPENBILL_WAITING_ORDER') {
      return false;
    }
    if ((order.syncIntent ?? '').trim().toUpperCase() != 'PROCESS') return false;
    return order.serverId != null && order.serverId! > 0;
  }

  bool _isStuckCashierOpenbillProcessError(BookingOrder order) {
    if (!order.openbillFlag) return false;
    if ((order.orderBy ?? '').trim().toUpperCase() != 'CASHIER') return false;
    if ((order.syncIntent ?? '').trim().toUpperCase() != 'PROCESS') return false;

    final error = (order.syncError ?? '').toUpperCase();
    return error.contains('PROCESS') && error.contains('OPENBILL_CONFIRMATION');
  }

  Future<void> markDeletedByServerId(int serverId, {DateTime? deletedAt}) async {
    await (db.update(db.bookingOrders)..where((t) => t.serverId.equals(serverId))).write(
          BookingOrdersCompanion(
            deletedAt: Value(deletedAt ?? DateTime.now()),
            syncDirty: const Value(false),
            syncError: const Value(null),
            syncIntent: const Value(null),
          ),
        );
  }

  Future<void> markDeletedByClientUuid(String clientUuid, {DateTime? deletedAt}) async {
    await (db.update(db.bookingOrders)..where((t) => t.clientUuid.equals(clientUuid))).write(
          BookingOrdersCompanion(
            deletedAt: Value(deletedAt ?? DateTime.now()),
            syncDirty: const Value(false),
            syncError: const Value(null),
            syncIntent: const Value(null),
          ),
        );
  }

  Future<void> _mergeDetailsIntoKeeper({
    required String fromClientUuid,
    required String toClientUuid,
  }) async {
    if (fromClientUuid == toClientUuid) return;

    await (db.update(db.orderDetails)
          ..where((t) => t.bookingOrderClientUuid.equals(fromClientUuid)))
        .write(
      OrderDetailsCompanion(
        bookingOrderClientUuid: Value(toClientUuid),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> removeOrderMirrorByClientUuid(String clientUuid) async {
    await db.transaction(() async {
      final details = await (db.select(db.orderDetails)
            ..where((t) => t.bookingOrderClientUuid.equals(clientUuid)))
          .get();

      for (final detail in details) {
        await (db.delete(db.orderDetailOptions)
              ..where((t) => t.orderDetailClientUuid.equals(detail.clientDetailUuid)))
            .go();
      }

      await (db.delete(db.orderDetails)
            ..where((t) => t.bookingOrderClientUuid.equals(clientUuid)))
          .go();

      await (db.delete(db.bookingOrders)..where((t) => t.clientUuid.equals(clientUuid))).go();
    });
  }

  Future<int> markOrderDetailsServedLocally({
    List<String> detailClientUuids = const [],
    List<int> detailServerIds = const [],
    int? cashierProcessId,
  }) async {
    final now = DateTime.now();
    var updatedCount = 0;

    for (final uuid in detailClientUuids) {
      final trimmed = uuid.trim();
      if (trimmed.isEmpty) continue;
      updatedCount += await (db.update(db.orderDetails)
            ..where((t) => t.clientDetailUuid.equals(trimmed)))
          .write(
        OrderDetailsCompanion(
          status: const Value('SERVED BY CASHIER'),
          cashierProcessId: cashierProcessId != null
              ? Value(cashierProcessId)
              : const Value.absent(),
          syncDirty: const Value(true),
          updatedAt: Value(now),
        ),
      );
    }

    for (final id in detailServerIds) {
      if (id <= 0) continue;
      updatedCount += await (db.update(db.orderDetails)
            ..where((t) => t.serverId.equals(id)))
          .write(
        OrderDetailsCompanion(
          status: const Value('SERVED BY CASHIER'),
          cashierProcessId: cashierProcessId != null
              ? Value(cashierProcessId)
              : const Value.absent(),
          syncDirty: const Value(true),
          updatedAt: Value(now),
        ),
      );
    }

    return updatedCount;
  }

  /// Merges duplicate mirror headers that share the same booking order code.
  Future<int> reconcileDuplicateMirrors() async {
    var removed = await _reconcileMirrorsByServerId();
    removed += await _reconcileStaleOpenbillGhostMirrors();

    final rows = await (db.select(db.bookingOrders)
          ..where((t) => t.deletedAt.isNull()))
        .get();

    final byCode = <String, List<BookingOrder>>{};
    for (final row in rows) {
      final code = row.bookingOrderCode?.trim();
      if (code == null || code.isEmpty) continue;
      byCode.putIfAbsent(code, () => []).add(row);
    }

    for (final group in byCode.values) {
      if (group.length < 2) continue;

      BookingOrder keeper = group.first;
      var bestScore = -1;

      for (final row in group) {
        final detailCount = await (db.select(db.orderDetails)
              ..where((t) => t.bookingOrderClientUuid.equals(row.clientUuid)))
            .get()
            .then((value) => value.length);

        var score = detailCount * 3;
        if (row.syncIntent == 'CREATE') score += 4;
        if (row.serverId != null) score += 2;
        if (!row.syncDirty) score += 1;

        if (score > bestScore) {
          bestScore = score;
          keeper = row;
        }
      }

      for (final row in group) {
        if (row.clientUuid == keeper.clientUuid) continue;

        final detailCount = await (db.select(db.orderDetails)
              ..where((t) => t.bookingOrderClientUuid.equals(row.clientUuid)))
            .get()
            .then((value) => value.length);

        if (detailCount == 0 || (row.serverId == null && keeper.serverId != null)) {
          await removeOrderMirrorByClientUuid(row.clientUuid);
          removed++;
        }
      }
    }

    return removed;
  }

  Future<BookingOrder?> _findOfflineMirrorForServerRow(Map<String, dynamic> row) async {
    final customerName = (row['customer_name'] ?? row['order_name'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    if (customerName.isEmpty) return null;

    final tableId = _toIntOrNull(row['table_id'] ?? row['order_table']);
    final isOpenbill = _toBool(row['openbill_flag']);
    final serverCreated = _parseDate(row['created_at']);

    final candidates = await (db.select(db.bookingOrders)
          ..where((t) => t.deletedAt.isNull())
          ..where((t) => t.serverId.isNull())
          ..where((t) => t.syncDirty.equals(true)))
        .get();

    BookingOrder? best;
    var bestScore = -1;

    for (final candidate in candidates) {
      if (candidate.customerName.trim().toLowerCase() != customerName) continue;
      if (candidate.openbillFlag != isOpenbill) continue;
      if (tableId != null &&
          candidate.tableId != null &&
          candidate.tableId != tableId) {
        continue;
      }

      var score = 0;
      final intent = (candidate.syncIntent ?? '').toUpperCase();
      if (intent == 'CREATE' || intent == 'SERVE_ITEMS' || intent == 'PAY') {
        score += 10;
      }
      if (await hasDirtyServedDetails(candidate.clientUuid)) score += 5;
      if (candidate.paidAmountLocal != null) score += 3;

      final detailCount = await (db.select(db.orderDetails)
            ..where((t) => t.bookingOrderClientUuid.equals(candidate.clientUuid)))
          .get()
          .then((value) => value.length);
      score += detailCount;

      if (serverCreated != null && candidate.createdAt != null) {
        final diff = serverCreated.difference(candidate.createdAt!).abs();
        if (diff.inMinutes <= 60) score += 4;
      }

      if (score > bestScore) {
        bestScore = score;
        best = candidate;
      }
    }

    return bestScore > 0 ? best : null;
  }

  Future<int> _reconcileMirrorsByServerId() async {
    final rows = await (db.select(db.bookingOrders)
          ..where((t) => t.deletedAt.isNull())
          ..where((t) => t.serverId.isNotNull()))
        .get();

    final byServerId = <int, List<BookingOrder>>{};
    for (final row in rows) {
      final serverId = row.serverId;
      if (serverId == null || serverId <= 0) continue;
      byServerId.putIfAbsent(serverId, () => []).add(row);
    }

    var removed = 0;
    for (final group in byServerId.values) {
      if (group.length < 2) continue;

      final keeper = await _pickKeeperMirror(group);
      for (final row in group) {
        if (row.clientUuid == keeper.clientUuid) continue;
        await removeOrderMirrorByClientUuid(row.clientUuid);
        removed++;
      }
    }

    return removed;
  }

  Future<int> _reconcileStaleOpenbillGhostMirrors() async {
    final rows = await (db.select(db.bookingOrders)
          ..where((t) => t.deletedAt.isNull()))
        .get();

    final keepersByKey = <String, BookingOrder>{};
    for (final row in rows) {
      if (row.serverId == null || row.serverId! <= 0) continue;
      final key = _openbillReconcileKey(row);
      final existing = keepersByKey[key];
      if (existing == null || _preferKeeperMirror(row, existing)) {
        keepersByKey[key] = row;
      }
    }

    var removed = 0;
    for (final row in rows) {
      if (row.serverId != null && row.serverId! > 0) continue;
      if (!row.openbillFlag) continue;

      final key = _openbillReconcileKey(row);
      final keeper = keepersByKey[key];
      if (keeper == null) continue;
      if (keeper.clientUuid == row.clientUuid) continue;

      final ghostStatus = row.orderStatus.trim().toUpperCase();
      const removableGhostStatuses = {
        'OPENBILL_WAITING_ORDER',
        'OPENBILL_CONFIRMATION',
        'UNPAID',
        'SERVED',
      };
      if (removableGhostStatuses.contains(ghostStatus)) {
        await _mergeDetailsIntoKeeper(
          fromClientUuid: row.clientUuid,
          toClientUuid: keeper.clientUuid,
        );
        await removeOrderMirrorByClientUuid(row.clientUuid);
        removed++;
      }
    }

    return removed;
  }

  String _openbillReconcileKey(BookingOrder row) {
    final name = row.customerName.trim().toLowerCase();
    final table = row.tableId ?? 0;
    return '$name|$table|${row.openbillFlag}';
  }

  Future<BookingOrder> _pickKeeperMirror(List<BookingOrder> group) async {
    BookingOrder keeper = group.first;
    var bestScore = -1;

    for (final row in group) {
      final detailCount = await (db.select(db.orderDetails)
            ..where((t) => t.bookingOrderClientUuid.equals(row.clientUuid)))
          .get()
          .then((value) => value.length);

      var score = detailCount * 3;
      if (row.syncDirty) score += 4;
      if (row.paidAmountLocal != null) score += 3;
      if (await hasDirtyServedDetails(row.clientUuid)) score += 2;

      final status = row.orderStatus.trim().toUpperCase();
      if (status == 'UNPAID' || status == 'SERVED') score += 2;

      if (score > bestScore) {
        bestScore = score;
        keeper = row;
      }
    }

    return keeper;
  }

  bool _preferKeeperMirror(BookingOrder candidate, BookingOrder current) {
    final candidateStatus = candidate.orderStatus.trim().toUpperCase();
    final currentStatus = current.orderStatus.trim().toUpperCase();
    const preferred = ['SERVED', 'UNPAID', 'PROCESSED', 'PAID'];
    final candidateRank = preferred.contains(candidateStatus)
        ? preferred.indexOf(candidateStatus)
        : -1;
    final currentRank = preferred.contains(currentStatus)
        ? preferred.indexOf(currentStatus)
        : -1;
    if (candidateRank != currentRank) {
      return candidateRank > currentRank;
    }
    if (candidate.syncDirty != current.syncDirty) {
      return candidate.syncDirty;
    }
    return (candidate.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
        .isAfter(current.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0));
  }

  Future<void> applyAppliedResult(Map<String, dynamic> applied) async {
    if (applied['deleted'] == true) {
      final serverId = _toIntOrNull(applied['server_id']);
      if (serverId != null) {
        await markDeletedByServerId(serverId);
      }

      final deletedClientUuid = applied['client_uuid']?.toString();
      if (deletedClientUuid != null && deletedClientUuid.isNotEmpty) {
        await markDeletedByClientUuid(deletedClientUuid);
      }
      return;
    }

    final clientUuid = applied['client_uuid']?.toString();
    if (clientUuid == null || clientUuid.isEmpty) return;

    final localBefore = await getByClientUuid(clientUuid);
    final appliedIntent = applied['sync_intent']?.toString().toUpperCase() ?? '';
    final serverApplied = applied['order_status']?.toString();

    if ((appliedIntent == 'CREATE' || appliedIntent == 'OFFLINE_CATCH_UP') &&
        applied['server_id'] != null) {
      await _linkDetailServerIdsFromApplied(
        clientUuid: clientUuid,
        applied: applied,
      );
      await reconcileDuplicateMirrors();
    }

    if (appliedIntent == 'PROCESS' ||
        appliedIntent == 'FINISH' ||
        appliedIntent == 'SERVE_ITEMS') {
      await _clearDetailSyncDirty(clientUuid);
    } else if (appliedIntent == 'OFFLINE_CATCH_UP') {
      final serverServed =
          (serverApplied ?? '').trim().toUpperCase() == 'SERVED';
      if (serverServed) {
        await _clearDetailSyncDirty(clientUuid);
      } else {
        final servedConfirmed = await _catchUpAppliedServedDetailsConfirmed(
          clientUuid: clientUuid,
          appliedDetails: applied['order_details'],
        );
        if (servedConfirmed) {
          await _clearDetailSyncDirty(clientUuid);
        }
      }
    }

    var stillNeedsSync = false;
    if (localBefore != null) {
      stillNeedsSync = await orderNeedsCatchUpSync(
            local: localBefore,
            serverStatus: serverApplied,
          ) ||
          _cashCatchUpPartiallyApplied(
            localBefore: localBefore,
            appliedIntent: appliedIntent,
            serverApplied: serverApplied,
          );

      final localStatus = localBefore.orderStatus.trim().toUpperCase();
      final appliedStatus = (serverApplied ?? '').trim().toUpperCase();
      if (localStatus == 'SERVED' && appliedStatus == 'SERVED') {
        stillNeedsSync = false;
      } else if (await shouldClearSyncDirtyFlag(
        local: localBefore,
        serverStatus: serverApplied ?? '',
      )) {
        stillNeedsSync = false;
      }
    }

    await (db.update(db.bookingOrders)..where((t) => t.clientUuid.equals(clientUuid))).write(
          BookingOrdersCompanion(
            serverId: applied['server_id'] != null
                ? Value(_toInt(applied['server_id']))
                : const Value.absent(),
            bookingOrderCode: applied['booking_order_code'] != null
                ? Value(applied['booking_order_code'].toString())
                : const Value.absent(),
            orderStatus: localBefore != null
                ? Value(localBefore.orderStatus)
                : applied['order_status'] != null
                    ? Value(applied['order_status'].toString())
                    : const Value.absent(),
            paymentId: applied['payment_id'] != null
                ? Value(_toInt(applied['payment_id']))
                : const Value.absent(),
            latestPaymentServerId: applied['payment_id'] != null
                ? Value(_toInt(applied['payment_id']))
                : const Value.absent(),
            syncVersion: applied['sync_version'] != null
                ? Value(_toInt(applied['sync_version']))
                : const Value.absent(),
            syncDirty: Value(stillNeedsSync),
            syncError: const Value(null),
            syncIntent: const Value(null),
            syncedAt: Value(DateTime.now()),
          ),
        );
  }

  bool _cashCatchUpPartiallyApplied({
    required BookingOrder localBefore,
    required String appliedIntent,
    String? serverApplied,
  }) {
    if (appliedIntent != 'OFFLINE_CATCH_UP') return false;
    if (localBefore.openbillFlag) return false;

    final local = localBefore.orderStatus.trim().toUpperCase();
    final server = (serverApplied ?? '').trim().toUpperCase();
    if (local == 'SERVED' && (server == 'PAID' || server == 'PROCESSED')) {
      return true;
    }
    if (local == 'PROCESSED' && server == 'PAID') return true;
    return false;
  }

  Future<void> _clearMirrorSyncState(
    String clientUuid, {
    bool clearDetails = false,
  }) async {
    await (db.update(db.bookingOrders)..where((t) => t.clientUuid.equals(clientUuid)))
        .write(
      const BookingOrdersCompanion(
        syncDirty: Value(false),
        syncIntent: Value(null),
        syncError: Value(null),
      ),
    );

    if (clearDetails) {
      await _clearDetailSyncDirty(clientUuid);
    }
  }

  Future<void> _clearDetailSyncDirty(String bookingClientUuid) async {
    await (db.update(db.orderDetails)
          ..where((t) => t.bookingOrderClientUuid.equals(bookingClientUuid)))
        .write(
      const OrderDetailsCompanion(
        syncDirty: Value(false),
      ),
    );
  }

  Future<bool> _catchUpAppliedServedDetailsConfirmed({
    required String clientUuid,
    required dynamic appliedDetails,
  }) async {
    if (!await hasDirtyServedDetails(clientUuid)) return true;
    if (appliedDetails is! List) return false;

    final localDetails = await (db.select(db.orderDetails)
          ..where((t) => t.bookingOrderClientUuid.equals(clientUuid)))
        .get();

    final pendingServed = localDetails.where((detail) {
      if (detail.syncDirty != true) return false;
      final status = (detail.status ?? '').trim().toUpperCase();
      return status.contains('SERVED');
    }).toList();
    if (pendingServed.isEmpty) return true;

    final appliedById = <int, String>{};
    for (final raw in appliedDetails) {
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);
      final serverId = _toIntOrNull(map['id'] ?? map['detail_id']);
      final status = (map['status'] ?? '').toString().trim().toUpperCase();
      if (serverId != null && status.contains('SERVED')) {
        appliedById[serverId] = status;
      }
    }

    for (final detail in pendingServed) {
      final serverId = detail.serverId;
      if (serverId == null) return false;
      final appliedStatus = appliedById[serverId];
      if (appliedStatus == null || !appliedStatus.contains('SERVED')) {
        return false;
      }
    }

    return true;
  }

  Future<void> _linkDetailServerIdsFromApplied({
    required String clientUuid,
    required Map<String, dynamic> applied,
  }) async {
    final details = applied['order_details'];
    if (details is! List) return;

    final unlinked = await (db.select(db.orderDetails)
          ..where((t) => t.bookingOrderClientUuid.equals(clientUuid))
          ..where((t) => t.serverId.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
    var unlinkedIndex = 0;

    for (final raw in details) {
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);
      final clientDetailUuid = map['client_detail_uuid']?.toString();
      final serverDetailId = _toIntOrNull(map['id'] ?? map['detail_id']);
      if (serverDetailId == null) continue;

      String? targetClientUuid;
      if (clientDetailUuid != null && clientDetailUuid.isNotEmpty) {
        targetClientUuid = clientDetailUuid;
      } else if (unlinkedIndex < unlinked.length) {
        targetClientUuid = unlinked[unlinkedIndex].clientDetailUuid;
        unlinkedIndex++;
      }

      if (targetClientUuid == null || targetClientUuid.isEmpty) continue;
      final detailUuid = targetClientUuid;

      await (db.update(db.orderDetails)
            ..where((t) => t.clientDetailUuid.equals(detailUuid)))
          .write(
        OrderDetailsCompanion(
          serverId: Value(serverDetailId),
          bookingOrderServerId: applied['server_id'] != null
              ? Value(_toInt(applied['server_id']))
              : const Value.absent(),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  /// Re-queues the next lifecycle intent after a partial offline sync apply.
  Future<void> queueRemainingSyncIntentIfNeeded({
    required String clientUuid,
    required String appliedIntent,
    String? appliedServerStatus,
  }) async {
    if (clientUuid.isEmpty) return;

    final order = await getByClientUuid(clientUuid);
    if (order == null) return;

    final dirtyServed = await hasDirtyServedDetails(clientUuid);
    final nextIntent = OrderSyncIntentChain.resolveNext(
      localStatus: order.orderStatus,
      storedIntent: order.syncIntent,
      appliedIntent: appliedIntent,
      openbillFlag: order.openbillFlag,
      paidAmountLocal: order.paidAmountLocal,
      orderBy: order.orderBy,
      serverStatusAfterApply: appliedServerStatus,
      hasDirtyServedDetails: dirtyServed,
    );
    if (nextIntent == null) return;

    await markIntent(
      clientUuid,
      nextIntent,
      extras: {
        'order_status': order.orderStatus,
        if (order.paidAmountLocal != null) 'paid_amount': order.paidAmountLocal,
        if (order.changeAmountLocal != null) 'change_amount': order.changeAmountLocal,
        if (order.paymentMethod != null) 'payment_method': order.paymentMethod,
      },
    );
  }

  Future<void> saveConflict(Map<String, dynamic> conflict) async {
    await db.into(db.syncConflicts).insert(
          SyncConflictsCompanion.insert(
            entityTable: conflict['table']?.toString() ?? 'unknown',
            serverId: Value(_toIntOrNull(conflict['server_id'])),
            clientUuid: Value(conflict['client_uuid']?.toString()),
            reason: conflict['reason']?.toString() ?? 'UNKNOWN',
            localSnapshotJson: Value(
              conflict['local'] != null ? jsonEncode(conflict['local']) : null,
            ),
            serverSnapshotJson: Value(
              conflict['server'] != null ? jsonEncode(conflict['server']) : null,
            ),
            suggestedResolution: Value(conflict['suggested_resolution']?.toString()),
            createdAt: DateTime.now(),
          ),
        );
  }

  Future<int> countUnresolvedConflicts() async {
    final rows = await (db.select(db.syncConflicts)..where((t) => t.isResolved.equals(false)))
        .get();
    return rows.length;
  }

  Future<void> resolveConflict(int id, String choice) async {
    await (db.update(db.syncConflicts)..where((t) => t.id.equals(id))).write(
          SyncConflictsCompanion(
            isResolved: const Value(true),
            resolutionChoice: Value(choice),
          ),
        );
  }

  Future<String?> getSyncMeta(String key) async {
    final row = await (db.select(db.syncMeta)..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> setSyncMeta(String key, String value) async {
    await db.into(db.syncMeta).insertOnConflictUpdate(
          SyncMetaCompanion(key: Value(key), value: Value(value)),
        );
  }

  Future<String> ensureDeviceId() async {
    final existing = await getSyncMeta('device_id');
    if (existing != null && existing.isNotEmpty && existing != 'mobile') {
      return existing;
    }
    final id = _uuid.v4();
    await setSyncMeta('device_id', id);
    return id;
  }

  Future<void> clearSessionData({bool keepDeviceId = true}) async {
    final deviceId = keepDeviceId ? await getSyncMeta('device_id') : null;

    await db.transaction(() async {
      await db.delete(db.orderDetailOptions).go();
      await db.delete(db.orderDetails).go();
      await db.delete(db.orderPayments).go();
      await db.delete(db.bookingOrders).go();
      await db.delete(db.syncConflicts).go();
      await db.delete(db.syncMeta).go();
    });

    if (deviceId != null && deviceId.isNotEmpty) {
      await setSyncMeta('device_id', deviceId);
    }
  }

  Future<List<SyncConflict>> getUnresolvedConflicts() {
    return (db.select(db.syncConflicts)..where((t) => t.isResolved.equals(false)))
        .get();
  }

  Future<void> applyConflictResolution({
    required int conflictId,
    required String choice,
  }) async {
    final row = await (db.select(db.syncConflicts)..where((t) => t.id.equals(conflictId)))
        .getSingleOrNull();
    if (row == null) return;

    if (choice == 'SERVER_WINS' && row.serverSnapshotJson != null) {
      try {
        final server = jsonDecode(row.serverSnapshotJson!) as Map<String, dynamic>;
        if (row.entityTable == 'booking_orders') {
          await upsertFromServer(server);
        } else if (row.entityTable == 'order_details') {
          await upsertDetailFromServerRow(server);
        }
        final clientUuid = row.clientUuid;
        if (clientUuid != null && clientUuid.isNotEmpty) {
          await (db.update(db.bookingOrders)..where((t) => t.clientUuid.equals(clientUuid)))
              .write(
            const BookingOrdersCompanion(
              syncDirty: Value(false),
              syncError: Value(null),
              syncIntent: Value(null),
            ),
          );
        }
      } catch (_) {}
    } else if (choice == 'LOCAL_WINS') {
      final clientUuid = row.clientUuid;
      if (clientUuid != null && clientUuid.isNotEmpty) {
        await markForcePushUpdate(clientUuid);
      }
    }

    await resolveConflict(conflictId, choice);
  }

  /// Creates a full checkout order in the mirror (single write path).
  Future<String> createCheckoutOrder({
    required String customerName,
    required int tableId,
    String? tableNo,
    required String paymentMethodSelected,
    required String paymentMethodEffective,
    required bool openbillFlag,
    required double subtotal,
    required double grandTotal,
    double ppn = 0,
    bool isPpnActive = false,
    double cashRoundingAmount = 0,
    int cashRoundingUnit = 0,
    int? partnerId,
    String? partnerName,
    String? manualPaymentRawJson,
    String? wifiSnapshotJson,
    required List<Map<String, dynamic>> cartItems,
  }) async {
    final clientUuid = _uuid.v4();
    final now = DateTime.now();
    final orderStatus = openbillFlag ? 'OPENBILL_WAITING_ORDER' : 'UNPAID';

    await db.into(db.bookingOrders).insert(
          BookingOrdersCompanion.insert(
            clientUuid: clientUuid,
            customerName: customerName,
            tableId: Value(tableId),
            tableNo: Value(tableNo),
            paymentMethod: Value(paymentMethodSelected),
            openbillFlag: Value(openbillFlag),
            orderBy: Value(openbillFlag ? 'CASHIER' : null),
            orderStatus: Value(orderStatus),
            totalOrderValue: Value(subtotal),
            ppn: Value(ppn),
            isPpnActive: Value(isPpnActive),
            cashRoundingAmount: Value(cashRoundingAmount),
            cashRoundingUnit: Value(cashRoundingUnit),
            partnerId: Value(partnerId),
            partnerName: Value(partnerName),
            latestPaymentJson: Value(manualPaymentRawJson),
            wifiSnapshotJson: Value(wifiSnapshotJson),
            syncDirty: const Value(true),
            syncIntent: const Value('CREATE'),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    for (final cartItem in cartItems) {
      await addDetail(
        bookingOrderClientUuid: clientUuid,
        partnerProductId: cartItem['product_id'] as int,
        productName: cartItem['product_name']?.toString() ?? '',
        basePrice: (cartItem['base_price'] as num).toDouble(),
        quantity: cartItem['qty'] as int,
        optionsPrice: (cartItem['options_price'] as num?)?.toDouble() ?? 0,
        customerNote: cartItem['note']?.toString(),
        promoId: cartItem['promo_id'] as int?,
        promoType: cartItem['promo_type']?.toString(),
        promoAmount: (cartItem['promo_amount'] as num?)?.toDouble(),
        options: (cartItem['options'] as List?)?.cast<Map<String, dynamic>>() ?? const [],
      );
    }

    return clientUuid;
  }

  Future<String> ensureEditMirror({
    required int serverId,
    required String bookingOrderCode,
    required String customerName,
    int? tableServerId,
    String? tableNoSnapshot,
    required String orderStatus,
    String? paymentMethodEffective,
    required double subtotal,
    required double grandTotal,
    bool isPpnActive = false,
    double ppn = 0,
    bool openbillFlag = false,
    String? orderBy,
    int? syncVersion,
    List<Map<String, dynamic>>? seedDetails,
  }) async {
    final existing = await getByServerId(serverId);
    if (existing != null) return existing.clientUuid;

    final clientUuid = _uuid.v4();
    final now = DateTime.now();
    await db.into(db.bookingOrders).insert(
          BookingOrdersCompanion.insert(
            clientUuid: clientUuid,
            serverId: Value(serverId),
            bookingOrderCode: Value(bookingOrderCode),
            customerName: customerName,
            tableId: Value(tableServerId),
            tableNo: Value(tableNoSnapshot),
            orderStatus: Value(orderStatus),
            paymentMethod: Value(paymentMethodEffective),
            openbillFlag: Value(openbillFlag),
            orderBy: Value(orderBy),
            totalOrderValue: Value(subtotal),
            ppn: Value(ppn),
            isPpnActive: Value(isPpnActive),
            syncVersion: Value(syncVersion ?? 0),
            syncDirty: const Value(true),
            syncIntent: const Value('UPDATE'),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    if (seedDetails != null && seedDetails.isNotEmpty) {
      await _seedDetailsFromUiList(
        clientUuid: clientUuid,
        serverId: serverId,
        details: seedDetails,
      );
    }

    return clientUuid;
  }

  Future<void> _seedDetailsFromUiList({
    required String clientUuid,
    required int serverId,
    required List<Map<String, dynamic>> details,
  }) async {
    final now = DateTime.now();
    for (final raw in details) {
      if (raw is! Map) continue;
      final detail = Map<String, dynamic>.from(raw);
      final detailUuid = detail['local_detail_uuid']?.toString() ?? _uuid.v4();
      final options = (detail['order_detail_options'] as List?) ?? [];

      await db.into(db.orderDetails).insert(
            OrderDetailsCompanion.insert(
              clientDetailUuid: detailUuid,
              bookingOrderClientUuid: clientUuid,
              bookingOrderServerId: Value(serverId),
              serverId: Value(_toIntOrNull(detail['id'])),
              partnerProductId: _toInt(
                detail['partner_product_id'] ?? detail['product_id'],
                fallback: 0,
              ),
              productName: Value(detail['product_name']?.toString()),
              basePrice: Value(_toDouble(detail['base_price'])),
              quantity: Value(_toInt(detail['quantity'] ?? detail['qty'], fallback: 1)),
              optionsPrice: Value(_toDouble(detail['options_price'])),
              customerNote: Value(detail['customer_note']?.toString()),
              promoId: Value(_toIntOrNull(detail['promo_id'])),
              promoAmount: Value(_toDouble(detail['promo_amount'])),
              promoType: Value(detail['promo_type']?.toString()),
              status: Value(detail['status']?.toString()),
              cashierProcessId: Value(_toIntOrNull(detail['cashier_process_id'])),
              kitchenProcessId: Value(_toIntOrNull(detail['kitchen_process_id'])),
              syncDirty: const Value(false),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );

      for (final optRaw in options) {
        if (optRaw is! Map) continue;
        final opt = Map<String, dynamic>.from(optRaw);
        await db.into(db.orderDetailOptions).insert(
              OrderDetailOptionsCompanion.insert(
                clientOptionUuid: _uuid.v4(),
                orderDetailClientUuid: detailUuid,
                optionId: _toInt(opt['option_id'] ?? opt['id'], fallback: 0),
                partnerProductOptionName:
                    Value(opt['partner_product_option_name']?.toString()),
                parentName: Value(opt['parent_name']?.toString()),
                price: Value(_toDouble(opt['price'])),
                createdAt: Value(now),
                updatedAt: Value(now),
              ),
            );
      }
    }
  }

  Future<void> detectEditDivergenceAfterPull({
    required String clientUuid,
    required Map<String, dynamic> serverRow,
  }) async {
    final local = await getByClientUuid(clientUuid);
    if (local == null || !local.syncDirty) return;
    if ((local.syncIntent ?? '').toUpperCase() != 'UPDATE') return;

    final bundle = await getBundleByClientUuid(clientUuid);
    if (bundle == null) return;

    final localDetails = bundle.details
        .map((d) => OrderMirrorMapper.detailToUiMap(d))
        .toList();
    final serverDetails = ((serverRow['order_details'] as List?) ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final result = OrderEditConflictDetector.compare(
      localDetails: localDetails,
      serverDetails: serverDetails,
    );
    if (!result.hasDivergence) return;

    await saveConflict({
      'table': 'booking_orders',
      'server_id': serverRow['id'],
      'client_uuid': clientUuid,
      'reason': 'EDIT_DIVERGENCE',
      'local': {
        'order_status': local.orderStatus,
        'booking_order_code': local.bookingOrderCode,
        'order_details': localDetails,
        'diffs': result.editableDiffs,
        'locked': result.lockedConflicts,
      },
      'server': serverRow,
      'suggested_resolution': 'MANUAL_RESOLVE',
    });
  }

  Future<void> markForcePushUpdate(String clientUuid) async {
    final existing = await getByClientUuid(clientUuid);
    if (existing == null) return;

    final merged = <String, dynamic>{};
    if (existing.localFilePathsJson != null &&
        existing.localFilePathsJson!.trim().isNotEmpty) {
      final decoded = jsonDecode(existing.localFilePathsJson!);
      if (decoded is Map) {
        merged.addAll(Map<String, dynamic>.from(decoded));
      }
    }
    merged['force_push_update'] = true;

    await (db.update(db.bookingOrders)..where((t) => t.clientUuid.equals(clientUuid)))
        .write(
      BookingOrdersCompanion(
        syncDirty: const Value(true),
        syncIntent: const Value('UPDATE'),
        syncError: const Value(null),
        localFilePathsJson: Value(jsonEncode(merged)),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> replaceDetailsFromEdit({
    required String clientUuid,
    required List<Map<String, dynamic>> lines,
    required double subtotal,
    required double grandTotal,
    String syncIntent = 'UPDATE',
  }) async {
    await db.transaction(() async {
      final details = await (db.select(db.orderDetails)
            ..where((t) => t.bookingOrderClientUuid.equals(clientUuid)))
          .get();
      for (final detail in details) {
        await (db.delete(db.orderDetailOptions)
              ..where((t) => t.orderDetailClientUuid.equals(detail.clientDetailUuid)))
            .go();
      }
      await (db.delete(db.orderDetails)
            ..where((t) => t.bookingOrderClientUuid.equals(clientUuid)))
          .go();

      final now = DateTime.now();
      for (final line in lines) {
        final detailUuid = line['local_id']?.toString() ?? _uuid.v4();
        final detailStatus = line['detail_status']?.toString();
        await db.into(db.orderDetails).insert(
              OrderDetailsCompanion.insert(
                clientDetailUuid: detailUuid,
                bookingOrderClientUuid: clientUuid,
                serverId: Value(_toIntOrNull(line['server_order_detail_id'])),
                partnerProductId: _toInt(line['product_server_id']),
                productName: Value(line['product_name_snapshot']?.toString()),
                basePrice: Value(_toDouble(line['base_price'])),
                quantity: Value(_toInt(line['qty'], fallback: 1)),
                optionsPrice: Value(_toDouble(line['options_price'])),
                customerNote: Value(line['customer_note']?.toString()),
                promoId: Value(_toIntOrNull(line['promo_id'])),
                promoType: Value(line['promo_type']?.toString()),
                promoAmount: Value(_toDouble(line['promo_amount'])),
                status: Value(detailStatus),
                syncDirty: const Value(true),
                createdAt: Value(now),
                updatedAt: Value(now),
              ),
            );

        final options = (line['options'] as List?) ?? [];
        for (final opt in options) {
          if (opt is! Map) continue;
          await db.into(db.orderDetailOptions).insert(
                OrderDetailOptionsCompanion.insert(
                  clientOptionUuid: _uuid.v4(),
                  orderDetailClientUuid: detailUuid,
                  optionId: _toInt(opt['option_server_id']),
                  partnerProductOptionName:
                      Value(opt['option_name_snapshot']?.toString()),
                  parentName: Value(opt['parent_name_snapshot']?.toString()),
                  price: Value(_toDouble(opt['price'])),
                  createdAt: Value(now),
                  updatedAt: Value(now),
                ),
              );
        }
      }

      await (db.update(db.bookingOrders)..where((t) => t.clientUuid.equals(clientUuid)))
          .write(
        BookingOrdersCompanion(
          totalOrderValue: Value(subtotal),
          syncDirty: const Value(true),
          syncIntent: Value(syncIntent),
          syncError: const Value(null),
          updatedAt: Value(now),
        ),
      );
    });
  }

  Future<List<MirrorPendingStockLine>> getPendingStockLines() async {
    final dirtyOrders = await (db.select(db.bookingOrders)
          ..where((t) => t.serverId.isNull())
          ..where((t) => t.syncDirty.equals(true))
          ..where((t) => t.deletedAt.isNull()))
        .get();

    final lines = <MirrorPendingStockLine>[];
    for (final order in dirtyOrders) {
      final details = await (db.select(db.orderDetails)
            ..where((t) => t.bookingOrderClientUuid.equals(order.clientUuid)))
          .get();

      for (final detail in details) {
        final opts = await (db.select(db.orderDetailOptions)
              ..where((t) => t.orderDetailClientUuid.equals(detail.clientDetailUuid)))
            .get();
        lines.add(
          MirrorPendingStockLine(
            productId: detail.partnerProductId,
            qty: detail.quantity,
            optionIds: opts.map((o) => o.optionId).toList(),
          ),
        );
      }
    }
    return lines;
  }

  Future<void> upsertPaymentFromServer(Map<String, dynamic> row) async {
    final serverId = _toIntOrNull(row['id']);
    if (serverId == null) return;

    final bookingOrderServerId = _toIntOrNull(row['booking_order_id']);
    if (bookingOrderServerId == null) return;

    final parent = await getByServerId(bookingOrderServerId);
    if (parent == null) return;

    final existing = await (db.select(db.orderPayments)..where((t) => t.serverId.equals(serverId)))
        .getSingleOrNull();

    final clientPaymentUuid = existing?.clientPaymentUuid ?? _uuid.v4();
    final now = DateTime.now();

    await db.into(db.orderPayments).insertOnConflictUpdate(
          OrderPaymentsCompanion(
            clientPaymentUuid: Value(clientPaymentUuid),
            serverId: Value(serverId),
            bookingOrderClientUuid: Value(parent.clientUuid),
            bookingOrderServerId: Value(bookingOrderServerId),
            employeeId: Value(_toIntOrNull(row['employee_id'])),
            customerId: Value(_toIntOrNull(row['customer_id'])),
            customerName: Value(row['customer_name']?.toString()),
            paymentType: Value(row['payment_type']?.toString() ?? 'CASH'),
            paidAmount: Value(_toDouble(row['paid_amount'])),
            changeAmount: Value(_toDouble(row['change_amount'])),
            paymentStatus: Value(row['payment_status']?.toString() ?? 'PAID'),
            note: Value(row['note']?.toString()),
            ppn: Value(_toDouble(row['ppn'])),
            amountBeforePpn: Value(_toDouble(row['amount_before_ppn'])),
            roundingAmount: Value(_toDouble(row['rounding_amount'])),
            ownerManualPaymentId: Value(_toIntOrNull(row['owner_manual_payment_id'])),
            manualProviderName: Value(row['manual_provider_name']?.toString()),
            manualProviderAccountName:
                Value(row['manual_provider_account_name']?.toString()),
            manualProviderAccountNo: Value(row['manual_provider_account_no']?.toString()),
            localFilePathsJson: row['manual_payment_image'] != null
                ? Value(jsonEncode({
                    'manual_payment_image': row['manual_payment_image'].toString(),
                  }))
                : const Value.absent(),
            syncDirty: const Value(false),
            createdAt: Value(_parseDate(row['created_at']) ?? now),
            updatedAt: Value(_parseDate(row['updated_at']) ?? now),
          ),
        );

    final paymentStatus = row['payment_status']?.toString().toUpperCase() ?? '';
    if (paymentStatus == 'PENDING' || paymentStatus == 'PAID') {
      await (db.update(db.bookingOrders)
            ..where((t) => t.clientUuid.equals(parent.clientUuid)))
          .write(
        BookingOrdersCompanion(
          latestPaymentServerId: Value(serverId),
          paymentId: parent.paymentId == null ? Value(serverId) : const Value.absent(),
        ),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _queryTabOrders({
    required List<String> statuses,
    String? query,
    int? employeeId,
  }) async {
    final q = db.select(db.bookingOrders)
      ..where((t) => t.orderStatus.isIn(statuses))
      ..where((t) => t.deletedAt.isNull());

    if (employeeId != null) {
      q.where(
        (t) => t.cashierProcessId.equals(employeeId) | t.cashierProcessId.isNull(),
      );
    }

    final rows = await q.get();
    return _mapRowsWithDetails(rows, query: query);
  }

  Future<List<Map<String, dynamic>>> _mapRowsWithDetails(
    List<BookingOrder> rows, {
    String? query,
  }) async {
    final result = <Map<String, dynamic>>[];

    for (final row in rows) {
      final map = OrderMirrorMapper.orderToUiMap(row);

      final details = _dedupeDetailRows(
        await (db.select(db.orderDetails)
              ..where((t) => t.bookingOrderClientUuid.equals(row.clientUuid)))
            .get(),
      );

      map['order_details'] = await Future.wait(details.map((d) async {
        final detailMap = OrderMirrorMapper.detailToUiMap(d);
        final opts = await (db.select(db.orderDetailOptions)
              ..where((t) => t.orderDetailClientUuid.equals(d.clientDetailUuid)))
            .get();
        detailMap['order_detail_options'] =
            opts.map(OrderMirrorMapper.optionToUiMap).toList();
        return detailMap;
      }));

      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        final code = (map['booking_order_code'] ?? '').toString().toLowerCase();
        final name = (map['customer_name'] ?? '').toString().toLowerCase();
        final tableNo = (map['table_no'] ?? '').toString().toLowerCase();
        if (!code.contains(q) && !name.contains(q) && !tableNo.contains(q)) {
          continue;
        }
      }

      result.add(map);
    }

    result.sort((a, b) {
      final aCreated = DateTime.tryParse((a['created_at'] ?? '').toString());
      final bCreated = DateTime.tryParse((b['created_at'] ?? '').toString());

      if (aCreated == null && bCreated == null) {
        final aUuid = (a['client_uuid'] ?? '').toString();
        final bUuid = (b['client_uuid'] ?? '').toString();
        return aUuid.compareTo(bUuid);
      }
      if (aCreated == null) return -1;
      if (bCreated == null) return 1;

      final cmp = aCreated.compareTo(bCreated);
      if (cmp != 0) return cmp;

      final aUuid = (a['client_uuid'] ?? '').toString();
      final bUuid = (b['client_uuid'] ?? '').toString();
      return aUuid.compareTo(bUuid);
    });

    return result;
  }

  Future<void> _markOrderDirty(String clientUuid, String intent) async {
    await (db.update(db.bookingOrders)..where((t) => t.clientUuid.equals(clientUuid))).write(
          BookingOrdersCompanion(
            syncDirty: const Value(true),
            syncIntent: Value(intent),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> _upsertDetailFromServer(
    Map<String, dynamic> row,
    String bookingClientUuid,
    int bookingServerId,
  ) async {
    final serverId = _detailServerIdFromRow(row);
    if (serverId == null) return;

    var existing = await (db.select(db.orderDetails)
          ..where((t) => t.serverId.equals(serverId)))
        .getSingleOrNull();

    existing ??= await _findOrphanDetailForServerRow(
      bookingClientUuid: bookingClientUuid,
      row: row,
    );

    final clientDetailUuid = existing?.clientDetailUuid ?? _uuid.v4();
    final now = DateTime.now();
    final incomingStatus = row['status']?.toString();
    final existingStatus = existing?.status;
    final preserveLocalDetail = existing != null &&
        (existing.syncDirty ||
            (existingStatus != null &&
                (isDetailServedStatus(existingStatus) ||
                    isDetailProcessingStatus(existingStatus))));

    await db.into(db.orderDetails).insertOnConflictUpdate(
          OrderDetailsCompanion(
            clientDetailUuid: Value(clientDetailUuid),
            serverId: Value(serverId),
            bookingOrderClientUuid: Value(bookingClientUuid),
            bookingOrderServerId: Value(bookingServerId),
            productCode: Value(row['product_code']?.toString()),
            productName: Value(row['product_name']?.toString()),
            partnerProductId: Value(_toInt(row['partner_product_id'])),
            quantity: Value(_toInt(row['quantity'], fallback: 1)),
            basePrice: Value(_toDouble(row['base_price'])),
            cogs: Value(_toDouble(row['cogs'])),
            optionsPrice: Value(_toDouble(row['options_price'])),
            customerNote: Value(row['customer_note']?.toString()),
            promoId: Value(_toIntOrNull(row['promo_id'])),
            promoAmount: Value(_toDouble(row['promo_amount'])),
            promoType: Value(row['promo_type']?.toString()),
            status: preserveLocalDetail && existingStatus != null
                ? Value(existingStatus)
                : Value(incomingStatus),
            cashierProcessId: Value(_toIntOrNull(row['cashier_process_id'])),
            kitchenProcessId: Value(_toIntOrNull(row['kitchen_process_id'])),
            syncVersion: Value(_toInt(row['sync_version'])),
            syncDirty: preserveLocalDetail
                ? Value(existing!.syncDirty)
                : const Value(false),
            createdAt: Value(_parseDate(row['created_at']) ?? now),
            updatedAt: preserveLocalDetail
                ? Value(existing!.updatedAt)
                : Value(_parseDate(row['updated_at']) ?? now),
          ),
        );

    final options = (row['order_detail_options'] as List?) ?? [];
    for (final raw in options) {
      if (raw is! Map) continue;
      final opt = Map<String, dynamic>.from(raw);
      final optServerId = _toIntOrNull(opt['id']);
      if (optServerId == null) continue;

      final existingOpt = await (db.select(db.orderDetailOptions)
            ..where((t) => t.serverId.equals(optServerId)))
          .getSingleOrNull();

      final optName = _optionNameFromServerRow(opt);
      final parentName = _optionParentFromServerRow(opt);

      await db.into(db.orderDetailOptions).insertOnConflictUpdate(
            OrderDetailOptionsCompanion(
              clientOptionUuid: Value(existingOpt?.clientOptionUuid ?? _uuid.v4()),
              serverId: Value(optServerId),
              orderDetailClientUuid: Value(clientDetailUuid),
              orderDetailServerId: Value(serverId),
              optionId: Value(_toInt(opt['option_id'])),
              parentName: Value(parentName),
              partnerProductOptionName: Value(optName),
              price: Value(_toDouble(opt['price'])),
              createdAt: Value(_parseDate(opt['created_at']) ?? now),
              updatedAt: Value(_parseDate(opt['updated_at']) ?? now),
            ),
          );
    }
  }

  int? _detailServerIdFromRow(Map<String, dynamic> row) =>
      _toIntOrNull(row['id']) ?? _toIntOrNull(row['order_detail_id']);

  Future<OrderDetail?> _findOrphanDetailForServerRow({
    required String bookingClientUuid,
    required Map<String, dynamic> row,
  }) async {
    final partnerProductId = _toIntOrNull(row['partner_product_id']);
    if (partnerProductId == null) return null;

    final orphans = await (db.select(db.orderDetails)
          ..where((t) => t.bookingOrderClientUuid.equals(bookingClientUuid))
          ..where((t) => t.serverId.isNull())
          ..where((t) => t.partnerProductId.equals(partnerProductId)))
        .get();

    if (orphans.length == 1) return orphans.first;
    return null;
  }

  List<OrderDetail> _dedupeDetailRows(List<OrderDetail> details) {
    if (details.length <= 1) return details;

    final withServerId = <int, OrderDetail>{};
    final withoutServerId = <OrderDetail>[];

    for (final detail in details) {
      final sid = detail.serverId;
      if (sid == null) {
        withoutServerId.add(detail);
        continue;
      }

      final existing = withServerId[sid];
      if (existing == null) {
        withServerId[sid] = detail;
        continue;
      }

      final existingUpdated = existing.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final candidateUpdated = detail.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      if (candidateUpdated.isAfter(existingUpdated)) {
        withServerId[sid] = detail;
      }
    }

    final dedupedOrphans = <String, OrderDetail>{};
    for (final detail in withoutServerId) {
      final key =
          '${detail.partnerProductId}|${detail.quantity}|${detail.basePrice}|${detail.optionsPrice}';
      final existing = dedupedOrphans[key];
      if (existing == null) {
        dedupedOrphans[key] = detail;
        continue;
      }

      final existingUpdated = existing.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final candidateUpdated = detail.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      if (candidateUpdated.isAfter(existingUpdated)) {
        dedupedOrphans[key] = detail;
      }
    }

    final result = <OrderDetail>[
      ...withServerId.values,
      ...dedupedOrphans.values,
    ];
    result.sort((a, b) {
      final aDate = a.createdAt ?? a.updatedAt;
      final bDate = b.createdAt ?? b.updatedAt;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return aDate.compareTo(bDate);
    });
    return result;
  }

  Future<void> _deleteDetailAndOptions(String clientDetailUuid) async {
    await (db.delete(db.orderDetailOptions)
          ..where((t) => t.orderDetailClientUuid.equals(clientDetailUuid)))
        .go();
    await (db.delete(db.orderDetails)
          ..where((t) => t.clientDetailUuid.equals(clientDetailUuid)))
        .go();
  }

  Future<void> _pruneOrderDetailsAfterServerUpsert({
    required String bookingClientUuid,
    required Set<int> keepServerIds,
  }) async {
    final parent = await getByClientUuid(bookingClientUuid);
    final existing = await (db.select(db.orderDetails)
          ..where((t) => t.bookingOrderClientUuid.equals(bookingClientUuid)))
        .get();

    for (final detail in existing) {
      if (detail.syncDirty == true) continue;
      if (detail.serverId == null &&
          parent != null &&
          parent.syncDirty == true) {
        continue;
      }

      final sid = detail.serverId;
      final shouldDelete = sid != null
          ? !keepServerIds.contains(sid)
          : keepServerIds.isNotEmpty;
      if (shouldDelete) {
        await _deleteDetailAndOptions(detail.clientDetailUuid);
      }
    }
  }

  Future<void> _deduplicateOrderDetailsByServerId(String bookingClientUuid) async {
    final existing = await (db.select(db.orderDetails)
          ..where((t) => t.bookingOrderClientUuid.equals(bookingClientUuid)))
        .get();

    final groups = <int, List<OrderDetail>>{};
    for (final detail in existing) {
      final sid = detail.serverId;
      if (sid == null) continue;
      groups.putIfAbsent(sid, () => []).add(detail);
    }

    for (final group in groups.values) {
      if (group.length <= 1) continue;
      group.sort((a, b) {
        final aDate = a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      for (final duplicate in group.skip(1)) {
        await _deleteDetailAndOptions(duplicate.clientDetailUuid);
      }
    }
  }

  Future<int> _resolveCashRoundingUnitForRow(Map<String, dynamic> row) async {
    final fromRow = _toIntOrNull(row['cash_rounding_unit']);
    if (fromRow != null && fromRow > 0) return fromRow;

    final partnerData = row['partner_data'];
    if (partnerData is Map) {
      final fromPartner = _toIntOrNull(partnerData['cash_rounding_unit']);
      if (fromPartner != null && fromPartner > 0) return fromPartner;
    }

    final settings = await CacheDao(db).getPartnerSettings();
    return settings?.cashRoundingUnit ?? 0;
  }

  bool _toBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v?.toString().toLowerCase();
    return s == '1' || s == 'true';
  }

  int? _toIntOrNull(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) {
      final trimmed = v.trim();
      if (trimmed.isEmpty) return null;
      return int.tryParse(trimmed) ?? double.tryParse(trimmed)?.toInt();
    }
    return null;
  }

  int _toInt(dynamic v, {int fallback = 0}) => _toIntOrNull(v) ?? fallback;

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) {
      final trimmed = v.trim();
      if (trimmed.isEmpty) return 0;
      return double.tryParse(trimmed) ?? 0;
    }
    return 0;
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  String? _optionNameFromServerRow(Map<String, dynamic> opt) {
    final nested = opt['option'];
    if (nested is Map && nested['name'] != null) {
      return nested['name'].toString();
    }
    final flat = opt['partner_product_option_name'] ?? opt['name'];
    if (flat != null && flat.toString().trim().isNotEmpty) {
      return flat.toString();
    }
    return null;
  }

  String? _optionParentFromServerRow(Map<String, dynamic> opt) {
    final nested = opt['option'];
    if (nested is Map) {
      final parent = nested['parent'];
      if (parent is Map && parent['name'] != null) {
        return parent['name'].toString();
      }
    }
    final flat = opt['parent_name'];
    if (flat != null && flat.toString().trim().isNotEmpty) {
      return flat.toString();
    }
    return null;
  }
}
