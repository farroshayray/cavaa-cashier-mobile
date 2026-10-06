import 'package:drift/drift.dart';

class OrderDetailOptions extends Table {
  TextColumn get clientOptionUuid => text()();
  IntColumn get serverId => integer().nullable()();
  TextColumn get orderDetailClientUuid => text()();
  IntColumn get orderDetailServerId => integer().nullable()();

  IntColumn get optionId => integer()();
  TextColumn get parentName => text().nullable()();
  TextColumn get partnerProductOptionName => text().nullable()();
  RealColumn get price => real().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {clientOptionUuid};
}
