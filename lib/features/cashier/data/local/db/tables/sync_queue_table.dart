import 'package:drift/drift.dart';

class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get entityType => text()();
  TextColumn get entityLocalId => text()();
  TextColumn get action => text()();

  IntColumn get dependsOnQueueId => integer().nullable()();

  TextColumn get payloadJson => text()();

  TextColumn get status => text().withDefault(const Constant('PENDING'))();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();

  TextColumn get lastError => text().nullable()();
  DateTimeColumn get nextRetryAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}