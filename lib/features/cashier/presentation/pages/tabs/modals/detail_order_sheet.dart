import 'package:flutter/material.dart';

class DetailOrderSheet extends StatefulWidget {
  const DetailOrderSheet({
    super.key,
    required this.orderId,
    required this.loadDetail,
  });

  final int orderId;
  final Future<Map<String, dynamic>> Function(int id) loadDetail;

  @override
  State<DetailOrderSheet> createState() => _DetailOrderSheetState();
}

class _DetailOrderSheetState extends State<DetailOrderSheet> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _order;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
      _order = null;
    });

    try {
      final o = await widget.loadDetail(widget.orderId);
      _order = o;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Material(
            color: Colors.white,
            child: Column(
              children: [
                _Header(
                  title: 'Detail Order',
                  onClose: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? _ErrorView(message: _error!, onRetry: _fetch)
                          : _Body(order: _order!),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onClose});
  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.08))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Tutup',
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.order});
  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    final code = (order['booking_order_code'] ?? '-').toString();
    final name = (order['customer_name'] ?? '-').toString();
    final table = (order['table'] is Map ? (order['table']['table_no'] ?? '-') : '-').toString();
    final total = _num(order['total_order_value']);
    final status = (order['order_status'] ?? '-').toString();

    // mirip web: ambil payment.note (jika ada)
    final paymentNote = ((order['payment'] is Map) ? (order['payment']['note'] ?? '') : '').toString().trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InfoCard(
            code: code,
            name: name,
            table: table,
            status: status,
            total: total,
          ),
          const SizedBox(height: 12),

          if (paymentNote.isNotEmpty) ...[
            _PaymentNoteCard(note: paymentNote),
            const SizedBox(height: 12),
          ],

          _ItemsCard(order: order),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.code,
    required this.name,
    required this.table,
    required this.status,
    required this.total,
  });

  final String code;
  final String name;
  final String table;
  final String status;
  final num total;

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    if (status == 'UNPAID') {
      statusColor = const Color(0xFFE11D48); // rose
    } else if (status == 'PROCESSED') {
      statusColor = const Color(0xFF2563EB); // blue
    } else if (status == 'SERVED') {
      statusColor = const Color(0xFF047857); // emerald
    } else {
      statusColor = Colors.black.withOpacity(0.65);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFCFD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          _kv('Kode', code, mono: true),
          const SizedBox(height: 8),
          _kv('Nama', name),
          const SizedBox(height: 8),
          _kv('Meja', table),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Text('Status', style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.55)))),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  status,
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: statusColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: Colors.black.withOpacity(0.06)),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('Total', style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.55))),
              const Spacer(),
              Text('Rp ${_rupiah(total)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            ],
          )
        ],
      ),
    );
  }

  Widget _kv(String k, String v, {bool mono = false}) {
    return Row(
      children: [
        Expanded(child: Text(k, style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.55)))),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            v,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              fontFamily: mono ? 'monospace' : null,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _PaymentNoteCard extends StatelessWidget {
  const _PaymentNoteCard({required this.note});
  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Catatan Pembayaran', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(note, style: TextStyle(color: Colors.black.withOpacity(0.75))),
        ],
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.order});
  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    final details = (order['order_details'] as List?) ?? [];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Items', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          if (details.isEmpty)
            Text('Tidak ada item.', style: TextStyle(color: Colors.black.withOpacity(0.6)))
          else
            ...details.map((it) {
              final m = (it as Map).cast<String, dynamic>();
              final qty = _num(m['quantity']).toInt();
              final basePrice = _num(m['base_price']);
              final promoAmount = _num(m['promo_amount']);
              final name = (m['product_name'] ??
                      (m['partner_product'] is Map ? (m['partner_product']['name'] ?? 'Produk') : 'Produk'))
                  .toString();

              final note = (m['customer_note'] ?? '').toString().trim();
              final lineTotal = (basePrice - promoAmount) * qty;

              final opts = (m['order_detail_options'] as List?) ?? [];

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$name × $qty = Rp ${_rupiah(lineTotal)}', style: const TextStyle(fontWeight: FontWeight.w800)),
                    if (note.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text('($note)', style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.55))),
                      ),
                    if (opts.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      ...opts.map((o) {
                        final om = (o as Map).cast<String, dynamic>();
                        final optName = (om['option'] is Map ? (om['option']['name'] ?? '-') : '-').toString();
                        final parentName = (om['option'] is Map &&
                                (om['option']['parent'] is Map) &&
                                om['option']['parent']['name'] != null)
                            ? om['option']['parent']['name'].toString()
                            : 'Opsi';
                        final price = _num(om['price']) * qty;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            '- $parentName: $optName × $qty = Rp ${_rupiah(price)}',
                            style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.65)),
                          ),
                        );
                      }),
                    ],
                    const SizedBox(height: 10),
                    Container(height: 1, color: Colors.black.withOpacity(0.06)),
                    const SizedBox(height: 10),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: onRetry, child: const Text('Coba lagi')),
          ],
        ),
      ),
    );
  }
}

// ===== helpers =====
num _num(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v;
  return num.tryParse(v.toString()) ?? 0;
}

String _rupiah(num n) {
  final v = n.toDouble().round();
  final s = v.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final idxFromEnd = s.length - i;
    buf.write(s[i]);
    if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buf.write('.');
  }
  return buf.toString();
}
