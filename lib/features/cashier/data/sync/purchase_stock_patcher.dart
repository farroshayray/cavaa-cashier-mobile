import '/features/cashier/data/models/purchase_models.dart';

/// Patches stock-related fields on in-memory products from a (possibly partial) cache.
List<Product> patchProductsStock({
  required List<Product> current,
  required List<Product> fromCache,
}) {
  if (fromCache.isEmpty) return List<Product>.from(current);

  final cacheById = {for (final product in fromCache) product.id: product};
  final existingIds = current.map((product) => product.id).toSet();

  final patched = current.map((product) {
    final cached = cacheById[product.id];
    if (cached == null) return product;
    return _mergeProductStock(product, cached);
  }).toList();

  for (final cached in fromCache) {
    if (!existingIds.contains(cached.id)) {
      patched.add(cached);
    }
  }

  return patched;
}

Product _mergeProductStock(Product existing, Product cached) {
  final cachedGroupsById = {
    for (final group in cached.optionGroups) group.id: group,
  };

  final mergedGroups = existing.optionGroups.map((group) {
    final cachedGroup = cachedGroupsById[group.id];
    if (cachedGroup == null) return group;
    return _mergeOptionGroupStock(group, cachedGroup);
  }).toList();

  return Product(
    id: existing.id,
    categoryId: existing.categoryId,
    name: existing.name,
    description: existing.description,
    price: existing.price,
    isHot: existing.isHot,
    isActive: existing.isActive,
    quantityAvailable: cached.quantityAvailable,
    alwaysAvailable: cached.alwaysAvailable,
    imagePath: existing.imagePath,
    promotion: existing.promotion,
    stockType: cached.stockType,
    recipes: cached.recipes,
    optionGroups: mergedGroups,
  );
}

OptionGroup _mergeOptionGroupStock(OptionGroup existing, OptionGroup cached) {
  final cachedItemsById = {for (final item in cached.items) item.id: item};

  final mergedItems = existing.items.map((item) {
    final cachedItem = cachedItemsById[item.id];
    if (cachedItem == null) return item;
    return OptionItem(
      id: item.id,
      name: item.name,
      price: item.price,
      stockType: cachedItem.stockType,
      quantityAvailable: cachedItem.quantityAvailable,
      alwaysAvailable: cachedItem.alwaysAvailable,
      recipes: cachedItem.recipes,
    );
  }).toList();

  return OptionGroup(
    id: existing.id,
    name: existing.name,
    min: existing.min,
    max: existing.max,
    required: existing.required,
    items: mergedItems,
  );
}
