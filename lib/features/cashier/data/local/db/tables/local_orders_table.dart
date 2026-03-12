import 'package:drift/drift.dart';

class LocalOrders extends Table {
  TextColumn get localId => text()();
  IntColumn get serverId => integer().nullable()();

  TextColumn get clientOrderCode => text().unique()();
  TextColumn get serverOrderCode => text().nullable()();

  IntColumn get partnerId => integer().nullable()();
  TextColumn get partnerName => text().nullable()();

  IntColumn get tableServerId => integer().nullable()();
  TextColumn get tableNoSnapshot => text().nullable()();

  TextColumn get customerName => text()();

  TextColumn get paymentMethodSelected => text().nullable()();
  TextColumn get paymentMethodEffective => text().nullable()();

  RealColumn get subtotal => real().withDefault(const Constant(0))();
  RealColumn get discountValue => real().withDefault(const Constant(0))();
  RealColumn get ppnPercent => real().withDefault(const Constant(0))();
  BoolColumn get isPpnActive => boolean().withDefault(const Constant(false))();
  RealColumn get grandTotal => real().withDefault(const Constant(0))();

  TextColumn get orderStatusLocal => text().withDefault(const Constant('DRAFT'))();
  TextColumn get syncStatus => text().withDefault(const Constant('PENDING'))();
  TextColumn get lastError => text().nullable()();

  DateTimeColumn get createdAtLocal => dateTime()();
  DateTimeColumn get updatedAtLocal => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {localId};
}