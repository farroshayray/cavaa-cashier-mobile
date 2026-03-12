import 'package:drift/drift.dart';

class LocalPayments extends Table {
  TextColumn get localId => text()();
  TextColumn get orderLocalId => text()();

  IntColumn get serverPaymentId => integer().nullable()();

  TextColumn get paymentType => text()();
  IntColumn get manualPaymentServerId => integer().nullable()();

  RealColumn get amountBeforePpn => real().withDefault(const Constant(0))();
  RealColumn get ppn => real().withDefault(const Constant(0))();
  RealColumn get paidAmount => real().withDefault(const Constant(0))();
  RealColumn get changeAmount => real().withDefault(const Constant(0))();

  TextColumn get paymentStatus => text().withDefault(const Constant('PENDING'))();
  TextColumn get note => text().nullable()();

  TextColumn get proofImageLocalPath => text().nullable()();
  BoolColumn get proofImageUploaded => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAtLocal => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {localId};
}