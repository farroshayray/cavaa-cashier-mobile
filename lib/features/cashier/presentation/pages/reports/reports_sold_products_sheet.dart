part of 'reports_page.dart';

class _SoldProductsReportSheet extends StatefulWidget {
  const _SoldProductsReportSheet({
    required this.from,
    required this.to,
    required this.cashierScope,
    required this.paymentFilters,
    required this.rangeLabel,
    required this.filterLabel,
  });

  final String from;
  final String to;
  final String cashierScope;
  final List<String> paymentFilters;
  final String rangeLabel;
  final String filterLabel;

  @override
  State<_SoldProductsReportSheet> createState() =>
      _SoldProductsReportSheetState();
}

class _SoldProductsReportSheetState extends State<_SoldProductsReportSheet> {
  bool _isLoading = true;
  String? _errorMessage;
  _SoldProductSummaryData? _summary;
  List<_SoldProductItem> _products = const [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dioClient = context.read<DioClient>();
      final api = ReportApi(dioClient.dio);
      final response = await api.getSoldProducts(
        from: widget.from,
        to: widget.to,
        cashierScope: widget.cashierScope,
        paymentFilters: widget.paymentFilters,
      );

      final data = response['data'];
      if (data is! Map<String, dynamic>) {
        throw Exception('Format response produk terjual tidak valid');
      }

      final summaryJson = data['summary'];
      final productsJson = data['products'];
      if (summaryJson is! Map<String, dynamic> || productsJson is! List) {
        throw Exception('Data produk terjual tidak valid');
      }

      final products = productsJson
          .whereType<Map>()
          .map(
            (item) =>
                _SoldProductItem.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();

      if (!mounted) return;
      setState(() {
        _summary = _SoldProductSummaryData.fromJson(summaryJson);
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatCurrency(num value) {
    final digits = value.round().toString();
    final buffer = StringBuffer();

    for (var i = 0; i < digits.length; i++) {
      final indexFromEnd = digits.length - i;
      buffer.write(digits[i]);
      if (indexFromEnd > 1 && indexFromEnd % 3 == 1) {
        buffer.write('.');
      }
    }

    return 'Rp ${buffer.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);
    const accent = Color(0xFFF4C95D);
    final topProduct = _products.isNotEmpty ? _products.first : null;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF7F4EF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.92,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Produk Terjual',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.rangeLabel,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black.withOpacity(0.64),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.filterLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black.withOpacity(0.52),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: brand),
                      )
                    : _errorMessage != null
                    ? _SoldProductsErrorState(
                        errorMessage: _errorMessage!,
                        onRetry: _loadProducts,
                      )
                    : _products.isEmpty
                    ? const _SoldProductsEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
                        itemCount: _products.length <= 1
                            ? 2
                            : _products.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _SoldProductsSummaryHero(
                              isLoading: _isLoading,
                              summary: _summary,
                              formatCurrency: _formatCurrency,
                            );
                          }

                          if (index == 1 && topProduct != null) {
                            return _TopSoldProductCard(
                              product: topProduct,
                              rank: 1,
                              formatCurrency: _formatCurrency,
                              accentColor: accent,
                            );
                          }

                          final product = _products[index - 1];
                          return _SoldProductTile(
                            product: product,
                            rank: index,
                            formatCurrency: _formatCurrency,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoldProductsSummaryHero extends StatelessWidget {
  const _SoldProductsSummaryHero({
    required this.isLoading,
    required this.summary,
    required this.formatCurrency,
  });

  final bool isLoading;
  final _SoldProductSummaryData? summary;
  final String Function(num value) formatCurrency;

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);
    const soft = Color(0xFFFFF4E7);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [brand, Color(0xFFD9481D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: brand.withOpacity(0.22),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: soft,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Sorotan Penjualan Produk',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SummaryStatPill(
                label: 'Produk',
                value: isLoading ? '...' : '${summary?.totalProducts ?? 0}',
              ),
              _SummaryStatPill(
                label: 'Qty Terjual',
                value: isLoading ? '...' : '${summary?.totalQuantity ?? 0}',
              ),
              _SummaryStatPill(
                label: 'Omzet Produk',
                value: isLoading
                    ? '...'
                    : formatCurrency(summary?.totalRevenue ?? 0),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryStatPill extends StatelessWidget {
  const _SummaryStatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.72),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopSoldProductCard extends StatelessWidget {
  const _TopSoldProductCard({
    required this.product,
    required this.rank,
    required this.formatCurrency,
    required this.accentColor,
  });

  final _SoldProductItem product;
  final int rank;
  final String Function(num value) formatCurrency;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF0E3D5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _RankBadge(rank: rank, backgroundColor: accentColor),
          const SizedBox(width: 14),
          _SoldProductImage(imageUrl: product.imageUrl, size: 72),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Paling Banyak Terjual',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8A5D2E),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetricChip(
                      icon: Icons.shopping_bag_outlined,
                      label: '${product.totalQuantity} porsi',
                    ),
                    _MetricChip(
                      icon: Icons.payments_outlined,
                      label: formatCurrency(product.totalRevenue),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SoldProductTile extends StatelessWidget {
  const _SoldProductTile({
    required this.product,
    required this.rank,
    required this.formatCurrency,
  });

  final _SoldProductItem product;
  final int rank;
  final String Function(num value) formatCurrency;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF8),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE6D8CA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RankBadge(rank: rank, backgroundColor: const Color(0xFFF5E7D8)),
          const SizedBox(width: 12),
          _SoldProductImage(imageUrl: product.imageUrl, size: 74),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  maxLines: 3,
                  overflow: TextOverflow.visible,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: _MetricChip(
                        icon: Icons.inventory_2_outlined,
                        label: '${product.totalQuantity} terjual',
                        compact: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: _MetricChip(
                        icon: Icons.account_balance_wallet_outlined,
                        label: formatCurrency(product.totalRevenue),
                        compact: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({
    required this.rank,
    this.backgroundColor = const Color(0xFFFFE7D3),
  });

  final int rank;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        '#$rank',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: Color(0xFF7F3A12),
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 8 : 9,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F2EC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Icon(icon, size: compact ? 14 : 15, color: const Color(0xFFAE1504)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF5B2A14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoldProductImage extends StatelessWidget {
  const _SoldProductImage({required this.imageUrl, this.size = 58});

  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    const fallbackColor = Color(0xFFFFF1E5);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fallbackColor,
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl == null
          ? const Icon(Icons.fastfood_rounded, color: Color(0xFFAE1504))
          : Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.fastfood_rounded, color: Color(0xFFAE1504)),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
            ),
    );
  }
}

class _SoldProductsErrorState extends StatelessWidget {
  const _SoldProductsErrorState({
    required this.errorMessage,
    required this.onRetry,
  });

  final String errorMessage;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.sentiment_dissatisfied_rounded,
              color: Color(0xFFAE1504),
              size: 38,
            ),
            const SizedBox(height: 12),
            const Text(
              'Produk terjual belum bisa dimuat',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black.withOpacity(0.62)),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => onRetry(),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFAE1504),
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoldProductsEmptyState extends StatelessWidget {
  const _SoldProductsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1E5),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 32,
                color: Color(0xFFAE1504),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Belum ada produk terjual',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              'Coba ubah periode atau filter pembayaran untuk melihat produk yang terjual.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black.withOpacity(0.62),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
