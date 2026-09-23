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
        _error = CashierShiftGate.shift == null ? 'Buku kasir gagal dimuat.' : null;
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
      movements.add({
        'direction': _direction,
        'amount': amount,
        'note': _note.text.trim(),
      });
      current['movements'] = movements;
      final key = _direction == 'in' ? 'cash_in' : 'cash_out';
      current[key] = (num.tryParse('${current[key]}') ?? 0) + amount;
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
      final text = status == 'closed'
          ? 'Buku tertutup. Selisih Rp ${_money(shift['variance'])}.'
          : 'Hitungan terkirim dan menunggu persetujuan.';
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

  void _selectIfZero(TextEditingController controller) {
    if (controller.text.replaceAll('.', '') != '0') return;
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _shift?['status']?.toString();
    final canMove = status == 'open';
    final canCount = status == 'open' || status == 'recount';

    final moneyIn = _direction == 'in';

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
                          onTap: () => Future.microtask(() => _selectIfZero(_amount)),
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
                            backgroundColor: moneyIn ? const Color(0xFF1B7F4E) : _brand,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _movement,
                          icon: Icon(moneyIn ? Icons.add_rounded : Icons.remove_rounded),
                          label: Text(
                            moneyIn ? 'Catat kas masuk' : 'Catat kas keluar',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
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
                    subtitle:
                        'Hitung uang fisik di laci, lalu isi angkanya di sini. Uang yang seharusnya tidak ditampilkan.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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
                          onTap: () => Future.microtask(() => _selectIfZero(_counted)),
                          decoration: _moneyDecoration(
                            hint: '0',
                            helper: 'Total uang kertas dan koin yang ada di laci.',
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
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
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
    return _sectionCard(
      title: _statusLabel(status),
      subtitle: null,
      child: Column(
        children: [
          _summaryRow('Modal awal', shift['opening_cash']),
          _summaryRow('Kas masuk', shift['cash_in']),
          _summaryRow('Kas keluar', shift['cash_out']),
          _summaryRow('Tunai bersih', shift['cash_net']),
          _summaryRow('Non-tunai', shift['non_cash_total']),
          if (status == 'closed') ...[
            _summaryRow('Seharusnya', shift['expected_cash']),
            _summaryRow('Dihitung', shift['counted_cash']),
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
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.black54, height: 1.35)),
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
      color: selected ? _brand.withValues(alpha: 0.08) : const Color(0xFFF6F7F9),
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

  InputDecoration _moneyDecoration({required String hint, required String helper}) {
    return InputDecoration(
      prefixText: 'Rp ',
      prefixStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.black54,
      ),
      hintText: hint,
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
