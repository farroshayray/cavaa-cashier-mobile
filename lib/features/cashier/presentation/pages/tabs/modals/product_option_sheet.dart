import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/features/cashier/presentation/providers/purchase_provider.dart';
import '/features/cashier/data/models/purchase_models.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';

class ProductOptionsSheet extends StatefulWidget {
  const ProductOptionsSheet({super.key, required this.product});
  final Product product;

  @override
  State<ProductOptionsSheet> createState() => _ProductOptionsSheetState();
}

class _ProductOptionsSheetState extends State<ProductOptionsSheet> {
  int qty = 1;
  final noteC = TextEditingController();
  final Map<int, Set<int>> selected = {}; // groupId -> set<optionId>

  @override
  void dispose() {
    noteC.dispose();
    super.dispose();
  }

  bool _isValid(PurchaseProvider vm) {
    for (final g in widget.product.optionGroups) {
      final count = selected[g.id]?.length ?? 0;

      // DEBUG
      // ignore: avoid_print
      // print('group=${g.name} min=${g.min} max=${g.max} count=$count');

      if (count < g.min) return false;
      if (g.max > 0 && count > g.max) return false;

      final picked = selected[g.id] ?? <int>{};
      for (final optId in picked) {
        final item = firstWhereOrNull<OptionItem>(g.items, (x) => x.id == optId);
        if (item == null ||
            vm.availableQtyForOption(item) < qty) {
          return false;
        }
      }
    }
    return vm.canAddWithOptions(
      product: widget.product,
      qty: qty,
      selected: selected,
    );
  }

  int _maxSelectableQty(PurchaseProvider vm) {
    return vm.maxAddableQtyWithOptions(
      product: widget.product,
      selected: selected,
    );
  }

  num get optionExtra {
    num extra = 0;
    for (final g in widget.product.optionGroups) {
      final picked = selected[g.id] ?? {};
      for (final id in picked) {
        final item = firstWhereOrNull<OptionItem>(g.items, (x) => x.id == id);
        if (item != null) extra += item.price;
      }
    }
    return extra;
  }

  num get unitFinal => promoUnitPrice(widget.product) + optionExtra;
  num get total => unitFinal * qty;

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);
    final vm = context.watch<PurchaseProvider>();
    final maxQty = _maxSelectableQty(vm);
    final canSave = _isValid(vm);
    final productRemaining = widget.product.alwaysAvailable
        ? null
        : vm.availableQtyForProduct(widget.product);

    return SafeArea(
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: Column(
            children: [
              // header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 72,
                        height: 72,
                        color: const Color(0xFFF3F4F6),
                        child: _ProductImage(path: widget.product.imagePath),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (promoUnitPrice(widget.product) < widget.product.price) ...[
                            Text(
                              'Rp ${_rupiah(widget.product.price)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black.withOpacity(0.5),
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(height: 2),
                          ],
                          Text(
                            'Harga: Rp ${_rupiah(promoUnitPrice(widget.product))}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.black.withOpacity(0.7),
                            ),
                          ),
                          if (productRemaining != null &&
                              productRemaining <= 3) ...[
                            const SizedBox(height: 4),
                            Text(
                              productRemaining <= 0
                                  ? 'Stok produk habis'
                                  : 'Sisa stok produk $productRemaining',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: productRemaining <= 0
                                    ? Colors.redAccent
                                    : Colors.orange,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // body scroll
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  children: [
                    if ((widget.product.description ?? '').isNotEmpty) ...[
                      Text(
                        widget.product.description!,
                        style: TextStyle(color: Colors.black.withOpacity(0.65)),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // option groups
                    for (final g in widget.product.optionGroups) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              g.name,
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                            ),
                          ),
                          if (g.required)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: brand.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text('Wajib', style: TextStyle(color: brand, fontSize: 12, fontWeight: FontWeight.w800)),
                            )
                        ],
                      ),
                      const SizedBox(height: 8),

                      ...g.items.map((it) {
                        final picked = selected[g.id] ?? {};
                        final checked = picked.contains(it.id);
                        final remaining = vm.availableQtyForOption(it);
                        final isOptionOut =
                            !it.alwaysAvailable && remaining <= 0;

                        return InkWell(
                          onTap: isOptionOut
                              ? null
                              : () {
                                  setState(() {
                                    selected.putIfAbsent(g.id, () => <int>{});
                                    if (g.multiple) {
                                      if (checked) {
                                        selected[g.id]!.remove(it.id);
                                      } else {
                                        selected[g.id]!.add(it.id);
                                      }
                                    } else {
                                      // radio
                                      selected[g.id] = {it.id};
                                    }
                                  });
                                },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: checked
                                    ? brand
                                    : isOptionOut
                                        ? Colors.black.withOpacity(0.06)
                                        : Colors.black.withOpacity(0.10),
                              ),
                              color: isOptionOut
                                  ? const Color(0xFFF3F4F6)
                                  : checked
                                      ? brand.withOpacity(0.06)
                                      : Colors.white,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  g.multiple
                                      ? (checked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded)
                                      : (checked ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded),
                                  color: isOptionOut
                                      ? Colors.black26
                                      : checked
                                          ? brand
                                          : Colors.black54,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        it.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: isOptionOut ? Colors.black38 : Colors.black87,
                                        ),
                                      ),
                                      if (isOptionOut)
                                        const Padding(
                                          padding: EdgeInsets.only(top: 2),
                                          child: Text(
                                            'Habis',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.black38,
                                            ),
                                          ),
                                        )
                                      else if (!it.alwaysAvailable && remaining <= 3)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Text(
                                            'Sisa $remaining',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.orange,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (it.price > 0)
                                  Text(
                                    '+Rp ${it.price.toString()}',
                                    style: TextStyle(
                                      color: isOptionOut
                                          ? Colors.black38
                                          : Colors.black.withOpacity(0.65),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 8),
                    ],

                    // note
                    TextField(
                      controller: noteC,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Catatan (opsional)…',
                        filled: true,
                        fillColor: const Color(0xFFF7F8FA),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.black.withOpacity(0.10)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: brand, width: 1.3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // footer: qty + save
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  children: [
                    // qty stepper
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black.withOpacity(0.10)),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: qty <= 1 ? null : () => setState(() => qty--),
                            icon: const Icon(Icons.remove_rounded),
                          ),
                          Text('$qty', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                          IconButton(
                            onPressed: qty >= maxQty ? null : () => setState(() => qty++),
                            icon: const Icon(Icons.add_rounded),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // save
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brand,
                          disabledBackgroundColor: brand.withOpacity(0.4),
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.white70,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),

                        onPressed: canSave
                            ? () {
                                context.read<PurchaseProvider>().addWithOptions(
                                      product: widget.product,
                                      qty: qty,
                                      selected: selected,
                                      note: noteC.text.trim(),
                                    );
                                Navigator.pop(context);
                              }
                            : null,
                        child: Text(
                          'Simpan • Rp ${_rupiah(total)}',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.path});

  final String? path;

  bool _isLocalFile(String value) {
    return value.startsWith('/') || value.startsWith('file://');
  }

  @override
  Widget build(BuildContext context) {
    final raw = path?.trim();

    if (raw == null || raw.isEmpty) {
      return const Icon(
        Icons.image_not_supported_outlined,
        size: 32,
        color: Colors.black45,
      );
    }

    if (_isLocalFile(raw)) {
      final filePath = raw.startsWith('file://')
          ? raw.replaceFirst('file://', '')
          : raw;

      final file = File(filePath);

      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.broken_image_outlined,
          size: 32,
          color: Colors.black45,
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: raw,
      fit: BoxFit.cover,
      placeholder: (_, __) => const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      errorWidget: (_, __, ___) => const Icon(
        Icons.broken_image_outlined,
        size: 32,
        color: Colors.black45,
      ),
    );
  }
}


T? firstWhereOrNull<T>(Iterable<T> list, bool Function(T) test) {
  for (final x in list) {
    if (test(x)) return x;
  }
  return null;
}

num promoUnitPrice(Product p) {
  final promo = p.promotion;
  final base = p.price;

  if (promo == null) return base;

  final v = promo.value; // num
  if (promo.type == 'percentage') {
    final after = base.toDouble() * (1.0 - (v.toDouble() / 100.0));
    return after < 0 ? 0 : after;
  } else {
    final after = base.toDouble() - v.toDouble();
    return after < 0 ? 0 : after;
  }
}

String _rupiah(num n) {
  final s = n.toInt().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final idxFromEnd = s.length - i;
    buf.write(s[i]);
    if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buf.write('.');
  }
  return buf.toString();
}
