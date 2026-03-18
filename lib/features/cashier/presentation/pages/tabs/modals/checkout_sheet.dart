import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/features/cashier/presentation/providers/purchase_provider.dart';
import '/features/cashier/data/models/purchase_models.dart';
import '/core/utils/open_url.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';

class CheckoutSheet extends StatefulWidget {
  const CheckoutSheet({
    super.key,
    this.onSubmit,
  });

  final Future<Map<String, dynamic>> Function({
    required String customerName,
    required StoreTable table,
    required PaymentOption payment,
  })? onSubmit;


  @override
  State<CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<CheckoutSheet> {
  final _nameCtrl = TextEditingController();
  StoreTable? _selectedTable;
  PaymentOption? _selectedPay;
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  bool get _isValid {
    final nameOk = _nameCtrl.text.trim().isNotEmpty;
    final tableOk = _selectedTable != null;
    final methodOk = _selectedPay != null;
    return nameOk && tableOk && methodOk && !_submitting;
  }

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);
    final vm = context.watch<PurchaseProvider>();
    final items = vm.cart;
    final availableTables = vm.tables.where((t) => t.isAvailable).toList();
    final payOptions = vm.paymentOptions;

    final subtotal = vm.cartSubtotal;
    final ppnActive = vm.isPpnActive;
    final ppnPercent = vm.ppnPercent;
    final ppnAmount = vm.cartPpnAmount;
    final grandTotal = vm.cartGrandTotalRounded;

    final instantPayments = payOptions.where((o) {
      return o.kind == PayKind.cashierCash || o.kind == PayKind.onlineQris;
    }).toList();

    final manualTfPayments = payOptions.where((o) {
      return o.kind == PayKind.manual && o.manualType == 'manual_tf';
    }).toList();

    final manualEwalletPayments = payOptions.where((o) {
      return o.kind == PayKind.manual && o.manualType == 'manual_ewallet';
    }).toList();

    final manualQrisPayments = payOptions.where((o) {
      return o.kind == PayKind.manual && o.manualType == 'manual_qris';
    }).toList();

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
                    _TotalCard(
                      subtotal: subtotal,
                      ppnActive: ppnActive,
                      ppnPercent: ppnPercent,
                      ppnAmount: ppnAmount,
                      grandTotal: grandTotal,
                    ),
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

                    if (payOptions.isEmpty)
                      Text(
                        'Metode pembayaran belum tersedia.',
                        style: TextStyle(color: Colors.black.withOpacity(0.55)),
                      )
                    else ...[
                      if (instantPayments.isNotEmpty) ...[
                        _PaymentGroupTitle(title: 'Pembayaran Instan'),
                        const SizedBox(height: 8),
                        ...instantPayments.map((opt) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _buildPaymentCard(opt, brand),
                            )),
                        const SizedBox(height: 8),
                      ],

                      if (manualTfPayments.isNotEmpty) ...[
                        _PaymentGroupTitle(title: 'Transfer Bank'),
                        const SizedBox(height: 8),
                        ...manualTfPayments.map((opt) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _buildPaymentCard(opt, brand),
                            )),
                        const SizedBox(height: 8),
                      ],

                      if (manualEwalletPayments.isNotEmpty) ...[
                        _PaymentGroupTitle(title: 'E-Wallet'),
                        const SizedBox(height: 8),
                        ...manualEwalletPayments.map((opt) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _buildPaymentCard(opt, brand),
                            )),
                        const SizedBox(height: 8),
                      ],

                      if (manualQrisPayments.isNotEmpty) ...[
                        _PaymentGroupTitle(title: 'QRIS Manual'),
                        const SizedBox(height: 8),
                        ...manualQrisPayments.map((opt) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _buildPaymentCard(opt, brand),
                            )),
                      ],
                    ],

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
                              final selectedPay = _selectedPay!;

                              final resp = await widget.onSubmit!(
                                customerName: _nameCtrl.text.trim(),
                                table: _selectedTable!,
                                payment: selectedPay,
                              );

                              final redirect = resp['redirect'];
                              final isXenditQris = selectedPay.kind == PayKind.onlineQris;

                              // patokan refresh baru:
                              // - QRIS Xendit -> jangan refresh dari sini
                              // - selain itu  -> refresh payment
                              final refreshTarget = isXenditQris ? '' : 'payment';

                              if (isXenditQris && redirect is String && redirect.isNotEmpty) {
                                if (mounted) {
                                  Navigator.pop(context, {
                                    'success': true,
                                    'refresh_target': refreshTarget,
                                  });
                                }
                                await openExternalUrl(redirect);
                                return;
                              }

                              if (mounted) {
                                Navigator.pop(context, {
                                  'success': true,
                                  'refresh_target': refreshTarget,
                                });
                              }
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

  Widget _buildPaymentCard(PaymentOption opt, Color brand) {
    final active =
        (_selectedPay?.kind == opt.kind) && (_selectedPay?.value == opt.value);

    IconData icon;
    switch (opt.kind) {
      case PayKind.cashierCash:
        icon = Icons.payments_outlined;
        break;
      case PayKind.onlineQris:
        icon = Icons.qr_code_2_rounded;
        break;
      case PayKind.manual:
      default:
        if (opt.manualType == 'manual_tf') {
          icon = Icons.account_balance_outlined;
        } else if (opt.manualType == 'manual_ewallet') {
          icon = Icons.account_balance_wallet_outlined;
        } else if (opt.manualType == 'manual_qris') {
          icon = Icons.qr_code_2_rounded;
        } else {
          icon = Icons.payments_outlined;
        }
    }

    return _PayCard(
      brand: brand,
      title: opt.label,
      // subtitle: opt.desc,
      icon: icon,
      active: active,
      onTap: _submitting ? null : () => setState(() => _selectedPay = opt),
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
              child: _ProductThumb(path: it.product.imagePath),
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
  const _TotalCard({
    required this.subtotal,
    required this.ppnActive,
    required this.ppnPercent,
    required this.ppnAmount,
    required this.grandTotal,
  });

  final num subtotal;
  final bool ppnActive;
  final num ppnPercent;
  final num ppnAmount;
  final num grandTotal;

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);

    Widget row(String label, String value, {bool highlight = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: highlight ? 16 : 14,
                  fontWeight: highlight ? FontWeight.w900 : FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: highlight ? 18 : 14,
                fontWeight: highlight ? FontWeight.w900 : FontWeight.w700,
                color: highlight ? brand : Colors.black87,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFF7F8FA),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          row('Total', 'Rp ${_rupiah(subtotal)}'),
          if (ppnActive) ...[
            row('PPN (${ppnPercent.toStringAsFixed(ppnPercent % 1 == 0 ? 0 : 2)}%)',
                'Rp ${_rupiah(ppnAmount)}'),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Divider(height: 1),
            ),
            row('Grand Total', 'Rp ${_rupiah(grandTotal)}', highlight: true),
          ] else
            row('Grand Total', 'Rp ${_rupiah(grandTotal)}', highlight: true),
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
    this.subtitle,
  });

  final Color brand;
  final String title;
  final IconData icon;
  final bool active;
  final VoidCallback? onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? brand : Colors.black.withOpacity(0.10),
            width: active ? 1.4 : 1.0,
          ),
          color: active ? brand.withOpacity(0.06) : Colors.white,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: active ? brand : Colors.black.withOpacity(0.55)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: active ? brand : Colors.black87,
                    ),
                  ),
                  if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withOpacity(0.60),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              active
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: active ? brand : Colors.black.withOpacity(0.40),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentGroupTitle extends StatelessWidget {
  const _PaymentGroupTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: Colors.black.withOpacity(0.65),
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.path});

  final String? path;

  bool _isLocalFile(String value) {
    return value.startsWith('/') || value.startsWith('file://');
  }

  @override
  Widget build(BuildContext context) {
    final raw = path?.trim();

    if (raw == null || raw.isEmpty) {
      return const Icon(Icons.fastfood_outlined);
    }

    if (_isLocalFile(raw)) {
      final filePath = raw.startsWith('file://')
          ? raw.replaceFirst('file://', '')
          : raw;

      return Image.file(
        File(filePath),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.broken_image_outlined),
      );
    }

    return CachedNetworkImage(
      imageUrl: raw,
      fit: BoxFit.cover,
      placeholder: (_, __) => const Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (_, __, ___) =>
          const Icon(Icons.broken_image_outlined),
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
