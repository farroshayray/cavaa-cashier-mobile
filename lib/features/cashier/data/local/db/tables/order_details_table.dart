import 'package:drift/drift.dart';

class OrderDetails extends Table {
  TextColumn get clientDetailUuid => text()();
  IntColumn get serverId => integer().nullable()();
  TextColumn get bookingOrderClientUuid => text()();
  IntColumn get bookingOrderServerId => integer().nullable()();

  TextColumn get productCode => text().nullable()();
  TextColumn get productName => text().nullable()();
  IntColumn get partnerProductId => integer()();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  RealColumn get basePrice => real().withDefault(const Constant(0))();
  RealColumn get cogs => real().nullable()();
  RealColumn get optionsPrice => real().withDefault(const Constant(0))();
  TextColumn get customerNote => text().nullable()();

  IntColumn get promoId => integer().nullable()();
  RealColumn get promoAmount => real().nullable()();
  TextColumn get promoType => text().nullable()();

  TextColumn get status => text().nullable()();
  IntColumn get cashierProcessId => integer().nullable()();
  IntColumn get kitchenProcessId => integer().nullable()();

  IntColumn get syncVersion => integer().withDefault(const Constant(0))();
  BoolColumn get syncDirty => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {clientDetailUuid};
}
