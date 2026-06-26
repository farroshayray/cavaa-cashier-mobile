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
import 'tables/cached_payment_orders_table.dart';
import 'tables/cached_payment_order_items_table.dart';
import 'tables/cached_payment_order_item_options_table.dart';


import 'tables/local_orders_table.dart';
import 'tables/local_order_items_table.dart';
import 'tables/local_order_item_options_table.dart';
import 'tables/local_payments_table.dart';
import 'tables/sync_queue_table.dart';
import 'tables/cached_process_orders_table.dart';
import '/features/cashier/data/local/db/daos/cached_process_orders_dao.dart';
import 'tables/cached_done_orders_table.dart';
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
  ],
  daos: [
    CachedProcessOrdersDao,
    CachedDoneOrdersDao,
  ],
)
class CashierDb extends _$CashierDb {
  CashierDb() : super(_openConnection());

  @override
  int get schemaVersion => 12;

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
        },
      );
}