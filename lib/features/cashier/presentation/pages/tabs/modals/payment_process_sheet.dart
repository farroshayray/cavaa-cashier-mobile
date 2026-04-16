import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '/core/config/env.dart';
import '/features/cashier/data/orders_api.dart';
import '/core/storage/secure_storage_service.dart';
import '/features/cashier/presentation/printing/receipt_printer.dart';
import 'package:provider/provider.dart';
import '/features/cashier/data/preference/printer_manager.dart';
import '/features/cashier/data/models/printer_device.dart';
import '/features/cashier/data/models/orders_repository.dart';
import '/core/services/connectivity_status_provider.dart';
import '/features/cashier/presentation/providers/payment_provider.dart';


class PaymentProcessSheet extends StatefulWidget {
  const PaymentProcessSheet({
    super.key,
    required this.orderId,
    required this.loadDetail,
    required this.ordersRepo,
    this.forceOffline = false,
  });

  final int orderId;
  final Future<Map<String, dynamic>> Function(int id) loadDetail;
  final OrdersRepository ordersRepo;
  final bool forceOffline;

  @override
  State<PaymentProcessSheet> createState() => _PaymentProcessSheetState();
}

class _PaymentProcessSheetState extends State<PaymentProcessSheet> {
  bool _loading = true;
  bool _paidSuccess = false;
  bool _printing = false;
  bool _printed = false;
  bool _paying = false;
  bool _showCashValidation = false;

  Map<String, dynamic>? _lastPaymentResp;
  String? _error;
  Map<String, dynamic>? _order;

  final _paidCtrl = TextEditingController();
  num _change = 0;

  final ImagePicker _picker = ImagePicker();

  XFile? _cashierProofImage;
  String? _cashierProofError;
  String _lastPaymentId = '';

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

  Map<String, dynamic> _buildOfflinePrintableOrder(
    Map<String, dynamic> source, {
    required num paid,
    required num change,
  }) {
    final cloned = Map<String, dynamic>.from(source);

    cloned['payment'] = {
      'updated_at': DateTime.now().toIso8601String(),
      'paid_amount': paid,
      'change_amount': change,
    };

    cloned['latest_payment'] ??= cloned['payment'];

    cloned['booking_order_code'] ??= cloned['client_order_code'] ?? '-';
    cloned['customer_name'] ??= 'Guest';
    cloned['employee_name'] ??= '-';
    cloned['store_name'] ??= 'CAVAA';
    cloned['store_address'] ??= '';
    cloned['store_is_wifi_shown'] ??= 0;
    cloned['store_wifi_user'] ??= '';
    cloned['store_wifi_password'] ??= '';

    cloned['order_details'] ??= <dynamic>[];

    return cloned;
  }

  bool get _isCaseA {
    if (_order == null) return false;
    return (_order!['order_status'] ?? '').toString() == 'PAYMENT REQUEST' &&
        _order!['payment_request'] is Map;
  }

  bool get _isCaseB {
    if (_order == null) return false;
    final latestPayment = _order!['latest_payment'];
    final cpi = latestPayment is Map ? latestPayment['owner_manual_payment'] : null;

    return (_order!['order_status'] ?? '').toString() == 'UNPAID' &&
        cpi is Map;
  }

  bool get _isCaseC => !_isCaseA && !_isCaseB;

  bool get _needsCashValidation {
    if (_order == null) return false;
    return _isCaseA || _isCaseB || ((_order!['payment_method'] ?? '').toString() == 'CASH');
  }

  bool get _paidInvalid {
    if (!_needsCashValidation) return false;
    if (!_showCashValidation) return false;

    final paid = _num(_paidCtrl.text);
    return paid <= 0;
  }

  bool get _paidInsufficient {
    if (!_needsCashValidation) return false;
    if (!_showCashValidation) return false;

    final total = _order == null ? 0 : _grandTotalFromOrder(_order!);
    final paid = _num(_paidCtrl.text);
    return paid > 0 && paid < total;
  }

  bool get _cashInputValid {
    if (!_needsCashValidation) return true;

    final total = _order == null ? 0 : _grandTotalFromOrder(_order!);
    final paid = _num(_paidCtrl.text);

    return paid > 0 && paid >= total;
  }

  bool _validateCashInputBeforeConfirm() {
    if (!_needsCashValidation) return true;

    setState(() => _showCashValidation = true);

    final total = _order == null ? 0 : _grandTotalFromOrder(_order!);
    final paid = _num(_paidCtrl.text);

    if (paid <= 0) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Uang diterima belum diisi'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      return false;
    }

    if (paid < total) {
      showDialog<void>(
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
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return false;
    }

    return true;
  }

  Future<void> _pickCashierProof({required ImageSource source}) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (file == null) return;

      final size = await File(file.path).length();
      const maxSize = 10 * 1024 * 1024; // 10MB

      if (size > maxSize) {
        setState(() {
          _cashierProofError = 'Ukuran gambar maksimal 10MB.';
          _cashierProofImage = null;
        });
        return;
      }

      setState(() {
        _cashierProofImage = file;
        _cashierProofError = null;
      });
    } catch (e) {
      setState(() {
        _cashierProofError = 'Gagal memilih gambar: $e';
      });
    }
  }

  Future<void> _showImageSourcePicker() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Ambil dari Kamera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Pilih dari Galeri'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;
    await _pickCashierProof(source: source);
  }

  void _removeCashierProof() {
    setState(() {
      _cashierProofImage = null;
      _cashierProofError = null;
    });
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

      _cashierProofImage = null;
      _cashierProofError = null;
      _lastPaymentId = '';

      final latestPayment = o['latest_payment'];
      if (latestPayment is Map && latestPayment['id'] != null) {
        _lastPaymentId = latestPayment['id'].toString();
      }

      // mirip web: kalau PAYMENT REQUEST dan ada payment_request → auto isi paid = total
      final status = (o['order_status'] ?? '').toString();
      final pr = o['payment_request'];
      final total = _grandTotalFromOrder(o);
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
    final total = _order == null ? 0 : _grandTotalFromOrder(_order!);
    final paid = _num(_paidCtrl.text);
    final change = (paid - total);

    setState(() {
      _change = change > 0 ? change : 0;
    });
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
                          : _Body(
                            order: _order!,
                            paidCtrl: _paidCtrl,
                            change: _change,
                            cashierProofImage: _cashierProofImage,
                            cashierProofError: _cashierProofError,
                            onPickImage: _showImageSourcePicker,
                            onRemoveImage: _removeCashierProof,
                            paidInvalid: _paidInvalid,
                            paidInsufficient: _paidInsufficient,
                          ),
                ),
                _Footer2(
                  paying: _paying,
                  ready: _cashInputValid,
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

    final valid = _validateCashInputBeforeConfirm();
    if (!valid) return;

    final total = _order == null ? 0 : _grandTotalFromOrder(_order!);
    final paid = _num(_paidCtrl.text);
    final change = (paid - total) > 0 ? (paid - total) : 0;

    final action = await showDialog<_PaymentCompletionAction>(
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
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              _PaymentCompletionAction.cancel,
            ),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(
              context,
              _PaymentCompletionAction.withoutPrint,
            ),
            child: const Text('Simpan'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(
              context,
              _PaymentCompletionAction.withPrint,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.print_rounded, size: 18),
                SizedBox(width: 8),
                Text('Simpan & Print'),
              ],
            ),
          ),
        ],
      ),
    );

    if (action == null || action == _PaymentCompletionAction.cancel) return;

    final shouldPrint = action == _PaymentCompletionAction.withPrint;

    setState(() => _paying = true);

    try {
      final repo = widget.ordersRepo;
      final isOnline =
          context.read<ConnectivityStatusProvider>().isOnline && !widget.forceOffline;

      if (isOnline) {
        await widget.ordersRepo.paymentOrder(
          id: widget.orderId,
          paidAmount: paid,
          changeAmount: change,
          lastPaymentId: _isCaseB ? _lastPaymentId : null,
          cashierProofImagePath: _isCaseB ? _cashierProofImage?.path : null,
        ).timeout(const Duration(seconds: 15));
      } else {
        final offlineOrder = Map<String, dynamic>.from(_order!);
        if (widget.forceOffline) {
          offlineOrder['sync_status'] = 'STOCK_CONFLICT';
        }
        await context.read<PaymentProvider>().confirmPaymentOffline(
          order: offlineOrder,
          paidAmount: paid,
          changeAmount: change,
          cashierProofImagePath: _cashierProofImage?.path,
          lastPaymentId: _isCaseB ? _lastPaymentId : null,
        );
      }

      String? printError;
      if (shouldPrint) {
        try {
          Map<String, dynamic> printOrder;

          if (isOnline) {
            printOrder = await repo
                .fetchPrintDetail(widget.orderId)
                .timeout(const Duration(seconds: 15));
          } else {
            printOrder = _buildOfflinePrintableOrder(
              _order!,
              paid: paid,
              change: change,
            );
          }

          await _printReceiptWithOrder(
            printOrder,
            paid: paid,
            change: change,
          );
        } catch (e) {
          printError = e.toString();
        }
      }

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        useRootNavigator: true,
        builder: (_) => AlertDialog(
          title: Text(
            !shouldPrint
                ? 'Pembayaran berhasil'
                : printError == null
                ? 'Pembayaran berhasil'
                : 'Pembayaran berhasil, print gagal',
          ),
          content: Text(
            !shouldPrint
                ? 'Pembayaran berhasil disimpan tanpa mencetak struk.'
                : printError == null
                ? 'Pembayaran berhasil disimpan dan struk sedang diprint.'
                : 'Pembayaran berhasil disimpan, tetapi struk gagal diprint.\n\nError: $printError',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan pembayaran: $e'),
            behavior: SnackBarBehavior.floating,
          ),
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

    final total = _order == null ? 0 : _grandTotalFromOrder(_order!);
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
    final total = _order == null ? 0 : _grandTotalFromOrder(_order!);
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

enum _PaymentCompletionAction {
  withPrint,
  withoutPrint,
  cancel,
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
    required this.cashierProofImage,
    required this.cashierProofError,
    required this.onPickImage,
    required this.onRemoveImage,
    required this.paidInvalid,
    required this.paidInsufficient,
  });

  final Map<String, dynamic> order;
  final TextEditingController paidCtrl;
  final num change;
  final XFile? cashierProofImage;
  final String? cashierProofError;
  final Future<void> Function() onPickImage;
  final VoidCallback onRemoveImage;
  final bool paidInvalid;
  final bool paidInsufficient;  

  @override
  Widget build(BuildContext context) {
    final code = (order['booking_order_code'] ?? '-').toString();
    final name = (order['customer_name'] ?? '-').toString();
    final status = (order['order_status'] ?? '-').toString();
    final method = (order['payment_method'] ?? '-').toString();
    final total = _calcGrandTotalFromMap(order);
    final isPpnActive = _toBool(order['is_ppn_active']);
    final ppnPercent = _num(order['ppn']);
    

    // ✅ TARUH DI SINI (bukan di dalam children)
    final paymentRequest = order['payment_request'];
    final hasPaymentRequest =
        (order['order_status'] ?? '').toString() == 'PAYMENT REQUEST' &&
        paymentRequest is Map;

    final latestPayment = order['latest_payment'];
    final cpi = latestPayment is Map ? latestPayment['owner_manual_payment'] : null;

    final hasCashierPaymentInstruction =
        (order['order_status'] ?? '').toString() == 'UNPAID' && cpi is Map;

    final showCashInput = method == 'CASH' || hasPaymentRequest || hasCashierPaymentInstruction;

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
            isPpnActive: isPpnActive,
            ppnPercent: ppnPercent,
          ),
          const SizedBox(height: 12),

          if (hasPaymentRequest) ...[
            _PaymentRequestCard(
              paymentRequest: (order['payment_request'] as Map).cast<String, dynamic>(),
            ),
            const SizedBox(height: 12),
          ] else if (hasCashierPaymentInstruction) ...[
            _CashierPaymentInstructionCard(
              paymentInstruction: Map<String, dynamic>.from(cpi),
              cashierProofImage: cashierProofImage,
              cashierProofError: cashierProofError,
              onPickImage: onPickImage,
              onRemoveImage: onRemoveImage,
            ),
            const SizedBox(height: 12),
          ],

          _ItemsCard(order: order),
          const SizedBox(height: 12),

          if (showCashInput)
            _CashInputCard(
              total: total,
              paidCtrl: paidCtrl,
              change: change,
              invalid: paidInvalid,
              insufficient: paidInsufficient,
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

  num _calcGrandTotalFromMap(Map<String, dynamic> order) {
    final subtotal = _num(order['total_order_value']);
    final isPpnActive = _toBool(order['is_ppn_active']);
    final ppnPercent = _num(order['ppn']);

    return isPpnActive
        ? (subtotal + (subtotal * ppnPercent / 100)).ceil()
        : subtotal.ceil();
  }

}

class _OrderInfoCard extends StatelessWidget {
  const _OrderInfoCard({
    required this.code,
    required this.name,
    required this.status,
    required this.method,
    required this.total,
    required this.isPpnActive,
    required this.ppnPercent,
  });

  final String code;
  final String name;
  final String status;
  final String method;
  final num total;
  final bool isPpnActive;
  final num ppnPercent;

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

          if (isPpnActive) ...[
            Row(
              children: [
                Text(
                  'PPN',
                  style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.55)),
                ),
                const Spacer(),
                Text(
                  '${_formatPercent(ppnPercent)}%',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          Row(
            children: [
              Text(
                'Total Tagihan',
                style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.55)),
              ),
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
    final proofLocalPath =
        (paymentRequest['manual_payment_image_local_path'] ?? '').toString().trim();

    final proofUrl = _normalizeProofUrl(proof);
    final localFile = proofLocalPath.isNotEmpty ? File(proofLocalPath) : null;
    final hasLocalFile = localFile != null && localFile.existsSync();

    final effectiveProofPath = hasLocalFile ? proofLocalPath : proofUrl;
    final isPdf = effectiveProofPath.toLowerCase().endsWith('.pdf');

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

          if (effectiveProofPath.isNotEmpty) ...[
            Row(
              children: [
                const Expanded(
                  child: Text('Bukti bayar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                ),
                if (proofUrl.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _openUrl(proofUrl),
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('Lihat Bukti'),
                  )
              ],
            ),

            if (!isPdf)
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: effectiveProofPath.isEmpty
                    ? null
                    : () => _showZoomableImagePreview(
                          context,
                          title: 'Bukti Bayar',
                          localFile: hasLocalFile ? localFile : null,
                          imageUrl: hasLocalFile ? null : proofUrl,
                        ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 4 / 3,
                        child: _buildProofImage(localFile, proofUrl),
                      ),
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.zoom_in_rounded, color: Colors.white, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Perbesar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  hasLocalFile
                      ? 'Bukti bayar tersimpan sebagai file PDF lokal.'
                      : 'Bukti berbentuk PDF. Klik “Lihat Bukti” untuk membuka.',
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

  Widget _buildProofImage(File? localFile, String proofUrl) {
    if (localFile != null && localFile.existsSync()) {
      return Image.file(
        localFile,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.white,
          child: const Center(child: Icon(Icons.broken_image_outlined, size: 34)),
        ),
      );
    }

    if (proofUrl.isNotEmpty) {
      return Image.network(
        proofUrl,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.white,
          child: const Center(child: Icon(Icons.broken_image_outlined, size: 34)),
        ),
      );
    }

    return Container(
      color: Colors.white,
      child: const Center(child: Icon(Icons.broken_image_outlined, size: 34)),
    );
  }
}

class _CashierPaymentInstructionCard extends StatelessWidget {
  const _CashierPaymentInstructionCard({
    required this.paymentInstruction,
    required this.cashierProofImage,
    required this.cashierProofError,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  final Map<String, dynamic> paymentInstruction;
  final XFile? cashierProofImage;
  final String? cashierProofError;
  final Future<void> Function()? onPickImage;
  final VoidCallback? onRemoveImage;

  @override
  Widget build(BuildContext context) {
    final type = (paymentInstruction['payment_type'] ?? '').toString();
    final provider = (paymentInstruction['provider_name'] ?? '-').toString();
    final accName = (paymentInstruction['provider_account_name'] ?? '-').toString();
    final accNo = (paymentInstruction['provider_account_no'] ?? '').toString().trim();

    final qris = (paymentInstruction['qris_image_url'] ?? '').toString().trim();
    final qrisLocalPath =
        (paymentInstruction['qris_image_local_path'] ?? '').toString().trim();

    final qrisUrl = _normalizeProofUrl(qris);
    final showAccNo = type == 'manual_tf' || type == 'manual_ewallet';
    final showQris = type == 'manual_qris' &&
        (qrisLocalPath.isNotEmpty || qrisUrl.isNotEmpty);

    final localFile = qrisLocalPath.isNotEmpty ? File(qrisLocalPath) : null;

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
          const Text('Instruksi Pembayaran Manual', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          _row('Tipe', _manualTypeLabel(type)),
          _row('Provider', provider),
          _row('Nama Akun', accName),
          if (showAccNo && accNo.isNotEmpty) _row('No Akun', accNo),

          if (showQris) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Expanded(
                  child: Text('QRIS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                ),
                TextButton.icon(
                  onPressed: qrisUrl.isEmpty ? null : () => _openUrl(qrisUrl),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('Buka QRIS'),
                ),
              ],
            ),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: (localFile != null && localFile.existsSync()) || qrisUrl.isNotEmpty
                  ? () => _showZoomableImagePreview(
                        context,
                        title: 'QRIS',
                        localFile: (localFile != null && localFile.existsSync()) ? localFile : null,
                        imageUrl: (localFile != null && localFile.existsSync()) ? null : qrisUrl,
                      )
                  : null,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: _buildQrisImage(localFile, qrisUrl),
                    ),
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.zoom_in_rounded, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Perbesar',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 10),

          const Text('Upload Bukti Bayar', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),

          Row(
            children: [
              ElevatedButton(
                onPressed: onPickImage == null ? null : () => onPickImage!(),
                child: const Text('Pilih / Foto'),
              ),
              const SizedBox(width: 8),
              if (cashierProofImage != null)
                OutlinedButton(
                  onPressed: onRemoveImage,
                  child: const Text('Hapus'),
                ),
            ],
          ),

          if (cashierProofError != null && cashierProofError!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              cashierProofError!,
              style: const TextStyle(fontSize: 12, color: Colors.red),
            ),
          ],

          if (cashierProofImage != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                File(cashierProofImage!.path),
                height: 220,
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQrisImage(File? localFile, String qrisUrl) {
    if (localFile != null && localFile.existsSync()) {
      return Image.file(
        localFile,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _brokenImage(),
      );
    }

    if (qrisUrl.isNotEmpty) {
      return Image.network(
        qrisUrl,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _brokenImage(),
      );
    }

    return _brokenImage();
  }

  Widget _brokenImage() {
    return Container(
      color: Colors.white,
      child: const Center(child: Icon(Icons.broken_image_outlined, size: 34)),
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
    required this.invalid,
    required this.insufficient,
  });

  final num total;
  final TextEditingController paidCtrl;
  final num change;
  final bool invalid;
  final bool insufficient;

  @override
  Widget build(BuildContext context) {
    final hasError = invalid || insufficient;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFCFD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasError ? Colors.red : Colors.black.withOpacity(0.08),
          width: hasError ? 1.3 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Pembayaran Cash', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),

          Row(
            children: const [
              Text(
                'Uang Diterima',
                style: TextStyle(fontSize: 12),
              ),
              SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          TextField(
            controller: paidCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'cth: 100000',
              helperText: invalid
                  ? 'Uang diterima wajib diisi'
                  : insufficient
                      ? 'Nominal uang diterima kurang dari total tagihan'
                      : null,
              helperStyle: TextStyle(
                color: hasError ? Colors.red : Colors.black54,
              ),
              filled: true,
              fillColor: const Color(0xFFF7F8FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: hasError ? Colors.red : Colors.black.withOpacity(0.10),
                  width: hasError ? 1.4 : 1.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: hasError ? Colors.red : const Color(0xFFAE1504),
                  width: 1.3,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.red, width: 1.4),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.red, width: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Text(
            'Kembalian',
            style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.55)),
          ),
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
    required this.ready,
  });

  final VoidCallback onBack;
  final Future<void> Function() onConfirm;
  final bool paying;
  final bool ready;

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
                backgroundColor: ready ? brand : brand.withOpacity(0.55),
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

Future<void> _showZoomableImagePreview(
  BuildContext context, {
  required String title,
  File? localFile,
  String? imageUrl,
}) async {
  await showDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierColor: Colors.black.withOpacity(0.85),
    builder: (_) {
      return Dialog(
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 52, 12, 12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(24),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 5,
                  panEnabled: true,
                  child: Container(
                    color: Colors.white,
                    alignment: Alignment.center,
                    child: _PreviewImageContent(
                      localFile: localFile,
                      imageUrl: imageUrl,
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
              top: 10,
              left: 16,
              right: 56,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),

            Positioned(
              top: 6,
              right: 6,
              child: Material(
                color: Colors.white.withOpacity(0.12),
                shape: const CircleBorder(),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  tooltip: 'Tutup',
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _PreviewImageContent extends StatelessWidget {
  const _PreviewImageContent({
    this.localFile,
    this.imageUrl,
  });

  final File? localFile;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (localFile != null && localFile!.existsSync()) {
      return Image.file(
        localFile!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _previewBroken(),
      );
    }

    final url = (imageUrl ?? '').trim();
    if (url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.contain,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return const SizedBox(
            height: 280,
            child: Center(child: CircularProgressIndicator()),
          );
        },
        errorBuilder: (_, __, ___) => _previewBroken(),
      );
    }

    return _previewBroken();
  }

  Widget _previewBroken() {
    return const SizedBox(
      height: 280,
      child: Center(
        child: Icon(Icons.broken_image_outlined, size: 48),
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

bool _toBool(dynamic v) {
  if (v == null) return false;
  if (v is bool) return v;
  final s = v.toString().toLowerCase();
  return s == '1' || s == 'true';
}

String _rupiah(num n) {
  final s = n.toInt().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final idxFromEnd = s.length - i;
    buf.write(s[i]);
    if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buf.write('.');
  }
  return buf.toString();
}

String _formatPercent(num n) {
  return n % 1 == 0 ? n.toInt().toString() : n.toString();
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

num _grandTotalFromOrder(Map<String, dynamic> order) {
  final subtotal = _num(order['total_order_value']);
  final isPpnActive = _toBool(order['is_ppn_active']);
  final ppnPercent = _num(order['ppn']);

  return isPpnActive
      ? (subtotal + (subtotal * ppnPercent / 100)).ceil()
      : subtotal.ceil();
}

String _manualTypeLabel(String type) {
  if (type == 'manual_tf') return 'Transfer Manual';
  if (type == 'manual_ewallet') return 'E-Wallet';
  if (type == 'manual_qris') return 'QR Statis';
  return type.isEmpty ? '-' : type;
}

String _normalizeProofUrl(String proof) {
  if (proof.isEmpty) return '';
  if (proof.startsWith('http')) return proof;

  final cleaned = proof.replaceFirst(RegExp(r'^\/?storage\/?'), '');
  return '${Env.baseUrl}/storage/$cleaned';
}
