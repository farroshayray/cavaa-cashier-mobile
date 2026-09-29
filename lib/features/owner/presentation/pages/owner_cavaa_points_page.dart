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

  List<_DurationChoice> _choices(Map<String, dynamic> product, int balance) {
    final isOnce = (product['billing_type'] ?? '') == 'one_time';
    if (isOnce) {
      final amount = _money(product['price_once']);
      return [
        _DurationChoice(
          title: 'Beli sekali',
          detail: amount > balance ? 'Saldo tidak cukup' : 'Berlaku tanpa perpanjangan hari',
          amount: amount,
          enabled: amount > 0 && amount <= balance,
        ),
      ];
    }

    final options = <_DurationChoice>[];
    void addPeriod(String period, String title, int amount) {
      if (amount < 1) return;
      options.add(
        _DurationChoice(
          title: title,
          detail: amount > balance ? 'Saldo tidak cukup' : 'Harga paket tetap',
          amount: amount,
          period: period,
          enabled: amount <= balance,
        ),
      );
    }

    addPeriod('3d', '3 hari', _money(product['price_3d']));
    addPeriod('7d', '7 hari', _money(product['price_7d']));
    addPeriod('1m', '1 bulan', _money(product['price_1m']));

    final daily = _money(product['daily']);
    final maxDays = _money(product['max_custom_days']);
    final customReady = daily > 0 && maxDays > 0;
    options.add(
      _DurationChoice(
        title: 'Eceran',
        detail: customReady
            ? '${_moneyLabel(daily)} poin / hari, sampai $maxDays hari'
            : 'Harga 3 hari belum diatur',
        amount: daily,
        custom: true,
        enabled: customReady,
      ),
    );
    return options;
  }

  bool _shortBalance(Map<String, dynamic> product, int balance) {
    if ((product['billing_type'] ?? '') != 'one_time') return false;
    final amount = _money(product['price_once']);
    return amount > balance;
  }

  String _summary(Map<String, dynamic> product) {
    if ((product['billing_type'] ?? '') == 'one_time') {
      return 'Beli sekali · ${_moneyLabel(_money(product['price_once']))} poin';
    }
    final parts = <String>[];
    if (_money(product['price_3d']) > 0) {
      parts.add('3 hari ${_moneyLabel(_money(product['price_3d']))}');
    }
    if (_money(product['price_7d']) > 0) {
      parts.add('7 hari ${_moneyLabel(_money(product['price_7d']))}');
    }
    if (_money(product['price_1m']) > 0) {
      parts.add('1 bulan ${_moneyLabel(_money(product['price_1m']))}');
    }
    if (_money(product['daily']) > 0) {
      parts.add('Eceran ${_moneyLabel(_money(product['daily']))}/hari');
    }
    if (parts.isEmpty) return 'Harga belum diatur';
    return parts.join(' · ');
  }

  Future<void> _openBuy(Map<String, dynamic> product, int balance) async {
    if (_busy) return;
    final choices = _choices(product, balance);
    if ((product['billing_type'] ?? '') == 'one_time') {
      if (choices.isEmpty) return;
      await _pick(product, choices.first);
      return;
    }

    final picked = await showModalBottomSheet<_DurationChoice>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (product['name'] ?? '').toString(),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Pilih masa aktif',
                    style: TextStyle(color: Color(0xFF8A9099)),
                  ),
                ],
              ),
            ),
            for (final choice in choices)
              _ChoiceRow(
                choice: choice,
                busy: false,
                moneyLabel: _moneyLabel,
                onTap: () => Navigator.pop(ctx, choice),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    await _pick(product, picked);
  }

  Future<void> _pick(Map<String, dynamic> product, _DurationChoice choice) async {
    if (_busy || !choice.enabled) return;
    final kind = (product['kind'] ?? '').toString();
    final id = _money(product['id']);
    if (choice.custom) {
      await _buyCustom(product);
      return;
    }
    await _purchase(
      kind: kind,
      id: id,
      mode: 'period',
      period: choice.period,
      label: choice.title,
      amount: choice.amount,
    );
  }

  Future<void> _buyCustom(Map<String, dynamic> product) async {
    final maxDays = _money(product['max_custom_days']);
    final daily = _money(product['daily']);
    if (maxDays < 1 || daily < 1) {
      _toast('Harga eceran belum bisa dipakai.');
      return;
    }
    final picked = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => _CustomDaysSheet(
        productName: (product['name'] ?? '').toString(),
        daily: daily,
        maxDays: maxDays,
        balance: _money(_data?['balance']),
        moneyLabel: _moneyLabel,
      ),
    );
    if (picked == null || !mounted) return;
    await _purchase(
      kind: (product['kind'] ?? '').toString(),
      id: _money(product['id']),
      mode: 'custom',
      days: picked,
      label: '$picked hari',
      amount: daily * picked,
      confirm: false,
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
    bool confirm = true,
  }) async {
    final balance = _money(_data?['balance']);
    if (amount > balance) {
      _toast('Saldo Cavaa Points tidak cukup.');
      return;
    }
    if (confirm) {
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
      if (ok != true || !mounted) return;
    }
    final api = ownerApiOf(context);
    final auth = context.read<AuthProvider>();
    setState(() => _busy = true);
    try {
      final res = await api.purchaseWithPoints(
        kind: kind,
        id: id,
        mode: mode,
        period: period,
        days: days,
      );
      final user = api.parseUser(res);
      if (user != null && mounted) {
        auth.applyOwner(user);
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

  List<Map<String, dynamic>> _ofKind(List<Map<String, dynamic>> products, String kind) {
    return products.where((product) => (product['kind'] ?? '') == kind).toList();
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
    final balance = _money(data?['balance']);
    final plans = _ofKind(products, 'plan');
    final addons = _ofKind(products, 'addon');

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
                        if (products.isEmpty)
                          const Text('Belum ada produk yang bisa dibeli dengan poin.')
                        else ...[
                          if (plans.isNotEmpty) ...[
                            const _SectionLabel('Paket langganan'),
                            const SizedBox(height: 10),
                            for (final product in plans)
                              _ProductCard(
                                name: (product['name'] ?? '').toString(),
                                summary: _summary(product),
                                busy: _busy,
                                shortBalance: _shortBalance(product, balance),
                                onBuy: () => _openBuy(product, balance),
                              ),
                          ],
                          if (addons.isNotEmpty) ...[
                            const _SectionLabel('Add-on'),
                            const SizedBox(height: 10),
                            for (final product in addons)
                              _ProductCard(
                                name: (product['name'] ?? '').toString(),
                                summary: _summary(product),
                                busy: _busy,
                                shortBalance: _shortBalance(product, balance),
                                onBuy: () => _openBuy(product, balance),
                              ),
                          ],
                        ],
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
    );
  }
}

class _DurationChoice {
  const _DurationChoice({
    required this.title,
    required this.detail,
    required this.amount,
    this.period,
    this.custom = false,
    this.enabled = true,
  });

  final String title;
  final String detail;
  final int amount;
  final String? period;
  final bool custom;
  final bool enabled;
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.name,
    required this.summary,
    required this.busy,
    required this.shortBalance,
    required this.onBuy,
  });

  final String name;
  final String summary;
  final bool busy;
  final bool shortBalance;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final canBuy = !busy && !shortBalance;
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
          const SizedBox(height: 6),
          Text(summary, style: const TextStyle(color: Color(0xFF5C6370), height: 1.35)),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFAE1504),
                disabledBackgroundColor: const Color(0xFFE5E7EB),
                disabledForegroundColor: const Color(0xFF8A9099),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: canBuy ? onBuy : null,
              child: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      shortBalance ? 'Saldo tidak cukup' : 'Beli',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.choice,
    required this.busy,
    required this.moneyLabel,
    required this.onTap,
  });

  final _DurationChoice choice;
  final bool busy;
  final String Function(int value) moneyLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = choice.enabled && !busy;
    final price = choice.custom
        ? (choice.amount > 0 ? '${moneyLabel(choice.amount)} / hari' : 'Belum ada')
        : '${moneyLabel(choice.amount)} poin';

    return InkWell(
      onTap: active ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? const Color(0xFFFFF1EF) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                choice.custom ? Icons.tune_rounded : Icons.calendar_today_rounded,
                size: 18,
                color: active ? const Color(0xFFAE1504) : const Color(0xFFB0B6BF),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    choice.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: active ? const Color(0xFF1F2430) : const Color(0xFFB0B6BF),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    choice.detail,
                    style: const TextStyle(color: Color(0xFF8A9099), fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              price,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: active ? const Color(0xFFAE1504) : const Color(0xFFB0B6BF),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: active ? const Color(0xFFAE1504) : const Color(0xFFD0D4DA),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomDaysSheet extends StatefulWidget {
  const _CustomDaysSheet({
    required this.productName,
    required this.daily,
    required this.maxDays,
    required this.balance,
    required this.moneyLabel,
  });

  final String productName;
  final int daily;
  final int maxDays;
  final int balance;
  final String Function(int value) moneyLabel;

  @override
  State<_CustomDaysSheet> createState() => _CustomDaysSheetState();
}

class _CustomDaysSheetState extends State<_CustomDaysSheet> {
  var _days = 1;

  int get _amount => widget.daily * _days;

  void _setDays(int value) {
    setState(() => _days = value.clamp(1, widget.maxDays));
  }

  @override
  Widget build(BuildContext context) {
    final short = _amount > widget.balance;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.productName,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tentukan sendiri berapa hari',
              style: TextStyle(color: Color(0xFF8A9099)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _StepButton(
                  icon: Icons.remove,
                  onPressed: _days > 1 ? () => _setDays(_days - 1) : null,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '$_days',
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800),
                      ),
                      const Text('hari', style: TextStyle(color: Color(0xFF8A9099))),
                    ],
                  ),
                ),
                _StepButton(
                  icon: Icons.add,
                  onPressed: _days < widget.maxDays ? () => _setDays(_days + 1) : null,
                ),
              ],
            ),
            Slider(
              min: 1,
              max: widget.maxDays.toDouble(),
              divisions: widget.maxDays > 1 ? widget.maxDays - 1 : null,
              value: _days.toDouble(),
              activeColor: const Color(0xFFAE1504),
              onChanged: (value) => _setDays(value.round()),
            ),
            Text(
              short
                  ? 'Butuh ${widget.moneyLabel(_amount)} poin. Saldo tidak cukup.'
                  : '${widget.moneyLabel(_amount)} poin · sisa ${widget.moneyLabel(widget.balance - _amount)} poin',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: short ? const Color(0xFFAE1504) : const Color(0xFF1F2430),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFAE1504),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: short ? null : () => Navigator.pop(context, _days),
                child: Text(
                  short ? 'Saldo tidak cukup' : 'Pakai ${widget.moneyLabel(_amount)} poin',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton.filledTonal(
        onPressed: onPressed,
        icon: Icon(icon),
        style: IconButton.styleFrom(foregroundColor: const Color(0xFFAE1504)),
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
