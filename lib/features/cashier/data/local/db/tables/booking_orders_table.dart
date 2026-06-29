import 'package:drift/drift.dart';

class BookingOrders extends Table {
  TextColumn get clientUuid => text()();
  IntColumn get serverId => integer().nullable()();

  TextColumn get bookingOrderCode => text().nullable()();
  IntColumn get partnerId => integer().nullable()();
  TextColumn get partnerName => text().nullable()();
  IntColumn get tableId => integer().nullable()();
  TextColumn get tableNo => text().nullable()();
  IntColumn get customerId => integer().nullable()();
  IntColumn get employeeOrderId => integer().nullable()();
  TextColumn get orderBy => text().nullable()();
  TextColumn get customerName => text()();

  TextColumn get orderStatus => text().withDefault(const Constant('DRAFT'))();
  TextColumn get paymentMethod => text().nullable()();
  BoolColumn get openbillFlag => boolean().withDefault(const Constant(false))();

  IntColumn get discountId => integer().nullable()();
  RealColumn get discountValue => real().withDefault(const Constant(0))();
  RealColumn get totalOrderValue => real().withDefault(const Constant(0))();
  RealColumn get ppn => real().nullable()();
  BoolColumn get isPpnActive => boolean().withDefault(const Constant(false))();

  TextColumn get customerOrderNote => text().nullable()();
  TextColumn get employeeOrderNote => text().nullable()();

  IntColumn get cashierProcessId => integer().nullable()();
  IntColumn get kitchenProcessId => integer().nullable()();
  IntColumn get paymentId => integer().nullable()();
  BoolColumn get paymentFlag => boolean().withDefault(const Constant(false))();

  TextColumn get wifiSnapshotJson => text().nullable()();
  TextColumn get paymentRequestJson => text().nullable()();
  TextColumn get latestPaymentJson => text().nullable()();

  IntColumn get syncVersion => integer().withDefault(const Constant(0))();
  BoolColumn get syncDirty => boolean().withDefault(const Constant(false))();
  TextColumn get syncIntent => text().nullable()();
  TextColumn get syncError => text().nullable()();
  TextColumn get localFilePathsJson => text().nullable()();

  RealColumn get paidAmountLocal => real().nullable()();
  RealColumn get changeAmountLocal => real().nullable()();
  RealColumn get cashRoundingAmount => real().nullable()();
  IntColumn get cashRoundingUnit => integer().nullable()();
  IntColumn get latestPaymentServerId => integer().nullable()();

  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {clientUuid};
}
