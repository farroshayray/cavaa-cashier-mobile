import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../data/models/checkout_exceptions.dart';
import '../../data/models/purchase_models.dart';
import '/features/cashier/data/models/purchase_repository.dart';
import '/features/cashier/data/local/db/cashier_db.dart';
import 'dart:convert';

import 'package:uuid/uuid.dart';
import '/features/cashier/data/local/db/daos/booking_orders_dao.dart';
import '/features/cashier/data/local/db/sync/sync_service.dart';
import '/core/services/connectivity_status_provider.dart';

class PurchaseProvider extends ChangeNotifier {
  final PurchaseRepository repo;
  final BookingOrdersDao bookingOrdersDao;
  final ConnectivityStatusProvider connectivity;
  final SyncService? syncService;
  final Uuid _uuid = const Uuid();

  PurchaseProvider({
    required this.repo,
    required this.bookingOrdersDao,
    required this.connectivity,
    this.syncService,
  });

  bool isLoading = false;
  String? error;

  List<Product> products = [];
  List<Category> categories = [];
  List<StoreTable> tables = [];
  List<PaymentOption> paymentOptions = [];
  PartnerData? partnerData;

  List<MirrorPendingStockLine> _pendingStockLines = [];
  List<CartItem> _stockOverlayLines = [];

  /// Lines from edit-order sheet counted toward stock validation.
  void setStockOverlay(List<CartItem> lines) {
    _stockOverlayLines = List<CartItem>.from(lines);
  }

  void clearStockOverlay() {
    if (_stockOverlayLines.isEmpty) return;
    _stockOverlayLines = [];
  }

  Iterable<CartItem> _stockItems({CartItem? excludingItem}) sync* {
    for (final item in cart) {
      if (!identical(item, excludingItem)) yield item;
    }
    for (final item in _stockOverlayLines) {
      if (!identical(item, excludingItem)) yield item;
    }
  }

  // UI state
  int selectedCategoryId = -1; // -1 = All
  String query = '';

  // Cart: list of cart items (support options)
  final List<CartItem> cart = [];

  int get cartItemCount =>
    cart.fold<int>(0, (sum, item) => sum + item.qty);

  /// total harga semua item (untuk total di bar)
  num get cartGrandTotal =>
      cart.fold<num>(0, (sum, item) => sum + item.lineTotal); // subtotal sebelum PPN

  num get cartSubtotal =>
    cart.fold<num>(0, (sum, item) => sum + item.lineTotal);

  bool get isPpnActive =>
      partnerData?.isPpnActive == true;

  num get ppnPercent =>
      partnerData?.ppn ?? 0;

  num get cartPpnAmount {
    if (!isPpnActive) return 0;
    return cartSubtotal * (ppnPercent / 100);
  }

  num get cartGrandTotalWithPpn =>
      cartSubtotal + cartPpnAmount;

  num get cartGrandTotalRounded =>
    cartGrandTotalWithPpn.toDouble().ceil();

  int get cashRoundingUnit => partnerData?.cashRoundingUnit ?? 0;

  num get cartCashRoundingAmount =>
      _roundingAmount(cartGrandTotalRounded, cashRoundingUnit);

  num get cartCashPayableTotal =>
      cartGrandTotalRounded + cartCashRoundingAmount;

  num payableTotalForPayment(PaymentOption? payment) {
    return cartGrandTotalRounded;
  }

  num roundingAmountForPayment(PaymentOption? payment) {
    return 0;
  }

  num _roundingAmount(num amount, int unit) {
    if (unit <= 0 || amount <= 0) return 0;
    final rounded = ((amount / unit).ceil() * unit);
    return rounded - amount.ceil();
  }

  String _buildClientOrderCode() {
    final now = DateTime.now();
    final y = now.year.toString();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    return 'OFFLINE-$y$m$d-$hh$mm$ss';
  }

  String _normalizeGuestName(String name) {
    final cleaned = name.trim();
    if (cleaned.isEmpty) return 'guest';

    final lower = cleaned.toLowerCase();
    if (lower.startsWith('guest-')) return cleaned;

    return 'guest-$cleaned';
  }

  bool _isConnectionError(Object e) {
    if (e is DioException) {
      return e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.unknown;
    }
    final msg = e.toString().toLowerCase();
    return msg.contains('socketexception') ||
        msg.contains('failed host lookup') ||
        msg.contains('connection error');
  }

  Future<void> _applyPendingStockLines() async {
    try {
      _pendingStockLines = await bookingOrdersDao.getPendingStockLines();
    } catch (e) {
      debugPrint('Failed to load local pending stock usage: $e');
      _pendingStockLines = [];
    }
  }

  void _applyPayload(PurchasePayload payload) {
    products = payload.products;
    categories = payload.categories;
    paymentOptions = payload.paymentOptions;
    tables = payload.tables;
    partnerData = payload.partnerData;
  }

  /// Refresh pending stock reservation counts without a network catalog fetch.
  Future<void> refreshPendingStockOnly() async {
    await _applyPendingStockLines();
    notifyListeners();
  }

  // ===== LOAD =====
  Future<void> load() async {
    final hadCatalog = products.isNotEmpty;
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      if (!connectivity.isOnline) {
        final cached = await repo.loadFromLocalCache();
        if (cached != null) {
          _applyPayload(cached);
        } else if (!hadCatalog) {
          error =
              'Mode offline — data menu belum tersedia. Sambungkan internet untuk memuat menu.';
        }
        await _applyPendingStockLines();
        return;
      }

      final payload = await repo.fetchPurchaseData();
      _applyPayload(payload);
      await _applyPendingStockLines();
    } catch (e) {
      final cached = await repo.loadFromLocalCache();
      if (cached != null) {
        _applyPayload(cached);
        await _applyPendingStockLines();
        if (_isConnectionError(e)) {
          error = hadCatalog || products.isNotEmpty
              ? null
              : 'Mode offline — menampilkan data cache.';
        }
        return;
      }

      final msg = e.toString();
      if (msg.contains('404')) {
        error =
            'Data menu tidak dapat dimuat (endpoint tidak ditemukan). Pastikan backend sudah di-update dan coba lagi.';
      } else if (_isConnectionError(e) && (hadCatalog || products.isNotEmpty)) {
        error = null;
        await _applyPendingStockLines();
      } else if (_isConnectionError(e)) {
        error = 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
      } else {
        error = msg;
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> checkout({
    required String customerName,
    required StoreTable table,
    required String paymentMethod,
    required PaymentOption payment,
  }) async {
    final normalizedCustomerName = customerName;

    final localOrderId = await _saveOrderToMirror(
      customerName: normalizedCustomerName,
      table: table,
      paymentMethod: paymentMethod,
      payment: payment,
    );

    if (paymentMethod != 'QRIS') {
      cart.clear();
    }
    notifyListeners();

    if (syncService != null) {
      try {
        await syncService!.syncPendingOrders();
      } catch (e) {
        debugPrint('checkout post-sync failed: $e');
      }
    }

    return {
      'status': true,
      'message': 'Order disimpan, menunggu sinkronisasi',
      'local_order_id': localOrderId,
      'saved_local': true,
      'offline': true,
    };
  }

  Future<String> _saveOrderToMirror({
    required String customerName,
    required StoreTable table,
    required String paymentMethod,
    required PaymentOption payment,
  }) async {
    final subtotal = cartSubtotal.toDouble();
    final ppn = ppnPercent.toDouble();
    final grandTotal = cartGrandTotalRounded.toDouble();

    final selectedPaymentMethod = paymentMethod;
    final effectivePaymentMethod =
      payment.isOpenbill
          ? 'OPENBILL'
          : payment.kind == PayKind.manual
              ? (payment.manualType ?? paymentMethod)
              : payment.backendPaymentMethod;
    String? manualPaymentRawJson;

    if (payment.kind == PayKind.manual) {
      manualPaymentRawJson = jsonEncode({
        'id': payment.manualId,
        'payment_type': payment.manualType,
        'provider_name': payment.providerName ?? payment.label,
        'provider_account_name': payment.providerAccountName,
        'provider_account_no': payment.providerAccountNo,
        'qris_image_url': payment.qrisImageUrl,
        'qris_image_local_path': payment.qrisImageLocalPath,
        'label': payment.label,
        'desc': payment.desc,
      });
    }

    final cartItems = <Map<String, dynamic>>[];
    for (final cartItem in cart) {
      num optionsPrice = 0;
      final optionsForThisItem = <Map<String, dynamic>>[];

      for (final group in cartItem.product.optionGroups) {
        final selectedIds = cartItem.selected[group.id] ?? <int>{};
        for (final optId in selectedIds) {
          final opt = group.items.cast<OptionItem?>().firstWhere(
                (x) => x?.id == optId,
                orElse: () => null,
              );
          if (opt != null) {
            optionsPrice += opt.price;
            optionsForThisItem.add({
              'option_id': opt.id,
              'name': opt.name,
              'parent_name': group.name,
              'price': opt.price,
            });
          }
        }
      }

      final promo = cartItem.product.promotion;
      num promoAmount = 0;
      if (promo != null) {
        if (promo.type == 'percentage') {
          promoAmount = cartItem.product.price.toDouble() -
              _promoFinalUnitPrice(cartItem.product).toDouble();
        } else {
          promoAmount = promo.value;
        }
      }

      cartItems.add({
        'product_id': cartItem.product.id,
        'product_name': cartItem.product.name,
        'base_price': cartItem.product.price.toDouble(),
        'qty': cartItem.qty,
        'note': cartItem.note.isEmpty ? null : cartItem.note,
        'options_price': optionsPrice.toDouble(),
        'promo_id': promo?.id,
        'promo_type': promo?.type,
        'promo_amount': promoAmount.toDouble(),
        'options': optionsForThisItem,
      });
    }

    final pd = partnerData;
    final wifiSnapshotJson = pd == null
        ? null
        : jsonEncode(pd.toWifiSnapshotMap());

    return bookingOrdersDao.createCheckoutOrder(
      customerName: customerName,
      tableId: table.id,
      tableNo: table.tableNo,
      paymentMethodSelected: selectedPaymentMethod,
      paymentMethodEffective: effectivePaymentMethod,
      openbillFlag: payment.isOpenbill,
      subtotal: subtotal,
      grandTotal: grandTotal,
      ppn: ppn,
      isPpnActive: isPpnActive,
      cashRoundingAmount: 0,
      cashRoundingUnit: cashRoundingUnit,
      partnerId: partnerData?.id,
      partnerName: partnerData?.name,
      manualPaymentRawJson: manualPaymentRawJson,
      wifiSnapshotJson: wifiSnapshotJson,
      cartItems: cartItems,
    );
  }


  // ===== CART HELPERS =====

  // Total qty untuk satu product (semua varian/options dijumlah)
  int qtyOf(int productId) =>
      cart.where((e) => e.product.id == productId).fold<int>(0, (a, b) => a + b.qty);

  int _qtyOfProduct(int productId, {CartItem? excludingItem}) => _stockItems(
        excludingItem: excludingItem,
      )
      .where((e) => e.product.id == productId)
      .fold<int>(0, (sum, item) => sum + item.qty);

  int _pendingQtyOfProduct(int productId) => _pendingStockLines
      .where((line) => line.productId == productId)
      .fold<int>(0, (sum, line) => sum + line.qty);

  int qtyOfOption(int optionId) {
    return cart
        .where((item) => item.selected.values.any((ids) => ids.contains(optionId)))
        .fold<int>(0, (sum, item) => sum + item.qty);
  }

  int _qtyOfOption(int optionId, {CartItem? excludingItem}) {
    return _stockItems(excludingItem: excludingItem)
        .where((item) =>
            item.selected.values.any((ids) => ids.contains(optionId)))
        .fold<int>(0, (sum, item) => sum + item.qty);
  }

  int _pendingQtyOfOption(int optionId) => _pendingStockLines
      .where((line) => line.optionIds.contains(optionId))
      .fold<int>(0, (sum, line) => sum + line.qty);

  Product? _productById(int productId) {
    for (final product in products) {
      if (product.id == productId) return product;
    }
    return null;
  }

  OptionItem? _optionById(Product product, int optionId) {
    for (final group in product.optionGroups) {
      for (final option in group.items) {
        if (option.id == optionId) return option;
      }
    }
    return null;
  }

  Map<int, double> _rawUsage({
    CartItem? excludingItem,
    bool includePendingLocal = true,
  }) {
    final usage = <int, double>{};

    void addRecipes(List<StockRecipe> recipes, int qty) {
      for (final recipe in recipes) {
        if (recipe.stockId <= 0 || recipe.quantityUsed <= 0) continue;
        usage[recipe.stockId] =
            (usage[recipe.stockId] ?? 0) + (recipe.quantityUsed * qty);
      }
    }

    for (final item in _stockItems(excludingItem: excludingItem)) {

      if (item.product.stockType == 'linked' &&
          item.product.recipes.isNotEmpty) {
        addRecipes(item.product.recipes, item.qty);
      }

      for (final group in item.product.optionGroups) {
        final picked = item.selected[group.id] ?? <int>{};
        for (final option in group.items) {
          if (!picked.contains(option.id)) continue;
          if (option.stockType != 'linked' || option.recipes.isEmpty) continue;
          addRecipes(option.recipes, item.qty);
        }
      }
    }

    if (includePendingLocal) {
      for (final line in _pendingStockLines) {
        final product = _productById(line.productId);
        if (product == null) continue;

        if (product.stockType == 'linked' && product.recipes.isNotEmpty) {
          addRecipes(product.recipes, line.qty);
        }

        for (final optionId in line.optionIds) {
          final option = _optionById(product, optionId);
          if (option == null) continue;
          if (option.stockType != 'linked' || option.recipes.isEmpty) continue;
          addRecipes(option.recipes, line.qty);
        }
      }
    }

    return usage;
  }

  int _availableQtyFromRecipes(
    List<StockRecipe> recipes, {
    CartItem? excludingItem,
  }) {
    if (recipes.isEmpty) return 999999;

    final usage = _rawUsage(excludingItem: excludingItem);
    var maxQty = 999999;

    for (final recipe in recipes) {
      if (recipe.stockId <= 0 || recipe.quantityUsed <= 0) continue;
      final remaining =
          recipe.availableQuantity - (usage[recipe.stockId] ?? 0);
      final portions = (remaining / recipe.quantityUsed).floor();
      if (portions < maxQty) maxQty = portions;
    }

    return maxQty < 0 ? 0 : maxQty;
  }

  int availableQtyForProduct(Product product, {CartItem? excludingItem}) {
    if (product.stockType == 'linked' && product.recipes.isNotEmpty) {
      return _availableQtyFromRecipes(
        product.recipes,
        excludingItem: excludingItem,
      );
    }
    if (product.alwaysAvailable) return 999999;

    final remaining =
        product.quantityAvailable -
            _qtyOfProduct(product.id, excludingItem: excludingItem) -
            _pendingQtyOfProduct(product.id);
    return remaining < 0 ? 0 : remaining;
  }

  int availableQtyForOption(OptionItem option, {CartItem? excludingItem}) {
    if (option.stockType == 'linked' && option.recipes.isNotEmpty) {
      return _availableQtyFromRecipes(
        option.recipes,
        excludingItem: excludingItem,
      );
    }
    if (option.alwaysAvailable) return 999999;

    final remaining =
        option.quantityAvailable -
            _qtyOfOption(option.id, excludingItem: excludingItem) -
            _pendingQtyOfOption(option.id);
    return remaining < 0 ? 0 : remaining;
  }

  int availableQtyForOptionOnProductLine({
    required Product product,
    required OptionItem option,
    required int qty,
    required Map<int, Set<int>> selected,
    CartItem? excludingItem,
  }) {
    if (option.stockType == 'linked' && option.recipes.isNotEmpty) {
      final usage = _rawUsage(excludingItem: excludingItem);

      void reserveRecipes(List<StockRecipe> recipes) {
        for (final recipe in recipes) {
          if (recipe.stockId <= 0 || recipe.quantityUsed <= 0) continue;
          usage[recipe.stockId] =
              (usage[recipe.stockId] ?? 0) + (recipe.quantityUsed * qty);
        }
      }

      if (product.stockType == 'linked' && product.recipes.isNotEmpty) {
        reserveRecipes(product.recipes);
      }

      for (final group in product.optionGroups) {
        final picked = selected[group.id] ?? <int>{};
        final sameSingleChoiceGroup =
            !group.multiple && group.items.any((item) => item.id == option.id);
        if (sameSingleChoiceGroup) continue;

        for (final selectedOption in group.items) {
          if (selectedOption.id == option.id) continue;
          if (!picked.contains(selectedOption.id)) continue;
          if (selectedOption.stockType != 'linked' ||
              selectedOption.recipes.isEmpty) {
            continue;
          }
          reserveRecipes(selectedOption.recipes);
        }
      }

      var maxQty = 999999;
      for (final recipe in option.recipes) {
        if (recipe.stockId <= 0 || recipe.quantityUsed <= 0) continue;
        final remaining =
            recipe.availableQuantity - (usage[recipe.stockId] ?? 0);
        final portions = (remaining / recipe.quantityUsed).floor();
        if (portions < maxQty) maxQty = portions;
      }

      return maxQty < 0 ? 0 : maxQty;
    }

    return availableQtyForOption(option, excludingItem: excludingItem);
  }

  int maxAddableQtyWithOptions({
    required Product product,
    required Map<int, Set<int>> selected,
    CartItem? excludingItem,
  }) {
    var maxQty = 999999;

    if (product.stockType == 'linked' && product.recipes.isNotEmpty) {
      // Linked products are handled together with linked options below,
      // because they may consume the same raw stock in one cart line.
    } else {
      if (!product.alwaysAvailable) {
        final available = product.quantityAvailable -
            _qtyOfProduct(product.id, excludingItem: excludingItem) -
            _pendingQtyOfProduct(product.id);
        if (available < maxQty) maxQty = available;
      }
    }

    final rawPerUnit = <int, double>{};
    final rawAvailable = <int, double>{};
    final rawUsed = _rawUsage(excludingItem: excludingItem);

    void addRawRecipes(List<StockRecipe> recipes) {
      for (final recipe in recipes) {
        if (recipe.stockId <= 0 || recipe.quantityUsed <= 0) continue;
        rawPerUnit[recipe.stockId] =
            (rawPerUnit[recipe.stockId] ?? 0) + recipe.quantityUsed;
        rawAvailable[recipe.stockId] = recipe.availableQuantity;
      }
    }

    if (product.stockType == 'linked' &&
        product.recipes.isNotEmpty) {
      addRawRecipes(product.recipes);
    }

    for (final group in product.optionGroups) {
      final picked = selected[group.id] ?? <int>{};
      for (final optId in picked) {
        final option = group.items.cast<OptionItem?>().firstWhere(
              (item) => item?.id == optId,
              orElse: () => null,
            );
        if (option == null) continue;

        if (option.stockType == 'linked' && option.recipes.isNotEmpty) {
          addRawRecipes(option.recipes);
        } else if (!option.alwaysAvailable) {
          final available = option.quantityAvailable -
              _qtyOfOption(option.id, excludingItem: excludingItem) -
              _pendingQtyOfOption(option.id);
          if (available < maxQty) maxQty = available;
        }
      }
    }

    rawPerUnit.forEach((stockId, requiredPerUnit) {
      if (requiredPerUnit <= 0) return;
      final remaining = (rawAvailable[stockId] ?? 0) - (rawUsed[stockId] ?? 0);
      final availableQty = (remaining / requiredPerUnit).floor();
      if (availableQty < maxQty) maxQty = availableQty;
    });

    return maxQty < 0 ? 0 : maxQty;
  }

  bool canAddWithOptions({
    required Product product,
    required int qty,
    required Map<int, Set<int>> selected,
    CartItem? excludingItem,
  }) {
    if (!product.isAvailableForSale) return false;

    for (final group in product.optionGroups) {
      final picked = selected[group.id] ?? <int>{};
      if (picked.length < group.min) return false;
      if (group.max > 0 && picked.length > group.max) return false;

      for (final optId in picked) {
        final option = group.items.cast<OptionItem?>().firstWhere(
              (item) => item?.id == optId,
              orElse: () => null,
            );

        if (option == null || !option.isAvailableForSale) return false;
      }
    }

    return qty <= maxAddableQtyWithOptions(
      product: product,
      selected: selected,
      excludingItem: excludingItem,
    );
  }

  num get cartTotal => cart.fold<num>(0, (a, b) => a + b.lineTotal);

  // Tambah item (dengan options)
  void addWithOptions({
    required Product product,
    required int qty,
    required Map<int, Set<int>> selected, // groupId -> set<optionId>
    required String note,
  }) {
    if (!canAddWithOptions(
      product: product,
      qty: qty,
      selected: selected,
    )) {
      return;
    }

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


    final baseAfterPromo = _promoFinalUnitPrice(product);
    final unitFinal = baseAfterPromo + optionExtra;

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
    if (!canAddWithOptions(
      product: p,
      qty: 1,
      selected: const {},
    )) {
      return;
    }

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

  String _manualTypeLabelFromMethod(String method) {
    if (method == 'manual_tf') return 'Transfer Manual';
    if (method == 'manual_ewallet') return 'E-Wallet';
    if (method == 'manual_qris') return 'QR Statis';
    return method;
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

    if (!canAddWithOptions(
      product: p,
      qty: item.qty + 1,
      selected: item.selected,
      excludingItem: item,
    )) {
      return;
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

  /// set qty secara spesifik untuk produk (hanya efektif untuk produk TANPA opsi)
  void setCartQtyForProduct(Product product, int newQty) {
    final index = cart.indexWhere((c) => c.product.id == product.id);
    
    if (index >= 0) {
      // Jika produk sudah ada di cart
      if (newQty < 1) {
        cart.removeAt(index);
        notifyListeners();
        return;
      }

      final item = cart[index];
      final max = maxAddableQtyWithOptions(
        product: product,
        selected: item.selected,
        excludingItem: item,
      );

      var finalQty = newQty > max ? max : newQty;
      if (finalQty < 1) finalQty = 1;

      cart[index].qty = finalQty;
      notifyListeners();
    } else if (newQty > 0) {
      // Jika belum ada di cart, kita tambahkan
      // (asumsi: hanya dipanggil untuk produk tanpa opsi)
      final max = maxAddableQtyWithOptions(
        product: product,
        selected: const {},
      );

      var finalQty = newQty > max ? max : newQty;
      if (finalQty > 0) {
        addWithOptions(
          product: product,
          qty: finalQty,
          selected: const {},
          note: '',
        );
      }
    }
  }

  /// set qty untuk CartItem tertentu (by index)
  void setCartQtyAt(int index, int newQty) {
    if (index < 0 || index >= cart.length) return;

    if (newQty < 1) {
      cart.removeAt(index);
      notifyListeners();
      return;
    }

    final item = cart[index];
    final max = maxAddableQtyWithOptions(
      product: item.product,
      selected: item.selected,
      excludingItem: item,
    );

    var finalQty = newQty > max ? max : newQty;
    if (finalQty < 1) finalQty = 1; // Jangan otomatis terhapus jika max < 1, cukup di-clamp ke 1 dan biarkan warning muncul

    cart[index].qty = finalQty;
    notifyListeners();
  }

  void clearCartAndReset() {
    cart.clear();
    selectedCategoryId = -1;
    query = '';
    notifyListeners();
  }

  num _promoFinalUnitPrice(Product p) {
    final promo = p.promotion;
    final base = p.price; // num
    if (promo == null) return base;

    final v = promo.value; // num
    if (promo.type == 'percentage') {
      final pct = (v.toDouble() / 100.0);
      final after = base.toDouble() * (1.0 - pct);
      return after < 0 ? 0 : after;
    } else {
      // amount
      final after = base.toDouble() - v.toDouble();
      return after < 0 ? 0 : after;
    }
  }
}
