import 'package:drift/drift.dart';

class CachedCategories extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverId => integer().unique()();

  TextColumn get name => text()();
  IntColumn get order => integer().withDefault(const Constant(99999))();

  TextColumn get rawJson => text()();
  DateTimeColumn get cachedAt => dateTime()();
}