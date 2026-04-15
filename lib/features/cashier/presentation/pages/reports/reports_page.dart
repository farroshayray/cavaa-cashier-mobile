import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '/core/network/dio_client.dart';
import '/features/cashier/data/report_api.dart';

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
      );

      final dir = await getApplicationDocumentsDirectory();
      final folder = Directory('${dir.path}/report_exports');
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }

      final fileName =
          'laporan_${_formatApiDate(_activeRange.start)}_${_formatApiDate(_activeRange.end)}_${_cashierScopeValue(_cashierScope)}.csv';
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
              onTap: _openPeriodFilterModal,
            ),
            const SizedBox(height: 16),
            _SummarySection(
              title: 'Ringkasan ${_periodTitle(_selectedPeriod)}',
              subtitle: _isLoading
                  ? 'Mengambil data laporan dari server.'
                  : 'Filter aktif: ${_cashierScopeLabel(_cashierScope)}.',
              omzet: _formatCurrency(_summary?.omzet ?? 0),
              totalTransactions: '${_summary?.totalTransactions ?? 0} Order',
              averageTransaction:
                  _formatCurrency(_summary?.averageTransaction ?? 0),
              cashVsNonCash:
                  '${_formatCurrency(_summary?.cashAmount ?? 0)} / ${_formatCurrency(_summary?.nonCashAmount ?? 0)}',
              isLoading: _isLoading,
            ),
            const SizedBox(height: 16),
            const _QuickReportSection(),
            const SizedBox(height: 16),
            _RecentActivitySection(
              isLoading: _isLoading,
              isExporting: _isExporting,
              errorMessage: _errorMessage,
              hasData: _summary != null,
              activeFilterLabel: _cashierScopeLabel(_cashierScope),
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
    required this.onTap,
  });

  final String selectedLabel;
  final String rangeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);

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
            title: 'Filter Tanggal',
            subtitle: 'Pilih preset periode atau tentukan rentang transaksi.',
          ),
          const SizedBox(height: 14),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: brand.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: brand.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.date_range_outlined, color: brand),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedLabel,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rangeLabel,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black.withOpacity(0.62),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded),
                ],
              ),
            ),
          ),
        ],
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
        Row(
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
        const SizedBox(height: 12),
        Row(
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
              child: _SummaryCard(
                icon: Icons.point_of_sale_outlined,
                label: 'Tunai/Non Tunai',
                value: cashVsNonCash,
                isLoading: isLoading,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickReportSection extends StatelessWidget {
  const _QuickReportSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _SectionTitle(
          title: 'Jenis Laporan',
          subtitle: 'Ruang ini tetap siap untuk laporan turunan berikutnya.',
        ),
        SizedBox(height: 12),
        _MenuCard(
          icon: Icons.today_outlined,
          title: 'Laporan Harian',
          subtitle: 'Rekap transaksi dan omzet per hari.',
        ),
        SizedBox(height: 10),
        _MenuCard(
          icon: Icons.date_range_outlined,
          title: 'Laporan Periode',
          subtitle: 'Filter laporan berdasarkan tanggal tertentu.',
        ),
        SizedBox(height: 10),
        _MenuCard(
          icon: Icons.inventory_2_outlined,
          title: 'Produk Terjual',
          subtitle: 'Slot untuk laporan penjualan produk berikutnya.',
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
      padding: const EdgeInsets.all(14),
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
              fontSize: 12,
              color: Colors.black.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isLoading ? 'Memuat...' : value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);

    return Container(
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
          const Icon(Icons.chevron_right_rounded),
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
