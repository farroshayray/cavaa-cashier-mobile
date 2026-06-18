import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '/core/config/env.dart';
import '/core/network/dio_client.dart';
import '/features/cashier/data/models/purchase_models.dart';
import '/features/cashier/data/report_api.dart';
import '/features/cashier/presentation/providers/purchase_provider.dart';

part 'reports_filters.dart';
part 'reports_sold_products_sheet.dart';
part 'reports_transaction_sheet.dart';

enum _ReportPeriodType { today, last7Days, thisMonth, last30Days, custom }

enum _CashierScope { self, all }

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  _ReportPeriodType _selectedPeriod = _ReportPeriodType.today;
  _CashierScope _cashierScope = _CashierScope.self;
  DateTimeRange? _customRange;
  DateTimeRange _activeRange = _singleDayRange(DateTime.now());
  _ReportSummaryData? _summary;
  bool _isLoading = false;
  bool _isExporting = false;
  String? _errorMessage;
  Set<String> _selectedPaymentFilters = <String>{};

  static DateTimeRange _singleDayRange(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return DateTimeRange(start: normalized, end: normalized);
  }

  @override
  void initState() {
    super.initState();
    _activeRange = _resolveRange(_selectedPeriod, DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSummary();
    });
  }

  DateTimeRange _resolveRange(_ReportPeriodType type, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);

    switch (type) {
      case _ReportPeriodType.today:
        return DateTimeRange(start: today, end: today);
      case _ReportPeriodType.last7Days:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 6)),
          end: today,
        );
      case _ReportPeriodType.thisMonth:
        return DateTimeRange(
          start: DateTime(today.year, today.month, 1),
          end: today,
        );
      case _ReportPeriodType.last30Days:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 29)),
          end: today,
        );
      case _ReportPeriodType.custom:
        return _customRange ?? DateTimeRange(start: today, end: today);
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  String _formatApiDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }

  String _formatCurrency(num value) {
    final isNegative = value < 0;
    final digits = value.abs().round().toString();
    final buffer = StringBuffer();

    for (var i = 0; i < digits.length; i++) {
      final indexFromEnd = digits.length - i;
      buffer.write(digits[i]);
      if (indexFromEnd > 1 && indexFromEnd % 3 == 1) {
        buffer.write('.');
      }
    }

    return '${isNegative ? '-' : ''}Rp ${buffer.toString()}';
  }

  String _periodTitle(_ReportPeriodType type) {
    switch (type) {
      case _ReportPeriodType.today:
        return 'Hari ini';
      case _ReportPeriodType.last7Days:
        return '7 Hari terakhir';
      case _ReportPeriodType.thisMonth:
        return 'Bulan ini';
      case _ReportPeriodType.last30Days:
        return '30 Hari terakhir';
      case _ReportPeriodType.custom:
        return 'Pilih Periode Transaksi';
    }
  }

  String _cashierScopeValue(_CashierScope scope) {
    switch (scope) {
      case _CashierScope.self:
        return 'self';
      case _CashierScope.all:
        return 'all';
    }
  }

  String _cashierScopeLabel(_CashierScope scope) {
    switch (scope) {
      case _CashierScope.self:
        return 'Kasir Saya';
      case _CashierScope.all:
        return 'Semua Kasir';
    }
  }

  List<_ReportPaymentFilterOption> get _availablePaymentFilterOptions {
    final purchaseProvider = context.read<PurchaseProvider>();
    final options = purchaseProvider.paymentOptions;

    if (options.isEmpty) {
      return const [
        _ReportPaymentFilterOption(
          key: 'cash',
          label: 'CASH',
          groupOrder: 0,
          icon: Icons.payments_outlined,
        ),
        _ReportPaymentFilterOption(
          key: 'qris',
          label: 'QR Xendit',
          groupOrder: 0,
          icon: Icons.qr_code_2_rounded,
        ),
      ];
    }

    final mapped = options
        .map(_ReportPaymentFilterOption.fromPaymentOption)
        .whereType<_ReportPaymentFilterOption>()
        .toList();

    mapped.sort((a, b) {
      final groupCompare = a.groupOrder.compareTo(b.groupOrder);
      if (groupCompare != 0) return groupCompare;
      return a.label.compareTo(b.label);
    });

    return mapped;
  }

  List<String> get _activePaymentFilterKeys {
    if (_selectedPaymentFilters.isEmpty) {
      return const [];
    }

    final availableKeys = _availablePaymentFilterOptions
        .map((e) => e.key)
        .toSet();
    return _selectedPaymentFilters.where(availableKeys.contains).toList()
      ..sort();
  }

  String get _paymentFilterLabel {
    final selectedKeys = _activePaymentFilterKeys;
    if (selectedKeys.isEmpty) {
      return 'Semua metode pembayaran';
    }

    final optionsByKey = {
      for (final option in _availablePaymentFilterOptions) option.key: option,
    };
    final labels = selectedKeys
        .map((key) => optionsByKey[key]?.label)
        .whereType<String>()
        .toList();

    if (labels.isEmpty) {
      return 'Semua metode pembayaran';
    }
    if (labels.length <= 2) {
      return labels.join(', ');
    }
    return '${labels.length} metode pembayaran';
  }

  String get _activeFilterSummary {
    return '${_cashierScopeLabel(_cashierScope)} | $_paymentFilterLabel';
  }

  String get _activeRangeLabel {
    return '${_formatDate(_activeRange.start)} - ${_formatDate(_activeRange.end)}';
  }

  String _extractErrorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message']?.toString();
        if (message != null && message.trim().isNotEmpty) {
          return message;
        }
      }
    }

    return 'Gagal memuat laporan. Coba lagi.';
  }

  Future<void> _loadSummary() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dioClient = context.read<DioClient>();
      final api = ReportApi(dioClient.dio);
      final response = await api.getSummary(
        from: _formatApiDate(_activeRange.start),
        to: _formatApiDate(_activeRange.end),
        cashierScope: _cashierScopeValue(_cashierScope),
        paymentFilters: _activePaymentFilterKeys,
      );

      final data = response['data'];
      if (data is! Map<String, dynamic>) {
        throw Exception('Format response laporan tidak valid');
      }

      if (!mounted) return;

      setState(() {
        _summary = _ReportSummaryData.fromJson(data);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _extractErrorMessage(e);
      });
    }
  }

  Future<void> _exportReport() async {
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
    });

    try {
      final dioClient = context.read<DioClient>();
      final api = ReportApi(dioClient.dio);
      final bytes = await api.exportSummary(
        from: _formatApiDate(_activeRange.start),
        to: _formatApiDate(_activeRange.end),
        cashierScope: _cashierScopeValue(_cashierScope),
        paymentFilters: _activePaymentFilterKeys,
      );

      final dir = await getApplicationDocumentsDirectory();
      final folder = Directory('${dir.path}/report_exports');
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }

      final fileName =
          'laporan_${_formatApiDate(_activeRange.start)}_${_formatApiDate(_activeRange.end)}_${_cashierScopeValue(_cashierScope)}${_activePaymentFilterKeys.isEmpty ? '' : '_filtered'}.csv';
      final file = File('${folder.path}/$fileName');

      if (await file.exists()) {
        await file.delete();
      }

      await file.writeAsBytes(bytes, flush: true);
      await OpenFilex.open(file.path);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File export disimpan: $fileName')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export gagal: ${_extractErrorMessage(e)}')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isExporting = false;
      });
    }
  }

  Future<void> _openPeriodFilterModal() async {
    final selected = await showModalBottomSheet<_ReportPeriodType>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _PeriodFilterSheet(selectedPeriod: _selectedPeriod),
    );

    if (!mounted || selected == null) return;

    if (selected == _ReportPeriodType.custom) {
      await _pickCustomRange();
      return;
    }

    final range = _resolveRange(selected, DateTime.now());
    setState(() {
      _selectedPeriod = selected;
      _activeRange = range;
    });
    await _loadSummary();
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final pickedRange = await showModalBottomSheet<DateTimeRange>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _CustomRangePickerSheet(
          initialRange: _customRange ?? _activeRange,
          firstDate: DateTime(2023),
          lastDate: today,
        );
      },
    );

    if (!mounted || pickedRange == null) return;

    setState(() {
      _customRange = pickedRange;
      _selectedPeriod = _ReportPeriodType.custom;
      _activeRange = pickedRange;
    });
    await _loadSummary();
  }

  Future<void> _updateCashierScope(_CashierScope scope) async {
    if (_cashierScope == scope) return;

    setState(() {
      _cashierScope = scope;
    });

    await _loadSummary();
  }

  Future<void> _openFilterModal() async {
    final availableOptions = _availablePaymentFilterOptions;
    final nextSelection = await showModalBottomSheet<Set<String>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ReportFilterSheet(
        paymentOptions: availableOptions,
        initialSelection: _activePaymentFilterKeys.toSet(),
      ),
    );

    if (!mounted || nextSelection == null) return;

    final sanitized = nextSelection
        .where(availableOptions.map((e) => e.key).toSet().contains)
        .toSet();

    if (setEquals(sanitized, _selectedPaymentFilters)) {
      return;
    }

    setState(() {
      _selectedPaymentFilters = sanitized;
    });
    await _loadSummary();
  }

  Future<void> _openTransactionReportModal() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _TransactionReportSheet(
        from: _formatApiDate(_activeRange.start),
        to: _formatApiDate(_activeRange.end),
        cashierScope: _cashierScopeValue(_cashierScope),
        paymentFilters: _activePaymentFilterKeys,
        rangeLabel: _activeRangeLabel,
        filterLabel: _activeFilterSummary,
      ),
    );
  }

  Future<void> _openSoldProductsModal() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _SoldProductsReportSheet(
        from: _formatApiDate(_activeRange.start),
        to: _formatApiDate(_activeRange.end),
        cashierScope: _cashierScopeValue(_cashierScope),
        paymentFilters: _activePaymentFilterKeys,
        rangeLabel: _activeRangeLabel,
        filterLabel: _activeFilterSummary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(title: const Text('Laporan')),
      body: RefreshIndicator(
        onRefresh: _loadSummary,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _ReportsHeroCard(),
            const SizedBox(height: 16),
            _CashierFilterSection(
              selectedScope: _cashierScope,
              onChanged: _updateCashierScope,
            ),
            const SizedBox(height: 16),
            _DateFilterSection(
              selectedLabel: _periodTitle(_selectedPeriod),
              rangeLabel: _activeRangeLabel,
              activeFilterCount: _activePaymentFilterKeys.length,
              onDateTap: _openPeriodFilterModal,
              onFilterTap: _openFilterModal,
            ),
            const SizedBox(height: 16),
            _SummarySection(
              title: 'Ringkasan ${_periodTitle(_selectedPeriod)}',
              subtitle: _isLoading
                  ? 'Mengambil data laporan dari server.'
                  : 'Filter aktif: $_activeFilterSummary.',
              omzet: _formatCurrency(_summary?.omzet ?? 0),
              totalTransactions: '${_summary?.totalTransactions ?? 0} Order',
              averageTransaction: _formatCurrency(
                _summary?.averageTransaction ?? 0,
              ),
              cashVsNonCash:
                  '${_formatCurrency(_summary?.cashAmount ?? 0)} / ${_formatCurrency(_summary?.nonCashAmount ?? 0)}',
              isLoading: _isLoading,
            ),
            const SizedBox(height: 16),
            _QuickReportSection(
              onTransactionTap: _openTransactionReportModal,
              onSoldProductsTap: _openSoldProductsModal,
            ),
            const SizedBox(height: 16),
            _RecentActivitySection(
              isLoading: _isLoading,
              isExporting: _isExporting,
              errorMessage: _errorMessage,
              hasData: _summary != null,
              activeFilterLabel: _activeFilterSummary,
              onRetry: _loadSummary,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: brand,
        foregroundColor: Colors.white,
        onPressed: (_isLoading || _isExporting) ? null : _exportReport,
        icon: _isExporting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.file_download_outlined),
        label: Text(_isExporting ? 'Exporting...' : 'Export CSV'),
      ),
    );
  }
}

class _ReportsHeroCard extends StatelessWidget {
  const _ReportsHeroCard();

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: brand,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: brand.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, color: Colors.white),
              SizedBox(width: 10),
              Text(
                'Laporan Penjualan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'Ringkasan laporan, filter kasir, dan export CSV sekarang siap untuk mobile cashier.',
            style: TextStyle(color: Colors.white, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({
    required this.title,
    required this.subtitle,
    required this.omzet,
    required this.totalTransactions,
    required this.averageTransaction,
    required this.cashVsNonCash,
    required this.isLoading,
  });

  final String title;
  final String subtitle;
  final String omzet;
  final String totalTransactions;
  final String averageTransaction;
  final String cashVsNonCash;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: title, subtitle: subtitle),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _SummaryCard(
                  icon: Icons.payments_outlined,
                  label: 'Omzet',
                  value: omzet,
                  isLoading: isLoading,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  icon: Icons.receipt_long_outlined,
                  label: 'Transaksi',
                  value: totalTransactions,
                  isLoading: isLoading,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _SummaryCard(
                  icon: Icons.trending_up_outlined,
                  label: 'Rata-rata',
                  value: averageTransaction,
                  isLoading: isLoading,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CashSplitSummaryCard(
                  icon: Icons.point_of_sale_outlined,
                  label: 'Tunai/Non Tunai',
                  cashVsNonCash: cashVsNonCash,
                  isLoading: isLoading,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickReportSection extends StatelessWidget {
  const _QuickReportSection({
    required this.onTransactionTap,
    required this.onSoldProductsTap,
  });

  final VoidCallback onTransactionTap;
  final VoidCallback onSoldProductsTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Jenis Laporan',
          subtitle: 'Ruang ini tetap siap untuk laporan turunan berikutnya.',
        ),
        const SizedBox(height: 12),
        _MenuCard(
          icon: Icons.today_outlined,
          title: 'Daftar Transaksi',
          subtitle:
              'Laporan lengkap semua transaksi yang terjadi dalam periode terpilih.',
          onTap: onTransactionTap,
        ),
        const SizedBox(height: 10),
        _MenuCard(
          icon: Icons.inventory_2_outlined,
          title: 'Produk Terjual',
          subtitle:
              'Ringkasan produk terlaris dan jumlah penjualan untuk periode terpilih.',
          onTap: onSoldProductsTap,
        ),
      ],
    );
  }
}

class _RecentActivitySection extends StatelessWidget {
  const _RecentActivitySection({
    required this.isLoading,
    required this.isExporting,
    required this.errorMessage,
    required this.hasData,
    required this.activeFilterLabel,
    required this.onRetry,
  });

  final bool isLoading;
  final bool isExporting;
  final String? errorMessage;
  final bool hasData;
  final String activeFilterLabel;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Divider(
            height: 1,
            thickness: 1,
            color: Colors.black.withOpacity(0.08),
          ),
        ),
        const SizedBox(height: 14),
        _EmptyStateCard(
          isLoading: isLoading,
          isExporting: isExporting,
          errorMessage: errorMessage,
          hasData: hasData,
          activeFilterLabel: activeFilterLabel,
          onRetry: onRetry,
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        // Text(
        //   subtitle,
        //   style: TextStyle(color: Colors.black.withOpacity(0.65)),
        // ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    this.isLoading = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);

    return Container(
      height: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: brand.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: brand),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.black.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isLoading ? 'Memuat...' : value,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _CashSplitSummaryCard extends StatelessWidget {
  const _CashSplitSummaryCard({
    required this.icon,
    required this.label,
    required this.cashVsNonCash,
    this.isLoading = false,
  });

  final IconData icon;
  final String label;
  final String cashVsNonCash;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);
    final parts = cashVsNonCash.split('/').map((e) => e.trim()).toList();
    final cashLabel = parts.isNotEmpty ? parts.first : 'Rp 0';
    final nonCashLabel = parts.length > 1 ? parts[1] : 'Rp 0';

    return Container(
      height: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: brand.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: brand),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.black.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          if (isLoading)
            const Text(
              'Memuat...',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            )
          else ...[
            _SummaryBreakdownRow(title: 'Tunai', value: cashLabel),
            const SizedBox(height: 6),
            _SummaryBreakdownRow(title: 'Non Tunai', value: nonCashLabel),
          ],
        ],
      ),
    );
  }
}

class _SummaryBreakdownRow extends StatelessWidget {
  const _SummaryBreakdownRow({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 58,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.black.withOpacity(0.52),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: brand.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: brand),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: onTap == null ? Colors.black54 : brand,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.isLoading,
    required this.isExporting,
    required this.errorMessage,
    required this.hasData,
    required this.activeFilterLabel,
    required this.onRetry,
  });

  final bool isLoading;
  final bool isExporting;
  final String? errorMessage;
  final bool hasData;
  final String activeFilterLabel;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);
    final hasError = errorMessage != null;

    final title = isLoading
        ? 'Memuat laporan'
        : hasError
        ? 'Laporan belum bisa diperbarui'
        : hasData
        ? isExporting
              ? 'Export sedang diproses'
              : 'Laporan mengikuti filter aktif'
        : 'Belum ada ringkasan laporan';

    final description = isLoading
        ? 'Ringkasan omzet dan transaksi sedang diambil dari server.'
        : hasError
        ? errorMessage!
        : hasData
        ? isExporting
              ? 'File CSV sedang disiapkan. Anda bisa menunggu sampai proses export selesai.'
              : 'Data yang tampil saat ini menggunakan filter: $activeFilterLabel.'
        : 'Pilih periode dan filter yang sesuai untuk mulai melihat data laporan.';

    final icon = isLoading
        ? Icons.sync_rounded
        : hasError
        ? Icons.error_outline_rounded
        : hasData
        ? isExporting
              ? Icons.file_download_outlined
              : Icons.info_outline_rounded
        : Icons.filter_alt_outlined;

    final backgroundColor = hasError
        ? const Color(0xFFFFF3F1)
        : const Color(0xFFFFFBF6);
    final borderColor = hasError
        ? const Color(0xFFF3C8C1)
        : const Color(0xFFF1DEC9);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 5,
            height: hasError ? 132 : 108,
            decoration: BoxDecoration(
              color: hasError
                  ? const Color(0xFFD9481D)
                  : const Color(0xFFE0B46C),
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(20),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: brand.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: brand, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            hasError ? 'Perhatian' : 'Catatan',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.black.withOpacity(0.6),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black.withOpacity(0.68),
                            height: 1.4,
                          ),
                        ),
                        if (hasError) ...[
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: isLoading ? null : () => onRetry(),
                            style: FilledButton.styleFrom(
                              backgroundColor: brand,
                              visualDensity: VisualDensity.compact,
                            ),
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportSummaryData {
  const _ReportSummaryData({
    required this.omzet,
    required this.totalTransactions,
    required this.averageTransaction,
    required this.cashAmount,
    required this.nonCashAmount,
  });

  final num omzet;
  final int totalTransactions;
  final num averageTransaction;
  final num cashAmount;
  final num nonCashAmount;

  factory _ReportSummaryData.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] is Map<String, dynamic>
        ? json['summary'] as Map<String, dynamic>
        : <String, dynamic>{};
    final breakdown = json['payment_breakdown'] is Map<String, dynamic>
        ? json['payment_breakdown'] as Map<String, dynamic>
        : <String, dynamic>{};
    final cash = breakdown['cash'] is Map<String, dynamic>
        ? breakdown['cash'] as Map<String, dynamic>
        : <String, dynamic>{};
    final nonCash = breakdown['non_cash'] is Map<String, dynamic>
        ? breakdown['non_cash'] as Map<String, dynamic>
        : <String, dynamic>{};

    return _ReportSummaryData(
      omzet: _asNum(summary['omzet']),
      totalTransactions: _asNum(summary['total_transactions']).toInt(),
      averageTransaction: _asNum(summary['average_transaction']),
      cashAmount: _asNum(cash['amount']),
      nonCashAmount: _asNum(nonCash['amount']),
    );
  }

  static num _asNum(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? 0;
    return 0;
  }
}

class _TransactionMonthBucket {
  const _TransactionMonthBucket({
    required this.monthKey,
    required this.monthLabel,
    required this.items,
  });

  final String monthKey;
  final String monthLabel;
  final List<_ReportTransactionItem> items;
}

class _ReportTransactionItem {
  const _ReportTransactionItem({
    required this.id,
    required this.orderCode,
    required this.customerName,
    required this.cashierName,
    required this.paymentLabel,
    required this.statusLabel,
    required this.totalAmount,
    required this.orderDate,
  });

  final int id;
  final String orderCode;
  final String customerName;
  final String cashierName;
  final String paymentLabel;
  final String statusLabel;
  final num totalAmount;
  final DateTime orderDate;

  DateTime get dateOnly =>
      DateTime(orderDate.year, orderDate.month, orderDate.day);

  String get dateKey {
    final month = orderDate.month.toString().padLeft(2, '0');
    final day = orderDate.day.toString().padLeft(2, '0');
    return '${orderDate.year}-$month-$day';
  }

  String get monthKey {
    final month = orderDate.month.toString().padLeft(2, '0');
    return '${orderDate.year}-$month';
  }

  factory _ReportTransactionItem.fromJson(Map<String, dynamic> json) {
    return _ReportTransactionItem(
      id: _ReportSummaryData._asNum(json['id']).toInt(),
      orderCode: (json['order_code'] ?? '-').toString(),
      customerName: (json['customer_name'] ?? 'Guest').toString(),
      cashierName: (json['cashier_name'] ?? '-').toString(),
      paymentLabel: (json['payment_label'] ?? '-').toString(),
      statusLabel: (json['status_label'] ?? json['status'] ?? '-').toString(),
      totalAmount: _ReportSummaryData._asNum(json['total_amount']),
      orderDate:
          _parseReportDateTime((json['order_datetime'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

DateTime? _parseReportDateTime(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return null;
  return parsed.isUtc ? parsed.toLocal() : parsed;
}

class _SoldProductSummaryData {
  const _SoldProductSummaryData({
    required this.totalProducts,
    required this.totalQuantity,
    required this.totalRevenue,
  });

  final int totalProducts;
  final int totalQuantity;
  final num totalRevenue;

  factory _SoldProductSummaryData.fromJson(Map<String, dynamic> json) {
    return _SoldProductSummaryData(
      totalProducts: _ReportSummaryData._asNum(json['total_products']).toInt(),
      totalQuantity: _ReportSummaryData._asNum(json['total_quantity']).toInt(),
      totalRevenue: _ReportSummaryData._asNum(json['total_revenue']),
    );
  }
}

class _SoldProductItem {
  const _SoldProductItem({
    required this.productKey,
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.totalQuantity,
    required this.totalRevenue,
  });

  final String productKey;
  final int? productId;
  final String productName;
  final String? imageUrl;
  final int totalQuantity;
  final num totalRevenue;

  factory _SoldProductItem.fromJson(Map<String, dynamic> json) {
    return _SoldProductItem(
      productKey: (json['product_key'] ?? '').toString(),
      productId: json['product_id'] == null
          ? null
          : _ReportSummaryData._asNum(json['product_id']).toInt(),
      productName: (json['product_name'] ?? '-').toString(),
      imageUrl: _normalizeReportImageUrl(json['image_url']?.toString()),
      totalQuantity: _ReportSummaryData._asNum(json['total_quantity']).toInt(),
      totalRevenue: _ReportSummaryData._asNum(json['total_revenue']),
    );
  }
}

String? _normalizeReportImageUrl(String? rawUrl) {
  if (rawUrl == null) return null;

  final normalized = rawUrl.trim();
  if (normalized.isEmpty) return null;
  if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
    return normalized;
  }

  final base = Env.baseUrl.replaceAll(RegExp(r'/$'), '');
  final cleanPath = normalized.replaceFirst(RegExp(r'^/+'), '');
  if (cleanPath.startsWith('storage/')) {
    return '$base/$cleanPath';
  }

  return '$base/storage/$cleanPath';
}

class _ReportPaymentFilterOption {
  const _ReportPaymentFilterOption({
    required this.key,
    required this.label,
    required this.groupOrder,
    required this.icon,
    this.subtitle,
  });

  final String key;
  final String label;
  final int groupOrder;
  final IconData icon;
  final String? subtitle;

  static _ReportPaymentFilterOption? fromPaymentOption(PaymentOption option) {
    switch (option.kind) {
      case PayKind.cashierCash:
        return const _ReportPaymentFilterOption(
          key: 'cash',
          label: 'CASH',
          groupOrder: 0,
          icon: Icons.payments_outlined,
        );
      case PayKind.paylater:
        return const _ReportPaymentFilterOption(
          key: 'paylater',
          label: 'PAYLATER',
          groupOrder: 0,
          icon: Icons.payments_outlined,
        );
      case PayKind.onlineQris:
        return const _ReportPaymentFilterOption(
          key: 'qris',
          label: 'QR Xendit',
          groupOrder: 0,
          icon: Icons.qr_code_2_rounded,
        );
      case PayKind.manual:
        final manualId = option.manualId;
        if (manualId == null) return null;

        final manualType = option.manualType ?? '';
        if (manualType == 'manual_tf') {
          return _ReportPaymentFilterOption(
            key: 'manual:$manualId',
            label: 'TF ${option.label}',
            subtitle: option.providerAccountName,
            groupOrder: 1,
            icon: Icons.account_balance_outlined,
          );
        }
        if (manualType == 'manual_ewallet') {
          return _ReportPaymentFilterOption(
            key: 'manual:$manualId',
            label: 'E-Wallet ${option.label}',
            subtitle: option.providerAccountName,
            groupOrder: 2,
            icon: Icons.account_balance_wallet_outlined,
          );
        }
        if (manualType == 'manual_qris') {
          return _ReportPaymentFilterOption(
            key: 'manual:$manualId',
            label: 'QR ${option.label}',
            subtitle: option.providerAccountName,
            groupOrder: 3,
            icon: Icons.qr_code_2_rounded,
          );
        }

        return _ReportPaymentFilterOption(
          key: 'manual:$manualId',
          label: option.label,
          subtitle: option.providerAccountName,
          groupOrder: 4,
          icon: Icons.payments_outlined,
        );
    }
  }
}
