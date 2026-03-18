import 'package:drift/drift.dart';

class LocalOrderItemOptions extends Table {
  TextColumn get localId => text()();
  TextColumn get orderItemLocalId => text()();

  IntColumn get serverOrderDetailOptionId => integer().nullable()();
  IntColumn get optionServerId => integer()();

  TextColumn get parentNameSnapshot => text().nullable()();
  TextColumn get optionNameSnapshot => text()();
  RealColumn get price => real().withDefault(const Constant(0))();

  DateTimeColumn get createdAtLocal => dateTime()();

  @override
  Set<Column> get primaryKey => {localId};
}