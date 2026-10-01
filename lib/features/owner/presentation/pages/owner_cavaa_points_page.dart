import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/features/owner/presentation/pages/owner_addons_page.dart';
import '/features/owner/presentation/pages/owner_home_page.dart';
import '../widgets/dock_inset.dart';

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
    } catch (_) {
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

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kode referral disalin')),
    );
  }

  Future<void> _openPaket() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OwnerAddonsPage()),
    );
    if (mounted) await _load();
  }

  List<_EarnHowToItem> _parseEarnHowTo(Map<String, dynamic>? data) {
    if (data == null) return const [];
    final raw = data['earn_howto'] ?? data['howto'] ?? data['earn_rules'];
    if (raw is! List) return const [];
    final items = <_EarnHowToItem>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final map = Map<String, dynamic>.from(entry);
      final title = (map['title'] ?? '').toString().trim();
      final detail = (map['detail'] ?? map['description'] ?? '')
          .toString()
          .trim();
      if (title.isEmpty || detail.isEmpty) continue;
      items.add(
        _EarnHowToItem(
          title: title,
          detail: detail,
          iconKey: (map['icon'] ?? '').toString().trim().toLowerCase(),
        ),
      );
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final enabled = data?['enabled'] != false;
    final transactions = (data?['transactions'] as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        [];
    final code = (data?['referral_code'] ?? '').toString();
    final referred = (data?['referred_code'] ?? '').toString();
    final earnHowTo = _parseEarnHowTo(data);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text(
          'Cavaa Points',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: _brand,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _brand))
          : _error != null
              ? Center(child: Text(_error!))
              : !enabled
                  ? const Center(
                      child: Text('Cavaa Points sedang tidak tersedia.'),
                    )
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
                          _BalanceCard(
                            balance: _moneyLabel(_money(data?['balance'])),
                            code: code,
                            referred: referred,
                            onCopy: code.isEmpty ? null : () => _copyCode(code),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: _brand,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _openPaket,
                              icon: const Icon(Icons.workspace_premium_rounded),
                              label: const Text(
                                'Pakai poin di Paket',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Beli atau perpanjang paket & add-on di menu Paket, lalu pilih bayar dengan Cavaa Points.',
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.35,
                              color: Colors.black.withValues(alpha: 0.5),
                            ),
                          ),
                          if (earnHowTo.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            const _SectionLabel('Cara dapat poin'),
                            const SizedBox(height: 10),
                            _HowToEarnCard(items: earnHowTo),
                          ],
                          const SizedBox(height: 18),
                          const _SectionLabel('Riwayat'),
                          const SizedBox(height: 10),
                          _HistoryCard(
                            rows: transactions,
                            moneyLabel: (value) => _moneyLabel(_money(value)),
                            when: _when,
                          ),
                        ],
                      ),
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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFAE1504), Color(0xFF7A0E03)],
        ),
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

class _EarnHowToItem {
  const _EarnHowToItem({
    required this.title,
    required this.detail,
    required this.iconKey,
  });

  final String title;
  final String detail;
  final String iconKey;

  IconData get icon {
    switch (iconKey) {
      case 'share':
        return Icons.share_rounded;
      case 'gift':
        return Icons.card_giftcard_rounded;
      case 'premium':
      case 'paket':
        return Icons.workspace_premium_rounded;
      default:
        return Icons.stars_rounded;
    }
  }
}

class _HowToEarnCard extends StatelessWidget {
  const _HowToEarnCard({required this.items});

  final List<_EarnHowToItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          for (final item in items)
            _HowToRow(
              icon: item.icon,
              title: item.title,
              detail: item.detail,
            ),
        ],
      ),
    );
  }
}

class _HowToRow extends StatelessWidget {
  const _HowToRow({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFAE1504).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFFAE1504), size: 20),
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
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ),
              ],
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
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFAE1504).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: Color(0xFFAE1504),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Belum ada transaksi',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              'Riwayat masuk & pemakaian poin akan muncul di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.black.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
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
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          when(rows[i]['created_at']),
                          style: const TextStyle(
                            color: Color(0xFF8A9099),
                            fontSize: 12,
                          ),
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
