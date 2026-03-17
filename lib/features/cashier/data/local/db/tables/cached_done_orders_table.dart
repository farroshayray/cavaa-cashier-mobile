import 'package:drift/drift.dart';

class CachedDoneOrders extends Table {
  IntColumn get serverId => integer()();
  TextColumn get bookingOrderCode => text()();
  TextColumn get customerName => text()();
  TextColumn get tableNo => text().nullable()();

  TextColumn get doneRequestJson => text().nullable()();
  TextColumn get latestDoneJson => text().nullable()();

  TextColumn get paymentMethod => text().nullable()();
  TextColumn get orderStatus => text()();
  TextColumn get detailJson => text().nullable()();

  RealColumn get subtotal => real().withDefault(const Constant(0))();
  RealColumn get ppnPercent => real().withDefault(const Constant(0))();
  BoolColumn get isPpnActive => boolean().withDefault(const Constant(false))();

  BoolColumn get isSynced => boolean().withDefault(const Constant(true))();
  BoolColumn get deletedLocally => boolean().withDefault(const Constant(false))();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {serverId};
}