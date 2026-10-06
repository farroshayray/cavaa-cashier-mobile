import 'package:drift/drift.dart';

class OrderPayments extends Table {
  TextColumn get clientPaymentUuid => text()();
  IntColumn get serverId => integer().nullable()();
  TextColumn get bookingOrderClientUuid => text()();
  IntColumn get bookingOrderServerId => integer().nullable()();

  IntColumn get employeeId => integer().nullable()();
  IntColumn get customerId => integer().nullable()();
  TextColumn get customerName => text().nullable()();
  TextColumn get paymentType => text()();
  RealColumn get paidAmount => real().withDefault(const Constant(0))();
  RealColumn get changeAmount => real().withDefault(const Constant(0))();
  TextColumn get paymentStatus => text().withDefault(const Constant('PENDING'))();
  TextColumn get note => text().nullable()();
  RealColumn get ppn => real().nullable()();
  RealColumn get amountBeforePpn => real().nullable()();
  RealColumn get roundingAmount => real().nullable()();
  IntColumn get ownerManualPaymentId => integer().nullable()();
  TextColumn get manualProviderName => text().nullable()();
  TextColumn get manualProviderAccountName => text().nullable()();
  TextColumn get manualProviderAccountNo => text().nullable()();

  BoolColumn get syncDirty => boolean().withDefault(const Constant(false))();
  TextColumn get localFilePathsJson => text().nullable()();

  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {clientPaymentUuid};
}
