import 'package:drift/drift.dart';

class CachedPartnerSettings extends Table {
  IntColumn get partnerId => integer()();
  TextColumn get name => text()();
  BoolColumn get isQrActive => boolean().withDefault(const Constant(false))();
  BoolColumn get isCashierActive => boolean().withDefault(const Constant(false))();
  BoolColumn get isOpenbill => boolean().withDefault(const Constant(false))();
  RealColumn get ppn => real().withDefault(const Constant(0))();
  BoolColumn get isPpnActive => boolean().withDefault(const Constant(false))();
  IntColumn get cashRoundingUnit => integer().withDefault(const Constant(0))();
  TextColumn get logo => text().nullable()();
  BoolColumn get printReceiptLogo =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {partnerId};
}
