part of 'reports_page.dart';

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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
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
                    const Icon(Icons.keyboard_arrow_down_rounded, color: brand),
                  ],
                ),
              ),
            ),
          ),
          Container(width: 1, height: 32, color: const Color(0xFFE4E7EC)),
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
                  const Icon(Icons.tune_rounded, color: brand, size: 20),
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
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
                        onPressed: () =>
                            Navigator.of(context).pop(_selectedKeys),
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
                color: selected
                    ? brand.withOpacity(0.12)
                    : const Color(0xFFF6F7F8),
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
