import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/features/auth/presentation/auth_provider.dart';
import 'owner_home_page.dart';
import 'owner_manual_checkout_page.dart';
import '../widgets/dock_inset.dart';

/// Manual payments the admin rejected: shows what was paid for and the
/// admin's note, and lets the owner send new proof or delete the payment.
class OwnerPaymentRevisionPage extends StatefulWidget {
  const OwnerPaymentRevisionPage({super.key});

  @override
  State<OwnerPaymentRevisionPage> createState() =>
      _OwnerPaymentRevisionPageState();
}

class _OwnerPaymentRevisionPageState extends State<OwnerPaymentRevisionPage> {
  static const _brand = Color(0xFFAE1504);

  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  final Set<String> _busy = {};

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
      final items = await ownerApiOf(context).billingRevisions();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _message(e, 'Gagal memuat pembayaran.');
      });
    }
  }

  String _key(Map<String, dynamic> item) => '${item['type']}-${item['id']}';

  int _int(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;

  Future<void> _resubmit(Map<String, dynamic> item) async {
    final message = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => OwnerManualCheckoutPage(
          type: (item['type'] ?? 'plan').toString(),
          itemId: _int(item['item_id']),
          itemName: (item['item_name'] ?? '-').toString(),
          amount: _int(item['amount']),
          period: item['period']?.toString(),
          periodLabel: item['period_label']?.toString(),
          revisionId: _int(item['id']),
          adminNote: item['admin_note']?.toString(),
        ),
      ),
    );
    if (message == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    await context.read<AuthProvider>().refreshOwner();
    if (mounted) await _load();
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final name = (item['item_name'] ?? 'pembayaran ini').toString();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus pembayaran?'),
        content: Text(
          'Pembayaran $name akan dihapus dan tidak bisa dikirim ulang. '
          'Untuk membeli lagi, lakukan pembelian baru.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: _brand),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final key = _key(item);
    setState(() => _busy.add(key));
    try {
      await ownerApiOf(context).deleteBillingRevision(
        type: (item['type'] ?? 'plan').toString(),
        id: _int(item['id']),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pembayaran dihapus.')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_message(e, 'Gagal menghapus pembayaran.'))),
      );
    } finally {
      if (mounted) setState(() => _busy.remove(key));
    }
  }

  String _message(Object error, String fallback) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final message = data['message']?.toString().trim() ?? '';
        if (message.isNotEmpty) return message;
      }
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: _brand,
        foregroundColor: Colors.white,
        title: const Text(
          'Revisi pembayaran',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _brand))
          : RefreshIndicator(
              color: _brand,
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28)
                    .withBottomInset(context),
                children: [
                  if (_error != null)
                    Text(_error!, style: const TextStyle(color: _brand))
                  else if (_items.isEmpty)
                    const _EmptyState()
                  else ...[
                    Text(
                      'Pembayaran berikut ditolak admin, sehingga paket/add-on '
                      'terkait dinonaktifkan. Kirim ulang bukti untuk '
                      'mengaktifkan kembali, atau hapus pembayarannya.',
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.6),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    for (final item in _items)
                      _RevisionCard(
                        item: item,
                        busy: _busy.contains(_key(item)),
                        onResubmit: () => _resubmit(item),
                        onDelete: () => _delete(item),
                      ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _RevisionCard extends StatelessWidget {
  const _RevisionCard({
    required this.item,
    required this.busy,
    required this.onResubmit,
    required this.onDelete,
  });

  static const _brand = Color(0xFFAE1504);

  final Map<String, dynamic> item;
  final bool busy;
  final VoidCallback onResubmit;
  final VoidCallback onDelete;

  String _idr(dynamic v) {
    final n = v is int ? v : int.tryParse('$v') ?? 0;
    return n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  String _date(dynamic iso) {
    final d = DateTime.tryParse('${iso ?? ''}')?.toLocal();
    if (d == null) return '—';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final note = item['admin_note']?.toString().trim() ?? '';
    final period = item['period_label']?.toString().trim() ?? '';
    final bank = item['bank']?.toString().trim() ?? '';
    final proof = item['proof_url']?.toString().trim() ?? '';
    final revisions = int.tryParse('${item['revision_count'] ?? 0}') ?? 0;

    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 116,
            child: Text(
              label,
              style: TextStyle(color: Colors.black.withValues(alpha: 0.55)),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (item['type_label'] ?? '').toString(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (item['item_name'] ?? '-').toString(),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (period.isNotEmpty)
                      Text(
                        period,
                        style: TextStyle(color: Colors.black.withValues(alpha: 0.55)),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Rp ${_idr(item['amount'])}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: _brand,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE4E2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Ditolak',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFB42318),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 12),
            BillingAdminNoteCard(note: note),
          ],
          const SizedBox(height: 12),
          row('Dibayar', _date(item['paid_at'])),
          row('Ditolak', _date(item['rejected_at'])),
          if (bank.isNotEmpty) row('Rekening tujuan', bank),
          if (revisions > 0) row('Dikirim ulang', '$revisions×'),
          if (proof.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Bukti sebelumnya',
              style: TextStyle(color: Colors.black.withValues(alpha: 0.55)),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  proof,
                  height: 110,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            height: 46,
            child: FilledButton.icon(
              onPressed: busy ? null : onResubmit,
              style: FilledButton.styleFrom(
                backgroundColor: _brand,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.upload_rounded),
              label: const Text(
                'Kirim ulang bukti',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: OutlinedButton.icon(
              onPressed: busy ? null : onDelete,
              style: OutlinedButton.styleFrom(
                foregroundColor: _brand,
                side: const BorderSide(color: Color(0x55AE1504)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _brand),
                    )
                  : const Icon(Icons.delete_outline_rounded),
              label: const Text(
                'Hapus pembayaran',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          Icon(
            Icons.verified_rounded,
            size: 48,
            color: Colors.black.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 10),
          Text(
            'Tidak ada pembayaran yang perlu direvisi.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.black.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}
