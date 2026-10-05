import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/core/network/dio_client.dart';
import '/features/cashier/data/cashier_shift_api.dart';
import '/features/cashier/presentation/pages/opening_cash_dialog.dart';

class CashBookPage extends StatefulWidget {
  const CashBookPage({super.key});

  @override
  State<CashBookPage> createState() => _CashBookPageState();
}

class _CashBookPageState extends State<CashBookPage> {
  static const _brand = Color(0xFFAE1504);

  Map<String, dynamic>? _shift;
  bool _loading = true;
  String? _error;
  String _direction = 'in';
  final _amount = TextEditingController();
  final _note = TextEditingController();
  final _counted = TextEditingController();

  CashierShiftApi get _api => CashierShiftApi(context.read<DioClient>().dio);

  bool get _isTransparent =>
      (_shift?['visibility_mode']?.toString() ?? 'blind') == 'transparent';

  bool get _showAggregates {
    final status = _shift?['status']?.toString();
    return _isTransparent || status == 'closed';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    _counted.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final shift = await _api.current();
      await CashierShiftGate.remember(shift);
      if (!mounted) return;
      setState(() {
        _shift = shift;
        _loading = false;
      });
    } catch (e) {
      await CashierShiftGate.restore();
      if (!mounted) return;
      setState(() {
        _shift = CashierShiftGate.shift;
        _error =
            CashierShiftGate.shift == null ? 'Buku kasir gagal dimuat.' : null;
        _loading = false;
      });
    }
  }

  Future<void> _movement() async {
    final amount = num.tryParse(_amount.text.replaceAll('.', '')) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi nominal uang tunai terlebih dahulu.')),
      );
      return;
    }
    final current = _shift;
    if (current != null && current['local_only'] == true) {
      final movements = List<Map<String, dynamic>>.from(
        (current['movements'] as List?) ?? const [],
      );
      final note = _note.text.trim();
      final createdAt = DateTime.now().toIso8601String();
      movements.add({
        'direction': _direction,
        'amount': amount,
        'note': note,
        'created_at': createdAt,
      });
      current['movements'] = movements;
      if (_isTransparent) {
        final key = _direction == 'in' ? 'cash_in' : 'cash_out';
        current[key] = (num.tryParse('${current[key]}') ?? 0) + amount;
        final ledger = List<Map<String, dynamic>>.from(
          (current['ledger'] as List?) ?? const [],
        );
        final isIn = _direction == 'in';
        ledger.add({
          'type': isIn ? 'cash_in' : 'cash_out',
          'title': isIn ? 'Kas masuk' : 'Kas keluar',
          'subtitle': note.isEmpty ? null : note,
          'amount': amount,
          'signed_amount': isIn ? amount : -amount,
          'created_at': createdAt,
        });
        current['ledger'] = ledger;
      }
      await CashierShiftGate.remember(current);
      _amount.clear();
      _note.clear();
      if (!mounted) return;
      setState(() => _shift = current);
      return;
    }
    try {
      final shift = await _api.movement(
        direction: _direction,
        amount: amount,
        note: _note.text.trim(),
      );
      await CashierShiftGate.remember(shift);
      _amount.clear();
      _note.clear();
      if (!mounted) return;
      setState(() => _shift = shift);
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map ? data['message']?.toString() : null;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message ?? 'Kas gagal dicatat.')),
      );
    }
  }

  Future<void> _close() async {
    final counted = num.tryParse(_counted.text.replaceAll('.', '')) ?? -1;
    if (counted < 0 || _counted.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi uang fisik yang dihitung.')),
      );
      return;
    }
    final current = _shift;
    if (current != null && current['local_only'] == true) {
      current['counted_cash'] = counted;
      current['status'] = 'counted_offline';
      await CashierShiftGate.remember(current);
      if (!mounted) return;
      setState(() => _shift = current);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Hitungan disimpan di perangkat. Persetujuan menunggu koneksi.',
          ),
        ),
      );
      return;
    }
    try {
      final shift = await _api.close(countedCash: counted);
      await CashierShiftGate.remember(
        shift['status'] == 'closed' ? null : shift,
      );
      if (!mounted) return;
      setState(() => _shift = shift);
      final status = shift['status']?.toString();
      final transparent = (shift['visibility_mode']?.toString() ?? 'blind') ==
          'transparent';
      String text;
      if (status == 'closed') {
        text = transparent
            ? 'Buku tertutup. Selisih Rp ${_money(shift['variance'])}.'
            : 'Buku tertutup.';
      } else if (transparent) {
        text =
            'Hitungan terkirim. Selisih Rp ${_money(shift['variance'])} menunggu persetujuan.';
      } else {
        text = 'Hitungan terkirim dan menunggu persetujuan owner.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map ? data['message']?.toString() : null;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message ?? 'Tutup buku gagal.')),
      );
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
    return n < 0 ? '-$buffer' : buffer.toString();
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

  void _selectIfZero(TextEditingController controller) {
    if (controller.text.replaceAll('.', '') != '0') return;
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
  }

  List<Map<String, dynamic>> get _ledgerRows {
    final raw = _shift?['ledger'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final status = _shift?['status']?.toString();
    final canMove = status == 'open';
    final canCount = status == 'open' || status == 'recount';
    final moneyIn = _direction == 'in';
    final tolerance =
        int.tryParse('${_shift?['variance_tolerance'] ?? 0}') ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text('Buku kasir'),
        backgroundColor: _brand,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null) Text(_error!),
                if (_shift != null) _summaryCard(status),
                if (_isTransparent && _ledgerRows.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _sectionCard(
                    title: 'Riwayat kas',
                    subtitle: _shift?['local_only'] == true
                        ? 'Menunggu sinkron. Mutasi order tunai belum lengkap offline.'
                        : null,
                    child: Column(
                      children: [
                        for (final row in _ledgerRows) ...[
                          _CashierLedgerTile(
                            row: row,
                            money: _money,
                            timeLabel:
                                _formatTime(row['created_at']?.toString()),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                ],
                if (status == 'pending_approval')
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'Menunggu persetujuan owner atau manajer. Hitungan tidak bisa diubah.',
                    ),
                  ),
                if (canMove) ...[
                  const SizedBox(height: 16),
                  _sectionCard(
                    title: 'Catat uang tunai',
                    subtitle:
                        'Pilih uang yang masuk ke laci atau yang diambil dari laci. Nominal ini mengubah saldo laci.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _directionButton(
                                selected: moneyIn,
                                icon: Icons.south_west_rounded,
                                title: 'Kas masuk',
                                caption: 'Tambah ke laci',
                                onTap: () => setState(() => _direction = 'in'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _directionButton(
                                selected: !moneyIn,
                                icon: Icons.north_east_rounded,
                                title: 'Kas keluar',
                                caption: 'Ambil dari laci',
                                onTap: () => setState(() => _direction = 'out'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'NOMINAL',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _amount,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                          inputFormatters: const [RupiahAmountFormatter()],
                          onTap: () =>
                              Future.microtask(() => _selectIfZero(_amount)),
                          decoration: _moneyDecoration(
                            hint: '0',
                            helper: moneyIn
                                ? 'Uang tunai yang ditambahkan ke laci.'
                                : 'Uang tunai yang diambil dari laci.',
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _note,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            labelText: 'Catatan',
                            hintText: moneyIn
                                ? 'Contoh: setoran tambahan'
                                : 'Contoh: beli galon, bayar listrik',
                            helperText: 'Supaya nanti jelas uang ini untuk apa.',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                moneyIn ? const Color(0xFF1B7F4E) : _brand,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _movement,
                          icon: Icon(
                            moneyIn ? Icons.add_rounded : Icons.remove_rounded,
                          ),
                          label: Text(
                            moneyIn ? 'Catat kas masuk' : 'Catat kas keluar',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (canCount) ...[
                  const SizedBox(height: 16),
                  _sectionCard(
                    title: 'Tutup buku',
                    subtitle: _isTransparent
                        ? 'Hitung uang fisik di laci. Nominal seharusnya ditampilkan sebagai acuan.'
                        : 'Hitung uang fisik di laci, lalu isi angkanya di sini. Uang yang seharusnya tidak ditampilkan.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_isTransparent) ...[
                          _summaryRow('Seharusnya', _shift?['expected_cash']),
                          if (tolerance > 0)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                'Selisih hingga Rp ${_money(tolerance)} bisa ditutup otomatis.',
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12.5,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                        ],
                        const Text(
                          'UANG YANG DIHITUNG',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _counted,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                          inputFormatters: const [RupiahAmountFormatter()],
                          onTap: () =>
                              Future.microtask(() => _selectIfZero(_counted)),
                          decoration: _moneyDecoration(
                            hint: '0',
                            helper:
                                'Total uang kertas dan koin yang ada di laci.',
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _brand,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _close,
                          child: const Text(
                            'Kirim hitungan',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _summaryCard(String? status) {
    final shift = _shift!;
    final showCloseFields = status == 'closed' ||
        (_isTransparent &&
            (status == 'pending_approval' || shift['counted_cash'] != null));

    return _sectionCard(
      title: _statusLabel(status),
      subtitle: null,
      child: Column(
        children: [
          _summaryRow('Modal awal', shift['opening_cash']),
          if (_showAggregates) ...[
            _summaryRow('Kas masuk', shift['cash_in']),
            _summaryRow('Kas keluar', shift['cash_out']),
            _summaryRow('Tunai bersih', shift['cash_net']),
          ],
          _summaryRow('Non-tunai', shift['non_cash_total']),
          if (_isTransparent &&
              status != 'closed' &&
              !showCloseFields)
            _summaryRow('Seharusnya', shift['expected_cash']),
          if (showCloseFields) ...[
            _summaryRow('Seharusnya', shift['expected_cash']),
            _summaryRow('Dihitung', shift['counted_cash']),
            if (_isTransparent || status == 'closed')
              _summaryRow('Selisih', shift['variance']),
          ],
        ],
      ),
    );
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'open':
        return 'Buku terbuka';
      case 'pending_approval':
        return 'Menunggu persetujuan';
      case 'recount':
        return 'Hitung ulang';
      case 'closed':
        return 'Buku tertutup';
      case 'counted_offline':
        return 'Hitungan tersimpan di perangkat';
      default:
        return 'Buku kasir';
    }
  }

  Widget _summaryRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            'Rp ${_money(value)}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required String? subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.black54, height: 1.35),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _directionButton({
    required bool selected,
    required IconData icon,
    required String title,
    required String caption,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected
          ? _brand.withValues(alpha: 0.08)
          : const Color(0xFFF6F7F9),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? _brand : Colors.transparent,
              width: 1.4,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? _brand : Colors.black54),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: selected ? _brand : Colors.black87,
                ),
              ),
              Text(
                caption,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _moneyDecoration({
    required String hint,
    required String helper,
  }) {
    return InputDecoration(
      prefixText: 'Rp ',
      prefixStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.black54,
      ),
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w300,
        color: Colors.black.withValues(alpha: 0.28),
      ),
      helperText: helper,
      filled: true,
      fillColor: const Color(0xFFF6F7F9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _brand, width: 1.6),
      ),
    );
  }
}

class _CashierLedgerTile extends StatelessWidget {
  const _CashierLedgerTile({
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F9),
        borderRadius: BorderRadius.circular(14),
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
