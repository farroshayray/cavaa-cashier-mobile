import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '/features/auth/presentation/auth_provider.dart';
import '/features/owner/presentation/pages/owner_home_page.dart';

class OwnerCavaaPointsPage extends StatefulWidget {
  const OwnerCavaaPointsPage({super.key});

  @override
  State<OwnerCavaaPointsPage> createState() => _OwnerCavaaPointsPageState();
}

class _OwnerCavaaPointsPageState extends State<OwnerCavaaPointsPage> {
  static const _brand = Color(0xFFAE1504);
  Map<String, dynamic>? _data;
  String? _error;
  var _loading = true;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ownerApiOf(context).cavaaPoints();
      if (!mounted) return;
      setState(() => _data = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Gagal memuat Cavaa Points.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _money(dynamic raw) {
    if (raw is int) return raw;
    return int.tryParse('$raw') ?? 0;
  }

  Future<void> _buy(Map<String, dynamic> product) async {
    final kind = (product['kind'] ?? '').toString();
    final id = _money(product['id']);
    final once = _money(product['price_once']);
    final isOnce = (product['billing_type'] ?? '') == 'one_time';
    if (isOnce) {
      await _purchase(kind: kind, id: id, mode: 'period', label: 'Beli sekali', amount: once);
      return;
    }

    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('Cara beli', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
            ListTile(
              title: const Text('Harga transfer'),
              subtitle: const Text('3 hari, 7 hari, atau 1 bulan'),
              onTap: () => Navigator.pop(ctx, 'period'),
            ),
            ListTile(
              title: const Text('Eceran hari'),
              subtitle: Text(
                _money(product['daily']) > 0
                    ? 'Rp ${_money(product['daily'])} per hari, maks ${_money(product['max_custom_days'])} hari'
                    : 'Harga 3 hari belum diatur',
              ),
              enabled: _money(product['daily']) > 0 && _money(product['max_custom_days']) > 0,
              onTap: () => Navigator.pop(ctx, 'custom'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'custom') {
      await _buyCustom(product);
      return;
    }

    final periods = <({String period, String title, int amount})>[
      if (_money(product['price_3d']) > 0) (period: '3d', title: '3 hari', amount: _money(product['price_3d'])),
      if (_money(product['price_7d']) > 0) (period: '7d', title: '7 hari', amount: _money(product['price_7d'])),
      if (_money(product['price_1m']) > 0) (period: '1m', title: '1 bulan', amount: _money(product['price_1m'])),
    ];
    if (periods.isEmpty) {
      _toast('Tidak ada harga periode untuk produk ini.');
      return;
    }
    final picked = periods.length == 1
        ? periods.first
        : await showDialog<({String period, String title, int amount})>(
            context: context,
            builder: (ctx) => SimpleDialog(
              title: const Text('Pilih masa'),
              children: [
                for (final item in periods)
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(ctx, item),
                    child: Text('${item.title} · ${_moneyLabel(item.amount)} poin'),
                  ),
              ],
            ),
          );
    if (picked == null) return;
    await _purchase(
      kind: kind,
      id: id,
      mode: 'period',
      period: picked.period,
      label: picked.title,
      amount: picked.amount,
    );
  }

  Future<void> _buyCustom(Map<String, dynamic> product) async {
    final maxDays = _money(product['max_custom_days']);
    final daily = _money(product['daily']);
    if (maxDays < 1 || daily < 1) {
      _toast('Saldo tidak cukup untuk 1 hari.');
      return;
    }
    var days = 1;
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Beli eceran'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$days hari · ${_moneyLabel(daily * days)} poin'),
              Slider(
                min: 1,
                max: maxDays.toDouble(),
                divisions: maxDays > 1 ? maxDays - 1 : null,
                value: days.toDouble(),
                activeColor: _brand,
                onChanged: (value) => setLocal(() => days = value.round()),
              ),
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Jumlah hari'),
                controller: TextEditingController(text: '$days'),
                onSubmitted: (value) {
                  final next = int.tryParse(value) ?? days;
                  setLocal(() => days = next.clamp(1, maxDays));
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, days),
              child: const Text('Lanjut'),
            ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    await _purchase(
      kind: (product['kind'] ?? '').toString(),
      id: _money(product['id']),
      mode: 'custom',
      days: picked,
      label: '$picked hari',
      amount: daily * picked,
    );
  }

  Future<void> _purchase({
    required String kind,
    required int id,
    required String mode,
    required String label,
    required int amount,
    String? period,
    int? days,
  }) async {
    final balance = _money(_data?['balance']);
    if (amount > balance) {
      _toast('Saldo Cavaa Points tidak cukup.');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pakai Cavaa Points?'),
        content: Text('$label membutuhkan ${_moneyLabel(amount)} poin.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Bayar')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      final res = await ownerApiOf(context).purchaseWithPoints(
        kind: kind,
        id: id,
        mode: mode,
        period: period,
        days: days,
      );
      final user = ownerApiOf(context).parseUser(res);
      if (user != null && mounted) {
        context.read<AuthProvider>().applyOwner(user);
      }
      _toast((res['message'] ?? 'Berhasil').toString());
      await _load();
    } on DioException catch (e) {
      final data = e.response?.data;
      _toast(data is Map ? (data['message'] ?? 'Pembelian gagal').toString() : 'Pembelian gagal');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _moneyLabel(int value) {
    final raw = value.toString();
    final buf = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (i > 0 && (raw.length - i) % 3 == 0) buf.write('.');
      buf.write(raw[i]);
    }
    return buf.toString();
  }

  String _when(dynamic raw) {
    final text = (raw ?? '').toString();
    if (text.length >= 16) {
      return text.substring(0, 16).replaceFirst('T', ' ');
    }
    return text;
  }

  List<String> _priceLines(Map<String, dynamic> product) {
    if ((product['billing_type'] ?? '') == 'one_time') {
      return ['Beli sekali · ${_moneyLabel(_money(product['price_once']))} poin'];
    }
    final lines = <String>[];
    final price3d = _money(product['price_3d']);
    final price7d = _money(product['price_7d']);
    final price1m = _money(product['price_1m']);
    final daily = _money(product['daily']);
    if (price3d > 0) lines.add('3 hari · ${_moneyLabel(price3d)} poin');
    if (price7d > 0) lines.add('7 hari · ${_moneyLabel(price7d)} poin');
    if (price1m > 0) lines.add('1 bulan · ${_moneyLabel(price1m)} poin');
    if (daily > 0) {
      lines.add('Eceran · ${_moneyLabel(daily)} poin / hari');
    }
    if (lines.isEmpty) lines.add('Harga belum diatur');
    return lines;
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kode referral disalin')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final enabled = data?['enabled'] != false;
    final products = (data?['products'] as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        [];
    final transactions = (data?['transactions'] as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        [];
    final code = (data?['referral_code'] ?? '').toString();
    final referred = (data?['referred_code'] ?? '').toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text('Cavaa Points', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: _brand,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _brand))
          : _error != null
              ? Center(child: Text(_error!))
              : !enabled
                  ? const Center(child: Text('Cavaa Points sedang tidak tersedia.'))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                      children: [
                        _BalanceCard(
                          balance: _moneyLabel(_money(data?['balance'])),
                          code: code,
                          referred: referred,
                          onCopy: code.isEmpty ? null : () => _copyCode(code),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Beli dengan poin',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        if (products.isEmpty)
                          const Text('Belum ada produk yang bisa dibeli dengan poin.'),
                        for (final product in products)
                          _ProductCard(
                            name: (product['name'] ?? '').toString(),
                            lines: _priceLines(product),
                            busy: _busy,
                            onBuy: () => _buy(product),
                          ),
                        const SizedBox(height: 8),
                        const Text(
                          'Riwayat',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        _HistoryCard(
                          rows: transactions,
                          moneyLabel: (value) => _moneyLabel(_money(value)),
                          when: _when,
                        ),
                      ],
                    ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.balance,
    required this.code,
    required this.referred,
    required this.onCopy,
  });

  final String balance;
  final String code;
  final String referred;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFAE1504),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Saldo Cavaa Points',
            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            '$balance poin',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kode referral',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        code.isEmpty ? '-' : code,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
          if (referred.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Kode yang dipakai: $referred',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.name,
    required this.lines,
    required this.busy,
    required this.onBuy,
  });

  final String name;
  final List<String> lines;
  final bool busy;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 8),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(line, style: const TextStyle(color: Color(0xFF5C6370))),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFAE1504),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: busy ? null : onBuy,
              child: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Beli', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.rows,
    required this.moneyLabel,
    required this.when,
  });

  final List<Map<String, dynamic>> rows;
  final String Function(dynamic value) moneyLabel;
  final String Function(dynamic raw) when;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Text('Belum ada transaksi.');
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (rows[i]['note'] ?? rows[i]['type'] ?? '').toString(),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          when(rows[i]['created_at']),
                          style: const TextStyle(color: Color(0xFF8A9099), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${rows[i]['direction'] == 'in' ? '+' : '-'}${moneyLabel(rows[i]['amount'])}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: rows[i]['direction'] == 'in'
                          ? const Color(0xFF1B7F3A)
                          : const Color(0xFFAE1504),
                    ),
                  ),
                ],
              ),
            ),
            if (i != rows.length - 1)
              const Divider(height: 1, indent: 14, endIndent: 14),
          ],
        ],
      ),
    );
  }
}
