import 'package:drift/drift.dart';

class CachedPaymentOrderItems extends Table {
  IntColumn get serverDetailId => integer()();
  IntColumn get orderServerId => integer()();

  IntColumn get productServerId => integer().nullable()();
  TextColumn get productName => text()();

  RealColumn get basePrice => real().withDefault(const Constant(0))();
  RealColumn get promoAmount => real().withDefault(const Constant(0))();
  IntColumn get qty => integer().withDefault(const Constant(1))();
  TextColumn get customerNote => text().nullable()();

  @override
  Set<Column> get primaryKey => {serverDetailId};
}