import '/core/config/env.dart';

class PurchasePayload {
  final List<Product> products;
  final List<Category> categories;
  final List<StoreTable> tables;
  final List<PaymentOption> paymentOptions;
  final List<PaymentOption> allPaymentOptionsForCache;
  final PartnerData? partnerData;

  PurchasePayload({
    required this.products,
    required this.categories,
    required this.tables,
    required this.paymentOptions,
    required this.allPaymentOptionsForCache,
    required this.partnerData,
  });

  static List<PaymentOption> buildPurchasePaymentOptions(PartnerData? partnerData) {
    final paymentOptions = <PaymentOption>[];

    if (partnerData?.isCashierActive == true) {
      paymentOptions.add(
        const PaymentOption(
          kind: PayKind.cashierCash,
          value: 'CASH',
          label: 'Bayar Sekarang',
        ),
      );
    }

    if (partnerData?.isOpenbillActive == true) {
      paymentOptions.add(
        const PaymentOption(
          kind: PayKind.openbill,
          value: 'OPENBILL',
          label: 'Bayar Nanti',
        ),
      );
    }

    return paymentOptions;
  }

  static List<PaymentOption> buildAllPaymentOptionsForCache(
    Map<String, dynamic> json, {
    PartnerData? partnerData,
  }) {
    final paymentOptions = <PaymentOption>[];

    if (partnerData?.isCashierActive == true) {
      paymentOptions.add(
        const PaymentOption(
          kind: PayKind.cashierCash,
          value: 'CASH',
          label: 'Cash (Kasir)',
        ),
      );
    }

    if (partnerData?.isQrisActive == true) {
      paymentOptions.add(
        const PaymentOption(
          kind: PayKind.onlineQris,
          value: 'QRIS',
          label: 'QRIS (Xendit)',
        ),
      );
    }

    if (partnerData?.isOpenbillActive == true) {
      paymentOptions.add(
        const PaymentOption(
          kind: PayKind.openbill,
          value: 'OPENBILL',
          label: 'Bayar Nanti',
        ),
      );
    }

    paymentOptions.addAll(parseManualPaymentOptions(json));
    return paymentOptions;
  }

  factory PurchasePayload.fromJson(Map<String, dynamic> json) {

    final productsJson = (json['partner_products'] as List? ?? const []);

    final products = productsJson
        .whereType<Map>()
        .map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final categoriesJson = (json['categories'] as List? ?? const []);
    var categories = categoriesJson
        .whereType<Map>()
        .map((e) => Category.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    if (categories.isEmpty) {
      final map = <int, Category>{};
      for (final raw in productsJson.whereType<Map>()) {
        final catRaw = raw['category'];
        if (catRaw is Map) {
          final c = Category.fromJson(Map<String, dynamic>.from(catRaw));
          map[c.id] = c;
        }
      }
      categories = map.values.toList()
        ..sort((a, b) => a.order.compareTo(b.order));
    }

    final tablesJson = (json['tables'] as List? ?? const []);
    final tables = tablesJson
        .whereType<Map>()
        .map((e) => StoreTable.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    // ✅ parse partner_data
    PartnerData? partnerData;
    final partnerRaw = json['partner_data'];
    if (partnerRaw is Map) {
      partnerData = PartnerData.fromJson(Map<String, dynamic>.from(partnerRaw));
    }

    final paymentOptions = buildPurchasePaymentOptions(partnerData);
    final allPaymentOptionsForCache =
        buildAllPaymentOptionsForCache(json, partnerData: partnerData);

    return PurchasePayload(
      products: products,
      categories: categories,
      tables: tables,
      paymentOptions: paymentOptions,
      allPaymentOptionsForCache: allPaymentOptionsForCache,
      partnerData: partnerData,
    );
  }
}

class PartnerData {
  final int id;
  final String name;
  final bool isQrisActive;
  final bool isCashierActive;
  final bool isOpenbillActive;

  final num ppn;
  final bool isPpnActive;
  final int cashRoundingUnit;
  final bool isWifiShown;
  final String? wifiUser;
  final String? wifiPassword;
  final String? address;

  PartnerData({
    required this.id,
    required this.name,
    required this.isQrisActive,
    required this.isCashierActive,
    required this.isOpenbillActive,
    required this.ppn,
    required this.isPpnActive,
    required this.cashRoundingUnit,
    this.isWifiShown = false,
    this.wifiUser,
    this.wifiPassword,
    this.address,
  });

  factory PartnerData.fromJson(Map<String, dynamic> json) {
    return PartnerData(
      id: parseInt(json['id']),
      name: (json['name'] ?? '').toString(),
      isQrisActive: parseBool(json['is_qr_active']),
      isCashierActive: parseBool(json['is_cashier_active']),
      isOpenbillActive: parseBool(json['is_openbill']),
      ppn: parseNum(json['ppn']),
      isPpnActive: parseBool(json['is_ppn_active']),
      cashRoundingUnit: parseInt(json['cash_rounding_unit']),
      isWifiShown: parseBool(json['is_wifi_shown']),
      wifiUser: json['user_wifi']?.toString(),
      wifiPassword: json['pass_wifi']?.toString(),
      address: json['address']?.toString(),
    );
  }

  Map<String, dynamic> toWifiSnapshotMap() {
    return {
      'wifi_shown': isWifiShown ? 1 : 0,
      if (wifiUser != null && wifiUser!.trim().isNotEmpty) 'wifi_ssid': wifiUser,
      if (wifiPassword != null && wifiPassword!.trim().isNotEmpty)
        'wifi_password': wifiPassword,
      if (address != null && address!.trim().isNotEmpty)
        'store_address': address,
    };
  }
}

class Category {
  final int id;
  final String name;
  final int order;

  Category({
    required this.id,
    required this.name,
    required this.order,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: parseInt(json['id']),
      name: (json['category_name'] ?? json['name'] ?? '').toString(),
      order: parseInt(json['category_order'] ?? json['order'], defaultValue: 99999),
    );
  }
}

class Promotion {
  final int id;
  final String type; // percentage | nominal
  final num value;

  Promotion({required this.id, required this.type, required this.value});

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      id: parseInt(json['id']),
      type: (json['promotion_type'] ?? json['type'] ?? '').toString(),
      value: parseNum(json['promotion_value'] ?? json['value']),
    );
  }
}

class Product {
  final int id;
  final int categoryId;
  final String name;
  final String? description;
  final num price;
  final bool isHot;
  final bool isActive;

  final int quantityAvailable;
  final bool alwaysAvailable;

  final String? imagePath;
  final Promotion? promotion;

  final String stockType;
  final List<StockRecipe> recipes;

  final List<OptionGroup> optionGroups;

  Product({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.price,
    required this.isHot,
    required this.isActive,
    required this.quantityAvailable,
    required this.alwaysAvailable,
    required this.imagePath,
    required this.promotion,
    required this.stockType,
    required this.recipes,
    required this.optionGroups,
  });

  bool get hasRequiredOptionsAvailable {
    for (final group in optionGroups) {
      if (!group.required && group.min <= 0) continue;
      if (group.availableItems.length < group.min) return false;
    }
    return true;
  }

  bool get consumesLinkedStock => stockType == 'linked' && recipes.isNotEmpty;

  bool get isAvailableForSale {
    if (!isActive) return false;
    if ((!alwaysAvailable || consumesLinkedStock) && quantityAvailable <= 0) {
      return false;
    }
    return hasRequiredOptionsAvailable;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    // image
    String? image;
    final pics = json['pictures'];
    if (pics is List && pics.isNotEmpty) {
      final first = pics.first;
      if (first is Map) image = (first['path'] ?? first['url'])?.toString();
    }

    image = _absUrl(image, baseUrl: Env.baseUrl);

    // promo
    final promoJson = json['promotion'];
    Promotion? promo;
    if (promoJson is Map) {
      promo = Promotion.fromJson(Map<String, dynamic>.from(promoJson));
    }

    // IMPORTANT: options di API kamu itu "parent_options"
    final groupsRaw = json['parent_options'] ?? json['option_groups'] ?? json['options'] ?? const [];
    final optionGroups = (groupsRaw is List)
        ? groupsRaw
            .whereType<Map>()
            .map((e) => OptionGroup.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <OptionGroup>[];

    final stockType = (json['stock_type'] ?? '').toString(); // direct | linked
    final qty = _computeAvailableQty(json);
    final recipes = StockRecipe.listFromJson(json['recipes']);

    return Product(
      id: parseInt(json['id']),
      categoryId: parseInt(json['category_id']),
      name: (json['name'] ?? '').toString(),
      description: json['description']?.toString(),
      price: parseNum(json['price']),
      isHot: parseBool(json['is_hot_product']),
      isActive: parseBool(json['is_active']),
      quantityAvailable: qty,
      alwaysAvailable: parseBool(json['always_available_flag']),
      imagePath: image,
      promotion: promo,
      stockType: stockType,
      recipes: recipes,
      optionGroups: optionGroups,
    );
  }
}

class StockRecipe {
  final int stockId;
  final String stockName;
  final double quantityUsed;
  final double availableQuantity;
  final String? unit;

  StockRecipe({
    required this.stockId,
    required this.stockName,
    required this.quantityUsed,
    required this.availableQuantity,
    required this.unit,
  });

  factory StockRecipe.fromJson(Map<String, dynamic> json) {
    final stockRaw = json['stock'];
    final stock = stockRaw is Map
        ? Map<String, dynamic>.from(stockRaw)
        : <String, dynamic>{};
    final displayUnitRaw = stock['display_unit'] ?? stock['displayUnit'];
    final displayUnit = displayUnitRaw is Map
        ? Map<String, dynamic>.from(displayUnitRaw)
        : <String, dynamic>{};
    final quantity = parseNum(stock['quantity'], defaultValue: 0).toDouble();
    final reserved =
        parseNum(stock['quantity_reserved'], defaultValue: 0).toDouble();
    final available = quantity - reserved;

    return StockRecipe(
      stockId: parseInt(json['stock_id'] ?? stock['id']),
      stockName: (stock['stock_name'] ?? json['stock_name'] ?? '').toString(),
      quantityUsed: parseNum(json['quantity_used'], defaultValue: 0).toDouble(),
      availableQuantity: available.isNaN || available < 0 ? 0 : available,
      unit: (displayUnit['unit_name'] ?? json['unit'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stock_id': stockId,
      'quantity_used': quantityUsed,
      'stock': {
        'id': stockId,
        'stock_name': stockName,
        'quantity': availableQuantity,
        'quantity_reserved': 0,
        'display_unit': {
          'unit_name': unit,
        },
      },
    };
  }

  static List<StockRecipe> listFromJson(dynamic raw) {
    if (raw is! List) return const <StockRecipe>[];
    return raw
        .whereType<Map>()
        .map((e) => StockRecipe.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.stockId > 0 && e.quantityUsed > 0)
        .toList();
  }
}

class OptionItem {
  final int id;
  final String name;
  final num price; // tambahan harga
  final String stockType;
  final int quantityAvailable;
  final bool alwaysAvailable;
  final List<StockRecipe> recipes;

  OptionItem({
    required this.id,
    required this.name,
    required this.price,
    required this.stockType,
    required this.quantityAvailable,
    required this.alwaysAvailable,
    required this.recipes,
  });

  bool get consumesLinkedStock => stockType == 'linked' && recipes.isNotEmpty;
  bool get isAvailableForSale =>
      (alwaysAvailable && !consumesLinkedStock) || quantityAvailable > 0;

  factory OptionItem.fromJson(Map<String, dynamic> json) {
    final stockType = (json['stock_type'] ?? '').toString();

    int qty;
    if (stockType == 'direct') {
      final stock = json['stock'];
      if (stock is Map) {
        final q = parseNum(stock['quantity'], defaultValue: 0).toDouble();
        final r = parseNum(stock['quantity_reserved'], defaultValue: 0).toDouble();
        final available = q - r;
        qty = available < 0 ? 0 : available.floor();
      } else {
        qty = 0;
      }
    } else {
      qty = parseInt(json['available_linked_quantity'] ?? 0);
    }

    return OptionItem(
      id: parseInt(json['id']),
      name: (json['name'] ?? '').toString(),
      price: parseNum(json['price'] ?? 0),
      stockType: stockType,
      quantityAvailable: qty,
      alwaysAvailable: parseBool(json['always_available_flag']),
      recipes: StockRecipe.listFromJson(json['recipes']),
    );
  }
}

class OptionGroup {
  final int id;
  final String name;

  final int min; // minimal dipilih
  final int max; // maksimal dipilih (0 = unlimited)
  final bool required;

  final List<OptionItem> items;

  OptionGroup({
    required this.id,
    required this.name,
    required this.min,
    required this.max,
    required this.required,
    required this.items,
  });

  bool get multiple => max != 1;
  List<OptionItem> get availableItems =>
      items.where((item) => item.isAvailableForSale).toList();

  factory OptionGroup.fromJson(Map<String, dynamic> json) {
    final prov = (json['provision'] ?? '').toString().toUpperCase();
    final val  = parseInt(json['provision_value'], defaultValue: 0);

    int min = 0;
    int max = 0;
    bool required = false;

    switch (prov) {
      case 'EXACT':
        min = val > 0 ? val : 1;
        max = min;
        required = true;
        break;

      case 'MIN':
        min = val > 0 ? val : 1;
        max = 0; // unlimited
        required = true;
        break;

      case 'MAX':
        min = 0;
        max = val > 0 ? val : 1;
        required = false;
        break;

      case 'OPTIONAL MAX':
        min = 0;
        max = val > 0 ? val : 1;
        required = false;
        break;

      case 'OPTIONAL':
      default:
        min = 0;
        max = 0; // unlimited
        required = false;
        break;
    }

    return OptionGroup(
      id: parseInt(json['id']),
      name: (json['name'] ?? '').toString(),
      min: min,
      max: max,
      required: required,
      items: (json['options'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => OptionItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class StoreTable {
  final int id;
  final String tableNo;     // "1", "O1"
  final String tableCode;   // "TBxxxx"
  final String tableClass;  // indoor/outdoor
  final String status;      // available/occupied/etc
  final String? imagePath;  // optional (ambil first images.path)
  final String? tableUrl;

  StoreTable({
    required this.id,
    required this.tableNo,
    required this.tableCode,
    required this.tableClass,
    required this.status,
    required this.imagePath,
    required this.tableUrl,
  });

  bool get isAvailable => status.toLowerCase() == 'available';

  String get label => 'Meja $tableNo'; // buat dropdown

  factory StoreTable.fromJson(Map<String, dynamic> json) {
    String? image;
    final imgs = json['images'];
    if (imgs is List && imgs.isNotEmpty) {
      final first = imgs.first;
      if (first is Map) image = (first['path'] ?? first['url'])?.toString();
    }

    image = _absUrl(image, baseUrl: Env.baseUrl);

    return StoreTable(
      id: parseInt(json['id']),
      tableNo: (json['table_no'] ?? '').toString(),
      tableCode: (json['table_code'] ?? '').toString(),
      tableClass: (json['table_class'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      imagePath: image,
      tableUrl: json['table_url']?.toString(),
    );
  }
}

enum PayKind { cashierCash, onlineQris, manual, openbill }

class PaymentOption {
  final PayKind kind;
  final String value;
  final String label;
  final String? desc;

  final String? manualType;
  final int? manualId;

  final String? providerName;
  final String? providerAccountName;
  final String? providerAccountNo;
  final String? qrisImageUrl;
  final String? qrisImageLocalPath;

  const PaymentOption({
    required this.kind,
    required this.value,
    required this.label,
    this.desc,
    this.manualType,
    this.manualId,
    this.providerName,
    this.providerAccountName,
    this.providerAccountNo,
    this.qrisImageUrl,
    this.qrisImageLocalPath,
  });

  bool get isOpenbill =>
      kind == PayKind.openbill || value.trim().toUpperCase() == 'OPENBILL';

  String get backendPaymentMethod {
    switch (kind) {
      case PayKind.cashierCash:
        return 'CASH';
      case PayKind.openbill:
        return 'OPENBILL';
      case PayKind.onlineQris:
        return 'QRIS';
      case PayKind.manual:
        return value;
    }
  }
}

List<PaymentOption> parseManualPaymentOptions(Map<String, dynamic> data) {
  final rows = (data['manualPaymentMethods'] as List? ?? []);

  return rows
      .whereType<Map>()
      .map((row) => Map<String, dynamic>.from(row))
      .map((row) {
        final pm = row['owner_manual_payment'];
        final pmMap = (pm is Map) ? Map<String, dynamic>.from(pm) : null;

        final int? manualId = pmMap?['id'];
        final String type = (pmMap?['payment_type'] ?? '').toString();
        final String provider = (pmMap?['provider_name'] ?? '-').toString();
        final String? desc = pmMap?['additional_info']?.toString();

        return PaymentOption(
          kind: PayKind.manual,
          value: manualId?.toString() ?? '',
          label: provider,
          desc: desc,
          manualType: type,
          manualId: manualId,
          providerName: provider,
          providerAccountName: pmMap?['provider_account_name']?.toString(),
          providerAccountNo: pmMap?['provider_account_no']?.toString(),
          qrisImageUrl: pmMap?['qris_image_url']?.toString(),
          qrisImageLocalPath: null,
        );
      })
      .where((o) => o.value.isNotEmpty)
      .toList();
}


class CartItem {
  final Product product;
  int qty;
  final Map<int, Set<int>> selected; // groupId -> set<optionId>
  String note;
  final num unitFinalPrice; // harga per item setelah opsi (dan promo kalau mau)

  CartItem({
    required this.product,
    required this.qty,
    required this.selected,
    required this.note,
    required this.unitFinalPrice,
  });

  num get lineTotal => unitFinalPrice * qty;
}


// ===== helpers tetap sama =====
num parseNum(dynamic v, {num defaultValue = 0}) {
  if (v == null) return defaultValue;
  if (v is num) return v;
  return num.tryParse(v.toString()) ?? defaultValue;
}

int parseInt(dynamic v, {int defaultValue = 0}) {
  if (v == null) return defaultValue;
  if (v is int) return v;
  if (v is num) return v.toInt();

  final s = v.toString().trim();
  // coba int dulu
  final asInt = int.tryParse(s);
  if (asInt != null) return asInt;

  // kalau ternyata "293.00" -> parse double -> toInt
  final asDouble = double.tryParse(s.replaceAll(',', '.'));
  if (asDouble != null) return asDouble.toInt();

  return defaultValue;
}


bool parseBool(dynamic v, {bool defaultValue = false}) {
  if (v == null) return defaultValue;
  if (v is bool) return v;
  final s = v.toString().toLowerCase();
  if (s == '1' || s == 'true') return true;
  if (s == '0' || s == 'false') return false;
  return defaultValue;
}

int _computeAvailableQty(Map<String, dynamic> json) {
  final stockType = (json['stock_type'] ?? '').toString();

  if (stockType == 'direct') {
    final stock = json['stock'];
    if (stock is Map) {
      final q = parseNum(stock['quantity'], defaultValue: 0).toDouble();
      final r = parseNum(stock['quantity_reserved'], defaultValue: 0).toDouble();
      final available = (q - r);

      // jaga-jaga kalau reserved minus (di contoh Mineral Water reserved = -2)
      // minimal jangan bikin stok tambah tak masuk akal -> clamp
      final safe = available.isNaN ? 0 : available;
      return safe < 0 ? 0 : safe.floor();
    }
    return 0;
  }

  // linked (default)
  return parseInt(
    json['available_linked_quantity'] ?? json['available_quantity'] ?? 0,
  );
}

String? _absUrl(String? path, {required String baseUrl}) {
  if (path == null || path.isEmpty) return null;
  // sudah absolut
  if (path.startsWith('http://') || path.startsWith('https://')) return path;

  final b = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
  final p = path.startsWith('/') ? path.substring(1) : path;
  return '$b/$p';
}
