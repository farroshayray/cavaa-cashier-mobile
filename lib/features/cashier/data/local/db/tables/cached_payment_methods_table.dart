import 'package:drift/drift.dart';

class CachedPaymentMethods extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get localKey => text().unique()();
  TextColumn get kind => text()(); // cash, qris, manual
  IntColumn get serverManualPaymentId => integer().nullable()();

  TextColumn get label => text()();
  TextColumn get providerName => text().nullable()();
  TextColumn get providerAccountName => text().nullable()();
  TextColumn get providerAccountNo => text().nullable()();
  TextColumn get qrisImageUrl => text().nullable()();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  TextColumn get rawJson => text()();
  DateTimeColumn get cachedAt => dateTime()();
}