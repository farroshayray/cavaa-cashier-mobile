import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '/core/config/env.dart';

const productBrand = Color(0xFFAE1504);

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
    this.alwaysAvailable = false,
    this.stockType = 'direct',
    this.stockQuantity = '',
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
  bool stockEditable;
  List<RecipeLine> recipes;

  factory MenuOptionItem.fromJson(Map<String, dynamic> json) {
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
      stockEditable: json['stock_editable'] != false &&
          (json['stock_type']?.toString() ?? 'direct') != 'linked',
      recipes: recipeLinesFrom(json['recipes']),
    );
  }

  Map<String, dynamic> toJson({bool includeAlwaysAvailable = false}) {
    return {
      if (optionId != null) 'option_id': optionId,
      'name': name,
      'price': int.tryParse(price.replaceAll('.', '').trim()) ?? 0,
      'description': description.isEmpty ? null : description,
      if (includeAlwaysAvailable) 'always_available': alwaysAvailable,
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

class ProductMenuOptionsEditor extends StatelessWidget {
  const ProductMenuOptionsEditor({
    super.key,
    required this.groups,
    required this.onChanged,
    this.readOnly = false,
    this.showOptionStock = false,
    this.canManageStock = false,
    this.ingredients = const [],
  });

  final List<MenuOptionGroup> groups;
  final ValueChanged<List<MenuOptionGroup>> onChanged;
  final bool readOnly;
  final bool showOptionStock;
  final bool canManageStock;
  final List<Map<String, dynamic>> ingredients;

  void _emit() => onChanged([...groups]);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                onPressed: () {
                  groups.add(MenuOptionGroup());
                  _emit();
                },
                icon: const Icon(Icons.add),
                label: const Text('Grup'),
              ),
          ],
        ),
        if (groups.isEmpty)
          Text(
            readOnly
                ? 'Tidak ada opsi.'
                : 'Belum ada grup opsi. Tambah jika produk punya pilihan.',
            style: TextStyle(color: Colors.black.withValues(alpha: 0.5)),
          ),
        ...List.generate(groups.length, (gi) {
          final g = groups[gi];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Grup #${gi + 1}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (!readOnly)
                      IconButton(
                        onPressed: () {
                          groups.removeAt(gi);
                          _emit();
                        },
                        icon: const Icon(Icons.delete_outline, color: productBrand),
                      ),
                  ],
                ),
                TextField(
                  controller: TextEditingController(text: g.name)
                    ..selection = TextSelection.collapsed(offset: g.name.length),
                  enabled: !readOnly,
                  decoration: const InputDecoration(
                    labelText: 'Nama grup (mis. Level Pedas)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    g.name = v;
                  },
                ),
                const SizedBox(height: 8),
                if (!readOnly) ...[
                  DropdownButtonFormField<String>(
                    initialValue: provisionChoices.containsKey(g.provision)
                        ? g.provision
                        : 'OPTIONAL',
                    decoration: const InputDecoration(
                      labelText: 'Aturan pilihan',
                      border: OutlineInputBorder(),
                    ),
                    items: provisionChoices.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      g.provision = v;
                      _emit();
                    },
                  ),
                  if (g.provision != 'OPTIONAL') ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: TextEditingController(text: g.provisionValue),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Nilai aturan',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => g.provisionValue = v,
                    ),
                  ],
                  const SizedBox(height: 8),
                  TextField(
                    controller: TextEditingController(text: g.description),
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi grup (opsional)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => g.description = v,
                  ),
                ] else ...[
                  Text(
                    '${provisionChoices[g.provision] ?? g.provision}'
                    '${g.provision != 'OPTIONAL' ? ' · ${g.provisionValue}' : ''}',
                    style: TextStyle(color: Colors.black.withValues(alpha: 0.55)),
                  ),
                  if (g.description.isNotEmpty) Text(g.description),
                ],
                const SizedBox(height: 10),
                ...List.generate(g.options.length, (oi) {
                  final opt = g.options[oi];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: TextEditingController(text: opt.name)
                                  ..selection = TextSelection.collapsed(
                                    offset: opt.name.length,
                                  ),
                                enabled: !readOnly,
                                decoration: InputDecoration(
                                  labelText: 'Opsi #${oi + 1}',
                                  border: const OutlineInputBorder(),
                                ),
                                onChanged: (v) => opt.name = v,
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 100,
                              child: TextField(
                                controller:
                                    TextEditingController(text: opt.price)
                                      ..selection = TextSelection.collapsed(
                                        offset: opt.price.length,
                                      ),
                                enabled: !readOnly,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Harga',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (v) => opt.price = v,
                              ),
                            ),
                            if (!readOnly)
                              IconButton(
                                onPressed: g.options.length <= 1
                                    ? null
                                    : () {
                                        g.options.removeAt(oi);
                                        _emit();
                                      },
                                icon: const Icon(Icons.close),
                              ),
                          ],
                        ),
                        if (showOptionStock && canManageStock) ...[
                          const SizedBox(height: 8),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'always', label: Text('Selalu')),
                              ButtonSegment(value: 'direct', label: Text('Pcs')),
                              ButtonSegment(value: 'linked', label: Text('Resep')),
                            ],
                            selected: {
                              opt.stockType == 'linked'
                                  ? 'linked'
                                  : opt.alwaysAvailable
                                      ? 'always'
                                      : 'direct',
                            },
                            onSelectionChanged: (v) {
                              final mode = v.first;
                              opt.stockType = mode == 'linked' ? 'linked' : 'direct';
                              opt.alwaysAvailable = mode == 'always';
                              opt.stockEditable = mode == 'direct';
                              if (mode == 'linked' && opt.recipes.isEmpty) {
                                opt.recipes.add(RecipeLine());
                              }
                              _emit();
                            },
                          ),
                          if (opt.stockType != 'linked' && !opt.alwaysAvailable)
                            Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 8),
                              child: TextField(
                                controller: TextEditingController(
                                  text: opt.stockQuantity,
                                )..selection = TextSelection.collapsed(
                                    offset: opt.stockQuantity.length,
                                  ),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Stok (pcs)',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (v) => opt.stockQuantity = v,
                              ),
                            ),
                          if (opt.stockType == 'linked')
                            LinkedRecipeEditor(
                              lines: opt.recipes,
                              ingredients: ingredients,
                              sellPrice: num.tryParse(opt.price.replaceAll('.', '').trim()),
                              onChanged: (next) {
                                opt.recipes = next;
                                _emit();
                              },
                            ),
                        ] else ...[
                        if (showOptionStock)
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            activeThumbColor: productBrand,
                            title: const Text('Opsi selalu tersedia'),
                            value: opt.alwaysAvailable,
                            onChanged: (v) {
                              opt.alwaysAvailable = v;
                              _emit();
                            },
                          ),
                        if (showOptionStock && !opt.alwaysAvailable)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: opt.stockEditable
                                ? TextField(
                                    controller: TextEditingController(
                                      text: opt.stockQuantity,
                                    )..selection = TextSelection.collapsed(
                                        offset: opt.stockQuantity.length,
                                      ),
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Stok (pcs)',
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (v) => opt.stockQuantity = v,
                                  )
                                : InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'Stok dari resep (pcs)',
                                      border: OutlineInputBorder(),
                                    ),
                                    child: Text(
                                      opt.stockQuantity.isEmpty
                                          ? '0'
                                          : opt.stockQuantity,
                                    ),
                                  ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
                if (!readOnly)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () {
                        g.options.add(MenuOptionItem());
                        _emit();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah opsi'),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
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
      return const Padding(
        padding: EdgeInsets.only(top: 8, bottom: 8),
        child: Text('Tambah bahan dulu di menu Stok.'),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < lines.length; i++) ...[
          const SizedBox(height: 8),
          _RecipeLineFields(
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
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              lines.add(RecipeLine());
              onChanged([...lines]);
            },
            icon: const Icon(Icons.add),
            label: const Text('Bahan resep'),
          ),
        ),
        _costEstimate(),
      ],
    );
  }

  Widget _costEstimate() {
    final hpp = _estimatedCost();
    if (hpp <= 0) return const SizedBox.shrink();
    final sell = sellPrice;
    final gap = sell == null ? null : sell - hpp;
    String money(num value) {
      final rounded = value.round();
      final text = rounded.abs().toString();
      final buffer = StringBuffer(rounded < 0 ? '-' : '');
      for (var i = 0; i < text.length; i++) {
        if (i > 0 && (text.length - i) % 3 == 0) buffer.write('.');
        buffer.write(text[i]);
      }
      return 'Rp $buffer';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Perkiraan HPP ${money(hpp)}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (gap != null)
            Text(
              'Selisih terhadap harga jual ${money(gap)}',
              style: TextStyle(
                color: gap < 0 ? const Color(0xFFB42318) : Colors.black54,
              ),
            ),
        ],
      ),
    );
  }

  double _estimatedCost() {
    var total = 0.0;
    for (final line in lines) {
      Map<String, dynamic>? ingredient;
      for (final item in ingredients) {
        if (int.tryParse('${item['id']}') == line.stockId) ingredient = item;
      }
      if (ingredient == null) continue;
      final qty = double.tryParse(line.quantity.replaceAll(',', '.')) ?? 0;
      final basePrice = ingredient['base_price'];
      final price = basePrice is num ? basePrice.toDouble() : double.tryParse('$basePrice') ?? 0;
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
}

class _RecipeLineFields extends StatelessWidget {
  const _RecipeLineFields({
    required this.line,
    required this.ingredients,
    required this.onChanged,
    required this.onRemove,
  });

  final RecipeLine line;
  final List<Map<String, dynamic>> ingredients;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  Map<String, dynamic>? _ingredient(int? stockId) {
    for (final item in ingredients) {
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

  @override
  Widget build(BuildContext context) {
    final units = _unitsFor(line.stockId);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                isExpanded: true,
                initialValue: ingredients.any(
                  (e) => int.tryParse('${e['id']}') == line.stockId,
                )
                    ? line.stockId
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Bahan',
                  border: OutlineInputBorder(),
                ),
                selectedItemBuilder: (context) => [
                  for (final item in ingredients)
                    Text(
                      item['stock_name']?.toString() ?? '-',
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
                items: [
                  for (final item in ingredients)
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
                  onChanged();
                },
              ),
            ),
            if (onRemove != null)
              IconButton(onPressed: onRemove, icon: const Icon(Icons.close)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: TextEditingController(text: line.quantity)
                  ..selection = TextSelection.collapsed(offset: line.quantity.length),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Jumlah',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => line.quantity = v,
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
                  onChanged();
                },
              ),
            ),
          ],
        ),
      ],
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
