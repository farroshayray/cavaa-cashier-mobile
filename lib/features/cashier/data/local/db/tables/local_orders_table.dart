import 'package:drift/drift.dart';

class LocalOrders extends Table {
  TextColumn get localId => text()();
  IntColumn get serverId => integer().nullable()();

  TextColumn get clientOrderCode => text().unique()();
  TextColumn get serverOrderCode => text().nullable()();

  IntColumn get partnerId => integer().nullable()();
  TextColumn get partnerName => text().nullable()();

  IntColumn get tableServerId => integer().nullable()();
  TextColumn get tableNoSnapshot => text().nullable()();

  TextColumn get customerName => text()();

  TextColumn get paymentMethodSelected => text().nullable()();
  TextColumn get paymentMethodEffective => text().nullable()();

  RealColumn get subtotal => real().withDefault(const Constant(0))();
  RealColumn get discountValue => real().withDefault(const Constant(0))();
  RealColumn get ppnPercent => real().withDefault(const Constant(0))();
  BoolColumn get isPpnActive => boolean().withDefault(const Constant(false))();
  RealColumn get grandTotal => real().withDefault(const Constant(0))();
  RealColumn get cashRoundingAmount => real().nullable()();
  IntColumn get cashRoundingUnit => integer().nullable()();

  RealColumn get paidAmountLocal => real().nullable()();
  RealColumn get changeAmountLocal => real().nullable()();
  TextColumn get cashierProofImageLocalPath => text().nullable()();
  DateTimeColumn get paymentConfirmedAtLocal => dateTime().nullable()();
  IntColumn get latestPaymentServerId => integer().nullable()();
  // snapshot detail order untuk print dan render tab proses saat offline
  TextColumn get orderSnapshotJson => text().nullable()();

  TextColumn get orderStatusLocal => text().withDefault(const Constant('DRAFT'))();
  TextColumn get syncStatus => text().withDefault(const Constant('PENDING'))();
  TextColumn get lastError => text().nullable()();

  IntColumn get manualPaymentServerId => integer().nullable()();
  TextColumn get manualPaymentType => text().nullable()();
  TextColumn get manualProviderName => text().nullable()();
  TextColumn get manualProviderAccountName => text().nullable()();
  TextColumn get manualProviderAccountNo => text().nullable()();
  TextColumn get manualQrisImageUrl => text().nullable()();
  TextColumn get manualQrisImageLocalPath => text().nullable()();
  TextColumn get manualPaymentLabel => text().nullable()();
  TextColumn get manualPaymentRawJson => text().nullable()();
  TextColumn get backendSyncStage => text().withDefault(const Constant('NONE'))();

  DateTimeColumn get createdAtLocal => dateTime()();
  DateTimeColumn get updatedAtLocal => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {localId};
}