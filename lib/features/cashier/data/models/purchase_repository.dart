import '/features/cashier/data/models/purchase_models.dart';
import '/features/cashier/data/purchase_api.dart';

import 'package:flutter/foundation.dart';
import '/features/cashier/data/local/db/cashier_db.dart';
import '/features/cashier/data/local/db/daos/cache_dao.dart';
import '/features/cashier/data/local/db/mappers/purchase_cache_mapper.dart';

class PurchaseRepository {
  final PurchaseApi api;
  final CashierDb db;

  PurchaseRepository({
    required this.api,
    required this.db,
  });

  Future<PurchasePayload> fetchPurchaseData() async {
    try {
      final json = await api.getProducts();
      final payload = PurchasePayload.fromJson(json);

      final productRows = payload.products
          .map(PurchaseCacheMapper.toCachedProduct)
          .toList();

      final groupRows = payload.products
          .expand(PurchaseCacheMapper.toCachedOptionGroups)
          .toList();

      final itemRows = payload.products
          .expand(PurchaseCacheMapper.toCachedOptionItems)
          .toList();

      final tableRows = payload.tables
          .map(PurchaseCacheMapper.toCachedTable)
          .toList();

      final paymentRows = payload.paymentOptions
          .map(PurchaseCacheMapper.toCachedPayment)
          .toList();

      final categoryRows = payload.categories
        .map(PurchaseCacheMapper.toCachedCategory)
        .toList();

      final cacheDao = CacheDao(db);
      await cacheDao.replaceAllCache(
        categories: categoryRows,
        products: productRows,
        groups: groupRows,
        items: itemRows,
        tables: tableRows,
        payments: paymentRows,
      );

      debugPrint('✅ cache purchase data saved to local DB');
      debugPrint('categories: ${categoryRows.length}');
      debugPrint('products: ${productRows.length}');
      debugPrint('groups: ${groupRows.length}');
      debugPrint('items: ${itemRows.length}');
      debugPrint('tables: ${tableRows.length}');
      debugPrint('payments: ${paymentRows.length}');

      final savedProducts = await cacheDao.getProducts();
      final savedGroups = await cacheDao.getGroups();
      final savedItems = await cacheDao.getItems();
      final savedTables = await cacheDao.getTables();
      final savedPayments = await cacheDao.getPayments();
      final savedCategories = await cacheDao.getCategories();
      
      debugPrint('db categories: ${savedCategories.length}');
      debugPrint('✅ read-back from local DB');
      debugPrint('db products: ${savedProducts.length}');
      debugPrint('db groups: ${savedGroups.length}');
      debugPrint('db items: ${savedItems.length}');
      debugPrint('db tables: ${savedTables.length}');
      debugPrint('db payments: ${savedPayments.length}');

       // ✅ TAMBAHKAN DI SINI
      if (savedProducts.isNotEmpty) {
        debugPrint(
          'first product in db: '
          'serverId=${savedProducts.first.serverId}, '
          'name=${savedProducts.first.name}, '
          'price=${savedProducts.first.price}',
        );
      }

      if (savedTables.isNotEmpty) {
        debugPrint(
          'first table in db: '
          'serverId=${savedTables.first.serverId}, '
          'tableNo=${savedTables.first.tableNo}, '
          'status=${savedTables.first.status}',
        );
      }

      if (savedPayments.isNotEmpty) {
        debugPrint(
          'first payment in db: '
          'key=${savedPayments.first.localKey}, '
          'label=${savedPayments.first.label}, '
          'kind=${savedPayments.first.kind}',
        );
      }

      return payload;
    } catch (e) {
      debugPrint('fetchPurchaseData online failed: $e');

      final cacheDao = CacheDao(db);

      final products = await cacheDao.getProducts();
      final groups = await cacheDao.getGroups();
      final items = await cacheDao.getItems();
      final tables = await cacheDao.getTables();
      final payments = await cacheDao.getPayments();
      final categories = await cacheDao.getCategories();

      debugPrint('🔄 trying fallback from local DB...');
      debugPrint('fallback products: ${products.length}');
      debugPrint('fallback groups: ${groups.length}');
      debugPrint('fallback items: ${items.length}');
      debugPrint('fallback tables: ${tables.length}');
      debugPrint('fallback payments: ${payments.length}');
      debugPrint('fallback categories: ${categories.length}');

      if (products.isEmpty) {
        rethrow;
      }

      return PurchaseCacheMapper.buildPayloadFromCache(
        categories: categories,
        products: products,
        groups: groups,
        items: items,
        tables: tables,
        payments: payments,
      );
    }
  }
}
