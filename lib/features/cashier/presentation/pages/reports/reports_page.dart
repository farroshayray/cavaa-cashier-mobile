import 'package:flutter/material.dart';

enum _ReportPeriodType {
  today,
  last7Days,
  thisMonth,
  last30Days,
  custom,
}

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  _ReportPeriodType _selectedPeriod = _ReportPeriodType.today;
  DateTimeRange? _customRange;
  DateTimeRange _activeRange = _singleDayRange(DateTime.now());

  static DateTimeRange _singleDayRange(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return DateTimeRange(start: normalized, end: normalized);
  }

  @override
  void initState() {
    super.initState();
    _activeRange = _resolveRange(_selectedPeriod, DateTime.now());
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

  String get _activeRangeLabel {
    return '${_formatDate(_activeRange.start)} - ${_formatDate(_activeRange.end)}';
  }

  Future<void> _openPeriodFilterModal() async {
    final selected = await showModalBottomSheet<_ReportPeriodType>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _PeriodFilterSheet(selectedPeriod: _selectedPeriod);
      },
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
  }

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text('Laporan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _ReportsHeroCard(),
          const SizedBox(height: 16),
          _DateFilterSection(
            selectedLabel: _periodTitle(_selectedPeriod),
            rangeLabel: _activeRangeLabel,
            onTap: _openPeriodFilterModal,
          ),
          const SizedBox(height: 16),
          const _SummarySection(),
          const SizedBox(height: 16),
          const _QuickReportSection(),
          const SizedBox(height: 16),
          const _RecentActivitySection(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: brand,
        foregroundColor: Colors.white,
        onPressed: null,
        icon: const Icon(Icons.file_download_outlined),
        label: const Text('Export'),
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
                    child: const Icon(
                      Icons.date_range_outlined,
                      color: brand,
                    ),
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

class _PeriodFilterSheet extends StatelessWidget {
  const _PeriodFilterSheet({
    required this.selectedPeriod,
  });

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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pilih rentang laporan yang ingin ditampilkan.',
                style: TextStyle(
                  color: Colors.black.withOpacity(0.65),
                ),
              ),
              const SizedBox(height: 16),
              ..._ReportPeriodType.values.map(
                (period) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _PeriodOptionTile(
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

class _PeriodOptionTile extends StatelessWidget {
  const _PeriodOptionTile({
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
            color: selected ? brand.withOpacity(0.40) : Colors.black.withOpacity(0.08),
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
            'Halaman ini disiapkan untuk ringkasan omzet, transaksi, dan performa penjualan.',
            style: TextStyle(
              color: Colors.white,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _SectionTitle(
          title: 'Ringkasan Hari Ini',
          subtitle: 'Placeholder untuk KPI utama laporan.',
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                icon: Icons.payments_outlined,
                label: 'Omzet',
                value: 'Rp 0',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                icon: Icons.receipt_long_outlined,
                label: 'Transaksi',
                value: '0 Order',
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                icon: Icons.trending_up_outlined,
                label: 'Rata-rata',
                value: 'Rp 0',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                icon: Icons.point_of_sale_outlined,
                label: 'Tunai/Non Tunai',
                value: '- / -',
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
          subtitle: 'Pilihan laporan yang nanti bisa dibuka cepat.',
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
          subtitle: 'Ringkasan item dan jumlah penjualan.',
        ),
      ],
    );
  }
}

class _RecentActivitySection extends StatelessWidget {
  const _RecentActivitySection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _SectionTitle(
          title: 'Status Integrasi',
          subtitle: 'Ruang untuk info sinkronisasi dan export laporan.',
        ),
        SizedBox(height: 12),
        _EmptyStateCard(),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.black.withOpacity(0.65),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

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
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
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
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
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
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard();

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);

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
          const Text(
            'Data laporan akan tampil di sini',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Kerangka halaman sudah siap untuk diisi API, filter tanggal, dan export file.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black.withOpacity(0.65),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
