import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '/core/config/env.dart';

const productBrand = Color(0xFFAE1504);

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
  });

  int? optionId;
  String name;
  String price;
  String description;
  bool alwaysAvailable;

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
  });

  final List<MenuOptionGroup> groups;
  final ValueChanged<List<MenuOptionGroup>> onChanged;
  final bool readOnly;
  final bool showOptionStock;

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
