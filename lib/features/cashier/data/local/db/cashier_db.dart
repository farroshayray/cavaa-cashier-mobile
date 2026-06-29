import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/cached_categories_table.dart';
import 'tables/cached_products_table.dart';
import 'tables/cached_option_groups_table.dart';
import 'tables/cached_option_items_table.dart';
import 'tables/cached_tables_table.dart';
import 'tables/cached_payment_methods_table.dart';
import 'tables/cached_partner_settings_table.dart';
import 'tables/cached_payment_orders_table.dart';
import 'tables/cached_payment_order_items_table.dart';
import 'tables/cached_payment_order_item_options_table.dart';
import 'tables/local_orders_table.dart';
import 'tables/local_order_items_table.dart';
import 'tables/local_order_item_options_table.dart';
import 'tables/local_payments_table.dart';
import 'tables/sync_queue_table.dart';
import 'tables/cached_process_orders_table.dart';
import 'tables/cached_done_orders_table.dart';
import 'tables/booking_orders_table.dart';
import 'tables/order_details_table.dart';
import 'tables/order_detail_options_table.dart';
import 'tables/order_payments_table.dart';
import 'tables/sync_conflicts_table.dart';
import 'tables/sync_meta_table.dart';
import '/features/cashier/data/local/db/daos/cached_process_orders_dao.dart';
import '/features/cashier/data/local/db/daos/cached_done_orders_dao.dart';

part 'cashier_db.g.dart';

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'cashier.db'));
    return NativeDatabase(file);
  });
}

@DriftDatabase(
  tables: [
    CachedCategories,
    CachedProducts,
    CachedOptionGroups,
    CachedOptionItems,
    CachedTables,
    CachedPaymentMethods,
    CachedPartnerSettings,
    LocalOrders,
    LocalOrderItems,
    LocalOrderItemOptions,
    LocalPayments,
    SyncQueue,
    CachedPaymentOrders,
    CachedProcessOrders,
    CachedPaymentOrderItems,
    CachedPaymentOrderItemOptions,
    CachedDoneOrders,
    BookingOrders,
    OrderDetails,
    OrderDetailOptions,
    OrderPayments,
    SyncConflicts,
    SyncMeta,
  ],
  daos: [
    CachedProcessOrdersDao,
    CachedDoneOrdersDao,
  ],
)
class CashierDb extends _$CashierDb {
  CashierDb() : super(_openConnection());

  @override
  int get schemaVersion => 14;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 12) {
            await m.addColumn(localOrders, localOrders.cashRoundingAmount);
            await m.addColumn(localOrders, localOrders.cashRoundingUnit);
          }
          if (from < 13) {
            await m.createTable(cachedPartnerSettings);
          }
          if (from < 14) {
            await m.createTable(bookingOrders);
            await m.createTable(orderDetails);
            await m.createTable(orderDetailOptions);
            await m.createTable(orderPayments);
            await m.createTable(syncConflicts);
            await m.createTable(syncMeta);
          }
        },
      );
}
