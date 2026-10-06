import 'package:flutter/material.dart';

import 'owner_home_page.dart';
import '../widgets/dock_inset.dart';

enum _LedgerFilter { all, manual, orderCash }

class OwnerCashBookDetailPage extends StatefulWidget {
  const OwnerCashBookDetailPage({super.key, required this.shiftId});

  final int shiftId;

  @override
  State<OwnerCashBookDetailPage> createState() =>
      _OwnerCashBookDetailPageState();
}

class _OwnerCashBookDetailPageState extends State<OwnerCashBookDetailPage> {
  static const _brand = Color(0xFFAE1504);
  static const _bg = Color(0xFFF6F7F9);

  Map<String, dynamic>? _shift;
  bool _loading = true;
  String? _error;
  _LedgerFilter _filter = _LedgerFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final shift =
          await ownerApiOf(context).cashierShiftDetail(widget.shiftId);
      if (!mounted) return;
      setState(() {
        _shift = shift;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Detail buku kasir gagal dimuat.';
        _loading = false;
      });
    }
  }

  String _money(dynamic value) {
    final n = (num.tryParse('$value') ?? 0).round();
    final raw = n.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (i > 0 && (raw.length - i) % 3 == 0) buffer.write('.');
      buffer.write(raw[i]);
    }
    return n < 0 ? '-$buffer' : '$buffer';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'open':
        return 'Terbuka';
      case 'pending_approval':
        return 'Menunggu persetujuan';
      case 'recount':
        return 'Hitung ulang';
      case 'closed':
        return 'Tertutup';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'open':
        return const Color(0xFF1D4ED8);
      case 'pending_approval':
        return const Color(0xFFB45309);
      case 'recount':
        return const Color(0xFFAE1504);
      case 'closed':
        return const Color(0xFF047857);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _formatTime(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '-';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    return '$d/$mo $h:$m';
  }

  List<Map<String, dynamic>> get _ledgerRows {
    final raw = _shift?['ledger'];
    if (raw is! List) return const [];
    final rows = raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    switch (_filter) {
      case _LedgerFilter.all:
        return rows;
      case _LedgerFilter.manual:
        return rows
            .where((e) =>
                e['type'] == 'cash_in' ||
                e['type'] == 'cash_out' ||
                e['type'] == 'opening')
            .toList();
      case _LedgerFilter.orderCash:
        return rows.where((e) => e['type'] == 'order_cash').toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final shift = _shift;
    final status = shift?['status']?.toString() ?? '';
    final statusColor = _statusColor(status);
    final employee = shift?['employee_name']?.toString() ?? '-';
    final store = shift?['store_name']?.toString() ?? '';
    final showCloseFields = status == 'closed' ||
        status == 'pending_approval' ||
        shift?['counted_cash'] != null;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          'Detail buku kasir',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: _brand,
        foregroundColor: Colors.white,
      ),
      body: _loading && shift == null
          ? const Center(child: CircularProgressIndicator(color: _brand))
          : RefreshIndicator(
              color: _brand,
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28)
                    .withBottomInset(context),
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: _brand),
                      ),
                    ),
                  if (shift != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      employee,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 17,
                                      ),
                                    ),
                                    if (store.isNotEmpty)
                                      Text(
                                        store,
                                        style: const TextStyle(
                                          color: Color(0xFF6B7280),
                                          fontSize: 13,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  _statusLabel(status),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Buka ${_formatTime(shift['opened_at']?.toString())}'
                            '${shift['closed_at'] != null ? ' · Tutup ${_formatTime(shift['closed_at']?.toString())}' : ''}',
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _SummaryChip(
                          label: 'Modal',
                          value: 'Rp ${_money(shift['opening_cash'])}',
                        ),
                        _SummaryChip(
                          label: 'Kas masuk',
                          value: 'Rp ${_money(shift['cash_in'])}',
                        ),
                        _SummaryChip(
                          label: 'Kas keluar',
                          value: 'Rp ${_money(shift['cash_out'])}',
                        ),
                        _SummaryChip(
                          label: 'Tunai order',
                          value: 'Rp ${_money(shift['cash_net'])}',
                        ),
                        _SummaryChip(
                          label: 'Non-tunai',
                          value: 'Rp ${_money(shift['non_cash_total'])}',
                        ),
                        if (showCloseFields) ...[
                          _SummaryChip(
                            label: 'Seharusnya',
                            value: 'Rp ${_money(shift['expected_cash'])}',
                          ),
                          _SummaryChip(
                            label: 'Dihitung',
                            value: 'Rp ${_money(shift['counted_cash'])}',
                          ),
                          _SummaryChip(
                            label: 'Selisih',
                            value: 'Rp ${_money(shift['variance'])}',
                            emphasize: true,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Mutasi laci',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _FilterChip(
                          label: 'Semua',
                          selected: _filter == _LedgerFilter.all,
                          onTap: () =>
                              setState(() => _filter = _LedgerFilter.all),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Manual',
                          selected: _filter == _LedgerFilter.manual,
                          onTap: () =>
                              setState(() => _filter = _LedgerFilter.manual),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Order cash',
                          selected: _filter == _LedgerFilter.orderCash,
                          onTap: () =>
                              setState(() => _filter = _LedgerFilter.orderCash),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_ledgerRows.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: const Text(
                          'Belum ada mutasi untuk filter ini.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF6B7280)),
                        ),
                      )
                    else
                      for (final row in _ledgerRows) ...[
                        _LedgerTile(
                          row: row,
                          money: _money,
                          timeLabel: _formatTime(row['created_at']?.toString()),
                        ),
                        const SizedBox(height: 8),
                      ],
                  ],
                ],
              ),
            ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: emphasize
            ? const Color(0xFFAE1504).withValues(alpha: 0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: emphasize
              ? const Color(0xFFAE1504).withValues(alpha: 0.25)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: emphasize
                  ? const Color(0xFFAE1504)
                  : const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? brand : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? brand : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
            color: selected ? Colors.white : const Color(0xFF374151),
          ),
        ),
      ),
    );
  }
}

class _LedgerTile extends StatelessWidget {
  const _LedgerTile({
    required this.row,
    required this.money,
    required this.timeLabel,
  });

  final Map<String, dynamic> row;
  final String Function(dynamic) money;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    final type = row['type']?.toString() ?? '';
    final title = row['title']?.toString() ?? '-';
    final subtitle = row['subtitle']?.toString();
    final signed = num.tryParse('${row['signed_amount']}') ?? 0;
    final isOut = type == 'cash_out' || signed < 0;
    final isOpening = type == 'opening';
    final amountColor = isOpening
        ? const Color(0xFF374151)
        : isOut
            ? const Color(0xFFAE1504)
            : const Color(0xFF047857);
    final icon = switch (type) {
      'opening' => Icons.account_balance_wallet_outlined,
      'cash_in' => Icons.south_west_rounded,
      'cash_out' => Icons.north_east_rounded,
      'order_cash' => Icons.receipt_long_outlined,
      _ => Icons.circle_outlined,
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: amountColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: amountColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
                if (subtitle != null && subtitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  timeLabel,
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isOut && !isOpening ? '-' : ''}Rp ${money(signed.abs())}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: amountColor,
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    );
  }
}
