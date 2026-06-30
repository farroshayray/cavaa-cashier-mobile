import '/features/cashier/data/local/db/cashier_db.dart';

class CacheDao {
  final CashierDb db;
  CacheDao(this.db);

  Future<void> replaceAllCache({
    required List<CachedCategoriesCompanion> categories,
    required List<CachedProductsCompanion> products,
    required List<CachedOptionGroupsCompanion> groups,
    required List<CachedOptionItemsCompanion> items,
    required List<CachedTablesCompanion> tables,
    required List<CachedPaymentMethodsCompanion> payments,
  }) async {
    await db.transaction(() async {
      await db.delete(db.cachedOptionItems).go();
      await db.delete(db.cachedOptionGroups).go();
      await db.delete(db.cachedProducts).go();
      await db.delete(db.cachedCategories).go();
      await db.delete(db.cachedTables).go();
      await db.delete(db.cachedPaymentMethods).go();

      await db.batch((batch) {
        batch.insertAll(db.cachedCategories, categories);
        batch.insertAll(db.cachedProducts, products);
        batch.insertAll(db.cachedOptionGroups, groups);
        batch.insertAll(db.cachedOptionItems, items);
        batch.insertAll(db.cachedTables, tables);
        batch.insertAll(db.cachedPaymentMethods, payments);
      });
    });
  }

  Future<List<CachedCategory>> getCategories() =>
      db.select(db.cachedCategories).get();

  Future<List<CachedProduct>> getProducts() =>
      db.select(db.cachedProducts).get();

  Future<List<CachedTable>> getTables() =>
      db.select(db.cachedTables).get();

  Future<List<CachedPaymentMethod>> getPayments() =>
      db.select(db.cachedPaymentMethods).get();

  Future<List<CachedOptionGroup>> getGroups() =>
      db.select(db.cachedOptionGroups).get();

  Future<List<CachedOptionItem>> getItems() =>
      db.select(db.cachedOptionItems).get();

  Future<void> savePartnerSettings(CachedPartnerSettingsCompanion row) async {
    await db.into(db.cachedPartnerSettings).insertOnConflictUpdate(row);
  }

  Future<CachedPartnerSetting?> getPartnerSettings() async {
    final rows = await db.select(db.cachedPartnerSettings).get();
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<int> getPartnerCashRoundingUnit() async {
    final settings = await getPartnerSettings();
    return settings?.cashRoundingUnit ?? 0;
  }
}