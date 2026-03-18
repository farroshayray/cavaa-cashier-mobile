import 'package:drift/drift.dart';

class CachedPaymentOrders extends Table {
  IntColumn get serverId => integer()();
  TextColumn get bookingOrderCode => text()();
  TextColumn get customerName => text()();
  TextColumn get tableNo => text().nullable()();
  TextColumn get paymentRequestJson => text().nullable()();
  TextColumn get latestPaymentJson => text().nullable()();  

  TextColumn get paymentMethod => text().nullable()();
  TextColumn get orderStatus => text()();
  TextColumn get detailJson => text().nullable()();

  RealColumn get subtotal => real().withDefault(const Constant(0))();
  RealColumn get ppnPercent => real().withDefault(const Constant(0))();
  BoolColumn get isPpnActive => boolean().withDefault(const Constant(false))();
  BoolColumn get isPendingDelete => boolean().withDefault(const Constant(false))();
  RealColumn get grandTotal => real().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {serverId};
}