import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/core/services/connectivity_status_provider.dart';
import '/features/cashier/data/models/checkout_exceptions.dart';
import '/features/cashier/data/models/purchase_models.dart';
import '/features/cashier/presentation/providers/edit_order_provider.dart';
import '/features/cashier/presentation/providers/purchase_provider.dart';

class EditOrderSheet extends StatefulWidget {
  const EditOrderSheet({
    super.key,
    required this.order,
    required this.onSaved,
  });

  final Map<String, dynamic> order;
  final Future<void> Function() onSaved;

  @override
  State<EditOrderSheet> createState() => _EditOrderSheetState();
}

class _EditOrderSheetState extends State<EditOrderSheet> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    final editVm = context.read<EditOrderProvider>();
    final purchaseVm = context.read<PurchaseProvider>();

    if (purchaseVm.products.isEmpty) {
      await purchaseVm.load();
    }

    editVm.reset();
    await editVm.loadFromOrder(
      order: widget.order,
      catalog: purchaseVm.products,
    );
  }

  Future<void> _save() async {
    final editVm = context.read<EditOrderProvider>();
    final isOnline = context.read<ConnectivityStatusProvider>().isOnline;

    try {
      await editVm.save(isOnline: isOnline);
      if (!mounted) return;
      await widget.onSaved();
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isOnline ? 'Order berhasil diperbarui' : 'Perubahan disimpan, menunggu sinkronisasi',
          ),
        ),
      );
    } on StockInsufficientException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e')),
      );
    }
  }

  Future<void> _openProductPicker() async {
    final purchaseVm = context.read<PurchaseProvider>();
    if (purchaseVm.products.isEmpty) {
      await purchaseVm.load();
    }

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Container(
            height: MediaQuery.of(ctx).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Tambah Menu',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: purchaseVm.products.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final product = purchaseVm.products[i];
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.black.withOpacity(0.08)),
                        ),
                        title: Text(
                          product.name,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text('Rp ${_rupiah(product.price)}'),
                        trailing: const Icon(Icons.add_circle_outline_rounded),
                        onTap: product.isAvailableForSale
                            ? () {
                                context.read<EditOrderProvider>().addProduct(product);
                                Navigator.pop(ctx);
                              }
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);
    final editVm = context.watch<EditOrderProvider>();

    return SafeArea(
      top: false,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.92,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Ubah Order',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: editVm.isLoading ? null : _openProductPicker,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Tambah Menu'),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (editVm.isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (editVm.error != null && editVm.items.isEmpty)
              Expanded(
                child: Center(child: Text(editVm.error!)),
              )
            else
              Expanded(
                child: editVm.items.isEmpty
                    ? const Center(child: Text('Belum ada item.'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: editVm.items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _EditItemRow(index: i, item: editVm.items[i]),
                      ),
              ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.55),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Rp ${_rupiah(editVm.grandTotalWithPpn)}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brand,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    ),
                    onPressed: editVm.isSaving || !editVm.hasItems ? null : _save,
                    child: editVm.isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Simpan', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditItemRow extends StatefulWidget {
  const _EditItemRow({required this.index, required this.item});

  final int index;
  final EditableCartItem item;

  @override
  State<_EditItemRow> createState() => _EditItemRowState();
}

class _EditItemRowState extends State<_EditItemRow> {
  late final TextEditingController _noteC;

  @override
  void initState() {
    super.initState();
    _noteC = TextEditingController(text: widget.item.note);
  }

  @override
  void dispose() {
    _noteC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editVm = context.read<EditOrderProvider>();
    final item = widget.item;
    final i = widget.index;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.isLocked
              ? Colors.blue.withOpacity(0.35)
              : Colors.black.withOpacity(0.10),
        ),
        color: item.isLocked ? Colors.blue.withOpacity(0.04) : Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.product.name,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              if (item.isLocked)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Sudah diproses',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ),
              if (!item.isLocked)
                IconButton(
                  onPressed: () => editVm.removeAt(i),
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: item.isLocked || item.qty <= item.minQty
                    ? null
                    : () => editVm.setQty(i, item.qty - 1),
                icon: const Icon(Icons.remove_circle_outline_rounded),
              ),
              Text('${item.qty}', style: const TextStyle(fontWeight: FontWeight.w900)),
              IconButton(
                onPressed: () => editVm.setQty(i, item.qty + 1),
                icon: const Icon(Icons.add_circle_outline_rounded),
              ),
              const Spacer(),
              Text(
                'Rp ${_rupiah(item.lineTotal)}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          TextField(
            controller: _noteC,
            decoration: const InputDecoration(
              labelText: 'Keterangan',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => editVm.setNote(i, v),
          ),
        ],
      ),
    );
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
