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
import 'tables/booking_orders_table.dart';
import 'tables/order_details_table.dart';
import 'tables/order_detail_options_table.dart';
import 'tables/order_payments_table.dart';
import 'tables/sync_conflicts_table.dart';
import 'tables/sync_meta_table.dart';
import '/features/cashier/data/sync/legacy_session_migrator.dart';

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
    BookingOrders,
    OrderDetails,
    OrderDetailOptions,
    OrderPayments,
    SyncConflicts,
    SyncMeta,
  ],
)
class CashierDb extends _$CashierDb {
  CashierDb() : super(_openConnection());

  @override
  int get schemaVersion => 15;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 12) {
            await m.database.customStatement(
              'ALTER TABLE local_orders ADD COLUMN cash_rounding_amount REAL',
            );
            await m.database.customStatement(
              'ALTER TABLE local_orders ADD COLUMN cash_rounding_unit INTEGER',
            );
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
          if (from < 15) {
            await LegacySessionMigrator.migrateBeforeDrop(m.database);
            await LegacySessionMigrator.dropLegacyTables(m.database);
          }
        },
      );
}
