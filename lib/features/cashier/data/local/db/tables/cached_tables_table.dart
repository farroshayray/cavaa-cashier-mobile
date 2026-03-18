import 'package:drift/drift.dart';

class CachedTables extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverId => integer().unique()();

  TextColumn get tableNo => text()();
  TextColumn get tableCode => text().nullable()();
  TextColumn get tableClass => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('available'))();

  TextColumn get imagePath => text().nullable()();
  TextColumn get tableUrl => text().nullable()();

  TextColumn get rawJson => text()();
  DateTimeColumn get cachedAt => dateTime()();
}