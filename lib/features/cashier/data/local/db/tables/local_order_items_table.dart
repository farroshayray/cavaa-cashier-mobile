import 'package:drift/drift.dart';

class LocalOrderItems extends Table {
  TextColumn get localId => text()();
  TextColumn get orderLocalId => text()();

  IntColumn get serverOrderDetailId => integer().nullable()();
  IntColumn get productServerId => integer()();

  TextColumn get productNameSnapshot => text()();
  RealColumn get basePrice => real().withDefault(const Constant(0))();

  IntColumn get promoId => integer().nullable()();
  TextColumn get promoType => text().nullable()();
  RealColumn get promoAmount => real().nullable()();

  RealColumn get optionsPrice => real().withDefault(const Constant(0))();
  IntColumn get qty => integer()();
  TextColumn get customerNote => text().nullable()();
  RealColumn get lineTotal => real().withDefault(const Constant(0))();

  DateTimeColumn get createdAtLocal => dateTime()();

  @override
  Set<Column> get primaryKey => {localId};
}