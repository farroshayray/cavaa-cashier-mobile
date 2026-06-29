import 'package:drift/drift.dart';

class SyncConflicts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityTable => text()();
  IntColumn get serverId => integer().nullable()();
  TextColumn get clientUuid => text().nullable()();
  TextColumn get reason => text()();
  TextColumn get localSnapshotJson => text().nullable()();
  TextColumn get serverSnapshotJson => text().nullable()();
  TextColumn get suggestedResolution => text().nullable()();
  BoolColumn get isResolved => boolean().withDefault(const Constant(false))();
  TextColumn get resolutionChoice => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}
