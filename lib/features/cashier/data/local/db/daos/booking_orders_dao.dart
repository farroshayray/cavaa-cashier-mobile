import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '/features/cashier/data/local/db/cashier_db.dart';
import '/features/cashier/data/local/db/mappers/order_mirror_mapper.dart';

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
    );

    await (db.update(db.bookingOrders)..where((t) => t.clientUuid.equals(clientUuid)))
        .write(companion);
  }

  /// Ensures a mirror row exists for a server order shown in tab UI.
  Future<void> ensureFromUiMap(
    Map<String, dynamic> order, {
    required int serverId,
  }) async {
    final existing = await getByServerId(serverId);
    if (existing != null) return;

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
            syncIntent: syncIntent != null ? Value(syncIntent) : const Value.absent(),
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
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));

    final rows = await (db.select(db.bookingOrders)
          ..where((t) => t.orderStatus.equals('SERVED'))
          ..where((t) => t.deletedAt.isNull())
          ..where((t) => t.updatedAt.isBiggerOrEqualValue(start))
          ..where((t) => t.updatedAt.isSmallerThanValue(end)))
        .get();

    return _mapRowsWithDetails(rows, query: query);
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

    final optionsByDetailUuid = <String, List<OrderDetailOption>>{};
    for (final detail in details) {
      final opts = await (db.select(db.orderDetailOptions)
            ..where((t) => t.orderDetailClientUuid.equals(detail.clientDetailUuid)))
          .get();
      optionsByDetailUuid[detail.clientDetailUuid] = opts;
    }

    return BookingOrderBundle(
      order: order,
      details: details,
      optionsByDetailUuid: optionsByDetailUuid,
    );
  }

  Future<void> upsertFromServer(Map<String, dynamic> row) async {
    final serverId = _toIntOrNull(row['id']);
    if (serverId == null) return;

    final existing = await getByServerId(serverId);
    final clientUuid = existing?.clientUuid ?? _uuid.v4();
    final now = DateTime.now();

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
      orderStatus: Value(row['order_status']?.toString() ?? 'UNPAID'),
      paymentMethod: Value(row['payment_method']?.toString()),
      openbillFlag: Value(_toBool(row['openbill_flag'])),
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
      paymentFlag: Value(_toBool(row['payment_flag'])),
      wifiSnapshotJson: Value(row['wifi_snapshot'] != null ? jsonEncode(row['wifi_snapshot']) : null),
      paymentRequestJson:
          Value(row['payment_request'] != null ? jsonEncode(row['payment_request']) : null),
      latestPaymentJson:
          Value(row['latest_payment'] != null ? jsonEncode(row['latest_payment']) : null),
      syncVersion: Value(_toInt(row['sync_version'])),
      syncDirty: const Value(false),
      syncError: const Value(null),
      createdAt: Value(_parseDate(row['created_at']) ?? now),
      updatedAt: Value(_parseDate(row['updated_at']) ?? now),
      deletedAt: Value(_parseDate(row['deleted_at'])),
      syncedAt: Value(now),
    );

    await db.into(db.bookingOrders).insertOnConflictUpdate(companion);

    final details = (row['order_details'] as List?) ?? [];
    for (final raw in details) {
      if (raw is! Map) continue;
      await _upsertDetailFromServer(Map<String, dynamic>.from(raw), clientUuid, serverId);
    }
  }

  /// Upsert satu baris order_details dari pull (tanpa parent row di batch yang sama).
  Future<void> upsertDetailFromServerRow(Map<String, dynamic> row) async {
    final bookingOrderServerId = _toIntOrNull(row['booking_order_id']);
    if (bookingOrderServerId == null) return;

    final parent = await getByServerId(bookingOrderServerId);
    if (parent == null) return;

    await _upsertDetailFromServer(row, parent.clientUuid, bookingOrderServerId);
  }

  Future<void> markSyncErrorByClientUuid(String clientUuid, String message) async {
    if (clientUuid.isEmpty) return;

    await (db.update(db.bookingOrders)..where((t) => t.clientUuid.equals(clientUuid))).write(
          BookingOrdersCompanion(
            syncError: Value(message),
          ),
        );
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

    await (db.update(db.bookingOrders)..where((t) => t.clientUuid.equals(clientUuid))).write(
          BookingOrdersCompanion(
            serverId: applied['server_id'] != null
                ? Value(_toInt(applied['server_id']))
                : const Value.absent(),
            bookingOrderCode: applied['booking_order_code'] != null
                ? Value(applied['booking_order_code'].toString())
                : const Value.absent(),
            orderStatus: applied['order_status'] != null
                ? Value(applied['order_status'].toString())
                : const Value.absent(),
            syncVersion: applied['sync_version'] != null
                ? Value(_toInt(applied['sync_version']))
                : const Value.absent(),
            syncDirty: const Value(false),
            syncError: const Value(null),
            syncedAt: Value(DateTime.now()),
          ),
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
    required List<Map<String, dynamic>> cartItems,
  }) async {
    final clientUuid = _uuid.v4();
    final now = DateTime.now();
    final orderStatus = openbillFlag ? 'OPENBILL_CONFIRMATION' : 'UNPAID';

    await db.into(db.bookingOrders).insert(
          BookingOrdersCompanion.insert(
            clientUuid: clientUuid,
            customerName: customerName,
            tableId: Value(tableId),
            tableNo: Value(tableNo),
            paymentMethod: Value(paymentMethodSelected),
            openbillFlag: Value(openbillFlag),
            orderStatus: Value(orderStatus),
            totalOrderValue: Value(subtotal),
            ppn: Value(ppn),
            isPpnActive: Value(isPpnActive),
            cashRoundingAmount: Value(cashRoundingAmount),
            cashRoundingUnit: Value(cashRoundingUnit),
            partnerId: Value(partnerId),
            partnerName: Value(partnerName),
            latestPaymentJson: Value(manualPaymentRawJson),
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
            totalOrderValue: Value(subtotal),
            ppn: Value(ppn),
            isPpnActive: Value(isPpnActive),
            syncDirty: const Value(true),
            syncIntent: const Value('UPDATE'),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
    return clientUuid;
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
                status: Value(line['detail_status']?.toString()),
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
            syncDirty: const Value(false),
            createdAt: Value(_parseDate(row['created_at']) ?? now),
            updatedAt: Value(_parseDate(row['updated_at']) ?? now),
          ),
        );
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

      final details = await (db.select(db.orderDetails)
            ..where((t) => t.bookingOrderClientUuid.equals(row.clientUuid)))
          .get();

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
      final aDate = a['updated_at']?.toString() ?? '';
      final bDate = b['updated_at']?.toString() ?? '';
      return bDate.compareTo(aDate);
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
    final serverId = _toIntOrNull(row['id']);
    if (serverId == null) return;

    final existing = await (db.select(db.orderDetails)..where((t) => t.serverId.equals(serverId)))
        .getSingleOrNull();

    final clientDetailUuid = existing?.clientDetailUuid ?? _uuid.v4();
    final now = DateTime.now();

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
            status: Value(row['status']?.toString()),
            cashierProcessId: Value(_toIntOrNull(row['cashier_process_id'])),
            kitchenProcessId: Value(_toIntOrNull(row['kitchen_process_id'])),
            syncVersion: Value(_toInt(row['sync_version'])),
            syncDirty: const Value(false),
            createdAt: Value(_parseDate(row['created_at']) ?? now),
            updatedAt: Value(_parseDate(row['updated_at']) ?? now),
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

      await db.into(db.orderDetailOptions).insertOnConflictUpdate(
            OrderDetailOptionsCompanion(
              clientOptionUuid: Value(existingOpt?.clientOptionUuid ?? _uuid.v4()),
              serverId: Value(optServerId),
              orderDetailClientUuid: Value(clientDetailUuid),
              orderDetailServerId: Value(serverId),
              optionId: Value(_toInt(opt['option_id'])),
              parentName: Value(opt['parent_name']?.toString()),
              partnerProductOptionName: Value(opt['partner_product_option_name']?.toString()),
              price: Value(_toDouble(opt['price'])),
              createdAt: Value(_parseDate(opt['created_at']) ?? now),
              updatedAt: Value(_parseDate(opt['updated_at']) ?? now),
            ),
          );
    }
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
}
