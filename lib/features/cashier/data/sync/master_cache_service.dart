import 'package:flutter/foundation.dart';

import '/features/cashier/data/local/db/cashier_db.dart';
import '/features/cashier/data/local/db/daos/cache_dao.dart';
import '/features/cashier/data/local/db/mappers/purchase_cache_mapper.dart';
import '/features/cashier/data/models/purchase_models.dart';

import '/features/cashier/data/sync/manual_payment_image_cache.dart';

/// Persists master catalog JSON (from GET /products or sync pull master) into Drift cache.
class MasterCacheService {
  MasterCacheService(this.db);

  final CashierDb db;

  Future<PurchasePayload> saveAndBuildPayload(Map<String, dynamic> json) async {
    final payload = PurchasePayload.fromJson(json);

    final productRows =
        payload.products.map(PurchaseCacheMapper.toCachedProduct).toList();
    final groupRows =
        payload.products.expand(PurchaseCacheMapper.toCachedOptionGroups).toList();
    final itemRows =
        payload.products.expand(PurchaseCacheMapper.toCachedOptionItems).toList();
    final tableRows =
        payload.tables.map(PurchaseCacheMapper.toCachedTable).toList();
    final paymentRows = payload.allPaymentOptionsForCache
        .map(PurchaseCacheMapper.toCachedPayment)
        .toList();
    final categoryRows =
        payload.categories.map(PurchaseCacheMapper.toCachedCategory).toList();

    final cacheDao = CacheDao(db);
    await cacheDao.replaceAllCache(
      categories: categoryRows,
      products: productRows,
      groups: groupRows,
      items: itemRows,
      tables: tableRows,
      payments: paymentRows,
    );

    if (payload.partnerData != null) {
      await cacheDao.savePartnerSettings(
        PurchaseCacheMapper.toCachedPartnerSettings(payload.partnerData!),
      );
    }

    debugPrint(
      'MasterCacheService saved: products=${productRows.length} tables=${tableRows.length}',
    );

    await ManualPaymentImageCache.prefetchPaymentOptions(
      db: db,
      options: payload.allPaymentOptionsForCache,
    );

    return payload;
  }

  /// Merges an incremental master delta (e.g. stock-changed products only).
  Future<PurchasePayload?> mergeMasterPayload(Map<String, dynamic> json) async {
    final payload = PurchasePayload.fromJson(json);
    final cacheDao = CacheDao(db);

    final productRows =
        payload.products.map(PurchaseCacheMapper.toCachedProduct).toList();
    final groupRows =
        payload.products.expand(PurchaseCacheMapper.toCachedOptionGroups).toList();
    final itemRows =
        payload.products.expand(PurchaseCacheMapper.toCachedOptionItems).toList();

    if (productRows.isNotEmpty) {
      await cacheDao.upsertProductsAndOptions(
        products: productRows,
        groups: groupRows,
        items: itemRows,
      );
    }

    final categoryRows =
        payload.categories.map(PurchaseCacheMapper.toCachedCategory).toList();
    final tableRows =
        payload.tables.map(PurchaseCacheMapper.toCachedTable).toList();
    final paymentRows = payload.allPaymentOptionsForCache
        .map(PurchaseCacheMapper.toCachedPayment)
        .toList();

    if (categoryRows.isNotEmpty ||
        tableRows.isNotEmpty ||
        paymentRows.isNotEmpty) {
      await cacheDao.replaceCategoriesTablesPayments(
        categories: categoryRows,
        tables: tableRows,
        payments: paymentRows,
      );
    }

    if (payload.partnerData != null) {
      await cacheDao.savePartnerSettings(
        PurchaseCacheMapper.toCachedPartnerSettings(payload.partnerData!),
      );
    }

    debugPrint(
      'MasterCacheService merged: products=${productRows.length} '
      'categories=${categoryRows.length}',
    );

    if (payload.allPaymentOptionsForCache.isNotEmpty) {
      await ManualPaymentImageCache.prefetchPaymentOptions(
        db: db,
        options: payload.allPaymentOptionsForCache,
      );
    }

    return loadFromLocalCache();
  }

  Future<PurchasePayload?> loadFromLocalCache() async {
    final cacheDao = CacheDao(db);
    final products = await cacheDao.getProducts();
    if (products.isEmpty) return null;

    return PurchaseCacheMapper.buildPayloadFromCache(
      categories: await cacheDao.getCategories(),
      products: products,
      groups: await cacheDao.getGroups(),
      items: await cacheDao.getItems(),
      tables: await cacheDao.getTables(),
      payments: await cacheDao.getPayments(),
      partnerSettings: await cacheDao.getPartnerSettings(),
    );
  }
}
