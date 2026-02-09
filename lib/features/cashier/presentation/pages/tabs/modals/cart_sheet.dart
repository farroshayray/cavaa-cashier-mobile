import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/features/cashier/presentation/providers/purchase_provider.dart';
import 'checkout_sheet.dart';

class CartSheet extends StatelessWidget {
  const CartSheet({super.key});

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);
    final vm = context.watch<PurchaseProvider>();
    final items = vm.cart;

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

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.black.withOpacity(0.10)),
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

                                    if ((it.note ?? '').toString().trim().isNotEmpty)
                                      Text(
                                        'Catatan: ${it.note}',
                                        style: TextStyle(
                                          color: Colors.black.withOpacity(0.60),
                                          fontSize: 12,
                                        ),
                                      ),

                                    // kalau kamu mau tampilkan opsi yg dipilih, bisa ditambah di sini (optional)

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
                    onPressed: items.isEmpty
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
                                  onSubmit: ({required customerName, required table, required method}) async {
                                    final pm = (method == PayMethod.qris) ? "QRIS" : "CASH";

                                    final resp = await context.read<PurchaseProvider>().checkout(
                                      customerName: customerName,
                                      table: table,
                                      paymentMethod: pm,
                                    );

                                    // kalau QRIS ada redirect url
                                    final redirect = resp["redirect"];
                                    if (redirect is String && redirect.isNotEmpty) {
                                      // TODO: buka redirect (url_launcher / webview)
                                      // print("QRIS URL: $redirect");
                                    }
                                  },
                                ),
                              ),
                            ),
                          );
                        },

                    child: const Text('Checkout',
                        style: TextStyle(fontWeight: FontWeight.w900)),
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
