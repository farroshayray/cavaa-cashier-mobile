import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '/core/network/dio_client.dart';
import '/features/cashier/data/models/purchase_models.dart';
import '/features/cashier/data/report_api.dart';
import '/features/cashier/presentation/providers/purchase_provider.dart';

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

    final availableKeys = _availablePaymentFilterOptions.map((e) => e.key).toSet();
    return _selectedPaymentFilters
        .where(availableKeys.contains)
        .toList()
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
    final initialRange = _customRange ?? _activeRange;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(now.year + 2),
      initialDateRange: initialRange,
      saveText: 'Tampilkan Laporan',
      cancelText: 'Kembali',
      helpText: 'Pilih Periode Transaksi',
      fieldStartHintText: 'Tanggal awal',
      fieldEndHintText: 'Tanggal akhir',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFFAE1504),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (!mounted || picked == null) return;

    setState(() {
      _customRange = picked;
      _selectedPeriod = _ReportPeriodType.custom;
      _activeRange = picked;
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
              averageTransaction:
                  _formatCurrency(_summary?.averageTransaction ?? 0),
              cashVsNonCash:
                  '${_formatCurrency(_summary?.cashAmount ?? 0)} / ${_formatCurrency(_summary?.nonCashAmount ?? 0)}',
              isLoading: _isLoading,
            ),
            const SizedBox(height: 16),
            _QuickReportSection(
              onTransactionTap: _openTransactionReportModal,
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

class _DateFilterSection extends StatelessWidget {
  const _DateFilterSection({
    required this.selectedLabel,
    required this.rangeLabel,
    required this.activeFilterCount,
    required this.onDateTap,
    required this.onFilterTap,
  });

  final String selectedLabel;
  final String rangeLabel;
  final int activeFilterCount;
  final VoidCallback onDateTap;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE4E7EC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(22),
              ),
              onTap: onDateTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      color: brand,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            selectedLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            rangeLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black.withOpacity(0.56),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: brand,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: 1,
            height: 32,
            color: const Color(0xFFE4E7EC),
          ),
          InkWell(
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(22),
            ),
            onTap: onFilterTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.tune_rounded,
                    color: brand,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Filter',
                    style: TextStyle(
                      color: brand,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (activeFilterCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: brand.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$activeFilterCount',
                        style: const TextStyle(
                          color: brand,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportFilterSheet extends StatefulWidget {
  const _ReportFilterSheet({
    required this.paymentOptions,
    required this.initialSelection,
  });

  final List<_ReportPaymentFilterOption> paymentOptions;
  final Set<String> initialSelection;

  @override
  State<_ReportFilterSheet> createState() => _ReportFilterSheetState();
}

class _ReportFilterSheetState extends State<_ReportFilterSheet> {
  late Set<String> _selectedKeys;

  @override
  void initState() {
    super.initState();
    _selectedKeys = {...widget.initialSelection};
  }

  bool get _isAllSelected => _selectedKeys.isEmpty;

  void _toggleKey(String key) {
    setState(() {
      if (_selectedKeys.contains(key)) {
        _selectedKeys.remove(key);
      } else {
        _selectedKeys.add(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
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
                const Text(
                  'Filter',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Atur filter laporan. Bagian ini siap ditambah filter lain nanti.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black.withOpacity(0.65),
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionTitle(
                          title: 'Metode Pembayaran',
                          subtitle:
                              'Pilih semua, satu, atau beberapa metode pembayaran.',
                        ),
                        const SizedBox(height: 12),
                        _MultiChoiceTile(
                          title: 'Semua metode pembayaran',
                          icon: Icons.layers_clear_outlined,
                          selected: _isAllSelected,
                          onTap: () => setState(() => _selectedKeys.clear()),
                        ),
                        const SizedBox(height: 12),
                        ...widget.paymentOptions.map(
                          (option) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _MultiChoiceTile(
                              title: option.label,
                              subtitle: option.subtitle,
                              icon: option.icon,
                              selected: _selectedKeys.contains(option.key),
                              onTap: () => _toggleKey(option.key),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _selectedKeys.clear()),
                        child: const Text('Reset'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(_selectedKeys),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFAE1504),
                        ),
                        child: const Text('Terapkan Filter'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CashierFilterSection extends StatelessWidget {
  const _CashierFilterSection({
    required this.selectedScope,
    required this.onChanged,
  });

  final _CashierScope selectedScope;
  final Future<void> Function(_CashierScope scope) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Laporan Kasir',
            subtitle: 'Default laporan menampilkan transaksi kasir yang login.',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ChoiceTile(
                  title: 'Kasir Saya',
                  selected: selectedScope == _CashierScope.self,
                  onTap: () => onChanged(_CashierScope.self),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ChoiceTile(
                  title: 'Semua Kasir',
                  selected: selectedScope == _CashierScope.all,
                  onTap: () => onChanged(_CashierScope.all),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PeriodFilterSheet extends StatelessWidget {
  const _PeriodFilterSheet({required this.selectedPeriod});

  final _ReportPeriodType selectedPeriod;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const Text(
                'Filter Periode',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Pilih rentang laporan yang ingin ditampilkan.',
                style: TextStyle(color: Colors.black.withOpacity(0.65)),
              ),
              const SizedBox(height: 16),
              ..._ReportPeriodType.values.map(
                (period) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ChoiceTile(
                    title: _title(period),
                    selected: selectedPeriod == period,
                    onTap: () => Navigator.of(context).pop(period),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _title(_ReportPeriodType type) {
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
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? brand.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? brand.withOpacity(0.40)
                : Colors.black.withOpacity(0.08),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? brand : Colors.black38,
            ),
          ],
        ),
      ),
    );
  }
}

class _MultiChoiceTile extends StatelessWidget {
  const _MultiChoiceTile({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        constraints: const BoxConstraints(minHeight: 60),
        decoration: BoxDecoration(
          color: selected ? brand.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? brand.withOpacity(0.40)
                : Colors.black.withOpacity(0.08),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: selected ? brand.withOpacity(0.12) : const Color(0xFFF6F7F8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: selected ? brand : Colors.black54),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.black.withOpacity(0.58),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? brand : Colors.black38,
            ),
          ],
        ),
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
  });

  final VoidCallback onTransactionTap;

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
          subtitle: 'Laporan lengkap semua transaksi yang terjadi dalam periode terpilih.',
          onTap: onTransactionTap,
        ),
        const SizedBox(height: 10),
        const _MenuCard(
          icon: Icons.inventory_2_outlined,
          title: 'Produk Terjual',
          subtitle: 'Ringkasan produk terlaris dan jumlah penjualan untuk periode terpilih.',
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
    final subtitle = errorMessage != null
        ? 'Ada kendala saat mengambil data laporan.'
        : hasData
            ? 'Filter aktif: $activeFilterLabel.'
            : 'Ruang untuk info sinkronisasi dan export laporan.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'Status Integrasi', subtitle: subtitle),
        const SizedBox(height: 12),
        _EmptyStateCard(
          isLoading: isLoading,
          isExporting: isExporting,
          errorMessage: errorMessage,
          hasData: hasData,
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
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            )
          else ...[
            _SummaryBreakdownRow(
              title: 'Tunai',
              value: cashLabel,
            ),
            const SizedBox(height: 6),
            _SummaryBreakdownRow(
              title: 'Non Tunai',
              value: nonCashLabel,
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryBreakdownRow extends StatelessWidget {
  const _SummaryBreakdownRow({
    required this.title,
    required this.value,
  });

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
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
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
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
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
  State<_TransactionReportSheet> createState() => _TransactionReportSheetState();
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

      final items = rawItems
          .whereType<Map>()
          .map((item) => _ReportTransactionItem.fromJson(
                Map<String, dynamic>.from(item),
              ))
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

    final buckets = grouped.entries
        .map(
          (entry) => _TransactionMonthBucket(
            monthKey: entry.key,
            monthLabel: _monthLabel(entry.value.first.orderDate),
            items: entry.value..sort((a, b) => b.orderDate.compareTo(a.orderDate)),
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
      builder: (context) => _TransactionDetailDialog(
        transactionId: item.id,
      ),
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
                  child: Center(
                    child: CircularProgressIndicator(
                      color: brand,
                    ),
                  ),
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
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
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
        final sectionItems = groups[key]!..sort((a, b) => b.orderDate.compareTo(a.orderDate));
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
              ...sectionItems.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _TransactionTile(
                    item: item,
                    timeLabel: formatTime(item.orderDate),
                    amountLabel: formatCurrency(item.totalAmount),
                    onTap: () => onTapItem(item),
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
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        paymentMeta.icon,
                        size: 14,
                        color: brand,
                      ),
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
      return const _TransactionPaymentMeta(Icons.account_balance_wallet_outlined);
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
  const _TransactionDetailDialog({
    required this.transactionId,
  });

  final int transactionId;

  @override
  State<_TransactionDetailDialog> createState() => _TransactionDetailDialogState();
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
    final parsed = DateTime.tryParse(raw);
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
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: SizedBox(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.82,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Detail Transaksi',
                      style: TextStyle(
                        fontSize: 16,
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
            ),
            Divider(height: 1, color: Colors.black.withOpacity(0.08)),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                ),
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

  @override
  Widget build(BuildContext context) {
    final order = detail['order'] is Map
        ? Map<String, dynamic>.from(detail['order'] as Map)
        : <String, dynamic>{};
    final payment = detail['payment'] is Map
        ? Map<String, dynamic>.from(detail['payment'] as Map)
        : <String, dynamic>{};
    final items = detail['items'] is List ? detail['items'] as List : const [];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailSectionCard(
            title: 'Booking Order',
            children: [
              _DetailRow(label: 'Kode', value: (order['booking_order_code'] ?? '-').toString()),
              _DetailRow(label: 'Customer', value: (order['customer_name'] ?? '-').toString()),
              _DetailRow(label: 'Meja', value: (order['table_name'] ?? '-').toString()),
              _DetailRow(label: 'Status', value: (order['order_status'] ?? '-').toString()),
              _DetailRow(
                label: 'Waktu Order',
                value: formatDateTime((order['created_at'] ?? '-').toString()),
              ),
              _DetailRow(
                label: 'Subtotal',
                value: formatCurrency(_ReportSummaryData._asNum(order['total_order_value'])),
              ),
              _DetailRow(
                label: 'PPN',
                value: '${_ReportSummaryData._asNum(order['ppn'])}%'
                    '${(order['is_ppn_active'] == true || order['is_ppn_active'] == 1 || order['is_ppn_active'] == '1') ? '' : ' (off)'}',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DetailSectionCard(
            title: 'Transaksi Pembayaran',
            children: [
              _DetailRow(label: 'Tipe', value: (payment['payment_label'] ?? '-').toString()),
              _DetailRow(label: 'Status', value: (payment['payment_status'] ?? '-').toString()),
              _DetailRow(label: 'Kasir', value: (payment['cashier_name'] ?? '-').toString()),
              _DetailRow(
                label: 'Waktu Bayar',
                value: formatDateTime((payment['paid_at'] ?? '-').toString()),
              ),
              _DetailRow(
                label: 'Sebelum PPN',
                value: formatCurrency(_ReportSummaryData._asNum(payment['amount_before_ppn'])),
              ),
              _DetailRow(
                label: 'Dibayar',
                value: formatCurrency(_ReportSummaryData._asNum(payment['paid_amount'])),
              ),
              _DetailRow(
                label: 'Kembalian',
                value: formatCurrency(_ReportSummaryData._asNum(payment['change_amount'])),
              ),
              if ((payment['provider_name'] ?? '').toString().trim().isNotEmpty)
                _DetailRow(label: 'Provider', value: payment['provider_name'].toString()),
              if ((payment['account_name'] ?? '').toString().trim().isNotEmpty)
                _DetailRow(label: 'Atas Nama', value: payment['account_name'].toString()),
              if ((payment['account_no'] ?? '').toString().trim().isNotEmpty)
                _DetailRow(label: 'No. Akun', value: payment['account_no'].toString()),
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
                  final options = map['options'] is List ? map['options'] as List : const [];

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
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              formatCurrency(_ReportSummaryData._asNum(map['line_total'])),
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        if ((map['customer_note'] ?? '').toString().trim().isNotEmpty) ...[
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
  const _DetailSectionCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 98,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.black.withOpacity(0.58),
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
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
    required this.onRetry,
  });

  final bool isLoading;
  final bool isExporting;
  final String? errorMessage;
  final bool hasData;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);
    final hasError = errorMessage != null;

    final title = isLoading
        ? 'Memuat data laporan'
        : hasError
            ? 'Gagal mengambil data laporan'
            : hasData
                ? 'Integrasi laporan aktif'
                : 'Data laporan akan tampil di sini';

    final description = isLoading
        ? 'Mohon tunggu, kami sedang mengambil ringkasan omzet dan transaksi.'
        : hasError
            ? errorMessage!
            : hasData
                ? isExporting
                    ? 'File export sedang disiapkan. Mohon tunggu sebentar.'
                    : 'Laporan sudah tersambung ke backend, mendukung filter kasir, dan siap diexport ke CSV.'
                : 'Kerangka halaman sudah siap untuk diisi API, filter tanggal, dan export file.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: brand.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.insights_outlined,
              color: brand,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black.withOpacity(0.65),
              height: 1.4,
            ),
          ),
          if (hasError) ...[
            const SizedBox(height: 14),
            FilledButton(
              onPressed: isLoading ? null : () => onRetry(),
              style: FilledButton.styleFrom(backgroundColor: brand),
              child: const Text('Coba Lagi'),
            ),
          ],
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

  DateTime get dateOnly => DateTime(orderDate.year, orderDate.month, orderDate.day);

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
      orderDate: DateTime.tryParse((json['order_datetime'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
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
