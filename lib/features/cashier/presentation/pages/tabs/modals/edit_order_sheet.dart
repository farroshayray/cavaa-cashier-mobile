import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/core/services/connectivity_status_provider.dart';
import '/features/cashier/data/models/checkout_exceptions.dart';
import '/features/cashier/data/models/purchase_models.dart';
import '/features/cashier/presentation/pages/tabs/modals/cart_sheet.dart';
import '/features/cashier/presentation/pages/tabs/modals/edit_product_picker_sheet.dart';
import '/features/cashier/presentation/pages/tabs/modals/product_option_sheet.dart';
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
  EditOrderProvider? _editVm;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _editVm?.removeListener(_syncStockOverlay);
    context.read<PurchaseProvider>().clearStockOverlay();
    super.dispose();
  }

  void _syncStockOverlay() {
    if (!mounted || _editVm == null) return;
    context.read<PurchaseProvider>().setStockOverlay(_editVm!.stockOverlayLines);
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

    _editVm = editVm;
    editVm.addListener(_syncStockOverlay);
    _syncStockOverlay();
  }

  Future<void> _save() async {
    final editVm = context.read<EditOrderProvider>();
    final isOnline = context.read<ConnectivityStatusProvider>().isOnline;

    final sendToProcess = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Simpan Perubahan'),
        content: const Text(
          'Pilih tindakan setelah menyimpan:\n\n'
          '• Kirim ke Proses Kitchen — order masuk tab Proses dan langsung terkonfirmasi, '
          'sehingga kitchen dapat melihat pesanan.\n\n'
          '• Tetap di Stage Ini — hanya memperbarui menu, status order tidak berubah.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Tetap di Stage Ini'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kirim ke Proses Kitchen'),
          ),
        ],
      ),
    );

    if (sendToProcess == null || !mounted) return;

    try {
      await editVm.save(isOnline: isOnline, sendToProcess: sendToProcess);
      if (!mounted) return;
      await widget.onSaved();
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sendToProcess
                ? (isOnline
                    ? 'Order diperbarui dan dikirim ke Proses Kitchen'
                    : 'Perubahan disimpan, order akan dikirim ke kitchen saat online')
                : (isOnline
                    ? 'Order berhasil diperbarui'
                    : 'Perubahan disimpan, menunggu sinkronisasi'),
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
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: purchaseVm),
          ChangeNotifierProvider.value(value: context.read<EditOrderProvider>()),
        ],
        child: const EditProductPickerSheet(),
      ),
    );
    _syncStockOverlay();
  }

  Future<void> _openItemEditor(int index) async {
    final editVm = context.read<EditOrderProvider>();
    final purchaseVm = context.read<PurchaseProvider>();
    final item = editVm.items[index];
    if (item.isLocked) return;

    Product product = item.product;
    for (final candidate in purchaseVm.products) {
      if (candidate.id == product.id) {
        product = candidate;
        break;
      }
    }

    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: purchaseVm,
        child: ProductOptionsSheet(
          product: product,
          editingItem: item.cart,
          confirmLabel: 'Perbarui Item',
          onConfirm: ({
            required qty,
            required selected,
            required note,
            required unitFinalPrice,
          }) {
            editVm.updateItemAt(
              index,
              qty: qty,
              selected: selected,
              note: note,
              unitFinalPrice: unitFinalPrice,
            );
          },
        ),
      ),
    );
    _syncStockOverlay();
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
              Expanded(child: Center(child: Text(editVm.error!)))
            else
              Expanded(
                child: editVm.items.isEmpty
                    ? const Center(child: Text('Belum ada item.'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: editVm.items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final item = editVm.items[i];
                          if (item.isLocked) {
                            return _LockedItemRow(item: item);
                          }
                          return _EditableItemRow(
                            index: i,
                            item: item,
                            onEdit: () => _openItemEditor(i),
                          );
                        },
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
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brand,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
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
                        : const Text(
                            'Simpan',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
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

class _LockedItemRow extends StatelessWidget {
  const _LockedItemRow({required this.item});

  final EditableCartItem item;

  @override
  Widget build(BuildContext context) {
    final purchaseVm = context.watch<PurchaseProvider>();
    final optionLines = selectedOptionTextLines(item.cart, purchaseVm);
    final promo = item.product.promotion;
    final hasPromo = promo != null;
    final note = item.note.trim();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.withOpacity(0.35)),
        color: Colors.blue.withOpacity(0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    if (hasPromo) ...[
                      const SizedBox(height: 2),
                      Text(
                        promo.type == 'percentage'
                            ? 'Diskon ${promo.value}%'
                            : 'Potongan Rp ${_rupiah(promo.value)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFAE1504),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.lockStatusLabel ?? 'Sudah diproses',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          if (optionLines.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...optionLines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  line,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.62),
                  ),
                ),
              ),
            ),
          ],
          if (note.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Catatan: $note',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black.withOpacity(0.62),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${item.qty}x',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(width: 8),
              Text(
                '@ Rp ${_rupiah(item.unitFinalPrice)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withOpacity(0.55),
                ),
              ),
              const Spacer(),
              Text(
                'Rp ${_rupiah(item.lineTotal)}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditableItemRow extends StatefulWidget {
  const _EditableItemRow({
    required this.index,
    required this.item,
    required this.onEdit,
  });

  final int index;
  final EditableCartItem item;
  final VoidCallback onEdit;

  @override
  State<_EditableItemRow> createState() => _EditableItemRowState();
}

class _EditableItemRowState extends State<_EditableItemRow> {
  late final TextEditingController _noteC;

  @override
  void initState() {
    super.initState();
    _noteC = TextEditingController(text: widget.item.note);
  }

  @override
  void didUpdateWidget(covariant _EditableItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item.note != _noteC.text) {
      _noteC.text = widget.item.note;
    }
  }

  @override
  void dispose() {
    _noteC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editVm = context.read<EditOrderProvider>();
    final purchaseVm = context.watch<PurchaseProvider>();
    final item = widget.item;
    final i = widget.index;
    final cartLine = item.cart;

    final stockNotices = stockNoticesFor(cartLine, purchaseVm);
    final hasBlockingWarning = stockNotices.any((notice) => notice.blocking);
    final optionLines = selectedOptionTextLines(cartLine, purchaseVm);
    final maxQty = purchaseVm.maxAddableQtyWithOptions(
      product: item.product,
      selected: item.selected,
      excludingItem: cartLine,
    );

    final promo = item.product.promotion;
    final hasPromo = promo != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: widget.onEdit,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasBlockingWarning
                  ? Colors.redAccent.withOpacity(0.55)
                  : Colors.black.withOpacity(0.10),
            ),
            color: hasBlockingWarning
                ? Colors.redAccent.withOpacity(0.04)
                : Colors.white,
          ),
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
                          item.product.name,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        if (hasPromo) ...[
                          const SizedBox(height: 2),
                          Text(
                            promo.type == 'percentage'
                                ? 'Diskon ${promo.value}%'
                                : 'Potongan Rp ${_rupiah(promo.value)}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFAE1504),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onEdit,
                    icon: const Icon(Icons.tune_rounded, size: 20),
                    tooltip: 'Ubah opsi',
                  ),
                  IconButton(
                    onPressed: () => editVm.removeAt(i),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
              if (stockNotices.isNotEmpty) ...[
                const SizedBox(height: 6),
                ...stockNotices.map(
                  (notice) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      notice.text,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: notice.blocking ? Colors.redAccent : Colors.orange,
                      ),
                    ),
                  ),
                ),
              ],
              ...optionLines.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    line,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black.withOpacity(0.62),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: item.qty <= item.minQty
                        ? null
                        : () => editVm.setQty(i, item.qty - 1, maxQty: maxQty),
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                  ),
                  Text(
                    '${item.qty}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  IconButton(
                    onPressed: item.qty >= maxQty
                        ? null
                        : () => editVm.setQty(i, item.qty + 1, maxQty: maxQty),
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
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: widget.onEdit,
                  child: const Text('Ubah opsi & qty'),
                ),
              ),
            ],
          ),
        ),
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
