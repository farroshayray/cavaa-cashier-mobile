import 'dart:convert';

import 'package:drift/drift.dart';

import '/core/network/api_debug_log.dart';
import '/features/cashier/data/local/db/cashier_db.dart';
import '/features/cashier/data/local/db/daos/booking_orders_dao.dart';

/// Mirrors unified booking_orders rows into legacy tab cache tables
/// so existing providers keep working during the transition.
class LegacyCacheBridge {
  LegacyCacheBridge({
    required this.db,
    required this.bookingOrdersDao,
  });

  final CashierDb db;
  final BookingOrdersDao bookingOrdersDao;

  Future<void> refreshAll() async {
    await _refreshPaymentCache();
    await _refreshProcessCache();
    await _refreshDoneCache();
    ApiDebugLog.sync('legacy cache bridge refreshed (payment/process/done)');
  }

  Future<void> _refreshPaymentCache() async {
    final rows = await bookingOrdersDao.getPaymentTabOrders();
    final now = DateTime.now();

    ApiDebugLog.sync('bridge payment tab rows=${rows.length}');

    await db.transaction(() async {
      await db.delete(db.cachedPaymentOrders).go();

      for (final map in rows) {
        final serverId = map['id'] as int?;
        if (serverId == null) continue;

        await db.into(db.cachedPaymentOrders).insert(
              CachedPaymentOrdersCompanion.insert(
                serverId: Value(serverId),
                bookingOrderCode: map['booking_order_code']?.toString() ?? '',
                customerName: map['customer_name']?.toString() ?? '',
                tableNo: Value(map['table_no']?.toString()),
                paymentMethod: Value(map['payment_method']?.toString()),
                orderStatus: map['order_status']?.toString() ?? 'UNPAID',
                detailJson: Value(jsonEncode(map)),
                subtotal: Value((map['total_order_value'] as num?)?.toDouble() ?? 0),
                ppnPercent: Value((map['ppn'] as num?)?.toDouble() ?? 0),
                isPpnActive: Value(map['is_ppn_active'] == true || map['is_ppn_active'] == 1),
                grandTotal: Value((map['total_order_value'] as num?)?.toDouble() ?? 0),
                createdAt: Value(_parseDate(map['created_at'])),
                updatedAt: Value(_parseDate(map['updated_at'])),
                cachedAt: now,
              ),
              mode: InsertMode.insertOrReplace,
            );
      }
    });
  }

  Future<void> _refreshProcessCache() async {
    final rows = await bookingOrdersDao.getProcessTabOrders();
    final now = DateTime.now();

    ApiDebugLog.sync('bridge process tab rows=${rows.length}');

    await db.transaction(() async {
      await db.delete(db.cachedProcessOrders).go();

      for (final map in rows) {
        final serverId = map['id'] as int?;
        if (serverId == null) continue;

        final order = await bookingOrdersDao.getByServerId(serverId);
        final pendingAction = order?.syncDirty == true ? order?.syncIntent : null;

        await db.into(db.cachedProcessOrders).insert(
              CachedProcessOrdersCompanion.insert(
                serverId: Value(serverId),
                bookingOrderCode: map['booking_order_code']?.toString() ?? '',
                customerName: map['customer_name']?.toString() ?? '',
                tableNo: Value(map['table_no']?.toString()),
                paymentMethod: Value(map['payment_method']?.toString()),
                orderStatus: map['order_status']?.toString() ?? 'PAID',
                detailJson: Value(jsonEncode(map)),
                subtotal: Value((map['total_order_value'] as num?)?.toDouble() ?? 0),
                ppnPercent: Value((map['ppn'] as num?)?.toDouble() ?? 0),
                isPpnActive: Value(map['is_ppn_active'] == true || map['is_ppn_active'] == 1),
                pendingAction: Value(pendingAction),
                isSynced: Value(pendingAction == null),
                processedByKitchen: Value(map['processed_by_kitchen'] == true),
                syncedAt: Value(now),
              ),
              mode: InsertMode.insertOrReplace,
            );
      }
    });
  }

  Future<void> _refreshDoneCache() async {
    final rows = await bookingOrdersDao.getDoneTabOrders();
    final now = DateTime.now();

    ApiDebugLog.sync('bridge done tab rows=${rows.length}');

    await db.transaction(() async {
      await db.delete(db.cachedDoneOrders).go();

      for (final map in rows) {
        final serverId = map['id'] as int?;
        if (serverId == null) continue;

        await db.into(db.cachedDoneOrders).insert(
              CachedDoneOrdersCompanion.insert(
                serverId: Value(serverId),
                bookingOrderCode: map['booking_order_code']?.toString() ?? '',
                customerName: map['customer_name']?.toString() ?? '',
                tableNo: Value(map['table_no']?.toString()),
                paymentMethod: Value(map['payment_method']?.toString()),
                orderStatus: map['order_status']?.toString() ?? 'SERVED',
                detailJson: Value(jsonEncode(map)),
                subtotal: Value((map['total_order_value'] as num?)?.toDouble() ?? 0),
                ppnPercent: Value((map['ppn'] as num?)?.toDouble() ?? 0),
                isPpnActive: Value(map['is_ppn_active'] == true || map['is_ppn_active'] == 1),
                isSynced: const Value(true),
                syncedAt: Value(now),
              ),
              mode: InsertMode.insertOrReplace,
            );
      }
    });
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
