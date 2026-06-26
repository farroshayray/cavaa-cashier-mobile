import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/features/cashier/data/models/checkout_exceptions.dart';
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

  bool _showValidation = false;

  bool get _nameInvalid => _showValidation && _nameCtrl.text.trim().isEmpty;
  bool get _tableInvalid => _showValidation && _selectedTable == null;
  bool get _paymentInvalid => _showValidation && _selectedPay == null;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  bool get _isValid => !_submitting;
  bool get _allRequiredFilled {
    return _nameCtrl.text.trim().isNotEmpty &&
        _selectedTable != null &&
        _selectedPay != null;
  }

  StoreTable? _currentSelectedTable(List<StoreTable> availableTables) {
    final selected = _selectedTable;
    if (selected == null) return null;

    for (final table in availableTables) {
      if (table.id == selected.id) return table;
    }

    return null;
  }

  Future<bool> _showSubmitConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Konfirmasi Pembayaran',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: const Text(
            'Apakah Anda yakin ingin memproses pembayaran untuk pesanan ini?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFAE1504),
                foregroundColor: Colors.white,
              ),
              child: const Text('Ya, Lanjutkan'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);
    final vm = context.watch<PurchaseProvider>();
    final items = vm.cart;
    final availableTables = vm.tables.where((t) => t.isAvailable).toList()
      ..sort((a, b) {
        final classCompare = (a.tableClass ?? '').compareTo(b.tableClass ?? '');
        if (classCompare != 0) return classCompare;
        return a.label.compareTo(b.label);
      });

    final currentSelectedTable = _currentSelectedTable(availableTables);

    if (_selectedTable != null && currentSelectedTable == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedTable != null) {
          setState(() => _selectedTable = null);
        }
      });
    }

    final Map<String, List<StoreTable>> groupedTables = {};
    for (final table in availableTables) {
      final groupName = (table.tableClass?.trim().isNotEmpty ?? false)
          ? table.tableClass!.trim()
          : 'Lainnya';

      groupedTables.putIfAbsent(groupName, () => []).add(table);
    }
    debugPrint(
      'Datadebug: ${availableTables.map((t) => '${t.id}-${t.tableNo}-${t.tableClass}').toList()}'
    );

    final payOptions = vm.paymentOptions;

    final subtotal = vm.cartSubtotal;
    final ppnActive = vm.isPpnActive;
    final ppnPercent = vm.ppnPercent;
    final ppnAmount = vm.cartPpnAmount;
    final roundingAmount = vm.roundingAmountForPayment(_selectedPay);
    final grandTotal = vm.payableTotalForPayment(_selectedPay);

    final instantPayments = payOptions.where((o) {
      return o.kind == PayKind.cashierCash || o.kind == PayKind.onlineQris || o.kind == PayKind.openbill;
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
                      roundingAmount: roundingAmount,
                      grandTotal: grandTotal,
                    ),
                    const SizedBox(height: 14),

                    // Nama Pemesan
                    _SectionLabel(
                      icon: Icons.person_outline_rounded,
                      text: 'Nama Pemesan',
                      requiredMark: true,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameCtrl,
                      enabled: !_submitting,
                      onChanged: (_) => setState(() {}),
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: 'Contoh: Budi Setiawan',
                        helperText: _nameInvalid
                            ? 'Nama pemesan wajib diisi'
                            : 'Isi nama agar pesanan mudah dipanggil',
                        helperStyle: TextStyle(
                          color: _nameInvalid ? Colors.red : Colors.black54,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF7F8FA),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: _nameInvalid
                                ? Colors.red
                                : Colors.black.withOpacity(0.10),
                            width: _nameInvalid ? 1.4 : 1.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: _nameInvalid ? Colors.red : brand,
                            width: 1.3,
                          ),
                          borderRadius: const BorderRadius.all(Radius.circular(14)),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Colors.red, width: 1.4),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Colors.red, width: 1.4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Pilih Meja
                    _SectionLabel(
                      icon: Icons.table_restaurant_outlined,
                      text: 'Pilih Meja',
                      requiredMark: true,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<StoreTable>(
                      value: currentSelectedTable,
                      items: groupedTables.entries.expand((entry) {
                        final groupName = entry.key;
                        final tables = entry.value;

                        return [
                          DropdownMenuItem<StoreTable>(
                            enabled: false,
                            value: null,
                            child: Text(
                              groupName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFAE1504),
                              ),
                            ),
                          ),
                          ...tables.map(
                            (t) => DropdownMenuItem<StoreTable>(
                              value: t,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: Text(t.label),
                              ),
                            ),
                          ),
                        ];
                      }).toList(),
                      onChanged: _submitting
                        ? null
                        : (v) => setState(() => _selectedTable = v),
                      decoration: InputDecoration(
                        hintText: availableTables.isEmpty ? 'Tidak ada meja tersedia' : 'Pilih meja',
                        helperText: _tableInvalid
                            ? 'Meja wajib dipilih'
                            : 'Meja yang tidak tersedia tidak dapat dipilih',
                        helperStyle: TextStyle(
                          color: _tableInvalid ? Colors.red : Colors.black54,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF7F8FA),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: _tableInvalid
                                ? Colors.red
                                : Colors.black.withOpacity(0.10),
                            width: _tableInvalid ? 1.4 : 1.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: _tableInvalid ? Colors.red : brand,
                            width: 1.3,
                          ),
                          borderRadius: const BorderRadius.all(Radius.circular(14)),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Colors.red, width: 1.4),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Colors.red, width: 1.4),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Metode Pembayaran
                    _SectionLabel(
                      icon: Icons.credit_card_rounded,
                      text: 'Metode Pembayaran',
                      requiredMark: true,
                    ),
                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8FA),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _paymentInvalid
                              ? Colors.red
                              : Colors.black.withOpacity(0.10),
                          width: _paymentInvalid ? 1.4 : 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
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
                          if (_paymentInvalid) ...[
                            const SizedBox(height: 4),
                            const Text(
                              'Metode pembayaran wajib dipilih',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
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
                      onPressed: _submitting || items.isEmpty
                        ? null
                        : () async {
                            final valid = _validateBeforeSubmit();
                            if (!valid) return;

                            final confirmed = await _showSubmitConfirmation();
                            if (!confirmed) return;

                            if (widget.onSubmit == null) return;

                            setState(() => _submitting = true);

                            try {
                              final selectedPay = _selectedPay!;

                              final selectedTable = currentSelectedTable;
                              if (selectedTable == null) {
                                setState(() => _selectedTable = null);
                                return;
                              }

                              final resp = await widget.onSubmit!(
                                customerName: _nameCtrl.text.trim(),
                                table: selectedTable,
                                payment: selectedPay,
                              );

                              final redirect = resp['redirect'];
                              final isXenditQris = selectedPay.kind == PayKind.onlineQris;

                              final isOpenbill = selectedPay.kind == PayKind.openbill;
                              final refreshTarget = isXenditQris
                                  ? ''
                                  : (isOpenbill ? 'process' : 'payment');

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
                            } on StockInsufficientException catch (e) {
                              if (!mounted) return;
                              await _showStockConflictDialog(e);
                              if (mounted) {
                                await context.read<PurchaseProvider>().load();
                              }
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  SnackBar(
                                    content: Text(_checkoutErrorMessage(e)),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                            } finally {
                              if (mounted) {
                                setState(() => _submitting = false);
                              }
                            }
                          },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _allRequiredFilled ? brand : brand.withOpacity(0.55),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: brand.withOpacity(0.35),
                        disabledForegroundColor: Colors.white70,
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

  Future<void> _showStockConflictDialog(
    StockInsufficientException exception,
  ) async {
    final items = exception.allItems;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Stok tidak mencukupi'),
          content: SizedBox(
            width: double.maxFinite,
            child: items.isEmpty
                ? Text(exception.message)
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 16),
                    itemBuilder: (_, index) {
                      final item = items[index];
                      return Text(
                        item.label,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Mengerti'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPaymentCard(PaymentOption opt, Color brand) {
    final active =
        (_selectedPay?.kind == opt.kind) && (_selectedPay?.value == opt.value);

    IconData icon;
    switch (opt.kind) {
      case PayKind.cashierCash:
      case PayKind.openbill:
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

  bool _validateBeforeSubmit() {
    setState(() => _showValidation = true);

    final missing = <String>[];

    if (_nameCtrl.text.trim().isEmpty) {
      missing.add('Nama Pemesan');
    }
    if (_selectedTable == null) {
      missing.add('Pilih Meja');
    }
    if (_selectedPay == null) {
      missing.add('Metode Pembayaran');
    }

    if (missing.isNotEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Mohon lengkapi: ${missing.join(', ')}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      return false;
    }

    return true;
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
    required this.roundingAmount,
    required this.grandTotal,
  });

  final num subtotal;
  final bool ppnActive;
  final num ppnPercent;
  final num ppnAmount;
  final num roundingAmount;
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
          ],
          if (roundingAmount > 0)
            row('Pembulatan Cash', 'Rp ${_rupiah(roundingAmount)}'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Divider(height: 1),
          ),
          row('Grand Total', 'Rp ${_rupiah(grandTotal)}', highlight: true),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.icon,
    required this.text,
    this.requiredMark = false,
  });

  final IconData icon;
  final String text;
  final bool requiredMark;

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);
    return Row(
      children: [
        Icon(icon, size: 18, color: brand),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w900)),
        if (requiredMark) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              color: Colors.red,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
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

String _checkoutErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      final message = data['message'].toString().trim();
      if (message.isNotEmpty) return message;
    }
  }

  if (error is Exception) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    if (message.isNotEmpty) return message;
  }

  return 'Gagal memproses pembayaran. Coba lagi.';
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
