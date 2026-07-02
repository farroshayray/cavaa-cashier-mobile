import 'package:cavaa_cashier/features/cashier/data/models/purchase_models.dart';
import 'package:cavaa_cashier/features/cashier/data/sync/purchase_stock_patcher.dart';
import 'package:flutter_test/flutter_test.dart';

Product _product({
  required int id,
  int qty = 10,
  bool alwaysAvailable = false,
}) {
  return Product(
    id: id,
    categoryId: 1,
    name: 'Product $id',
    description: null,
    price: 1000,
    isHot: false,
    isActive: true,
    quantityAvailable: qty,
    alwaysAvailable: alwaysAvailable,
    imagePath: null,
    promotion: null,
    stockType: 'direct',
    recipes: const [],
    optionGroups: const [],
  );
}

void main() {
  group('patchProductsStock', () {
    test('keeps all in-memory products and updates qty for matches', () {
      final current = List.generate(10, (i) => _product(id: i + 1, qty: 10));
      final fromCache = [
        _product(id: 2, qty: 3),
        _product(id: 5, qty: 0),
      ];

      final patched = patchProductsStock(current: current, fromCache: fromCache);

      expect(patched.length, 10);
      expect(patched[0].quantityAvailable, 10);
      expect(patched[1].quantityAvailable, 3);
      expect(patched[4].quantityAvailable, 0);
      expect(patched[9].quantityAvailable, 10);
    });

    test('appends new products from cache not present in memory', () {
      final current = [_product(id: 1)];
      final fromCache = [
        _product(id: 1, qty: 4),
        _product(id: 99, qty: 7),
      ];

      final patched = patchProductsStock(current: current, fromCache: fromCache);

      expect(patched.length, 2);
      expect(patched[0].quantityAvailable, 4);
      expect(patched[1].id, 99);
      expect(patched[1].quantityAvailable, 7);
    });

    test('returns current list when cache delta is empty', () {
      final current = [_product(id: 1), _product(id: 2)];
      final patched = patchProductsStock(current: current, fromCache: const []);

      expect(patched.length, 2);
      expect(patched[0].quantityAvailable, 10);
    });
  });
}
