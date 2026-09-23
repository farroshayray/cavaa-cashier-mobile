import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/features/auth/presentation/auth_provider.dart';
import 'owner_home_page.dart';

class OwnerCashBookPage extends StatefulWidget {
  const OwnerCashBookPage({super.key});

  @override
  State<OwnerCashBookPage> createState() => _OwnerCashBookPageState();
}

class _OwnerCashBookPageState extends State<OwnerCashBookPage> {
  static const _brand = Color(0xFFAE1504);

  Map<String, dynamic>? _summary;
  bool _loading = true;
  String? _error;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  String get _dateParam {
    final month = _date.month.toString().padLeft(2, '0');
    final day = _date.day.toString().padLeft(2, '0');
    return '${_date.year}-$month-$day';
  }

  String get _dateLabel {
    final month = _date.month.toString().padLeft(2, '0');
    final day = _date.day.toString().padLeft(2, '0');
    return '$day/$month/${_date.year}';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final summary = await ownerApiOf(context).cashierShiftSummary(date: _dateParam);
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Rekap buku kasir gagal dimuat.';
        _loading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked == null || !mounted) return;
    setState(() => _date = picked);
    await _load();
  }

  Future<void> _decide(int id, bool approve) async {
    final api = ownerApiOf(context);
    if (approve) {
      await api.approveCashierShift(id);
    } else {
      await api.rejectCashierShift(id);
    }
    await _load();
  }

  Future<void> _switchStore(int storeId) async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.selectStore(storeId);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Gagal memilih toko')),
      );
      return;
    }
    await _load();
  }

  String _money(dynamic value) {
    final n = (num.tryParse('$value') ?? 0).round();
    final raw = n.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (i > 0 && (raw.length - i) % 3 == 0) buffer.write('.');
      buffer.write(raw[i]);
    }
    return n < 0 ? '-$buffer' : buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final pending = (_summary?['pending'] as List?) ?? const [];
    final shifts = (_summary?['shifts'] as List?) ?? const [];
    final others = (_summary?['other_stores'] as List?) ?? const [];
    final storeName = _summary?['store_name']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buku kasir'),
        backgroundColor: _brand,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              color: _brand,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null) Text(_error!),
                  Text(
                    storeName.isEmpty ? 'Toko aktif' : storeName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ActionChip(
                      avatar: const Icon(Icons.calendar_today, size: 16),
                      label: Text(_dateLabel),
                      onPressed: _pickDate,
                    ),
                  ),
                  if (others.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _otherStoresNotice(others),
                  ],
                  const SizedBox(height: 16),
                  const Text(
                    'Menunggu persetujuan',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  if (pending.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text('Tidak ada selisih yang menunggu.'),
                    ),
                  for (final raw in pending)
                    if (raw is Map) _pendingCard(Map<String, dynamic>.from(raw)),
                  const SizedBox(height: 16),
                  Text(
                    'Rekap $_dateLabel',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  if (shifts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text('Belum ada buku pada tanggal ini.'),
                    ),
                  for (final raw in shifts)
                    if (raw is Map) _shiftCard(Map<String, dynamic>.from(raw)),
                  const SizedBox(height: 12),
                  Text(
                    'QR pelanggan: Rp ${_money(_summary?['customer_qr_total'])}',
                  ),
                ],
              ),
            ),
    );
  }

  Widget _otherStoresNotice(List<dynamic> others) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Toko lain juga menunggu persetujuan',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final raw in others)
                if (raw is Map)
                  ActionChip(
                    label: Text(
                      '${raw['name']} (${raw['pending_count']})',
                    ),
                    onPressed: () {
                      final id = int.tryParse('${raw['id']}') ?? 0;
                      if (id > 0) _switchStore(id);
                    },
                  ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pendingCard(Map<String, dynamic> row) {
    final id = int.tryParse('${row['id']}') ?? 0;
    final store = row['store_name']?.toString() ?? '';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (store.isNotEmpty)
              Text(
                store,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            Text(row['employee_name']?.toString() ?? '-'),
            const SizedBox(height: 6),
            Text('Seharusnya Rp ${_money(row['expected_cash'])}'),
            Text('Dihitung Rp ${_money(row['counted_cash'])}'),
            Text('Selisih Rp ${_money(row['variance'])}'),
            Row(
              children: [
                TextButton(
                  onPressed: () => _decide(id, true),
                  child: const Text('Setujui'),
                ),
                TextButton(
                  onPressed: () => _decide(id, false),
                  child: const Text('Hitung ulang'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _shiftCard(Map<String, dynamic> row) {
    final store = row['store_name']?.toString() ?? '';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(row['employee_name']?.toString() ?? '-'),
      subtitle: Text(
        [
          if (store.isNotEmpty) store,
          '${row['status']}',
          'modal ${_money(row['opening_cash'])}',
          'tunai ${_money(row['cash_net'])}',
          'non-tunai ${_money(row['non_cash_total'])}',
          'selisih ${_money(row['variance'])}',
        ].join(' · '),
      ),
    );
  }
}
