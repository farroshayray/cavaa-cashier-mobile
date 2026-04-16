import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/features/cashier/presentation/providers/purchase_provider.dart';
import 'checkout_sheet.dart';
import '/features/cashier/data/models/purchase_models.dart';
import '/core/utils/open_url.dart';

class CartSheet extends StatelessWidget {
  const CartSheet({super.key});

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);
    final vm = context.watch<PurchaseProvider>();
    final items = vm.cart;
    final hasBlockingStockWarnings = items.any(
      (it) => _stockNoticesFor(it, vm).any((notice) => notice.blocking),
    );

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.only(top: 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // handle
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 10),

            // header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Keranjang',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // list
            Flexible(
              child: items.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Keranjang masih kosong.'),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final it = items[i];
                        final stockNotices = _stockNoticesFor(it, vm);
                        final hasBlockingWarning =
                            stockNotices.any((notice) => notice.blocking);
                        final hasNotice = stockNotices.isNotEmpty;

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: hasBlockingWarning
                                  ? Colors.redAccent.withOpacity(0.55)
                                  : hasNotice
                                      ? Colors.orange.withOpacity(0.45)
                                  : Colors.black.withOpacity(0.10),
                            ),
                            color: hasBlockingWarning
                                ? Colors.redAccent.withOpacity(0.04)
                                : hasNotice
                                    ? Colors.orange.withOpacity(0.05)
                                : Colors.white,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      it.product.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w900),
                                    ),
                                    const SizedBox(height: 4),

                                    if (stockNotices.isNotEmpty) ...[
                                      ...stockNotices.map(
                                        (notice) => Padding(
                                          padding: const EdgeInsets.only(bottom: 4),
                                          child: _StockWarningPill(notice: notice),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                    ],

                                    if ((it.note ?? '').toString().trim().isNotEmpty)
                                      Text(
                                        'Catatan: ${it.note}',
                                        style: TextStyle(
                                          color: Colors.black.withOpacity(0.60),
                                          fontSize: 12,
                                        ),
                                      ),

                                    // kalau kamu mau tampilkan opsi yg dipilih, bisa ditambah di sini (optional)
                                    ..._selectedOptionTextLines(it, vm).map(
                                      (line) => Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          line,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.black.withOpacity(0.60),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 6),
                                    Text(
                                      'Rp ${_rupiah(it.unitFinalPrice)}',
                                      style: const TextStyle(fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),

                              // stepper
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.black.withOpacity(0.10)),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () => context.read<PurchaseProvider>().decCartAt(i),
                                      icon: const Icon(Icons.remove_rounded),
                                    ),
                                    Text('${it.qty}',
                                        style: const TextStyle(fontWeight: FontWeight.w900)),
                                    IconButton(
                                      onPressed: () => context.read<PurchaseProvider>().incCartAt(i),
                                      icon: const Icon(Icons.add_rounded),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            const Divider(height: 1),

            // footer total + checkout
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total',
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.55),
                              fontWeight: FontWeight.w700,
                            )),
                        const SizedBox(height: 2),
                        Text('Rp ${_rupiah(vm.cartGrandTotal)}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
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
                    onPressed: items.isEmpty || hasBlockingStockWarnings
                      ? null
                      : () async {
                          final purchaseVm = context.read<PurchaseProvider>();

                          // tutup CartSheet terlebih dahulu
                          Navigator.pop(context);

                          // tunggu 1 frame supaya animasi pop selesai
                          await Future.delayed(const Duration(milliseconds: 150));

                          // gunakan root navigator
                          final rootCtx = Navigator.of(context, rootNavigator: true).context;

                          await showModalBottomSheet(
                            context: rootCtx,
                            useRootNavigator: true,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => ChangeNotifierProvider.value(
                              value: purchaseVm,
                              child: SizedBox(
                                height: MediaQuery.of(rootCtx).size.height * 0.92,
                                child: CheckoutSheet(
                                  onSubmit: ({required customerName, required table, required payment}) async {
                                    // 1) mapping ke string backend (sementara)
                                    // - cashierCash => "CASH"
                                    // - onlineQris  => "QRIS"
                                    // - manual      => biasanya kirim manualId (string) ATAU "MANUAL" tergantung backend
                                    final String paymentMethod = switch (payment.kind) {
                                      PayKind.cashierCash => 'CASH',
                                      PayKind.onlineQris  => 'QRIS',
                                      PayKind.manual      => payment.value, // default: kirim manualId string
                                    };

                                    final resp = await context.read<PurchaseProvider>().checkout(
                                      customerName: customerName,
                                      table: table,
                                      paymentMethod: paymentMethod,
                                      payment: payment,
                                    );

                                    // 2) redirect hanya kalau ONLINE QRIS (xendit)
                                    if (payment.kind == PayKind.onlineQris) {
                                      final redirect = resp["redirect"];
                                      if (redirect is String && redirect.isNotEmpty) {
                                        Navigator.of(context, rootNavigator: true).pop();
                                        await openInAppUrl(redirect);
                                      } else {
                                        throw Exception("URL pembayaran QRIS tidak ditemukan");
                                      }
                                    } else {
                                      // CASH atau MANUAL
                                      Navigator.of(context, rootNavigator: true).pop();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Checkout ${payment.label} dibuat')),
                                      );
                                    }

                                    return resp;
                                  },
                                ),
                              ),
                            ),
                          );
                        },

                    child: Text(
                      hasBlockingStockWarnings ? 'Periksa Stok' : 'Checkout',
                      style: const TextStyle(fontWeight: FontWeight.w900),
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

class _StockWarningPill extends StatelessWidget {
  const _StockWarningPill({required this.notice});

  final _StockNotice notice;

  @override
  Widget build(BuildContext context) {
    final color = notice.blocking ? Colors.redAccent : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              notice.text,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ).copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _StockNotice {
  const _StockNotice(this.text, {required this.blocking});

  final String text;
  final bool blocking;
}

List<_StockNotice> _stockNoticesFor(CartItem item, PurchaseProvider vm) {
  final notices = <_StockNotice>[];
  final product = _latestProductFor(item, vm);

  if (!product.isActive) {
    notices.add(const _StockNotice('Produk tidak aktif', blocking: true));
  } else if (!product.alwaysAvailable) {
    final availableForThisLine =
        vm.availableQtyForProduct(product, excludingItem: item);
    final remainingAfterThisLine = availableForThisLine - item.qty;

    if (availableForThisLine <= 0) {
      notices.add(const _StockNotice('Produk habis', blocking: true));
    } else if (item.qty > availableForThisLine) {
      notices.add(_StockNotice(
        'Produk kurang: diminta ${item.qty}, tersedia $availableForThisLine',
        blocking: true,
      ));
    } else if (remainingAfterThisLine > 0 && remainingAfterThisLine <= 3) {
      notices.add(_StockNotice(
        'Stok produk tinggal $remainingAfterThisLine',
        blocking: false,
      ));
    }
  }

  for (final group in product.optionGroups) {
    final selectedIds = item.selected[group.id] ?? const <int>{};

    if (group.min > 0) {
      final availableSelected = selectedIds.where((optionId) {
        final option = _findOption(group, optionId);
        if (option == null) return false;
        final availableForThisLine = option.alwaysAvailable
            ? item.qty
            : vm.availableQtyForOption(option, excludingItem: item);
        return availableForThisLine > 0;
      }).length;

      if (availableSelected < group.min) {
        notices.add(_StockNotice(
          'Opsi wajib ${group.name} tidak cukup tersedia',
          blocking: true,
        ));
      }
    }

    for (final optionId in selectedIds) {
      final option = _findOption(group, optionId);
      if (option == null) {
        notices.add(_StockNotice(
          'Opsi ${group.name} tidak ditemukan',
          blocking: true,
        ));
        continue;
      }

      if (option.alwaysAvailable) continue;

      final availableForThisLine =
          vm.availableQtyForOption(option, excludingItem: item);
      if (availableForThisLine <= 0) {
        notices.add(_StockNotice('Opsi ${option.name} habis', blocking: true));
      } else if (item.qty > availableForThisLine) {
        notices.add(_StockNotice(
          'Opsi ${option.name} kurang: diminta ${item.qty}, tersedia $availableForThisLine',
          blocking: true,
        ));
      }
    }
  }

  final maxForLine = vm.maxAddableQtyWithOptions(
    product: product,
    selected: item.selected,
    excludingItem: item,
  );
  if (item.qty > maxForLine &&
      !notices.any((notice) => notice.blocking)) {
    notices.add(_StockNotice(
      'Stok bahan/produk kurang: diminta ${item.qty}, tersedia $maxForLine',
      blocking: true,
    ));
  }

  return notices;
}

Product _latestProductFor(CartItem item, PurchaseProvider vm) {
  for (final product in vm.products) {
    if (product.id == item.product.id) return product;
  }
  return item.product;
}

OptionItem? _findOption(OptionGroup group, int optionId) {
  for (final option in group.items) {
    if (option.id == optionId) return option;
  }
  return null;
}

List<String> _selectedOptionTextLines(CartItem it, PurchaseProvider vm) {
  final lines = <String>[];
  final product = _latestProductFor(it, vm);

  for (final entry in it.selected.entries) {
    final groups = product.optionGroups.where((g) => g.id == entry.key);
    if (groups.isEmpty) continue;

    final group = groups.first;
    for (final optionId in entry.value) {
      final option = _findOption(group, optionId);
      if (option == null) continue;
      lines.add('${group.name}: ${option.name}');
    }
  }

  return lines;
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
