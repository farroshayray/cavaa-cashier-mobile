import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/features/cashier/presentation/providers/purchase_provider.dart';
import '/features/cashier/data/models/purchase_models.dart';

enum PayMethod { cash, qris }

class CheckoutSheet extends StatefulWidget {
  const CheckoutSheet({
    super.key,
    this.onSubmit,
  });

  final Future<void> Function({
    required String customerName,
    required StoreTable table,
    required PayMethod method,
  })? onSubmit;

  @override
  State<CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<CheckoutSheet> {
  final _nameCtrl = TextEditingController();
  StoreTable? _selectedTable;
  PayMethod? _method;
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  bool get _isValid {
    final nameOk = _nameCtrl.text.trim().isNotEmpty;
    final tableOk = _selectedTable != null;
    final methodOk = _method != null;
    return nameOk && tableOk && methodOk && !_submitting;
  }

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);
    final vm = context.watch<PurchaseProvider>();
    final items = vm.cart;
    final availableTables = vm.tables.where((t) => t.isAvailable).toList();

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: Column(
          children: [
            // ===== Header =====
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Konfirmasi Pesanan',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton(
                    onPressed: _submitting ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  )
                ],
              ),
            ),
            const Divider(height: 1),

            // ===== Body (scroll) =====
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ITEMS title
                    Text(
                      'ITEMS',
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w900,
                        color: Colors.black.withOpacity(0.55),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Items list (card)
                    ...items.map((it) => _ItemRow(it: it)).toList(),
                    const SizedBox(height: 12),

                    // Total card
                    _TotalCard(total: vm.cartGrandTotal),
                    const SizedBox(height: 14),

                    // Nama Pemesan
                    _SectionLabel(icon: Icons.person_outline_rounded, text: 'Nama Pemesan'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameCtrl,
                      enabled: !_submitting,
                      onChanged: (_) => setState(() {}),
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: 'Contoh: Budi Setiawan',
                        helperText: 'Isi nama agar pesanan mudah dipanggil',
                        filled: true,
                        fillColor: const Color(0xFFF7F8FA),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.black.withOpacity(0.10)),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: brand, width: 1.3),
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Pilih Meja
                    _SectionLabel(icon: Icons.table_restaurant_outlined, text: 'Pilih Meja'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<StoreTable>(
                      value: _selectedTable,
                      items: availableTables
                          .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                          .toList(),
                      onChanged: _submitting ? null : (v) => setState(() => _selectedTable = v),
                      decoration: InputDecoration(
                        hintText: availableTables.isEmpty ? 'Tidak ada meja tersedia' : 'Pilih meja',
                        helperText: 'Meja yang tidak tersedia tidak dapat dipilih',
                        filled: true,
                        fillColor: const Color(0xFFF7F8FA),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.black.withOpacity(0.10)),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: brand, width: 1.3),
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Metode Pembayaran
                    _SectionLabel(icon: Icons.credit_card_rounded, text: 'Metode Pembayaran'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _PayCard(
                            brand: brand,
                            title: 'Cash',
                            icon: Icons.payments_outlined,
                            active: _method == PayMethod.cash,
                            onTap: _submitting ? null : () => setState(() => _method = PayMethod.cash),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PayCard(
                            brand: brand,
                            title: 'QRIS',
                            icon: Icons.qr_code_2_rounded,
                            active: _method == PayMethod.qris,
                            onTap: _submitting ? null : () => setState(() => _method = PayMethod.qris),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // ===== Footer sticky =====
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.black.withOpacity(0.08))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _submitting ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: (!_isValid || items.isEmpty)
                          ? null
                          : () async {
                              setState(() => _submitting = true);
                              try {
                                debugPrint("SUBMIT checkout: name=${_nameCtrl.text.trim()} table=${_selectedTable!.id} method=$_method cart=${items.length}");
                                // Kamu bisa taruh validasi stok/checkout di sini
                                if (widget.onSubmit != null) {
                                  await widget.onSubmit!(
                                    customerName: _nameCtrl.text.trim(),
                                    table: _selectedTable!,
                                    method: _method!,
                                  );
                                }

                                if (mounted) Navigator.pop(context);
                              } catch (_) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Gagal memproses pembayaran. Coba lagi.')),
                                );
                              } finally {
                                if (mounted) setState(() => _submitting = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brand,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Pembayaran', style: TextStyle(fontWeight: FontWeight.w900)),
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

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.it});
  final CartItem it;

  @override
  Widget build(BuildContext context) {
    final int qty = it.qty;
    final String name = it.product.name;

    final num lineTotal = it.lineTotal;      // (unitFinalPrice * qty)
    final num baseUnit = it.product.price;   // unit


    final optionLines = _selectedOptionLinesUnit(it); // label + harga unit

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 52,
              height: 52,
              color: const Color(0xFFF3F4F6),
              child: (it.product.imagePath == null)
                  ? const Icon(Icons.fastfood_outlined)
                  : Image.network(
                      it.product.imagePath!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image_outlined),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // kiri teks
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${qty}×   $name',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),

                const Text(
                  'Harga dasar',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),

                ...optionLines.map((l) => Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        l.label,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black.withOpacity(0.70),
                        ),
                      ),
                    )),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // kanan angka (segaris)
          SizedBox(
            width: 96,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Rp ${_rupiah(lineTotal)}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),

                Text(
                  'Rp ${_rupiah(baseUnit)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),

                ...optionLines.map((l) => Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        l.priceText,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black.withOpacity(0.70),
                          fontWeight: l.isFree ? FontWeight.w400 : FontWeight.w700,
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OptLine {
  final String label;
  final String priceText;
  final bool isFree;
  _OptLine({required this.label, required this.priceText, required this.isFree});
}

List<_OptLine> _selectedOptionLinesUnit(CartItem it) {
  final res = <_OptLine>[];

  for (final entry in it.selected.entries) {
    final groupId = entry.key;
    final optionIds = entry.value;

    final groups = it.product.optionGroups.where((g) => g.id == groupId);
    if (groups.isEmpty) continue;
    final group = groups.first;

    for (final optId in optionIds) {
      final opts = group.items.where((o) => o.id == optId);
      if (opts.isEmpty) continue;
      final opt = opts.first;

      final num priceUnit = opt.price;
      final bool isFree = priceUnit <= 0;

      res.add(_OptLine(
        label: '${group.name}: ${opt.name}',
        priceText: isFree ? '(Free)' : 'Rp ${_rupiah(priceUnit)}',
        isFree: isFree,
      ));
    }
  }

  return res;
}


List<String> _selectedOptionTextLines(CartItem it) {
  final res = <String>[];

  for (final entry in it.selected.entries) {
    final groupId = entry.key;
    final optionIds = entry.value;

    final groupList = it.product.optionGroups.where((g) => g.id == groupId);
    if (groupList.isEmpty) continue;
    final group = groupList.first;

    for (final optId in optionIds) {
      final optList = group.items.where((o) => o.id == optId);
      if (optList.isEmpty) continue;
      final opt = optList.first;

      res.add('${group.name}: ${opt.name}');
    }
  }

  return res;
}

List<String> _selectedOptionPriceLines(CartItem it) {
  final res = <String>[];

  for (final entry in it.selected.entries) {
    final groupId = entry.key;
    final optionIds = entry.value;

    final groupList = it.product.optionGroups.where((g) => g.id == groupId);
    if (groupList.isEmpty) continue;
    final group = groupList.first;

    for (final optId in optionIds) {
      final optList = group.items.where((o) => o.id == optId);
      if (optList.isEmpty) continue;
      final opt = optList.first;

      res.add(opt.price <= 0 ? '(Free)' : 'Rp ${_rupiah(opt.price)}');
    }
  }

  return res;
}


class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.total});
  final num total;

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFF7F8FA),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          ),
          Text(
            'Rp ${_rupiah(total)}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: brand),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);
    return Row(
      children: [
        Icon(icon, size: 18, color: brand),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _PayCard extends StatelessWidget {
  const _PayCard({
    required this.brand,
    required this.title,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final Color brand;
  final String title;
  final IconData icon;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? brand : Colors.black.withOpacity(0.10), width: active ? 1.4 : 1.0),
          color: active ? brand.withOpacity(0.06) : Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon, color: active ? brand : Colors.black.withOpacity(0.55)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontWeight: FontWeight.w900, color: active ? brand : Colors.black87),
              ),
            ),
            Icon(
              active ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: active ? brand : Colors.black.withOpacity(0.40),
            ),
          ],
        ),
      ),
    );
  }
}

String _rupiah(num n) {
  final v = n.toDouble().round();
  final s = v.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final idxFromEnd = s.length - i;
    buf.write(s[i]);
    if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buf.write('.');
  }
  return buf.toString();
}


num? _tryReadNum(dynamic obj, String key) {
  try {
    final v = (obj as dynamic).__getattribute__(key); // ini tidak ada di Dart, jadi jangan
  } catch (_) {}
  return null;
}
