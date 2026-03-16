import '/features/cashier/data/models/purchase_models.dart';
import '/features/cashier/data/purchase_api.dart';

import 'package:flutter/foundation.dart';
import '/features/cashier/data/local/db/cashier_db.dart';
import '/features/cashier/data/local/db/daos/cache_dao.dart';
import '/features/cashier/data/local/db/mappers/purchase_cache_mapper.dart';

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '/core/config/env.dart';


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
      for (final p in payload.paymentOptions) {
        debugPrint(
          'PAYLOAD PAYMENT => '
          'kind=${p.kind}, '
          'value=${p.value}, '
          'manualType=${p.manualType}, '
          'manualId=${p.manualId}, '
          'label=${p.label}, '
          'providerName=${p.providerName}, '
          'providerAccountName=${p.providerAccountName}, '
          'providerAccountNo=${p.providerAccountNo}, '
          'qrisImageUrl=${p.qrisImageUrl}, '
          'qrisImageLocalPath=${p.qrisImageLocalPath}',
        );
      }

      final enrichedPayments = <PaymentOption>[];

      for (final pmt in payload.paymentOptions) {
        String? localPath;
        if (pmt.qrisImageUrl != null && pmt.qrisImageUrl!.trim().isNotEmpty) {
          localPath = await _downloadManualPaymentImageToLocal(pmt.qrisImageUrl!);
        }

        enrichedPayments.add(
          PaymentOption(
            kind: pmt.kind,
            value: pmt.value,
            label: pmt.label,
            desc: pmt.desc,
            manualType: pmt.manualType,
            manualId: pmt.manualId,
            providerName: pmt.providerName,
            providerAccountName: pmt.providerAccountName,
            providerAccountNo: pmt.providerAccountNo,
            qrisImageUrl: pmt.qrisImageUrl,
            qrisImageLocalPath: localPath,
          ),
        );
      }

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

      final paymentRows = enrichedPayments
          .map(PurchaseCacheMapper.toCachedPayment)
          .toList();

      for (final row in paymentRows) {
        debugPrint(
          'PAYMENT ROW => '
          'localKey=${row.localKey.value}, '
          'kind=${row.kind.value}, '
          'serverManualPaymentId=${row.serverManualPaymentId.value}, '
          'label=${row.label.value}, '
          'providerName=${row.providerName.value}, '
          'providerAccountName=${row.providerAccountName.value}, '
          'providerAccountNo=${row.providerAccountNo.value}, '
          'qrisImageUrl=${row.qrisImageUrl.value}, '
          'qrisImageLocalPath=${row.qrisImageLocalPath.value}',
        );
      }

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

      for (final sp in savedPayments) {
        debugPrint(
          'DB PAYMENT => '
          'key=${sp.localKey}, '
          'kind=${sp.kind}, '
          'serverManualPaymentId=${sp.serverManualPaymentId}, '
          'label=${sp.label}, '
          'providerName=${sp.providerName}, '
          'providerAccountName=${sp.providerAccountName}, '
          'providerAccountNo=${sp.providerAccountNo}, '
          'qrisImageUrl=${sp.qrisImageUrl}, '
          'qrisImageLocalPath=${sp.qrisImageLocalPath}',
        );
      }
      
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

  Future<String?> _downloadManualPaymentImageToLocal(String rawPath) async {
    try {
      if (rawPath.trim().isEmpty) return null;

      final imageUrl = rawPath.startsWith('http')
          ? rawPath
          : '${Env.baseUrl}/storage/${rawPath.replaceFirst(RegExp(r'^\/?storage\/?'), '')}';

      final dir = await getApplicationDocumentsDirectory();
      final folder = Directory(p.join(dir.path, 'manual_payment_images'));
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }

      final ext = p.extension(Uri.parse(imageUrl).path);
      final safeExt = ext.isEmpty ? '.jpg' : ext;
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${rawPath.hashCode}$safeExt';

      final filePath = p.join(folder.path, fileName);

      final dio = Dio();
      await dio.download(imageUrl, filePath);

      final file = File(filePath);
      if (await file.exists()) return file.path;
      return null;
    } catch (_) {
      return null;
    }
  }
}
