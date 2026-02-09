import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/features/cashier/data/purchase_api.dart';
import '/features/cashier/data/models/purchase_repository.dart';
import '../../../presentation/providers/purchase_provider.dart';
import '../../../../../core/storage/secure_storage_service.dart';
import '../../../data/models/purchase_models.dart';
import '/features/cashier/presentation/pages/tabs/modals/product_option_sheet.dart';
import '/features/cashier/presentation/pages/tabs/modals/cart_sheet.dart';
import '/features/cashier/presentation/pages/tabs/modals/checkout_sheet.dart';



class PurchaseTab extends StatelessWidget {
  const PurchaseTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Provider dibuat di sini supaya tab ini mandiri.
    // Kalau kamu nanti mau global (dipakai tab lain), pindahin ke atas (CashierHomePage).
    return ChangeNotifierProvider(
      create: (_) => PurchaseProvider(
        PurchaseRepository(
          api: PurchaseApi(),
          storage: SecureStorageService(),
        ),
      )..load(),
      child: const _PurchaseView(),
    );
  }
}

class _PurchaseView extends StatelessWidget {
  const _PurchaseView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PurchaseProvider>();
    const brand = Color(0xFFAE1504);

    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(vm.error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.read<PurchaseProvider>().load(),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () => context.read<PurchaseProvider>().load(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Sticky header: category + search (mirip web)
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyHeaderDelegate(
                  minHeight: 126,
                  maxHeight: 126,
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: Column(
                      children: [
                        _CategoryTabs(
                          brand: brand,
                          categories: vm.categories,
                          selectedCategoryId: vm.selectedCategoryId,
                          onTapCategory: (id) => context.read<PurchaseProvider>().setCategory(id),
                        ),
                        const SizedBox(height: 8),
                        _SearchBar(
                          onChanged: (q) => context.read<PurchaseProvider>().setQuery(q),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 110),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      if (vm.hotProducts.isNotEmpty) ...[
                        _SectionTitle(
                          title: 'Hot Products',
                          icon: Icons.local_fire_department_rounded,
                        ),
                        const SizedBox(height: 10),
                        _ProductGrid(products: vm.hotProducts),
                        const SizedBox(height: 18),
                      ],

                      // grouped category
                      ...vm.groupedByCategory.entries.map((entry) {
                        final cat = vm.categoryById(entry.key);
                        final name = cat?.name ?? 'Uncategorized';
                        final prods = entry.value;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _CategoryHeader(title: name, count: prods.length),
                            const SizedBox(height: 10),
                            _ProductGrid(products: prods),
                            const SizedBox(height: 18),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ✅ Mini cart bar (Shopee style)
        const Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: _MiniCartBar(),
        ),
      ],
    );
  }
}

class _MiniCartBar extends StatelessWidget {
  const _MiniCartBar();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PurchaseProvider>();
    const brand = Color(0xFFAE1504);

    // TODO: sesuaikan dengan provider kamu
    final itemCount = vm.cartItemCount;        // total qty semua item
    final total = vm.cartGrandTotal;           // total harga semua item (num/double)
    // final distinct = vm.cart.length;         // kalau kamu butuh jumlah jenis item

    if (itemCount <= 0) return const SizedBox.shrink();

    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset : 0),
      child: Material(
        elevation: 10,
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              // kiri: cart + badge jumlah item (klik -> buka cart sheet)
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                final purchaseVm = context.read<PurchaseProvider>();

                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => ChangeNotifierProvider.value(
                    value: purchaseVm,
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.85,
                      child: const CartSheet(),
                    ),
                  ),
                );
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: brand.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.shopping_cart_rounded, color: brand),
                  ),
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: brand,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$itemCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),


              const SizedBox(width: 12),

              // tengah: total
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.55),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rp ${_rupiah(total)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // kanan: tombol checkout
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: brand,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
                onPressed: () async {
                  final purchaseVm = context.read<PurchaseProvider>();
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

                            final redirect = resp["redirect"];
                            if (redirect is String && redirect.isNotEmpty) {
                              // TODO: buka redirect
                              // print("QRIS URL: $redirect");
                            }
                          },
                        ),
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Checkout',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({
    required this.brand,
    required this.categories,
    required this.selectedCategoryId,
    required this.onTapCategory,
  });

  final Color brand;
  final List<Category> categories;
  final int selectedCategoryId;
  final ValueChanged<int> onTapCategory;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      _CatChip(
        label: 'All',
        active: selectedCategoryId == -1,
        brand: brand,
        onTap: () => onTapCategory(-1),
      ),
      ...categories.map((c) {
        return _CatChip(
          label: c.name,
          active: selectedCategoryId == c.id,
          brand: brand,
          onTap: () => onTapCategory(c.id),
        );
      }),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, i) => chips[i],
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: chips.length,
      ),
    );
  }
}

class _CatChip extends StatelessWidget {
  const _CatChip({
    required this.label,
    required this.active,
    required this.brand,
    required this.onTap,
  });

  final String label;
  final bool active;
  final Color brand;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? brand.withOpacity(0.10) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? brand : Colors.transparent),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: active ? brand : Colors.black87,
            fontWeight: active ? FontWeight.w800 : FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatefulWidget {
  const _SearchBar({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final c = TextEditingController();

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: c,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          hintText: 'Cari menu… (nama / deskripsi)',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: c.text.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    c.clear();
                    widget.onChanged('');
                    setState(() {});
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
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
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ),
        Text(
          '($count)',
          style: TextStyle(color: Colors.black.withOpacity(0.55)),
        ),
      ],
    );
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    // Grid di dalam SliverList -> pakai GridView shrinkWrap
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.74,
      ),
      itemBuilder: (_, i) => _ProductCard(product: products[i]),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PurchaseProvider>();
    const brand = Color(0xFFAE1504);

    final qty = vm.qtyOf(product.id);

    final isOut = !product.alwaysAvailable && product.quantityAvailable <= 0;
    final lowStock = !product.alwaysAvailable && product.quantityAvailable > 0 && product.quantityAvailable <= 3;

    // promo calc (mirip web)
    final basePrice = product.price.toDouble();
    double discounted = basePrice;
    String? promoBadge;

    final promo = product.promotion;
    if (promo != null) {
      if (promo.type == 'percentage') {
        discounted = (basePrice * (1 - (promo.value.toDouble() / 100))).clamp(0, double.infinity);
        promoBadge = '-${_trimPromo(promo.value)}%';
      } else {
        discounted = (basePrice - promo.value.toDouble()).clamp(0, double.infinity);
        promoBadge = '-Rp ${_rupiah(promo.value)}';
      }
    }

    final hasPromo = discounted < basePrice;

    return Opacity(
      opacity: isOut ? 0.65 : 1,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              blurRadius: 18,
              offset: const Offset(0, 10),
              color: Colors.black.withOpacity(0.06),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: isOut
            ? null
            : () async {
                if (product.optionGroups.isNotEmpty) {
                  final purchaseVm = context.read<PurchaseProvider>();
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => ChangeNotifierProvider.value(
                      value: purchaseVm,
                      child: ProductOptionsSheet(product: product),
                    ),
                  );

                } else {
                  context.read<PurchaseProvider>().add(product);
                }
              },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // image
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                      child: Container(
                        color: const Color(0xFFF3F4F6),
                        child: product.imagePath == null
                            ? const Center(child: Icon(Icons.image_not_supported_outlined, size: 44))
                            : Image.network(
                                product.imagePath!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (_, __, ___) =>
                                    const Center(child: Icon(Icons.broken_image_outlined, size: 44)),
                              ),
                      ),
                    ),

                    if (hasPromo && promoBadge != null)
                      Positioned(
                        left: 10,
                        top: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: brand,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            promoBadge,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),

                    if (lowStock)
                      Positioned(
                        left: 10,
                        right: 10,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.90),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.orange.withOpacity(0.30)),
                          ),
                          child: const Center(
                            child: Text(
                              'Stok Terbatas',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.orange),
                            ),
                          ),
                        ),
                      ),

                    if (isOut)
                      Positioned.fill(
                        child: Container(
                          color: Colors.white.withOpacity(0.35),
                          child: const Center(
                            child: DecoratedBox(
                              decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.all(Radius.circular(999))),
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                child: Text(
                                  'Habis',
                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // info
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.description ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.55)),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: _PriceView(
                            base: basePrice,
                            discounted: discounted,
                            hasPromo: hasPromo,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // qty controls
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (qty > 0)
                              _CircleButton(
                                onTap: () => context.read<PurchaseProvider>().minus(product),
                                outline: true,
                                child: const Icon(Icons.remove_rounded, size: 18),
                              ),
                            if (qty > 0) ...[
                              const SizedBox(width: 6),
                              Text('$qty', style: const TextStyle(fontWeight: FontWeight.w900)),
                              const SizedBox(width: 6),
                            ],
                            _CircleButton(
                              onTap: isOut
                                  ? null
                                  : () async {
                                      if (product.optionGroups.isNotEmpty) {
                                        final purchaseVm = context.read<PurchaseProvider>();
                                        await showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (_) => ChangeNotifierProvider.value(
                                            value: purchaseVm,
                                            child: ProductOptionsSheet(product: product),
                                          ),
                                        );

                                      } else {
                                        context.read<PurchaseProvider>().add(product);
                                      }
                                    },
                              child: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                              filled: true,
                            ),
                          ],
                        ),
                      ],
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

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.onTap,
    required this.child,
    this.filled = false,
    this.outline = false,
  });

  final VoidCallback? onTap;
  final Widget child;
  final bool filled;
  final bool outline;

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: filled ? brand : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: outline ? Border.all(color: brand, width: 1.2) : null,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _PriceView extends StatelessWidget {
  const _PriceView({required this.base, required this.discounted, required this.hasPromo});

  final double base;
  final double discounted;
  final bool hasPromo;

  @override
  Widget build(BuildContext context) {
    String rupiah(num n) => _rupiah(n);

    if (!hasPromo) {
      return Text(
        'Rp ${rupiah(base)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rp ${rupiah(base)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            color: Colors.black.withOpacity(0.55),
            decoration: TextDecoration.lineThrough,
          ),
        ),
        Text(
          'Rp ${rupiah(discounted)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
        ),
      ],
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

String _trimPromo(num v) {
  // 10.0 -> 10, 10.5 -> 10.5
  final d = v.toDouble();
  if (d == d.roundToDouble()) return d.toInt().toString();
  return d.toString();
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  _StickyHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      elevation: overlapsContent ? 2 : 0,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
    return minHeight != oldDelegate.minHeight ||
        maxHeight != oldDelegate.maxHeight ||
        child != oldDelegate.child;
  }
}
