import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '/core/network/api_debug_log.dart';
import '/features/cashier/data/local/db/cashier_db.dart';
import '/features/cashier/data/local/db/daos/booking_orders_dao.dart';

/// One-time migration from legacy local_orders into booking_orders mirror (v15).
class LegacySessionMigrator {
  static const _uuid = Uuid();

  static const _legacyTables = [
    'local_order_item_options',
    'local_order_items',
    'local_payments',
    'local_orders',
    'sync_queue',
    'cached_payment_order_item_options',
    'cached_payment_order_items',
    'cached_payment_orders',
    'cached_process_orders',
    'cached_done_orders',
  ];

  static Future<void> migrateBeforeDrop(GeneratedDatabase database) async {
    if (database is! CashierDb) return;
    final db = database;
    final dao = BookingOrdersDao(db);
    final existing = await dao.getSyncMeta('legacy_migrated_v15');
    if (existing == '1') return;

    try {
      final orders = await db.customSelect(
        "SELECT * FROM local_orders WHERE sync_status != 'SYNCED'",
        readsFrom: {},
      ).get();

      ApiDebugLog.sync('legacy migrator: rows=${orders.length}');

      for (final row in orders) {
        final data = row.data;
        final localId = data['local_id']?.toString() ?? '';
        if (localId.isEmpty) continue;

        final serverId = _toIntOrNull(data['server_id']);
        final clientUuid = localId;
        final paymentForCheckout =
            data['payment_method_selected'] ?? data['payment_method_effective'];

        await db.into(db.bookingOrders).insertOnConflictUpdate(
              BookingOrdersCompanion(
                clientUuid: Value(clientUuid),
                serverId: Value(serverId),
                bookingOrderCode: Value(data['server_order_code']?.toString()),
                partnerId: Value(_toIntOrNull(data['partner_id'])),
                partnerName: Value(data['partner_name']?.toString()),
                tableId: Value(_toIntOrNull(data['table_server_id'])),
                tableNo: Value(data['table_no_snapshot']?.toString()),
                customerName: Value(data['customer_name']?.toString() ?? 'guest'),
                paymentMethod: Value(paymentForCheckout?.toString()),
                openbillFlag: Value(
                  data['payment_method_selected']?.toString() == 'OPENBILL' ||
                      data['payment_method_effective']?.toString() == 'OPENBILL' ||
                      (data['order_status_local']?.toString() ?? '')
                          .startsWith('OPENBILL'),
                ),
                totalOrderValue: Value(_toDouble(data['subtotal'])),
                ppn: Value(_toDouble(data['ppn_percent'])),
                isPpnActive: Value(_toBool(data['is_ppn_active'])),
                orderStatus: Value(data['order_status_local']?.toString() ?? 'UNPAID'),
                paidAmountLocal: Value(_toDouble(data['paid_amount_local'])),
                changeAmountLocal: Value(_toDouble(data['change_amount_local'])),
                cashRoundingAmount: Value(_toDouble(data['cash_rounding_amount'])),
                cashRoundingUnit: Value(_toIntOrNull(data['cash_rounding_unit'])),
                latestPaymentServerId:
                    Value(_toIntOrNull(data['latest_payment_server_id'])),
                syncDirty: const Value(true),
                syncIntent: Value(_intentFromLegacy(data)),
                createdAt: Value(_parseDate(data['created_at_local'])),
                updatedAt: Value(_parseDate(data['updated_at_local'])),
              ),
            );

        final items = await db.customSelect(
          'SELECT * FROM local_order_items WHERE order_local_id = ?',
          variables: [Variable.withString(localId)],
          readsFrom: {},
        ).get();

        for (final itemRow in items) {
          final item = itemRow.data;
          final detailUuid = item['local_id']?.toString() ?? _uuid.v4();
          await db.into(db.orderDetails).insertOnConflictUpdate(
                OrderDetailsCompanion(
                  clientDetailUuid: Value(detailUuid),
                  serverId: Value(_toIntOrNull(item['server_order_detail_id'])),
                  bookingOrderClientUuid: Value(clientUuid),
                  bookingOrderServerId: Value(serverId),
                  partnerProductId: Value(_toInt(item['product_server_id'])),
                  productName: Value(item['product_name_snapshot']?.toString()),
                  basePrice: Value(_toDouble(item['base_price'])),
                  quantity: Value(_toInt(item['qty'], fallback: 1)),
                  optionsPrice: Value(_toDouble(item['options_price'])),
                  customerNote: Value(item['customer_note']?.toString()),
                  promoId: Value(_toIntOrNull(item['promo_id'])),
                  promoType: Value(item['promo_type']?.toString()),
                  promoAmount: Value(_toDouble(item['promo_amount'])),
                  syncDirty: const Value(true),
                  createdAt: Value(_parseDate(item['created_at_local'])),
                  updatedAt: Value(DateTime.now()),
                ),
              );

          final options = await db.customSelect(
            'SELECT * FROM local_order_item_options WHERE order_item_local_id = ?',
            variables: [Variable.withString(detailUuid)],
            readsFrom: {},
          ).get();

          for (final optRow in options) {
            final opt = optRow.data;
            await db.into(db.orderDetailOptions).insertOnConflictUpdate(
                  OrderDetailOptionsCompanion(
                    clientOptionUuid: Value(opt['local_id']?.toString() ?? _uuid.v4()),
                    orderDetailClientUuid: Value(detailUuid),
                    orderDetailServerId:
                        Value(_toIntOrNull(item['server_order_detail_id'])),
                    optionId: Value(_toInt(opt['option_server_id'])),
                    partnerProductOptionName:
                        Value(opt['option_name_snapshot']?.toString()),
                    parentName: Value(opt['parent_name_snapshot']?.toString()),
                    price: Value(_toDouble(opt['price'])),
                    createdAt: Value(DateTime.now()),
                    updatedAt: Value(DateTime.now()),
                  ),
                );
          }
        }
      }

      await dao.setSyncMeta('legacy_migrated_v15', '1');
      ApiDebugLog.sync('legacy v15 migration completed');
    } catch (e, st) {
      ApiDebugLog.syncError('legacy v15 migration skipped/failed', '$e\n$st');
    }
  }

  static Future<void> dropLegacyTables(GeneratedDatabase database) async {
    for (final table in _legacyTables) {
      await database.customStatement('DROP TABLE IF EXISTS $table');
    }
  }

  static String _intentFromLegacy(Map<String, Object?> data) {
    final syncStatus = data['sync_status']?.toString() ?? '';
    final status = data['order_status_local']?.toString() ?? '';
    final serverId = _toIntOrNull(data['server_id']);

    if (syncStatus == 'PENDING_UPDATE') return 'UPDATE';
    if (syncStatus == 'PENDING_PAYMENT') return 'PAY';
    if (syncStatus == 'PENDING_PROCESS') return 'PROCESS';
    if (syncStatus == 'PENDING_FINISH') return 'FINISH';
    if (syncStatus == 'PENDING_DELETE') return 'DELETE';
    if (status == 'OPENBILL_CONFIRMATION' && serverId != null && serverId > 0) {
      return 'CONFIRM_OPENBILL';
    }
    if (status == 'PAID' || status == 'PROCESSED') return 'PROCESS';
    if (status == 'SERVED') return 'FINISH';
    return serverId == null ? 'CREATE' : 'UPDATE';
  }

  static bool _toBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v?.toString().toLowerCase();
    return s == '1' || s == 'true';
  }

  static int? _toIntOrNull(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim());
    return null;
  }

  static int _toInt(dynamic v, {int fallback = 0}) => _toIntOrNull(v) ?? fallback;

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.trim()) ?? 0;
    return 0;
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return DateTime.tryParse(v.toString());
  }
}
