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

class _CustomRangePickerSheet extends StatefulWidget {
  const _CustomRangePickerSheet({
    required this.initialRange,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTimeRange initialRange;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<_CustomRangePickerSheet> createState() => _CustomRangePickerSheetState();
}

class _CustomRangePickerSheetState extends State<_CustomRangePickerSheet> {
  late DateTime _selectedStart;
  late DateTime _selectedEnd;
  late final ScrollController _scrollController;
  late final Map<String, GlobalKey> _monthKeys;

  static const _weekdayLabels = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

  @override
  void initState() {
    super.initState();
    _selectedStart = _normalizeDate(widget.initialRange.start);
    _selectedEnd = _normalizeDate(widget.initialRange.end);
    _scrollController = ScrollController();
    _monthKeys = <String, GlobalKey>{};

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToSelectedMonth();
    });
  }

  DateTime get _maxAllowedEndDate {
    final twoMonthsAfterStart = _addMonthsClamped(_selectedStart, 2);
    return twoMonthsAfterStart.isAfter(widget.lastDate)
        ? _normalizeDate(widget.lastDate)
        : twoMonthsAfterStart;
  }

  void _selectDate(DateTime date) {
    final normalized = _normalizeDate(date);
    if (_isDisabled(normalized)) return;

    setState(() {
      if (_selectedStart == _selectedEnd) {
        if (normalized.isBefore(_selectedStart)) {
          _selectedStart = normalized;
          _selectedEnd = normalized;
        } else {
          _selectedEnd = normalized;
        }
        return;
      }

      if (normalized.isBefore(_selectedStart) || normalized.isAfter(_selectedEnd)) {
        _selectedStart = normalized;
        _selectedEnd = normalized;
      } else {
        _selectedStart = normalized;
        _selectedEnd = normalized;
      }
    });
  }

  bool _isDisabled(DateTime day) {
    if (day.isBefore(_normalizeDate(widget.firstDate))) return true;
    if (day.isAfter(_normalizeDate(widget.lastDate))) return true;

    if (_selectedStart == _selectedEnd) {
      final maxEndDate = _maxAllowedEndDate;
      return day.isAfter(maxEndDate) && !day.isAtSameMomentAs(_selectedStart);
    }

    return false;
  }

  bool _isSelectedStart(DateTime day) => _isSameDate(day, _selectedStart);
  bool _isSelectedEnd(DateTime day) => _isSameDate(day, _selectedEnd);

  bool _isInRange(DateTime day) {
    if (_selectedStart == _selectedEnd) return false;
    return day.isAfter(_selectedStart) && day.isBefore(_selectedEnd);
  }

  List<DateTime> get _visibleMonths {
    final months = <DateTime>[];
    var current = DateTime(widget.firstDate.year, widget.firstDate.month, 1);
    final lastMonth = DateTime(widget.lastDate.year, widget.lastDate.month, 1);

    while (!current.isAfter(lastMonth)) {
      months.add(current);
      current = _addMonths(current, 1);
    }

    return months;
  }

  Future<void> _scrollToSelectedMonth() async {
    final selectedMonth = DateTime(_selectedStart.year, _selectedStart.month, 1);
    final key = _monthKeys[_monthKey(selectedMonth)];
    final context = key?.currentContext;
    if (context == null) return;

    await Scrollable.ensureVisible(
      context,
      duration: Duration.zero,
      alignment: 0.5,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _monthKey(DateTime month) =>
      '${month.year}-${month.month.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
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
                  'Pilih Periode Transaksi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Rentang maksimal 2 bulan dan tidak bisa melewati hari ini.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _SelectedDateCard(
                        label: 'Tanggal awal',
                        value: _displayDateLabel(_selectedStart),
                        active: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SelectedDateCard(
                        label: 'Tanggal akhir',
                        value: _displayDateLabel(_selectedEnd),
                        active: _selectedStart != _selectedEnd,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      children: _visibleMonths
                          .map(
                            (month) => Padding(
                              key: _monthKeys.putIfAbsent(
                                _monthKey(month),
                                () => GlobalKey(),
                              ),
                              padding: const EdgeInsets.only(bottom: 18),
                              child: _MonthCalendar(
                                month: month,
                                weekdayLabels: _weekdayLabels,
                                isDisabled: _isDisabled,
                                isSelectedStart: _isSelectedStart,
                                isSelectedEnd: _isSelectedEnd,
                                isInRange: _isInRange,
                                onDateTap: _selectDate,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(context).pop(
                            DateTimeRange(
                              start: _selectedStart,
                              end: _selectedEnd,
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFAE1504),
                        ),
                        child: const Text('Terapkan'),
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

  static DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime _addMonths(DateTime date, int months) {
    final targetMonthIndex = date.month - 1 + months;
    final year = date.year + (targetMonthIndex ~/ 12);
    final month = (targetMonthIndex % 12) + 1;
    return DateTime(year, month, 1);
  }

  static DateTime _addMonthsClamped(DateTime date, int months) {
    final targetMonthIndex = date.month - 1 + months;
    final year = date.year + (targetMonthIndex ~/ 12);
    final month = (targetMonthIndex % 12) + 1;
    final lastDayOfTargetMonth = DateTime(year, month + 1, 0).day;
    final day = date.day > lastDayOfTargetMonth ? lastDayOfTargetMonth : date.day;
    return DateTime(year, month, day);
  }

  static bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _displayDateLabel(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.month,
    required this.weekdayLabels,
    required this.isDisabled,
    required this.isSelectedStart,
    required this.isSelectedEnd,
    required this.isInRange,
    required this.onDateTap,
  });

  final DateTime month;
  final List<String> weekdayLabels;
  final bool Function(DateTime day) isDisabled;
  final bool Function(DateTime day) isSelectedStart;
  final bool Function(DateTime day) isSelectedEnd;
  final bool Function(DateTime day) isInRange;
  final ValueChanged<DateTime> onDateTap;

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final leadingEmpty = firstDayOfMonth.weekday % 7;
    final cells = <Widget>[];

    for (final label in weekdayLabels) {
      cells.add(
        Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.black.withOpacity(0.45),
              ),
            ),
          ),
        ),
      );
    }

    for (var i = 0; i < leadingEmpty; i++) {
      cells.add(const SizedBox.shrink());
    }

    for (var day = 1; day <= daysInMonth; day++) {
      final currentDate = DateTime(month.year, month.month, day);
      final disabled = isDisabled(currentDate);
      final selectedStart = isSelectedStart(currentDate);
      final selectedEnd = isSelectedEnd(currentDate);
      final inRange = isInRange(currentDate);
      final selected = selectedStart || selectedEnd;

      cells.add(
        GestureDetector(
          onTap: disabled ? null : () => onDateTap(currentDate),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 3),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFFAE1504)
                  : inRange
                      ? const Color(0xFFFFE4DF)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              '$day',
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: disabled
                    ? Colors.black26
                    : selected
                        ? Colors.white
                        : const Color(0xFF111827),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _monthTitle(month),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1,
            children: cells,
          ),
        ],
      ),
    );
  }

  String _monthTitle(DateTime month) {
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

    return '${monthNames[month.month - 1]} ${month.year}';
  }
}

class _SelectedDateCard extends StatelessWidget {
  const _SelectedDateCard({
    required this.label,
    required this.value,
    required this.active,
  });

  final String label;
  final String value;
  final bool active;

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: active ? brand.withOpacity(0.08) : const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? brand.withOpacity(0.24) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
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
