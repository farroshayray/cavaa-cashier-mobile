part of 'reports_page.dart';

class _TransactionReportSheet extends StatefulWidget {
  const _TransactionReportSheet({
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
  State<_TransactionReportSheet> createState() =>
      _TransactionReportSheetState();
}

class _TransactionReportSheetState extends State<_TransactionReportSheet> {
  bool _isLoading = true;
  String? _errorMessage;
  List<_ReportTransactionItem> _transactions = const [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dioClient = context.read<DioClient>();
      final api = ReportApi(dioClient.dio);
      final response = await api.getTransactions(
        from: widget.from,
        to: widget.to,
        cashierScope: widget.cashierScope,
        paymentFilters: widget.paymentFilters,
      );

      final data = response['data'];
      if (data is! Map<String, dynamic>) {
        throw Exception('Format response transaksi tidak valid');
      }

      final rawItems = data['transactions'];
      if (rawItems is! List) {
        throw Exception('Daftar transaksi tidak valid');
      }

      final items =
          rawItems
              .whereType<Map>()
              .map(
                (item) => _ReportTransactionItem.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
            ..sort((a, b) => b.orderDate.compareTo(a.orderDate));

      if (!mounted) return;
      setState(() {
        _transactions = items;
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

  List<_TransactionMonthBucket> get _monthBuckets {
    final grouped = <String, List<_ReportTransactionItem>>{};

    for (final item in _transactions) {
      grouped.putIfAbsent(item.monthKey, () => []).add(item);
    }

    final buckets =
        grouped.entries
            .map(
              (entry) => _TransactionMonthBucket(
                monthKey: entry.key,
                monthLabel: _monthLabel(entry.value.first.orderDate),
                items: entry.value
                  ..sort((a, b) => b.orderDate.compareTo(a.orderDate)),
              ),
            )
            .toList()
          ..sort((a, b) => a.monthKey.compareTo(b.monthKey));

    return buckets;
  }

  String _monthLabel(DateTime date) {
    const monthNames = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return '${monthNames[date.month - 1]} ${date.year}';
  }

  String _formatDateHeading(DateTime date) {
    const dayNames = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const monthNames = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return '${dayNames[date.weekday - 1]}, ${date.day} ${monthNames[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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

  Future<void> _openTransactionDetail(_ReportTransactionItem item) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _TransactionDetailDialog(transactionId: item.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);
    final monthBuckets = _monthBuckets;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.92,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Daftar Transaksi',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    Text(
                      widget.rangeLabel,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black.withOpacity(0.64),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.filterLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withOpacity(0.52),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              if (_isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator(color: brand)),
                )
              else if (_errorMessage != null)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: brand,
                            size: 36,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Gagal memuat daftar transaksi',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.62),
                            ),
                          ),
                          const SizedBox(height: 14),
                          FilledButton(
                            onPressed: _loadTransactions,
                            style: FilledButton.styleFrom(
                              backgroundColor: brand,
                            ),
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (monthBuckets.isEmpty)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.receipt_long_outlined,
                            color: brand,
                            size: 38,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Belum ada transaksi pada filter ini',
                            style: TextStyle(fontWeight: FontWeight.w800),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: DefaultTabController(
                    length: monthBuckets.length,
                    child: Column(
                      children: [
                        SizedBox(
                          height: 48,
                          child: TabBar(
                            isScrollable: true,
                            labelColor: brand,
                            unselectedLabelColor: Colors.black54,
                            indicatorColor: brand,
                            dividerColor: const Color(0xFFE9EAEC),
                            tabs: [
                              for (final bucket in monthBuckets)
                                Tab(text: bucket.monthLabel),
                            ],
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              for (final bucket in monthBuckets)
                                _TransactionMonthList(
                                  items: bucket.items,
                                  formatDateHeading: _formatDateHeading,
                                  formatTime: _formatTime,
                                  formatCurrency: _formatCurrency,
                                  onTapItem: _openTransactionDetail,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionMonthList extends StatelessWidget {
  const _TransactionMonthList({
    required this.items,
    required this.formatDateHeading,
    required this.formatTime,
    required this.formatCurrency,
    required this.onTapItem,
  });

  final List<_ReportTransactionItem> items;
  final String Function(DateTime date) formatDateHeading;
  final String Function(DateTime date) formatTime;
  final String Function(num value) formatCurrency;
  final Future<void> Function(_ReportTransactionItem item) onTapItem;

  @override
  Widget build(BuildContext context) {
    const dividerColor = Color(0xFFE9EAEC);
    final groups = <String, List<_ReportTransactionItem>>{};
    final dateOrder = <String, DateTime>{};

    for (final item in items) {
      groups.putIfAbsent(item.dateKey, () => []).add(item);
      dateOrder[item.dateKey] = item.dateOnly;
    }

    final dateKeys = groups.keys.toList()
      ..sort((a, b) => dateOrder[b]!.compareTo(dateOrder[a]!));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: dateKeys.length,
      itemBuilder: (context, index) {
        final key = dateKeys[index];
        final sectionItems = groups[key]!
          ..sort((a, b) => b.orderDate.compareTo(a.orderDate));
        final sectionDate = dateOrder[key]!;

        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatDateHeading(sectionDate),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 14),
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      for (var i = 0; i < sectionItems.length; i++) ...[
                        _TransactionTile(
                          item: sectionItems[i],
                          timeLabel: formatTime(sectionItems[i].orderDate),
                          amountLabel: formatCurrency(
                            sectionItems[i].totalAmount,
                          ),
                          onTap: () => onTapItem(sectionItems[i]),
                        ),
                        if (i < sectionItems.length - 1)
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: dividerColor,
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.item,
    required this.timeLabel,
    required this.amountLabel,
    this.onTap,
  });

  final _ReportTransactionItem item;
  final String timeLabel;
  final String amountLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);
    final paymentMeta = _paymentMeta(item.paymentLabel);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(paymentMeta.icon, size: 14, color: brand),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.paymentLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  amountLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Flexible(
                  flex: 4,
                  child: Text(
                    item.orderCode,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black.withOpacity(0.52),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 5,
                  child: Text(
                    item.customerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black.withOpacity(0.64),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '$timeLabel | ${item.cashierName} | ${item.statusLabel}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                height: 1.35,
                color: Colors.black.withOpacity(0.64),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _TransactionPaymentMeta _paymentMeta(String label) {
    final normalized = label.toLowerCase();
    if (normalized.contains('cash')) {
      return const _TransactionPaymentMeta(Icons.payments_outlined);
    }
    if (normalized.contains('e-wallet')) {
      return const _TransactionPaymentMeta(
        Icons.account_balance_wallet_outlined,
      );
    }
    if (normalized.contains('tf')) {
      return const _TransactionPaymentMeta(Icons.account_balance_outlined);
    }
    if (normalized.contains('qr')) {
      return const _TransactionPaymentMeta(Icons.qr_code_2_rounded);
    }
    return const _TransactionPaymentMeta(Icons.credit_card_outlined);
  }
}

class _TransactionPaymentMeta {
  const _TransactionPaymentMeta(this.icon);

  final IconData icon;
}

class _TransactionDetailDialog extends StatefulWidget {
  const _TransactionDetailDialog({required this.transactionId});

  final int transactionId;

  @override
  State<_TransactionDetailDialog> createState() =>
      _TransactionDetailDialogState();
}

class _TransactionDetailDialogState extends State<_TransactionDetailDialog> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _detail;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dioClient = context.read<DioClient>();
      final api = ReportApi(dioClient.dio);
      final response = await api.getTransactionDetail(id: widget.transactionId);
      final data = response['data'];
      if (data is! Map<String, dynamic>) {
        throw Exception('Format detail transaksi tidak valid');
      }

      if (!mounted) return;
      setState(() {
        _detail = data;
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

  String _formatDateTime(String raw) {
    final parsed = _parseReportDateTime(raw);
    if (parsed == null) return raw;
    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final year = parsed.year.toString();
    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.82,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 10, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Detail Transaksi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Informasi order, pembayaran, dan item booking.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black.withOpacity(0.56),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF6F7F8),
                    ),
                    icon: const Icon(Icons.close_rounded, color: brand),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.black.withOpacity(0.08)),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: brand))
                  : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_errorMessage!, textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: _loadDetail,
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _TransactionDetailBody(
                      detail: _detail!,
                      formatCurrency: _formatCurrency,
                      formatDateTime: _formatDateTime,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionDetailBody extends StatelessWidget {
  const _TransactionDetailBody({
    required this.detail,
    required this.formatCurrency,
    required this.formatDateTime,
  });

  final Map<String, dynamic> detail;
  final String Function(num value) formatCurrency;
  final String Function(String raw) formatDateTime;

  Future<void> _openProofImagePreview(
    BuildContext context,
    String imageUrl,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Center(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Bukti transaksi tidak dapat dimuat.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.12),
                ),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = detail['order'] is Map
        ? Map<String, dynamic>.from(detail['order'] as Map)
        : <String, dynamic>{};
    final payment = detail['payment'] is Map
        ? Map<String, dynamic>.from(detail['payment'] as Map)
        : <String, dynamic>{};
    final items = detail['items'] is List ? detail['items'] as List : const [];
    final proofImageUrl = _normalizeReportImageUrl(
      payment['manual_payment_image']?.toString(),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailSectionCard(
            title: 'Booking Order',
            children: [
              _DetailRow(
                label: 'Kode',
                value: (order['booking_order_code'] ?? '-').toString(),
              ),
              _DetailRow(
                label: 'Customer',
                value: (order['customer_name'] ?? '-').toString(),
              ),
              _DetailRow(
                label: 'Meja',
                value: (order['table_name'] ?? '-').toString(),
              ),
              _DetailRow(
                label: 'Status',
                value: (order['order_status'] ?? '-').toString(),
              ),
              _DetailRow(
                label: 'Waktu Order',
                value: formatDateTime((order['created_at'] ?? '-').toString()),
              ),
              _DetailRow(
                label: 'Subtotal',
                value: formatCurrency(
                  _ReportSummaryData._asNum(order['total_order_value']),
                ),
              ),
              _DetailRow(
                label: 'PPN',
                value:
                    '${_ReportSummaryData._asNum(order['ppn'])}%'
                    '${(order['is_ppn_active'] == true || order['is_ppn_active'] == 1 || order['is_ppn_active'] == '1') ? '' : ' (off)'}',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DetailSectionCard(
            title: 'Transaksi Pembayaran',
            children: [
              _DetailRow(
                label: 'Tipe',
                value: (payment['payment_label'] ?? '-').toString(),
              ),
              _DetailRow(
                label: 'Status',
                value: (payment['payment_status'] ?? '-').toString(),
              ),
              _DetailRow(
                label: 'Kasir',
                value: (payment['cashier_name'] ?? '-').toString(),
              ),
              _DetailRow(
                label: 'Waktu Bayar',
                value: formatDateTime((payment['paid_at'] ?? '-').toString()),
              ),
              _DetailRow(
                label: 'Sebelum PPN',
                value: formatCurrency(
                  _ReportSummaryData._asNum(payment['amount_before_ppn']),
                ),
              ),
              _DetailRow(
                label: 'Dibayar',
                value: formatCurrency(
                  _ReportSummaryData._asNum(payment['paid_amount']),
                ),
              ),
              _DetailRow(
                label: 'Kembalian',
                value: formatCurrency(
                  _ReportSummaryData._asNum(payment['change_amount']),
                ),
              ),
              if ((payment['provider_name'] ?? '').toString().trim().isNotEmpty)
                _DetailRow(
                  label: 'Provider',
                  value: payment['provider_name'].toString(),
                ),
              if ((payment['account_name'] ?? '').toString().trim().isNotEmpty)
                _DetailRow(
                  label: 'Atas Nama',
                  value: payment['account_name'].toString(),
                ),
              if ((payment['account_no'] ?? '').toString().trim().isNotEmpty)
                _DetailRow(
                  label: 'No. Akun',
                  value: payment['account_no'].toString(),
                ),
              if (proofImageUrl != null) ...[
                const SizedBox(height: 6),
                const Text(
                  'Bukti Transaksi',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () => _openProofImagePreview(context, proofImageUrl),
                  borderRadius: BorderRadius.circular(12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: ColoredBox(
                              color: const Color(0xFFF7F8F9),
                              child: Image.network(
                                proofImageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFFF7F8F9),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Bukti transaksi tidak dapat dimuat.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black.withOpacity(0.58),
                                    ),
                                  ),
                                ),
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(
                                        child: SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      );
                                    },
                              ),
                            ),
                          ),
                          Positioned(
                            right: 10,
                            bottom: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.55),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.zoom_in_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Perbesar',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              if ((payment['note'] ?? '').toString().trim().isNotEmpty)
                _DetailRow(label: 'Catatan', value: payment['note'].toString()),
            ],
          ),
          const SizedBox(height: 12),
          _DetailSectionCard(
            title: 'Item Booking',
            children: [
              if (items.isEmpty)
                Text(
                  'Tidak ada item.',
                  style: TextStyle(color: Colors.black.withOpacity(0.6)),
                )
              else
                ...items.map<Widget>((item) {
                  final map = item is Map
                      ? Map<String, dynamic>.from(item)
                      : <String, dynamic>{};
                  final options = map['options'] is List
                      ? map['options'] as List
                      : const [];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                '${(map['product_name'] ?? '-').toString()} x ${(map['quantity'] ?? 0).toString()}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              formatCurrency(
                                _ReportSummaryData._asNum(map['line_total']),
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        if ((map['customer_note'] ?? '')
                            .toString()
                            .trim()
                            .isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Catatan: ${(map['customer_note'] ?? '').toString()}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black.withOpacity(0.58),
                            ),
                          ),
                        ],
                        if (options.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          ...options.map<Widget>((option) {
                            final optionMap = option is Map
                                ? Map<String, dynamic>.from(option)
                                : <String, dynamic>{};
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                '- ${(optionMap['parent_name'] ?? 'Opsi').toString()}: ${(optionMap['option_name'] ?? '-').toString()}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black.withOpacity(0.62),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ],
                    ),
                  );
                }).toList(),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailSectionCard extends StatelessWidget {
  const _DetailSectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE9ECEF)),
            ),
            child: Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 102,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.black.withOpacity(0.52),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
