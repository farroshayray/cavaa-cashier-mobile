import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/features/cashier/data/models/purchase_models.dart';
import '/features/cashier/presentation/pages/tabs/modals/product_option_sheet.dart';
import '/features/cashier/presentation/providers/edit_order_provider.dart';
import '/features/cashier/presentation/providers/purchase_provider.dart';

class EditProductPickerSheet extends StatefulWidget {
  const EditProductPickerSheet({super.key});

  @override
  State<EditProductPickerSheet> createState() => _EditProductPickerSheetState();
}

class _EditProductPickerSheetState extends State<EditProductPickerSheet> {
  final _searchC = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  Future<void> _onProductTap(Product product) async {
    final purchaseVm = context.read<PurchaseProvider>();
    final editVm = context.read<EditOrderProvider>();

    if (!product.isAvailableForSale) return;

    if (product.optionGroups.isNotEmpty) {
      await showModalBottomSheet<void>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ChangeNotifierProvider.value(
          value: purchaseVm,
          child: ProductOptionsSheet(
            product: product,
            onConfirm: ({
              required qty,
              required selected,
              required note,
              required unitFinalPrice,
            }) {
              editVm.addWithOptions(
                product: product,
                qty: qty,
                selected: selected,
                note: note,
                unitFinalPrice: unitFinalPrice,
              );
            },
          ),
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);
      return;
    }

    editVm.addWithOptions(
      product: product,
      qty: 1,
      selected: const {},
      note: '',
      unitFinalPrice: _promoUnitPrice(product),
    );
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final purchaseVm = context.watch<PurchaseProvider>();
    final q = _query.trim().toLowerCase();
    final products = purchaseVm.products.where((p) {
      if (!q.isEmpty) {
        final name = p.name.toLowerCase();
        final desc = (p.description ?? '').toLowerCase();
        if (!name.contains(q) && !desc.contains(q)) return false;
      }
      return true;
    }).toList();

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.82,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Tambah Menu',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchC,
                decoration: InputDecoration(
                  hintText: 'Cari menu...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final product = products[i];
                  final available = product.isAvailableForSale;
                  final unit = _promoUnitPrice(product);
                  final hasPromo = unit < product.price;

                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.black.withOpacity(0.08)),
                    ),
                    title: Text(
                      product.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: available ? null : Colors.black45,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasPromo) ...[
                          Text(
                            'Rp ${_rupiah(product.price)}',
                            style: TextStyle(
                              fontSize: 11,
                              decoration: TextDecoration.lineThrough,
                              color: Colors.black.withOpacity(0.45),
                            ),
                          ),
                        ],
                        Text('Rp ${_rupiah(unit)}'),
                        if (product.optionGroups.isNotEmpty)
                          Text(
                            'Ada pilihan opsi',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.black.withOpacity(0.55),
                            ),
                          ),
                        if (!available)
                          const Text(
                            'Tidak tersedia',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.redAccent,
                            ),
                          ),
                      ],
                    ),
                    trailing: Icon(
                      available ? Icons.add_circle_outline_rounded : Icons.block,
                      color: available ? const Color(0xFFAE1504) : Colors.black26,
                    ),
                    onTap: available ? () => _onProductTap(product) : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

num _promoUnitPrice(Product p) {
  final promo = p.promotion;
  final base = p.price;
  if (promo == null) return base;
  if (promo.type == 'percentage') {
    final after = base.toDouble() * (1.0 - (promo.value.toDouble() / 100.0));
    return after < 0 ? 0 : after;
  }
  final after = base.toDouble() - promo.value.toDouble();
  return after < 0 ? 0 : after;
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
