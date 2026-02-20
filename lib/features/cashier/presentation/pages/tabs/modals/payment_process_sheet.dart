import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '/core/config/env.dart';
import '/features/cashier/data/orders_api.dart';
import '/core/storage/secure_storage_service.dart';
import '/features/cashier/presentation/printing/receipt_printer.dart';
import 'package:provider/provider.dart';
import '/features/cashier/data/preference/printer_manager.dart';
import '/features/cashier/data/models/printer_device.dart';


class PaymentProcessSheet extends StatefulWidget {
  const PaymentProcessSheet({
    super.key,
    required this.orderId,
    required this.loadDetail,
  });

  final int orderId;
  final Future<Map<String, dynamic>> Function(int id) loadDetail;

  @override
  State<PaymentProcessSheet> createState() => _PaymentProcessSheetState();
}

class _PaymentProcessSheetState extends State<PaymentProcessSheet> {
  bool _loading = true;
  bool _paidSuccess = false;
  bool _printing = false;
  bool _printed = false;
  bool _paying = false;

  Map<String, dynamic>? _lastPaymentResp;
  String? _error;
  Map<String, dynamic>? _order;

  final _paidCtrl = TextEditingController();
  num _change = 0;

  @override
  void initState() {
    super.initState();
    _paidCtrl.addListener(_recalcChange);
    _fetch();
  }

  @override
  void dispose() {
    _paidCtrl.removeListener(_recalcChange);
    _paidCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
      _order = null;
      _change = 0;
      _paidCtrl.text = '';
    });

    try {
      final o = await widget.loadDetail(widget.orderId);
      _order = o;

      // mirip web: kalau PAYMENT REQUEST dan ada payment_request → auto isi paid = total
      final status = (o['order_status'] ?? '').toString();
      final pr = o['payment_request'];
      final total = _num(o['total_order_value']);
      final method = (o['payment_method'] ?? '').toString();

      final hasManual = pr != null;
      if ((method == 'CASH' || hasManual) && status == 'PAYMENT REQUEST') {
        _paidCtrl.text = total.toStringAsFixed(0);
        _recalcChange(); // biar kembalian langsung ke-update
      }

    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _recalcChange() {
    final total = _num(_order?['total_order_value']);
    final paid = _num(_paidCtrl.text);
    final change = (paid - total);
    setState(() => _change = change > 0 ? change : 0);
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.of(context).viewInsets.bottom; // ✅ tinggi keyboard
    final safe = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        // ✅ dorong konten naik sebesar keyboard + safe area
        padding: EdgeInsets.only(bottom: keyboard + safe),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Material(
            color: Colors.white,
            child: Column(
              children: [
                _Header(
                  title: '💵 Proses Pembayaran',
                  onClose: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? _ErrorView(message: _error!, onRetry: _fetch)
                          : _Body(order: _order!, paidCtrl: _paidCtrl, change: _change),
                ),
                _Footer2(
                  paying: _paying,
                  onBack: () => Navigator.of(context).pop(false),
                  onConfirm: () async => _confirmAndPay(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAndPay() async {
    if (_paying) return;

    final total = _num(_order?['total_order_value']);
    final paid  = _num(_paidCtrl.text);
    final change = (paid - total) > 0 ? (paid - total) : 0;

    // Validasi cepat (JANGAN set _paying dulu)
    if (paid <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uang diterima belum diisi')),
      );
      return;
    }

    if (paid < total) {
      await showDialog<void>(
        context: context,
        useRootNavigator: true,
        builder: (_) => AlertDialog(
          title: const Text('Uang tidak cukup'),
          content: Text(
            'Uang diterima Rp ${_rupiah(paid)}\n'
            'Total tagihan Rp ${_rupiah(total)}\n\n'
            'Silakan periksa kembali nominal pembayaran.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        ),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Pembayaran'),
        content: Text(
          'Uang diterima Rp ${_rupiah(paid)}\n'
          'Total tagihan Rp ${_rupiah(total)}\n'
          'Kembalian Rp ${_rupiah(change)}\n\n'
          'Lanjutkan proses pembayaran?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ya, lanjutkan')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _paying = true);
    try {
      final storage = SecureStorageService();
      final token = await storage.getToken();
      if (token == null || token.trim().isEmpty) {
        throw Exception('Token kosong. Silakan login ulang.');
      }

      final api = OrdersApi();
      await api.paymentOrder(
        token: token,
        id: widget.orderId,
        paidAmount: paid,
        changeAmount: change,
      ).timeout(const Duration(seconds: 15));

      // ✅ setelah sukses bayar: ambil data print detail terbaru
      final printOrder = await api.printDetail(token: token, id: widget.orderId)
          .timeout(const Duration(seconds: 15));

      // ✅ print otomatis
      await _printReceiptWithOrder(printOrder, paid: paid, change: change);

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        useRootNavigator: true,
        builder: (_) => AlertDialog(
          title: const Text('Pembayaran berhasil'),
          content: const Text('Pembayaran berhasil disimpan dan struk sedang diprint.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e')),
      );
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }



  Future<void> _printReceipt() async {
    if (_order == null) return;
    if (_printing) return;

    // ✅ validasi dulu
    final ok = await _validateBeforePrint();
    if (!ok) return;

    final total = _num(_order?['total_order_value']);
    final paid  = _num(_paidCtrl.text);
    final change = (paid - total) > 0 ? (paid - total) : 0;

    setState(() => _printing = true);

    try {
      final pm = context.read<PrinterManager>();
      final p = pm.defaultPrinter;
      if (p == null) throw Exception('Default printer belum dipilih');

      // 1) build bytes
      final bytes = await ReceiptPrinter().buildReceiptBytes(
        order: _order!,
        paidAmount: paid,
        changeAmount: change,
      );

      // 2) kirim via printer manager (yang pegang koneksi)
      await pm.write(bytes);

      if (!mounted) return;
      setState(() => _printed = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Struk berhasil diprint')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal print: $e')),
      );
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }


  Future<bool> _validateBeforePrint() async {
    final total = _num(_order?['total_order_value']);
    final paid  = _num(_paidCtrl.text);
    final change = (paid - total) > 0 ? (paid - total) : 0;

    // kalau metode non-cash, biasanya paidCtrl kosong, tapi kamu mungkin tetap mau allow print
    // Kalau kamu hanya mau validasi untuk CASH/manual, cek showCashInput juga.
    // Untuk simpel: validasi jika user memang mengisi paidCtrl atau metode CASH/manual.
    if (paid <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uang diterima belum diisi')),
      );
      return false;
    }

    if (paid < total) {
      await showDialog<void>(
        context: context,
        useRootNavigator: true,
        builder: (_) => AlertDialog(
          title: const Text('Uang tidak cukup'),
          content: Text(
            'Uang diterima Rp ${_rupiah(paid)}\n'
            'Total tagihan Rp ${_rupiah(total)}\n\n'
            'Silakan periksa kembali nominal pembayaran.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        ),
      );
      return false;
    }

    // konfirmasi sebelum print (opsional tapi biasanya bagus)
    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Print'),
        content: Text(
          'Uang diterima Rp ${_rupiah(paid)}\n'
          'Total tagihan Rp ${_rupiah(total)}\n'
          'Kembalian Rp ${_rupiah(change)}\n\n'
          'Cetak struk sekarang?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ya, print')),
        ],
      ),
    );

    return ok == true;
  }

  Future<void> _printReceiptWithOrder(
    Map<String, dynamic> order, {
    required num paid,
    required num change,
  }) async {
    final pm = context.read<PrinterManager>();
    final p = pm.defaultPrinter;
    if (p == null) throw Exception('Default printer belum dipilih');

    final bytes = await ReceiptPrinter().buildReceiptBytes(
      order: order,
      paidAmount: paid,
      changeAmount: change,
    );

    await pm.write(bytes);
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
  const _Body({
    required this.order,
    required this.paidCtrl,
    required this.change,
  });

  final Map<String, dynamic> order;
  final TextEditingController paidCtrl;
  final num change;

  @override
  Widget build(BuildContext context) {
    final code = (order['booking_order_code'] ?? '-').toString();
    final name = (order['customer_name'] ?? '-').toString();
    final status = (order['order_status'] ?? '-').toString();
    final method = (order['payment_method'] ?? '-').toString();
    final total = _num(order['total_order_value']);

    // ✅ TARUH DI SINI (bukan di dalam children)
    final hasManual = order['payment_request'] != null;
    final showCashInput = method == 'CASH' || hasManual;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _OrderInfoCard(
            code: code,
            name: name,
            status: status,
            method: method,
            total: total,
          ),
          const SizedBox(height: 12),

          if (hasManual)
            _PaymentRequestCard(
              paymentRequest: (order['payment_request'] as Map).cast<String, dynamic>(),
            ),
          if (hasManual) const SizedBox(height: 12),

          _ItemsCard(order: order),
          const SizedBox(height: 12),

          if (showCashInput)
            _CashInputCard(
              total: total,
              paidCtrl: paidCtrl,
              change: change,
            )
          else
            _HintCard(
              icon: Icons.info_outline_rounded,
              title: 'Pembayaran non-cash',
              message: _paymentMethodMessage(order),
            ),
        ],
      ),
    );
  }

}

class _OrderInfoCard extends StatelessWidget {
  const _OrderInfoCard({
    required this.code,
    required this.name,
    required this.status,
    required this.method,
    required this.total,
  });

  final String code;
  final String name;
  final String status;
  final String method;
  final num total;

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFCFD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          _kv('Kode Order', code, mono: true),
          const SizedBox(height: 8),
          _kv('Nama Order', name),
          const SizedBox(height: 8),
          _kv('Status', status),
          const SizedBox(height: 8),
          _kv('Metode', method),
          const SizedBox(height: 10),
          Container(height: 1, color: Colors.black.withOpacity(0.06)),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('Total Tagihan', style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.55))),
              const Spacer(),
              Text(
                'Rp ${_rupiah(total)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: brand),
              ),
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

class _PaymentRequestCard extends StatelessWidget {
  const _PaymentRequestCard({required this.paymentRequest});

  final Map<String, dynamic> paymentRequest;

  @override
  Widget build(BuildContext context) {
    final type = (paymentRequest['payment_type_label'] ?? '-').toString();
    final provider = (paymentRequest['manual_provider_name'] ?? '-').toString();
    final accName = (paymentRequest['manual_provider_account_name'] ?? '-').toString();
    final accNo = (paymentRequest['manual_provider_account_no'] ?? '').toString().trim();
    final proof = (paymentRequest['manual_payment_image'] ?? '').toString().trim();

    final proofUrl = _normalizeProofUrl(proof);

    final isPdf = proofUrl.toLowerCase().endsWith('.pdf');

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
          const Text('Pembayaran Manual Terdeteksi', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          _row('Tipe', type),
          _row('Provider', provider),
          _row('Nama Akun', accName),
          if (accNo.isNotEmpty) _row('No Akun', accNo),

          const SizedBox(height: 10),

          if (proofUrl.isNotEmpty) ...[
            Row(
              children: [
                const Expanded(
                  child: Text('Bukti bayar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                ),
                TextButton.icon(
                  onPressed: () => _openUrl(proofUrl),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('Lihat Bukti'),
                )
              ],
            ),

            if (!isPdf)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.network(
                    proofUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.white,
                      child: const Center(child: Icon(Icons.broken_image_outlined, size: 34)),
                    ),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Bukti berbentuk PDF. Klik “Lihat Bukti” untuk membuka.',
                  style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.6)),
                ),
              ),
          ] else ...[
            Text(
              'Tidak ada bukti bayar.',
              style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.6)),
            )
          ]
        ],
      ),
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(k, style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.55)))),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              v,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static String _normalizeProofUrl(String proof) {
    if (proof.isEmpty) return '';
    if (proof.startsWith('http')) return proof;

    // proof bisa "storage/...." atau "/storage/...."
    final cleaned = proof.replaceFirst(RegExp(r'^\/?storage\/?'), '');

    // ✅ jadi URL absolut
    return '${Env.baseUrl}/storage/$cleaned';
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
                    Text(
                      '$name × $qty = Rp ${_rupiah(lineTotal)}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
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

class _CashInputCard extends StatelessWidget {
  const _CashInputCard({
    required this.total,
    required this.paidCtrl,
    required this.change,
  });

  final num total;
  final TextEditingController paidCtrl;
  final num change;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFCFD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Pembayaran Cash', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),

          Text('Uang Diterima', style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.55))),
          const SizedBox(height: 6),
          TextField(
            controller: paidCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'cth: 100000',
              filled: true,
              fillColor: const Color(0xFFF7F8FA),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.black.withOpacity(0.10)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Text('Kembalian', style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.55))),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black.withOpacity(0.10)),
            ),
            child: Text(
              'Rp ${_rupiah(change)}',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),

          const SizedBox(height: 10),
          Text(
            'Total tagihan: Rp ${_rupiah(total)}',
            style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.60)),
          ),
        ],
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({required this.icon, required this.title, required this.message});
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(message, style: TextStyle(color: Colors.black.withOpacity(0.65))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.onPrimary,
    required this.primaryLabel,
    required this.primaryBusy,
  });

  final Future<void> Function() onPrimary;
  final String primaryLabel;
  final bool primaryBusy;

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black.withOpacity(0.08))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: primaryBusy ? null : () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: brand, foregroundColor: Colors.white),
              onPressed: primaryBusy ? null : () async => onPrimary(),
              child: primaryBusy
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(primaryLabel, style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer2 extends StatelessWidget {
  const _Footer2({
    required this.onBack,
    required this.onConfirm,
    required this.paying,
  });

  final VoidCallback onBack;
  final Future<void> Function() onConfirm;
  final bool paying;

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black.withOpacity(0.08))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: paying ? null : onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Kembali'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: brand,
                foregroundColor: Colors.white,
              ),
              onPressed: paying ? null : () async => onConfirm(),
              child: paying
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Konfirmasi', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
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

String _paymentMethodMessage(Map<String, dynamic> order) {
  final method = (order['payment_method'] ?? '-').toString();

  final pr = (order['payment_request'] is Map)
      ? (order['payment_request'] as Map).cast<String, dynamic>()
      : null;

  final provider = (pr?['manual_provider_name'] ?? '').toString().trim();
  final providerLabel = provider.isNotEmpty ? provider : 'provider';

  // Mapping khusus untuk manual payment
  if (method == 'manual_tf') {
    return 'Order ini menggunakan metode transfer ke $providerLabel. Modal ini menampilkan detail pembayaran (jika ada).';
  }

  if (method == 'manual_ewallet') {
    return 'Order ini menggunakan metode e-wallet $providerLabel. Modal ini menampilkan detail pembayaran (jika ada).';
  }

  if (method == 'manual_qris') {
    return 'Order ini menggunakan metode QRIS $providerLabel. Modal ini menampilkan detail pembayaran (jika ada).';
  }

  // Default fallback
  return 'Order ini menggunakan metode $method. Modal ini menampilkan detail pembayaran (jika ada).';
}



