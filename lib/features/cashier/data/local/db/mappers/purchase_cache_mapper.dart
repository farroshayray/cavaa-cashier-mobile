import 'dart:convert';
import 'package:drift/drift.dart';
import '/features/cashier/data/models/purchase_models.dart';
import '/features/cashier/data/local/db/cashier_db.dart';

class PurchaseCacheMapper {
  static CachedProductsCompanion toCachedProduct(Product p) {
    return CachedProductsCompanion.insert(
      serverId: p.id,
      name: p.name,
      categoryId: p.categoryId,
      price: p.price.toDouble(),
      stockType: Value(p.stockType),
      quantityAvailable: Value(p.quantityAvailable),
      alwaysAvailable: Value(p.alwaysAvailable),
      isActive: Value(p.isActive),
      promoId: Value(p.promotion?.id),
      promoType: Value(p.promotion?.type),
      promoValue: Value(p.promotion?.value.toDouble()),
      imagePath: Value(p.imagePath),
      description: Value(p.description),
      rawJson: jsonEncode({
        'id': p.id,
        'name': p.name,
      }),
      cachedAt: DateTime.now(),
    );
  }

  static List<CachedOptionGroupsCompanion> toCachedOptionGroups(Product p) {
    return p.optionGroups.map((g) {
      return CachedOptionGroupsCompanion.insert(
        serverId: g.id,
        productServerId: p.id,
        name: g.name,
        minSelect: Value(g.min),
        maxSelect: Value(g.max),
        requiredFlag: Value(g.required),
        rawJson: jsonEncode({
          'id': g.id,
          'name': g.name,
        }),
        cachedAt: DateTime.now(),
      );
    }).toList();
  }

  static List<CachedOptionItemsCompanion> toCachedOptionItems(Product p) {
    final out = <CachedOptionItemsCompanion>[];
    for (final g in p.optionGroups) {
      for (final item in g.items) {
        out.add(
          CachedOptionItemsCompanion.insert(
            serverId: item.id,
            groupServerId: g.id,
            productServerId: p.id,
            name: item.name,
            price: Value(item.price.toDouble()),
            stockType: Value(item.stockType),
            quantityAvailable: Value(item.quantityAvailable),
            alwaysAvailable: Value(item.alwaysAvailable),
            rawJson: jsonEncode({
              'id': item.id,
              'name': item.name,
            }),
            cachedAt: DateTime.now(),
          ),
        );
      }
    }
    return out;
  }

  static CachedTablesCompanion toCachedTable(StoreTable t) {
    return CachedTablesCompanion.insert(
      serverId: t.id,
      tableNo: t.tableNo,
      tableCode: Value(t.tableCode),
      tableClass: Value(t.tableClass),
      status: Value(t.status),
      imagePath: Value(t.imagePath),
      tableUrl: Value(t.tableUrl),
      rawJson: jsonEncode({
        'id': t.id,
        'table_no': t.tableNo,
      }),
      cachedAt: DateTime.now(),
    );
  }

  static CachedPaymentMethodsCompanion toCachedPayment(PaymentOption p) {
    return CachedPaymentMethodsCompanion.insert(
      localKey: '${p.kind.name}-${p.value}',
      kind: p.kind.name,
      serverManualPaymentId: Value(p.manualId),
      label: p.label,
      providerName: Value(p.label),
      providerAccountName: const Value(null),
      providerAccountNo: const Value(null),
      qrisImageUrl: const Value(null),
      isActive: const Value(true),
      rawJson: jsonEncode({
        'kind': p.kind.name,
        'value': p.value,
        'label': p.label,
      }),
      cachedAt: DateTime.now(),
    );
  }

    static Product fromCachedProduct({
    required CachedProduct row,
    required List<CachedOptionGroup> groups,
    required List<CachedOptionItem> items,
  }) {
    final productGroups = groups
        .where((g) => g.productServerId == row.serverId)
        .map((g) {
          final groupItems = items
              .where((i) => i.groupServerId == g.serverId)
              .map((i) => OptionItem(
                    id: i.serverId,
                    name: i.name,
                    price: i.price,
                    stockType: i.stockType,
                    quantityAvailable: i.quantityAvailable,
                    alwaysAvailable: i.alwaysAvailable,
                  ))
              .toList();

          return OptionGroup(
            id: g.serverId,
            name: g.name,
            min: g.minSelect,
            max: g.maxSelect,
            required: g.requiredFlag,
            items: groupItems,
          );
        })
        .toList();

    Promotion? promo;
    if (row.promoId != null) {
      promo = Promotion(
        id: row.promoId!,
        type: row.promoType ?? '',
        value: row.promoValue ?? 0,
      );
    }

    return Product(
      id: row.serverId,
      categoryId: row.categoryId,
      name: row.name,
      description: row.description,
      price: row.price,
      isHot: false,
      isActive: row.isActive,
      quantityAvailable: row.quantityAvailable,
      alwaysAvailable: row.alwaysAvailable,
      imagePath: row.imagePath,
      promotion: promo,
      stockType: row.stockType,
      optionGroups: productGroups,
    );
  }

  static StoreTable fromCachedTable(CachedTable row) {
    return StoreTable(
      id: row.serverId,
      tableNo: row.tableNo,
      tableCode: row.tableCode ?? '',
      tableClass: row.tableClass ?? '',
      status: row.status,
      imagePath: row.imagePath,
      tableUrl: row.tableUrl,
    );
  }

  static PaymentOption fromCachedPayment(CachedPaymentMethod row) {
    PayKind kind;
    switch (row.kind) {
      case 'cashierCash':
        kind = PayKind.cashierCash;
        break;
      case 'onlineQris':
        kind = PayKind.onlineQris;
        break;
      case 'manual':
      default:
        kind = PayKind.manual;
        break;
    }

    return PaymentOption(
      kind: kind,
      value: row.serverManualPaymentId?.toString() ?? row.localKey,
      label: row.label,
      desc: row.providerName,
      manualType: row.kind,
      manualId: row.serverManualPaymentId,
    );
  }

  static PurchasePayload buildPayloadFromCache({
    required List<CachedCategory> categories,
    required List<CachedProduct> products,
    required List<CachedOptionGroup> groups,
    required List<CachedOptionItem> items,
    required List<CachedTable> tables,
    required List<CachedPaymentMethod> payments,
  }) {
    final mappedProducts = products
        .map((p) => fromCachedProduct(
              row: p,
              groups: groups,
              items: items,
            ))
        .toList();

    final mappedCategories = categories
        .map(fromCachedCategory)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    final mappedTables = tables.map(fromCachedTable).toList();
    final mappedPayments = payments.map(fromCachedPayment).toList();

    return PurchasePayload(
      products: mappedProducts,
      categories: mappedCategories,
      tables: mappedTables,
      paymentOptions: mappedPayments,
      partnerData: null,
    );
  }

  static CachedCategoriesCompanion toCachedCategory(Category c) {
    return CachedCategoriesCompanion.insert(
      serverId: c.id,
      name: c.name,
      order: Value(c.order),
      rawJson: jsonEncode({
        'id': c.id,
        'name': c.name,
        'order': c.order,
      }),
      cachedAt: DateTime.now(),
    );
  }

  static Category fromCachedCategory(CachedCategory row) {
    return Category(
      id: row.serverId,
      name: row.name,
      order: row.order,
    );
  }
}