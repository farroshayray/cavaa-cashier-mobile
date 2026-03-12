import 'package:drift/drift.dart';

class CachedProducts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverId => integer().unique()();

  TextColumn get name => text()();
  IntColumn get categoryId => integer()();
  RealColumn get price => real()();

  TextColumn get stockType => text().withDefault(const Constant('linked'))();
  IntColumn get quantityAvailable => integer().withDefault(const Constant(0))();
  BoolColumn get alwaysAvailable => boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  IntColumn get promoId => integer().nullable()();
  TextColumn get promoType => text().nullable()();
  RealColumn get promoValue => real().nullable()();

  TextColumn get imagePath => text().nullable()();
  TextColumn get description => text().nullable()();

  TextColumn get rawJson => text()();

  DateTimeColumn get updatedAtServer => dateTime().nullable()();
  DateTimeColumn get cachedAt => dateTime()();
}