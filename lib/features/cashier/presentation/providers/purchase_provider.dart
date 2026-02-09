import 'package:flutter/material.dart';
import '../../data/models/purchase_models.dart';
import '/features/cashier/data/models/purchase_repository.dart';
import '/features/cashier/presentation/pages/tabs/modals/checkout_sheet.dart';

class PurchaseProvider extends ChangeNotifier {
  final PurchaseRepository repo;

  PurchaseProvider(this.repo);

  bool isLoading = false;
  String? error;

  List<Product> products = [];
  List<Category> categories = [];
  List<StoreTable> tables = [];


  // UI state
  int selectedCategoryId = -1; // -1 = All
  String query = '';

  // Cart: list of cart items (support options)
  final List<CartItem> cart = [];

  int get cartItemCount =>
    cart.fold<int>(0, (sum, item) => sum + item.qty);

  /// total harga semua item (untuk total di bar)
  num get cartGrandTotal =>
      cart.fold<num>(0, (sum, item) => sum + item.lineTotal);

  // ===== LOAD =====
  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final payload = await repo.fetchPurchaseData();

      products = payload.products;
      categories = payload.categories;

      tables = payload.tables;

      // ... logic lain (hot products, grouping, dst)
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> checkout({
    required String customerName,
    required StoreTable table,
    required String paymentMethod, // "CASH" / "QRIS"
  }) async {
    // 1) ambil token: sesuaikan fungsi token di repo kamu
    // contoh umum:
    final token = await repo.storage.getToken(); // <-- PAKAI repo (bukan repository)
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found');
    }

    final itemsPayload = cart.map((it) {
      final optionIds = it.selected.values.expand((s) => s).toList();

      return <String, dynamic>{
        "product_id": it.product.id,
        "qty": it.qty,
        "note": it.note,
        "option_ids": optionIds,
        "promo_id": it.product.promotion?.id,
      };
    }).toList();

    final resp = await repo.api.checkout(
      token: token,
      orderTable: table.id,
      orderName: customerName,
      paymentMethod: paymentMethod, // "CASH"/"QRIS"
      totalAmount: cartGrandTotal,
      items: itemsPayload,
    );

    // kalau CASH biasanya clear cart
    if (paymentMethod == "CASH") {
      cart.clear();
      notifyListeners();
    }

    return resp;
  }



  // ===== CART HELPERS =====

  // Total qty untuk satu product (semua varian/options dijumlah)
  int qtyOf(int productId) =>
      cart.where((e) => e.product.id == productId).fold<int>(0, (a, b) => a + b.qty);

  num get cartTotal => cart.fold<num>(0, (a, b) => a + b.lineTotal);

  // Tambah item (dengan options)
  void addWithOptions({
    required Product product,
    required int qty,
    required Map<int, Set<int>> selected, // groupId -> set<optionId>
    required String note,
  }) {
    if (!product.alwaysAvailable && product.quantityAvailable <= 0) return;

    // stok limit: total existing qty untuk product ini
    final currentTotal = qtyOf(product.id);
    if (!product.alwaysAvailable && (currentTotal + qty) > product.quantityAvailable) return;

    // hitung extra dari opsi
    num optionExtra = 0;

    for (final g in product.optionGroups) {
      final picked = selected[g.id] ?? <int>{};

      for (final optId in picked) {
        final matches = g.items.where((x) => x.id == optId);
        if (matches.isNotEmpty) {
          optionExtra += matches.first.price;
        }
      }
    }


    final unitFinal = product.price + optionExtra;

    // kalau mau: merge item yang sama persis (product + selected + note)
    final same = cart.indexWhere((c) =>
        c.product.id == product.id &&
        _sameSelected(c.selected, selected) &&
        c.note == note);

    if (same >= 0) {
      cart[same].qty += qty;
    } else {
      cart.add(CartItem(
        product: product,
        qty: qty,
        selected: selected,
        note: note,
        unitFinalPrice: unitFinal,
      ));
    }

    notifyListeners();
  }

  // tombol + simple (tanpa modal/options)
  // jika product punya optionGroups, seharusnya di UI kamu panggil open modal, bukan panggil add()
  void add(Product p) {
    if (!p.alwaysAvailable && p.quantityAvailable <= 0) return;

    final currentTotal = qtyOf(p.id);
    if (!p.alwaysAvailable && currentTotal >= p.quantityAvailable) return;

    // item simple = selected kosong, note kosong, unitFinal = price
    addWithOptions(product: p, qty: 1, selected: {}, note: '');
  }

  void minus(Product p) {
    // kurangi 1 dari item paling akhir untuk product tsb (simple behavior)
    final idx = cart.lastIndexWhere((c) => c.product.id == p.id);
    if (idx < 0) return;

    if (cart[idx].qty > 1) {
      cart[idx].qty -= 1;
    } else {
      cart.removeAt(idx);
    }
    notifyListeners();
  }

  bool _sameSelected(Map<int, Set<int>> a, Map<int, Set<int>> b) {
    if (a.length != b.length) return false;
    for (final k in a.keys) {
      final sa = a[k] ?? <int>{};
      final sb = b[k] ?? <int>{};
      if (sa.length != sb.length) return false;
      if (!sa.containsAll(sb)) return false;
    }
    return true;
  }

  // ===== FILTERING =====
  void setCategory(int categoryId) {
    selectedCategoryId = categoryId;
    notifyListeners();
  }

  void setQuery(String q) {
    query = q;
    notifyListeners();
  }

  List<Product> get filteredProducts {
    final q = query.trim().toLowerCase();
    return products.where((p) {
      final catOk = selectedCategoryId == -1 || p.categoryId == selectedCategoryId;
      if (!catOk) return false;
      if (q.isEmpty) return true;
      final name = p.name.toLowerCase();
      final desc = (p.description ?? '').toLowerCase();
      return name.contains(q) || desc.contains(q);
    }).toList();
  }

  List<Product> get hotProducts => filteredProducts.where((p) => p.isHot).toList();

  Map<int, List<Product>> get groupedByCategory {
    final list = filteredProducts.where((p) => !p.isHot).toList();
    final map = <int, List<Product>>{};
    for (final p in list) {
      map.putIfAbsent(p.categoryId, () => []).add(p);
    }
    for (final entry in map.entries) {
      entry.value.sort((a, b) => a.name.compareTo(b.name));
    }
    return map;
  }

  Category? categoryById(int id) {
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

    /// tambah qty untuk CartItem tertentu (by index)
  void incCartAt(int index) {
    if (index < 0 || index >= cart.length) return;

    final item = cart[index];
    final p = item.product;

    if (!p.alwaysAvailable) {
      final currentTotal = qtyOf(p.id);
      if (currentTotal >= p.quantityAvailable) return; // stop kalau stok habis
    }

    cart[index].qty += 1;
    notifyListeners();
  }

  /// kurang qty untuk CartItem tertentu (by index), kalau jadi 0 -> hapus
  void decCartAt(int index) {
    if (index < 0 || index >= cart.length) return;

    if (cart[index].qty > 1) {
      cart[index].qty -= 1;
    } else {
      cart.removeAt(index); // qty 0 -> remove
    }
    notifyListeners();
  }

  /// hapus item cart tertentu
  void removeCartAt(int index) {
    if (index < 0 || index >= cart.length) return;
    cart.removeAt(index);
    notifyListeners();
  }

}
