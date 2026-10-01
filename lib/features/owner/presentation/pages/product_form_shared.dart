import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '/core/config/env.dart';
import '../widgets/dock_inset.dart';

const productBrand = Color(0xFFAE1504);
const productCatalogAccent = Color(0xFF334155);

InputDecoration productFieldDecoration({
  required String label,
  String? helper,
  String? prefixText,
}) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
  );
  return InputDecoration(
    labelText: label,
    helperText: helper,
    prefixText: prefixText,
    filled: true,
    fillColor: Colors.white,
    border: border,
    enabledBorder: border,
    disabledBorder: border,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: productBrand, width: 1.4),
    ),
  );
}

class ProductFormSectionCard extends StatelessWidget {
  const ProductFormSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.black.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class ProductMetaChip extends StatelessWidget {
  const ProductMetaChip({
    super.key,
    required this.label,
    this.filled = false,
    this.color = productBrand,
  });

  final String label;
  final bool filled;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: filled
            ? color.withValues(alpha: 0.12)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: filled ? color : const Color(0xFF475569),
        ),
      ),
    );
  }
}

class ProductFormSwitchTile extends StatelessWidget {
  const ProductFormSwitchTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.icon = Icons.toggle_on_rounded,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: productBrand.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: productBrand, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black.withValues(alpha: 0.45),
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: productBrand,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class ProductStockModeTabs extends StatelessWidget {
  const ProductStockModeTabs({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget tab(String key, String label, IconData icon) {
      final selected = value == key;
      return Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onChanged(key),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: selected ? productBrand : const Color(0xFF6B7280),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: selected ? productBrand : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB).withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          tab('always', 'Selalu', Icons.all_inclusive_rounded),
          tab('direct', 'Pcs', Icons.inventory_2_rounded),
          tab('linked', 'Resep', Icons.restaurant_menu_rounded),
        ],
      ),
    );
  }
}

class ProductCategoryTab extends StatelessWidget {
  const ProductCategoryTab({
    super.key,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.accent = productBrand,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final top = Color.lerp(accent, Colors.black, 0.12) ?? accent;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.fromLTRB(14, 9, 12, 9),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [top, accent],
                  )
                : null,
            color: selected ? null : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : Colors.black.withValues(alpha: 0.07),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.1,
                  color: selected ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.22)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

int? productCategoryIdOf(Map<String, dynamic> product) {
  final cat = product['category'];
  if (cat is Map) return int.tryParse('${cat['id'] ?? ''}');
  return int.tryParse('${product['category_id'] ?? ''}');
}

/// Kategori yang punya minimal 1 item di [products] (+ jumlahnya).
List<({int id, String name, int count})> populatedProductCategories({
  required List<Map<String, dynamic>> products,
  required List<Map<String, dynamic>> categories,
}) {
  final counts = <int, int>{};
  for (final p in products) {
    final id = productCategoryIdOf(p);
    if (id == null) continue;
    counts[id] = (counts[id] ?? 0) + 1;
  }
  final rows = <({int id, String name, int count})>[];
  for (final c in categories) {
    final id = int.tryParse('${c['id'] ?? ''}');
    if (id == null) continue;
    final count = counts[id] ?? 0;
    if (count <= 0) continue;
    final name = c['name']?.toString() ??
        c['category_name']?.toString() ??
        '-';
    rows.add((id: id, name: name, count: count));
  }
  for (final entry in counts.entries) {
    if (rows.any((r) => r.id == entry.key)) continue;
    String name = 'Kategori';
    for (final p in products) {
      if (productCategoryIdOf(p) != entry.key) continue;
      final cat = p['category'];
      if (cat is Map) name = cat['name']?.toString() ?? name;
      break;
    }
    rows.add((id: entry.key, name: name, count: entry.value));
  }
  rows.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return rows;
}

/// Toko yang memakai item katalog (dari field API `used_in_stores`).
List<({int id, String name})> catalogUsedInStores(Map<String, dynamic> product) {
  final raw = product['used_in_stores'];
  if (raw is! List) return const [];
  final seen = <int>{};
  final out = <({int id, String name})>[];
  for (final item in raw) {
    if (item is! Map) continue;
    final id = int.tryParse('${item['id'] ?? ''}');
    final name = item['name']?.toString().trim() ?? '';
    if (id == null || id <= 0 || name.isEmpty || seen.contains(id)) continue;
    seen.add(id);
    out.add((id: id, name: name));
  }
  return out;
}

/// Copy ringkas untuk subtitle card Katalog.
String catalogUsedInStoresLabel(Map<String, dynamic> product) {
  final stores = catalogUsedInStores(product);
  final countFromApi = int.tryParse('${product['used_in_store_count'] ?? ''}');
  final n = stores.isNotEmpty ? stores.length : (countFromApi ?? 0);
  if (n <= 0 || stores.isEmpty) {
    return 'Belum dipakai toko mana pun';
  }
  if (stores.length <= 2) {
    return 'Dipakai: ${stores.map((s) => s.name).join(', ')}';
  }
  final shown = stores.take(2).map((s) => s.name).join(', ');
  final more = stores.length - 2;
  return 'Dipakai di $n toko · $shown +$more';
}

class RecipeLine {
  RecipeLine({
    this.stockId,
    this.quantity = '1',
    this.unitId,
    this.stockName = '',
  });

  int? stockId;
  String quantity;
  int? unitId;
  String stockName;

  factory RecipeLine.fromJson(Map<String, dynamic> json) {
    final raw = json['quantity'] ?? json['quantity_used'];
    String qty = '1';
    if (raw is num) {
      qty = raw == raw.roundToDouble() ? raw.toStringAsFixed(0) : raw.toString();
    } else if (raw != null && raw.toString().isNotEmpty) {
      qty = raw.toString();
    }
    return RecipeLine(
      stockId: int.tryParse('${json['stock_id'] ?? ''}'),
      quantity: qty,
      unitId: int.tryParse('${json['unit_id'] ?? ''}'),
      stockName: json['stock_name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toPayload() {
    return {
      'stock_id': stockId,
      'quantity': num.tryParse(quantity.trim().replaceAll(',', '.')) ?? 0,
      'unit_id': unitId,
    };
  }
}

List<RecipeLine> recipeLinesFrom(dynamic raw) {
  if (raw is! List) return [];
  return raw
      .whereType<Map>()
      .map((e) => RecipeLine.fromJson(Map<String, dynamic>.from(e)))
      .toList();
}

const provisionChoices = <String, String>{
  'OPTIONAL': 'Opsional',
  'OPTIONAL MAX': 'Opsional (maks)',
  'MAX': 'Maksimal',
  'EXACT': 'Tepat',
  'MIN': 'Minimal',
};

class MenuOptionItem {
  MenuOptionItem({
    this.optionId,
    this.name = '',
    this.price = '0',
    this.description = '',
    this.alwaysAvailable = true,
    this.stockType = 'direct',
    this.stockQuantity = '',
    this.modalPrice = '',
    this.lastUnitCost = 0,
    this.stockEditable = true,
    List<RecipeLine>? recipes,
  }) : recipes = recipes ?? [];

  int? optionId;
  String name;
  String price;
  String description;
  bool alwaysAvailable;
  String stockType;
  String stockQuantity;
  String modalPrice;
  num lastUnitCost;
  bool stockEditable;
  List<RecipeLine> recipes;

  factory MenuOptionItem.fromJson(Map<String, dynamic> json) {
    final costRaw = json['unit_cost'] ?? json['modal_price'];
    final cost = costRaw is num
        ? costRaw
        : num.tryParse('${costRaw ?? ''}') ?? 0;
    return MenuOptionItem(
      optionId: json['option_id'] is int
          ? json['option_id'] as int
          : int.tryParse('${json['option_id'] ?? ''}'),
      name: json['name']?.toString() ?? '',
      price: () {
        final p = json['price'];
        if (p is num) return p.toStringAsFixed(0);
        return p?.toString() ?? '0';
      }(),
      description: json['description']?.toString() ?? '',
      alwaysAvailable:
          json['always_available'] == true || json['always_available'] == 1,
      stockType: json['stock_type']?.toString() ?? 'direct',
      stockQuantity: () {
        final q = json['stock_quantity'];
        if (q is num) return q.toStringAsFixed(0);
        final text = q?.toString() ?? '';
        return text.isEmpty ? '' : text;
      }(),
      modalPrice: cost > 0
          ? (cost == cost.roundToDouble()
              ? cost.toStringAsFixed(0)
              : cost.toString())
          : '',
      lastUnitCost: cost > 0 ? cost : 0,
      stockEditable: json['stock_editable'] != false &&
          (json['stock_type']?.toString() ?? 'direct') != 'linked',
      recipes: recipeLinesFrom(json['recipes']),
    );
  }

  Map<String, dynamic> toJson() {
    final modal = num.tryParse(modalPrice.trim().replaceAll(',', '.'));
    return {
      if (optionId != null) 'option_id': optionId,
      'name': name,
      'price': int.tryParse(price.replaceAll('.', '').trim()) ?? 0,
      'description': description.isEmpty ? null : description,
      // Stok opsi selalu dikirim agar opsi baru tidak otomatis Habis.
      'always_available': alwaysAvailable,
      'stock_type': stockType == 'linked' ? 'linked' : 'direct',
      if (!alwaysAvailable && stockType != 'linked')
        'stock_quantity': int.tryParse(stockQuantity.replaceAll('.', '').trim()) ?? 0,
      if (!alwaysAvailable && stockType != 'linked' && modal != null && modal > 0)
        'modal_price': modal,
    };
  }
}

class MenuOptionGroup {
  MenuOptionGroup({
    this.parentId,
    this.name = '',
    this.description = '',
    this.provision = 'OPTIONAL',
    this.provisionValue = '0',
    List<MenuOptionItem>? options,
  }) : options = options ?? [MenuOptionItem()];

  int? parentId;
  String name;
  String description;
  String provision;
  String provisionValue;
  List<MenuOptionItem> options;

  factory MenuOptionGroup.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    return MenuOptionGroup(
      parentId: json['parent_id'] is int
          ? json['parent_id'] as int
          : int.tryParse('${json['parent_id'] ?? ''}'),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      provision: json['provision']?.toString() ?? 'OPTIONAL',
      provisionValue: '${json['provision_value'] ?? 0}',
      options: rawOptions is List
          ? rawOptions
              .whereType<Map>()
              .map((e) => MenuOptionItem.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : [MenuOptionItem()],
    );
  }

  Map<String, dynamic> toJson() => {
        if (parentId != null) 'parent_id': parentId,
        'name': name,
        'description': description.isEmpty ? null : description,
        'provision': provision,
        'provision_value':
            int.tryParse(provisionValue.replaceAll('.', '').trim()) ?? 0,
        'options': options.map((e) => e.toJson()).toList(),
      };
}

String? resolveProductImageUrl(dynamic pictures) {
  if (pictures is! List || pictures.isEmpty) return null;
  final first = pictures.first;
  if (first is! Map) return null;
  final path = first['path']?.toString();
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  final base = Env.baseUrl.replaceAll(RegExp(r'/$'), '');
  final clean = path.replaceFirst(RegExp(r'^/+'), '');
  if (clean.startsWith('storage/')) return '$base/$clean';
  return '$base/storage/$clean';
}

List<Map<String, dynamic>> pictureMaps(dynamic pictures) {
  if (pictures is! List) return [];
  return pictures
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

String formatProductPrice(dynamic price) {
  final n = price is num ? price : num.tryParse('$price') ?? 0;
  return n.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      );
}

String formatRupiah(num value) {
  final rounded = value.round();
  final text = rounded.abs().toString();
  final buffer = StringBuffer(rounded < 0 ? '-' : '');
  for (var i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) buffer.write('.');
    buffer.write(text[i]);
  }
  return 'Rp $buffer';
}

double estimateRecipeCost(
  List<RecipeLine> lines,
  List<Map<String, dynamic>> ingredients,
) {
  var total = 0.0;
  for (final line in lines) {
    Map<String, dynamic>? ingredient;
    for (final item in ingredients) {
      if (int.tryParse('${item['id']}') == line.stockId) ingredient = item;
    }
    if (ingredient == null) continue;
    final qty = double.tryParse(line.quantity.replaceAll(',', '.')) ?? 0;
    final basePrice = ingredient['base_price'];
    final price = basePrice is num
        ? basePrice.toDouble()
        : double.tryParse('$basePrice') ?? 0;
    var toBase = 0.0;
    final units = ingredient['available_units'];
    if (units is List) {
      for (final unit in units.whereType<Map>()) {
        if (int.tryParse('${unit['id']}') == line.unitId) {
          final factor = unit['to_base'];
          toBase = factor is num ? factor.toDouble() : double.tryParse('$factor') ?? 0;
        }
      }
    }
    total += qty * toBase * price;
  }
  return total;
}

int filledRecipeCount(List<RecipeLine> lines) {
  return lines.where((line) => line.stockId != null).length;
}

String productStockSummary({
  required String mode,
  required String quantity,
  required List<RecipeLine> recipes,
  required List<Map<String, dynamic>> ingredients,
}) {
  if (mode == 'always') return 'Selalu tersedia';
  if (mode == 'direct') {
    return 'Pcs · ${quantity.trim().isEmpty ? '0' : quantity.trim()}';
  }
  final count = filledRecipeCount(recipes);
  final hpp = estimateRecipeCost(recipes, ingredients);
  if (hpp <= 0) return 'Resep · $count bahan';
  return 'Resep · $count bahan · HPP ${formatRupiah(hpp)}';
}

String optionStockLabel(
  MenuOptionItem option, {
  required bool showOptionStock,
  required bool canManageStock,
}) {
  if (!showOptionStock) return '';
  if (canManageStock && option.stockType == 'linked') {
    return 'Resep · ${filledRecipeCount(option.recipes)} bahan';
  }
  if (option.alwaysAvailable) return 'Selalu';
  final qty = option.stockQuantity.trim().isEmpty ? '0' : option.stockQuantity.trim();
  return '$qty pcs';
}

String groupRuleLabel(MenuOptionGroup group) {
  final rule = provisionChoices[group.provision] ?? group.provision;
  final count = '${group.options.length} opsi';
  if (group.provision == 'OPTIONAL') return '$rule · $count';
  return '$rule ${group.provisionValue} · $count';
}

class ProductMenuOptionsEditor extends StatelessWidget {
  const ProductMenuOptionsEditor({
    super.key,
    required this.groups,
    required this.onChanged,
    this.readOnly = false,
    this.showOptionStock = false,
    this.canManageStock = false,
    this.ingredients = const [],
    this.showHeader = true,
  });

  final List<MenuOptionGroup> groups;
  final ValueChanged<List<MenuOptionGroup>> onChanged;
  final bool readOnly;
  final bool showOptionStock;
  final bool canManageStock;
  final List<Map<String, dynamic>> ingredients;
  final bool showHeader;

  void _emit() => onChanged([...groups]);

  Future<void> _openGroup(BuildContext context, MenuOptionGroup group) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OptionGroupEditorPage(
          group: group,
          readOnly: readOnly,
          showOptionStock: showOptionStock,
          canManageStock: canManageStock,
          ingredients: ingredients,
        ),
      ),
    );
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeader)
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Opsi / varian',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
              if (!readOnly)
                TextButton.icon(
                  onPressed: () async {
                    final group = MenuOptionGroup();
                    groups.add(group);
                    await _openGroup(context, group);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: productBrand,
                    backgroundColor: productBrand.withValues(alpha: 0.08),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text(
                    'Tambah grup',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
            ],
          ),
        if (showHeader) const SizedBox(height: 8),
        if (!showHeader && !readOnly)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () async {
                final group = MenuOptionGroup();
                groups.add(group);
                await _openGroup(context, group);
              },
              style: TextButton.styleFrom(
                foregroundColor: productBrand,
                backgroundColor: productBrand.withValues(alpha: 0.08),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                'Tambah grup',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        if (!showHeader && !readOnly) const SizedBox(height: 8),
        if (groups.isEmpty)
          Container(
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: productBrand.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: productBrand,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  readOnly
                      ? 'Tidak ada opsi'
                      : 'Belum ada grup opsi',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  readOnly
                      ? 'Produk ini tidak punya pilihan varian.'
                      : 'Tambah grup jika produk punya pilihan (level, topping, dll).',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          )
        else
          for (var gi = 0; gi < groups.length; gi++)
            _OptionGroupSummary(
              group: groups[gi],
              showOptionStock: showOptionStock,
              canManageStock: canManageStock,
              onOpen: () => _openGroup(context, groups[gi]),
              onDelete: readOnly
                  ? null
                  : () {
                      groups.removeAt(gi);
                      _emit();
                    },
            ),
      ],
    );
  }
}

class _OptionGroupSummary extends StatelessWidget {
  const _OptionGroupSummary({
    required this.group,
    required this.showOptionStock,
    required this.canManageStock,
    required this.onOpen,
    required this.onDelete,
  });

  final MenuOptionGroup group;
  final bool showOptionStock;
  final bool canManageStock;
  final VoidCallback onOpen;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final title =
        group.name.trim().isEmpty ? 'Grup tanpa nama' : group.name.trim();
    final rule = provisionChoices[group.provision] ?? group.provision;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onOpen,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                ProductMetaChip(label: rule, filled: true),
                                if (group.provision != 'OPTIONAL')
                                  ProductMetaChip(
                                    label: 'Nilai ${group.provisionValue}',
                                  ),
                                ProductMetaChip(
                                  label: '${group.options.length} opsi',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (onDelete != null)
                        IconButton(
                          onPressed: onDelete,
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: productBrand,
                          ),
                        ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.black.withValues(alpha: 0.35),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                  if (group.options.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    for (final option in group.options)
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    option.name.trim().isEmpty
                                        ? 'Opsi tanpa nama'
                                        : option.name.trim(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (showOptionStock)
                                    Text(
                                      optionStockLabel(
                                        option,
                                        showOptionStock: showOptionStock,
                                        canManageStock: canManageStock,
                                      ),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black
                                            .withValues(alpha: 0.45),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              'Rp ${formatProductPrice(option.price.replaceAll('.', ''))}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: productBrand,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProductStockEditorPage extends StatefulWidget {
  const ProductStockEditorPage({
    super.key,
    required this.mode,
    required this.quantity,
    required this.modalPrice,
    required this.lastUnitCost,
    required this.recipes,
    required this.ingredients,
    required this.sellPrice,
    required this.onModeChanged,
    required this.onRecipesChanged,
  });

  final String mode;
  final TextEditingController quantity;
  final TextEditingController modalPrice;
  final num lastUnitCost;
  final List<RecipeLine> recipes;
  final List<Map<String, dynamic>> ingredients;
  final num? sellPrice;
  final ValueChanged<String> onModeChanged;
  final ValueChanged<List<RecipeLine>> onRecipesChanged;

  @override
  State<ProductStockEditorPage> createState() => _ProductStockEditorPageState();
}

class _ProductStockEditorPageState extends State<ProductStockEditorPage> {
  late String _mode;

  @override
  void initState() {
    super.initState();
    _mode = widget.mode;
  }

  void _setMode(String mode) {
    setState(() {
      _mode = mode;
      if (mode == 'linked' && widget.recipes.isEmpty) {
        widget.recipes.add(RecipeLine());
      }
    });
    widget.onModeChanged(mode);
    widget.onRecipesChanged(widget.recipes);
  }

  String get _lastCostLabel {
    final v = widget.lastUnitCost;
    if (v <= 0) return 'belum ada';
    return 'Rp${v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text('Stok produk', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: productBrand,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28).withBottomInset(context),
        children: [
          ProductStockModeTabs(
            value: _mode,
            onChanged: _setMode,
          ),
          if (_mode == 'direct') ...[
            const SizedBox(height: 16),
            TextField(
              controller: widget.quantity,
              keyboardType: TextInputType.number,
              decoration: productFieldDecoration(label: 'Stok (pcs)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: widget.modalPrice,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: productFieldDecoration(
                label: 'Harga modal / pcs',
                helper: 'Opsional. Kosong = pakai HPP terakhir ($_lastCostLabel)',
                prefixText: 'Rp ',
              ),
            ),
          ],
          if (_mode == 'linked') ...[
            const SizedBox(height: 8),
            LinkedRecipeEditor(
              lines: widget.recipes,
              ingredients: widget.ingredients,
              sellPrice: widget.sellPrice,
              onChanged: (next) {
                widget.onRecipesChanged(next);
                setState(() {});
              },
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: productBrand,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Selesai', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}

class OptionGroupEditorPage extends StatefulWidget {
  const OptionGroupEditorPage({
    super.key,
    required this.group,
    required this.readOnly,
    required this.showOptionStock,
    required this.canManageStock,
    required this.ingredients,
  });

  final MenuOptionGroup group;
  final bool readOnly;
  final bool showOptionStock;
  final bool canManageStock;
  final List<Map<String, dynamic>> ingredients;

  @override
  State<OptionGroupEditorPage> createState() => _OptionGroupEditorPageState();
}

class _OptionGroupEditorPageState extends State<OptionGroupEditorPage> {
  late final TextEditingController _name;
  late final TextEditingController _provisionValue;
  late final TextEditingController _description;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.group.name);
    _provisionValue = TextEditingController(text: widget.group.provisionValue);
    _description = TextEditingController(text: widget.group.description);
  }

  @override
  void dispose() {
    _name.dispose();
    _provisionValue.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _openOption(MenuOptionItem option) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OptionItemEditorPage(
          option: option,
          readOnly: widget.readOnly,
          showOptionStock: widget.showOptionStock,
          canManageStock: widget.canManageStock,
          ingredients: widget.ingredients,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text('Grup opsi', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: productBrand,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28).withBottomInset(context),
        children: [
          ProductFormSectionCard(
            title: 'Detail grup',
            child: Column(
              children: [
                TextField(
                  controller: _name,
                  enabled: !widget.readOnly,
                  decoration: productFieldDecoration(
                    label: 'Nama grup (mis. Level Pedas)',
                  ),
                  onChanged: (value) => group.name = value,
                ),
                if (widget.readOnly) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ProductMetaChip(
                      label: groupRuleLabel(group),
                      filled: true,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 14),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Aturan pilihan',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final entry in provisionChoices.entries)
                        _ProvisionChip(
                          label: entry.value,
                          selected: group.provision == entry.key,
                          onTap: () => setState(() => group.provision = entry.key),
                        ),
                    ],
                  ),
                  if (group.provision != 'OPTIONAL') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _provisionValue,
                      keyboardType: TextInputType.number,
                      decoration: productFieldDecoration(label: 'Nilai aturan'),
                      onChanged: (value) => group.provisionValue = value,
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: _description,
                    decoration: productFieldDecoration(
                      label: 'Deskripsi grup (opsional)',
                    ),
                    onChanged: (value) => group.description = value,
                  ),
                ],
              ],
            ),
          ),
          ProductFormSectionCard(
            title: 'Daftar opsi',
            subtitle: '${group.options.length} item',
            trailing: widget.readOnly
                ? null
                : TextButton.icon(
                    onPressed: () {
                      final option = MenuOptionItem();
                      setState(() => group.options.add(option));
                      _openOption(option);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: productBrand,
                      backgroundColor: productBrand.withValues(alpha: 0.08),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text(
                      'Tambah',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
            child: Column(
              children: [
                if (group.options.isEmpty)
                  Text(
                    'Belum ada opsi di grup ini.',
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                  )
                else
                  for (var i = 0; i < group.options.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _openOption(group.options[i]),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        group.options[i].name.trim().isEmpty
                                            ? 'Opsi tanpa nama'
                                            : group.options[i].name.trim(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        [
                                          'Rp ${formatProductPrice(group.options[i].price.replaceAll('.', ''))}',
                                          if (widget.showOptionStock)
                                            optionStockLabel(
                                              group.options[i],
                                              showOptionStock: true,
                                              canManageStock:
                                                  widget.canManageStock,
                                            ),
                                        ].join(' · '),
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: Colors.black
                                              .withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!widget.readOnly &&
                                    group.options.length > 1)
                                  IconButton(
                                    onPressed: () => setState(
                                      () => group.options.removeAt(i),
                                    ),
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      color: productBrand,
                                    ),
                                  )
                                else
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: Colors.black.withValues(alpha: 0.35),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: productBrand,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Selesai',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProvisionChip extends StatelessWidget {
  const _ProvisionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? productBrand.withValues(alpha: 0.12)
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? productBrand.withValues(alpha: 0.35)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
              color: selected ? productBrand : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }
}

class OptionItemEditorPage extends StatefulWidget {
  const OptionItemEditorPage({
    super.key,
    required this.option,
    required this.readOnly,
    required this.showOptionStock,
    required this.canManageStock,
    required this.ingredients,
  });

  final MenuOptionItem option;
  final bool readOnly;
  final bool showOptionStock;
  final bool canManageStock;
  final List<Map<String, dynamic>> ingredients;

  @override
  State<OptionItemEditorPage> createState() => _OptionItemEditorPageState();
}

class _OptionItemEditorPageState extends State<OptionItemEditorPage> {
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _quantity;
  late final TextEditingController _modalPrice;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.option.name);
    _price = TextEditingController(text: widget.option.price);
    _quantity = TextEditingController(text: widget.option.stockQuantity);
    _modalPrice = TextEditingController(text: widget.option.modalPrice);
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _quantity.dispose();
    _modalPrice.dispose();
    super.dispose();
  }

  String get _mode {
    final option = widget.option;
    if (option.stockType == 'linked') return 'linked';
    if (option.alwaysAvailable) return 'always';
    return 'direct';
  }

  String get _lastCostLabel {
    final v = widget.option.lastUnitCost;
    if (v <= 0) return 'belum ada';
    return 'Rp${v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString()}';
  }

  void _setMode(String mode) {
    final option = widget.option;
    setState(() {
      option.stockType = mode == 'linked' ? 'linked' : 'direct';
      option.alwaysAvailable = mode == 'always';
      option.stockEditable = mode == 'direct';
      if (mode == 'linked' && option.recipes.isEmpty) {
        option.recipes.add(RecipeLine());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final option = widget.option;
    final sellPrice = num.tryParse(_price.text.replaceAll('.', '').trim());
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text('Opsi', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: productBrand,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28).withBottomInset(context),
        children: [
          ProductFormSectionCard(
            title: 'Detail opsi',
            child: Column(
              children: [
                TextField(
                  controller: _name,
                  enabled: !widget.readOnly,
                  decoration: productFieldDecoration(label: 'Nama opsi'),
                  onChanged: (value) => option.name = value,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _price,
                  enabled: !widget.readOnly,
                  keyboardType: TextInputType.number,
                  decoration: productFieldDecoration(label: 'Harga'),
                  onChanged: (value) {
                    option.price = value;
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
          if (widget.showOptionStock && widget.canManageStock)
            ProductFormSectionCard(
              title: 'Stok opsi',
              child: Column(
                children: [
                  ProductStockModeTabs(
                    value: _mode,
                    onChanged: _setMode,
                  ),
                  if (_mode == 'direct') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _quantity,
                      keyboardType: TextInputType.number,
                      decoration: productFieldDecoration(label: 'Stok (pcs)'),
                      onChanged: (value) => option.stockQuantity = value,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _modalPrice,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: productFieldDecoration(
                        label: 'Harga modal / pcs',
                        helper:
                            'Opsional. Kosong = pakai HPP terakhir ($_lastCostLabel)',
                        prefixText: 'Rp ',
                      ),
                      onChanged: (value) => option.modalPrice = value,
                    ),
                  ],
                  if (_mode == 'linked') ...[
                    const SizedBox(height: 8),
                    LinkedRecipeEditor(
                      lines: option.recipes,
                      ingredients: widget.ingredients,
                      sellPrice: sellPrice,
                      onChanged: (next) =>
                          setState(() => option.recipes = next),
                    ),
                  ],
                ],
              ),
            )
          else if (widget.showOptionStock)
            ProductFormSectionCard(
              title: 'Stok opsi',
              child: Column(
                children: [
                  ProductFormSwitchTile(
                    title: 'Opsi selalu tersedia',
                    value: option.alwaysAvailable,
                    icon: Icons.all_inclusive_rounded,
                    onChanged: (value) => setState(() {
                      option.alwaysAvailable = value;
                      if (!value && option.stockType != 'linked') {
                        option.stockType = 'direct';
                        option.stockEditable = true;
                      }
                    }),
                  ),
                  if (!option.alwaysAvailable)
                    option.stockEditable
                        ? Column(
                            children: [
                              TextField(
                                controller: _quantity,
                                keyboardType: TextInputType.number,
                                decoration: productFieldDecoration(
                                  label: 'Stok (pcs)',
                                ),
                                onChanged: (value) =>
                                    option.stockQuantity = value,
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _modalPrice,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: productFieldDecoration(
                                  label: 'Harga modal / pcs',
                                  helper:
                                      'Opsional. Kosong = pakai HPP terakhir ($_lastCostLabel)',
                                  prefixText: 'Rp ',
                                ),
                                onChanged: (value) =>
                                    option.modalPrice = value,
                              ),
                            ],
                          )
                        : InputDecorator(
                            decoration: productFieldDecoration(
                              label: 'Stok dari resep (pcs)',
                            ),
                            child: Text(
                              option.stockQuantity.isEmpty
                                  ? '0'
                                  : option.stockQuantity,
                            ),
                          ),
                ],
              ),
            ),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: productBrand,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Selesai',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LinkedRecipeEditor extends StatelessWidget {
  const LinkedRecipeEditor({
    super.key,
    required this.lines,
    required this.ingredients,
    required this.onChanged,
    this.sellPrice,
  });

  final List<RecipeLine> lines;
  final List<Map<String, dynamic>> ingredients;
  final ValueChanged<List<RecipeLine>> onChanged;
  final num? sellPrice;

  @override
  Widget build(BuildContext context) {
    if (ingredients.isEmpty) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'Belum ada bahan. Tambah bahan dulu di menu Stok, lalu susun resep di sini.',
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Text(
          'Setiap kartu adalah satu bahan untuk satu porsi.',
          style: TextStyle(color: Colors.black.withValues(alpha: 0.55)),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < lines.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _RecipeLineFields(
            key: ObjectKey(lines[i]),
            index: i,
            line: lines[i],
            ingredients: ingredients,
            onChanged: () => onChanged([...lines]),
            onRemove: lines.length <= 1
                ? null
                : () {
                    lines.removeAt(i);
                    onChanged([...lines]);
                  },
          ),
        ],
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            lines.add(RecipeLine());
            onChanged([...lines]);
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: productBrand,
            side: BorderSide(color: productBrand.withValues(alpha: 0.35)),
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Tambah bahan', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 12),
        _costEstimate(),
      ],
    );
  }

  Widget _costEstimate() {
    final hpp = estimateRecipeCost(lines, ingredients);
    final sell = sellPrice;
    final gap = sell == null ? null : sell - hpp;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: productBrand.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Perkiraan HPP satu porsi',
            style: TextStyle(color: Colors.black.withValues(alpha: 0.55)),
          ),
          const SizedBox(height: 4),
          Text(
            hpp <= 0 ? 'Isi bahan dan jumlah dulu' : formatRupiah(hpp),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          if (gap != null) ...[
            const SizedBox(height: 4),
            Text(
              'Selisih terhadap harga jual ${formatRupiah(gap)}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: gap < 0 ? const Color(0xFFB42318) : const Color(0xFF0B6E4F),
              ),
            ),
          ],
        ],
      ),
    );
  }

}

class _RecipeLineFields extends StatefulWidget {
  const _RecipeLineFields({
    super.key,
    required this.index,
    required this.line,
    required this.ingredients,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final RecipeLine line;
  final List<Map<String, dynamic>> ingredients;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  @override
  State<_RecipeLineFields> createState() => _RecipeLineFieldsState();
}

class _RecipeLineFieldsState extends State<_RecipeLineFields> {
  late final TextEditingController _quantity;

  @override
  void initState() {
    super.initState();
    _quantity = TextEditingController(text: widget.line.quantity);
  }

  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  Map<String, dynamic>? _ingredient(int? stockId) {
    for (final item in widget.ingredients) {
      if (int.tryParse('${item['id']}') == stockId) return item;
    }
    return null;
  }

  List<Map<String, dynamic>> _unitsFor(int? stockId) {
    final ingredient = _ingredient(stockId);
    final raw = ingredient?['available_units'];
    if (raw is List && raw.isNotEmpty) {
      return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    final unitId = int.tryParse('${ingredient?['display_unit_id'] ?? ''}');
    final unitName = ingredient?['display_unit_name']?.toString() ?? '';
    if (unitId == null) return [];
    return [
      {'id': unitId, 'name': unitName.isEmpty ? 'satuan' : unitName},
    ];
  }

  String _unitName(List<Map<String, dynamic>> units) {
    for (final unit in units) {
      if (int.tryParse('${unit['id']}') == widget.line.unitId) {
        return unit['name']?.toString() ?? '';
      }
    }
    return '';
  }

  String _preview(List<Map<String, dynamic>> units) {
    final name = widget.line.stockName.trim();
    if (name.isEmpty) return 'Pilih bahan, jumlah, dan satuan';
    final qty = _quantity.text.trim();
    final unit = _unitName(units);
    if (qty.isEmpty) return name;
    return [qty, unit, name].where((part) => part.isNotEmpty).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final line = widget.line;
    final units = _unitsFor(line.stockId);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: productBrand.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${widget.index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: productBrand),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bahan ${widget.index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      _preview(units),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.onRemove != null)
                IconButton(
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.delete_outline, color: productBrand),
                ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            isExpanded: true,
            initialValue: widget.ingredients.any(
              (e) => int.tryParse('${e['id']}') == line.stockId,
            )
                ? line.stockId
                : null,
            decoration: const InputDecoration(
              labelText: 'Bahan',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Color(0xFFF8FAFC),
            ),
            selectedItemBuilder: (context) => [
              for (final item in widget.ingredients)
                Text(
                  item['stock_name']?.toString() ?? '-',
                  overflow: TextOverflow.ellipsis,
                ),
            ],
            items: [
              for (final item in widget.ingredients)
                DropdownMenuItem(
                  value: int.tryParse('${item['id']}'),
                  child: Text(
                    item['stock_name']?.toString() ?? '-',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (id) {
              line.stockId = id;
              final ingredient = _ingredient(id);
              line.stockName = ingredient?['stock_name']?.toString() ?? '';
              line.unitId = int.tryParse('${ingredient?['display_unit_id'] ?? ''}');
              widget.onChanged();
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _quantity,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Jumlah',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Color(0xFFF8FAFC),
                  ),
                  onChanged: (value) {
                    line.quantity = value;
                    setState(() {});
                    widget.onChanged();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<int>(
                  isExpanded: true,
                  initialValue: units.any(
                    (e) => int.tryParse('${e['id']}') == line.unitId,
                  )
                      ? line.unitId
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Satuan',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Color(0xFFF8FAFC),
                  ),
                  selectedItemBuilder: (context) => [
                    for (final unit in units)
                      Text(
                        unit['name']?.toString() ?? '-',
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                  items: [
                    for (final unit in units)
                      DropdownMenuItem(
                        value: int.tryParse('${unit['id']}'),
                        child: Text(
                          unit['name']?.toString() ?? '-',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (id) {
                    line.unitId = id;
                    widget.onChanged();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class ProductImagePickerRow extends StatelessWidget {
  const ProductImagePickerRow({
    super.key,
    required this.existing,
    required this.pickedPaths,
    required this.onPick,
    required this.onRemoveExisting,
    required this.onRemovePicked,
    this.enabled = true,
    this.maxImages = 5,
  });

  final List<Map<String, dynamic>> existing;
  final List<String> pickedPaths;
  final VoidCallback onPick;
  final ValueChanged<int> onRemoveExisting;
  final ValueChanged<int> onRemovePicked;
  final bool enabled;
  final int maxImages;

  @override
  Widget build(BuildContext context) {
    final total = existing.length + pickedPaths.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Gambar produk',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            if (enabled && total < maxImages)
              TextButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Tambah'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...List.generate(existing.length, (i) {
              final url = resolveProductImageUrl([existing[i]]);
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: url == null
                        ? Container(
                            width: 72,
                            height: 72,
                            color: Colors.black12,
                          )
                        : CachedNetworkImage(
                            imageUrl: url,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                          ),
                  ),
                  if (enabled)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => onRemoveExisting(i),
                        icon: const Icon(Icons.cancel, color: productBrand),
                      ),
                    ),
                ],
              );
            }),
            ...List.generate(pickedPaths.length, (i) {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(pickedPaths[i]),
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (enabled)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => onRemovePicked(i),
                        icon: const Icon(Icons.cancel, color: productBrand),
                      ),
                    ),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }
}

Future<String?> pickProductImage() async {
  final file = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    imageQuality: 85,
  );
  return file?.path;
}
