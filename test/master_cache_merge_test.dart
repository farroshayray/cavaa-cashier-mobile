import 'package:cavaa_cashier/features/cashier/data/local/db/cashier_db.dart';
import 'package:cavaa_cashier/features/cashier/data/sync/master_cache_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _productJson(int id, {int qty = 10}) {
  return {
    'id': id,
    'category_id': 1,
    'name': 'Product $id',
    'price': 1000,
    'stock_type': 'direct',
    'always_available_flag': false,
    'is_active': true,
    'is_hot_product': false,
    'parent_options': [],
    'recipes': [],
    'stock': {
      'quantity': qty,
      'quantity_reserved': 0,
    },
  };
}

Map<String, dynamic> _masterJson(List<Map<String, dynamic>> products) {
  return {
    'partner_products': products,
    'categories': [
      {'id': 1, 'name': 'Food', 'order': 1},
    ],
    'tables': [],
    'manualPaymentMethods': [],
    'partner_data': {
      'ppn': 0,
      'is_ppn_active': false,
      'cash_rounding_unit': 0,
    },
  };
}

void main() {
  group('MasterCacheService.mergeMasterPayload', () {
    late CashierDb db;
    late MasterCacheService service;

    setUp(() {
      db = CashierDb.forTesting(NativeDatabase.memory());
      service = MasterCacheService(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('incremental merge keeps all products and updates changed qty', () async {
      final full = _masterJson(
        List.generate(10, (i) => _productJson(i + 1, qty: 10)),
      );
      await service.saveAndBuildPayload(full);

      final delta = _masterJson([
        _productJson(2, qty: 3),
        _productJson(5, qty: 1),
      ]);
      await service.mergeMasterPayload(delta);

      final cached = await service.loadFromLocalCache();
      expect(cached, isNotNull);
      expect(cached!.products.length, 10);

      final byId = {for (final p in cached.products) p.id: p};
      expect(byId[1]!.quantityAvailable, 10);
      expect(byId[2]!.quantityAvailable, 3);
      expect(byId[5]!.quantityAvailable, 1);
      expect(byId[10]!.quantityAvailable, 10);
    });

    test('merge appends brand-new products from delta', () async {
      await service.saveAndBuildPayload(_masterJson([_productJson(1)]));

      await service.mergeMasterPayload(_masterJson([_productJson(99, qty: 4)]));

      final cached = await service.loadFromLocalCache();
      expect(cached!.products.length, 2);
      final byId = {for (final p in cached.products) p.id: p};
      expect(byId[99]!.quantityAvailable, 4);
    });
  });
}
