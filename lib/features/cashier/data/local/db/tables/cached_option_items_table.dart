import 'package:drift/drift.dart';

class CachedOptionItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverId => integer().unique()();

  IntColumn get groupServerId => integer()();
  IntColumn get productServerId => integer()();

  TextColumn get name => text()();
  RealColumn get price => real().withDefault(const Constant(0))();

  TextColumn get stockType => text().withDefault(const Constant('linked'))();
  IntColumn get quantityAvailable => integer().withDefault(const Constant(0))();
  BoolColumn get alwaysAvailable => boolean().withDefault(const Constant(false))();

  TextColumn get rawJson => text()();
  DateTimeColumn get cachedAt => dateTime()();
}