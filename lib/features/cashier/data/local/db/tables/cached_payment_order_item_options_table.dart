import 'package:drift/drift.dart';

class CachedPaymentOrderItemOptions extends Table {
  IntColumn get serverDetailOptionId => integer()();
  IntColumn get orderDetailServerId => integer()();

  TextColumn get parentName => text().nullable()();
  TextColumn get optionName => text()();
  RealColumn get price => real().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {serverDetailOptionId};
}