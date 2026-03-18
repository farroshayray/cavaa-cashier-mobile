import 'package:drift/drift.dart';

class CachedOptionGroups extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverId => integer().unique()();

  IntColumn get productServerId => integer()();
  TextColumn get name => text()();

  IntColumn get minSelect => integer().withDefault(const Constant(0))();
  IntColumn get maxSelect => integer().withDefault(const Constant(0))();
  BoolColumn get requiredFlag => boolean().withDefault(const Constant(false))();

  TextColumn get rawJson => text()();
  DateTimeColumn get cachedAt => dateTime()();
}