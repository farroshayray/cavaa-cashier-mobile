import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/features/cashier/data/preference/printer_manager.dart';
import '/features/cashier/data/models/printer_device.dart';
import '/features/cashier/presentation/printing/order_list_printer.dart';
import '/features/cashier/presentation/utils/order_edit_utils.dart';

class DetailOrderSheet extends StatefulWidget {
  const DetailOrderSheet({
    super.key,
    required this.orderId,
    required this.loadDetail,
    this.stockConflictMessage,
    this.canEdit = false,
    this.canDelete = false,
    this.canMarkKitchenServed = false,
    this.onEdit,
    this.onDelete,
    this.onMarkKitchenServed,
  });

  final int orderId;
  final Future<Map<String, dynamic>> Function(int id) loadDetail;
  final String? stockConflictMessage;
  final bool canEdit;
  final bool canDelete;
  final bool canMarkKitchenServed;
  final VoidCallback? onEdit;
  final Future<void> Function()? onDelete;
  final Future<void> Function(int detailId)? onMarkKitchenServed;

  @override
  State<DetailOrderSheet> createState() => _DetailOrderSheetState();
}

class _DetailOrderSheetState extends State<DetailOrderSheet> {
  bool _loading = true;
  bool _printing = false;
  int? _markingDetailId;
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

  Future<void> _printOrderList() async {
    if (_printing) return;
    final order = _order;
    if (order == null) return;

    setState(() => _printing = true);

    try {
      final pm = context.read<PrinterManager>();
      final p = pm.defaultPrinter;

      if (p == null) {
        throw Exception('Default printer belum dipilih');
      }

      if (p.type != PrinterType.bluetooth || p.address == null || p.address!.trim().isEmpty) {
        throw Exception('Default printer bukan Bluetooth / address kosong');
      }

      final bytes = await OrderListPrinter().buildOrderListBytes(order: order);

      await pm.write(bytes);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('List order berhasil diprint')),
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

  Future<void> _markKitchenServed(int detailId) async {
    if (widget.onMarkKitchenServed == null || _markingDetailId != null) return;

    setState(() => _markingDetailId = detailId);
    try {
      await widget.onMarkKitchenServed!(detailId);
      await _fetch();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status item berhasil diperbarui')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal update status: $e')),
      );
    } finally {
      if (mounted) setState(() => _markingDetailId = null);
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
                  isPrinting: _printing,
                  onPrint: (_loading || _order == null) ? null : _printOrderList,
                  onClose: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? _ErrorView(message: _error!, onRetry: _fetch)
                          : _Body(
                              order: _order!,
                              stockConflictMessage: widget.stockConflictMessage,
                              canEdit: widget.canEdit,
                              canDelete: widget.canDelete,
                              canMarkKitchenServed: widget.canMarkKitchenServed,
                              markingDetailId: _markingDetailId,
                              onEdit: widget.onEdit,
                              onDelete: widget.onDelete,
                              onMarkKitchenServed: widget.onMarkKitchenServed == null
                                  ? null
                                  : _markKitchenServed,
                            ),
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
  const _Header({
    required this.title,
    required this.onClose,
    required this.onPrint,
    required this.isPrinting,
  });

  final String title;
  final VoidCallback onClose;
  final VoidCallback? onPrint;
  final bool isPrinting;

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
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ),
          TextButton.icon(
            onPressed: onPrint,
            icon: isPrinting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.print_rounded, size: 18),
            label: const Text(
              'Print Order',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            style: TextButton.styleFrom(
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
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
    this.stockConflictMessage,
    this.canEdit = false,
    this.canDelete = false,
    this.canMarkKitchenServed = false,
    this.markingDetailId,
    this.onEdit,
    this.onDelete,
    this.onMarkKitchenServed,
  });

  final Map<String, dynamic> order;
  final String? stockConflictMessage;
  final bool canEdit;
  final bool canDelete;
  final bool canMarkKitchenServed;
  final int? markingDetailId;
  final VoidCallback? onEdit;
  final Future<void> Function()? onDelete;
  final Future<void> Function(int detailId)? onMarkKitchenServed;

  @override
  Widget build(BuildContext context) {
    final code = (order['booking_order_code'] ?? '-').toString();
    final name = (order['customer_name'] ?? '-').toString();
    final table = (order['table'] is Map ? (order['table']['table_no'] ?? '-') : '-').toString();
    final isPpnActive = _toBool(order['is_ppn_active']);
    final ppnPercent = _num(order['ppn']);
    final total = _calcGrandTotalFromMap(order);
    final roundingAmount = _calcCashRoundingAmount(order);
    final status = (order['order_status'] ?? '-').toString();
    final conflictMessage = (stockConflictMessage ?? order['last_error'] ?? '')
        .toString()
        .trim();

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
            roundingAmount: roundingAmount,
            isPpnActive: isPpnActive,
            ppnPercent: ppnPercent,
          ),
          const SizedBox(height: 12),

          if (conflictMessage.isNotEmpty) ...[
            _StockConflictCard(message: conflictMessage),
            const SizedBox(height: 12),
          ],

          if (paymentNote.isNotEmpty) ...[
            _PaymentNoteCard(note: paymentNote),
            const SizedBox(height: 12),
          ],

          _ItemsCard(
            order: order,
            canMarkKitchenServed: canMarkKitchenServed,
            markingDetailId: markingDetailId,
            onMarkKitchenServed: onMarkKitchenServed,
          ),

          if (canEdit || canDelete) ...[
            const SizedBox(height: 16),
            if (canEdit && onEdit != null)
              ElevatedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Ubah Order'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFAE1504),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            if (canDelete && onDelete != null) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () async => onDelete!.call(),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Hapus Order'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFFECACA)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  num _calcGrandTotalFromMap(Map<String, dynamic> order) {
    if (order['grand_total_local'] != null) {
      return _num(order['grand_total_local']).ceil();
    }

    final subtotal = _num(order['total_order_value']);
    final isPpnActive = _toBool(order['is_ppn_active']);
    final ppnPercent = _num(order['ppn']);

    final baseTotal = isPpnActive
        ? (subtotal + (subtotal * ppnPercent / 100)).ceil()
        : subtotal.ceil();
    return baseTotal + _calcCashRoundingAmount(order, baseTotal: baseTotal);
  }
}

class _StockConflictCard extends StatelessWidget {
  const _StockConflictCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final lines = message
        .split(RegExp(r'[\r\n]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.error_outline_rounded, size: 18, color: Color(0xFFDC2626)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Konflik Stok',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF991B1B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (lines.length <= 1)
            Text(
              lines.isEmpty ? message : lines.first,
              style: const TextStyle(
                color: Color(0xFF7F1D1D),
                fontWeight: FontWeight.w700,
              ),
            )
          else
            ...lines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 7),
                      child: SizedBox(
                        width: 5,
                        height: 5,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0xFFDC2626),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        line,
                        style: const TextStyle(
                          color: Color(0xFF7F1D1D),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
    required this.roundingAmount,
    required this.isPpnActive,
    required this.ppnPercent,
  });

  final String code;
  final String name;
  final String table;
  final String status;
  final num total;
  final num roundingAmount;
  final bool isPpnActive;
  final num ppnPercent;

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

          if (roundingAmount > 0) ...[
            Row(
              children: [
                Text(
                  'Pembulatan Cash',
                  style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.55)),
                ),
                const Spacer(),
                Text(
                  'Rp ${_rupiah(roundingAmount)}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          Row(
            children: [
              Text(
                'Total',
                style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.55)),
              ),
              const Spacer(),
              Text(
                'Rp ${_rupiah(total)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ],
          ),
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
  const _ItemsCard({
    required this.order,
    this.canMarkKitchenServed = false,
    this.markingDetailId,
    this.onMarkKitchenServed,
  });

  final Map<String, dynamic> order;
  final bool canMarkKitchenServed;
  final int? markingDetailId;
  final Future<void> Function(int detailId)? onMarkKitchenServed;

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
              final itemState = _resolveKitchenItemState(m, order);
              final detailId = orderDetailId(m);
              final canMarkThis = canMarkKitchenServed &&
                  onMarkKitchenServed != null &&
                  detailId != null &&
                  isItemAwaitingServe(m);
              final serveLabel = serveButtonLabelForItem(m);
              final isMarking = detailId != null && markingDetailId == detailId;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            '$name × $qty = Rp ${_rupiah(lineTotal)}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (itemState != null) ...[
                          const SizedBox(width: 8),
                          _KitchenStateBadge(state: itemState),
                        ],
                      ],
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
                    if (canMarkThis) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: isMarking
                              ? null
                              : () => onMarkKitchenServed!(detailId!),
                          icon: isMarking
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.restaurant_rounded, size: 18),
                          label: Text(serveLabel),
                        ),
                      ),
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

class _KitchenStateBadge extends StatelessWidget {
  const _KitchenStateBadge({required this.state});

  final _KitchenItemState state;

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;
    late final IconData icon;
    late final String label;

    switch (state) {
      case _KitchenItemState.processing:
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF1D4ED8);
        icon = Icons.timelapse_rounded;
        label = 'Diproses';
        break;
      case _KitchenItemState.servedKitchen:
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF047857);
        icon = Icons.check_circle_rounded;
        label = 'Served Kitchen';
        break;
      case _KitchenItemState.servedCashier:
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF047857);
        icon = Icons.check_circle_rounded;
        label = 'Served';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ===== helpers =====
enum _KitchenItemState {
  processing,
  servedKitchen,
  servedCashier,
}

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

num _calcCashRoundingAmount(Map<String, dynamic> data, {num? baseTotal}) {
  final stored = _pickNum(data, ['cash_rounding_amount']) ??
      _pickNum(data, ['rounding_amount']) ??
      _pickNum(data, ['payment', 'rounding_amount']) ??
      _pickNum(data, ['latest_payment', 'rounding_amount']);
  if (stored != null && stored > 0) return stored.ceil();

  final method = (_toBool(data['openbill_flag']) &&
          ((data['payment_method'] ?? '').toString().trim().isEmpty))
      ? 'OPENBILL'
      : (data['payment_method'] ?? '').toString().toUpperCase();
  if (method != 'CASH') return 0;

  final effectiveBaseTotal = baseTotal ?? _baseGrandTotal(data);
  final snap = _num(data['grand_total_local'] ?? data['grand_total']);
  final diff = snap.ceil() - effectiveBaseTotal.ceil();
  return diff > 0 ? diff : 0;
}

num _baseGrandTotal(Map<String, dynamic> data) {
  final subtotal = _num(data['total_order_value'] ?? data['subtotal']);
  final isPpnActive = _toBool(data['is_ppn_active']);
  final ppnPercent = _num(data['ppn']);
  return isPpnActive
      ? (subtotal + (subtotal * ppnPercent / 100)).ceil()
      : subtotal.ceil();
}

num? _pickNum(Map<String, dynamic> root, List<String> path) {
  dynamic cur = root;
  for (final k in path) {
    if (cur is Map && cur[k] != null) {
      cur = cur[k];
    } else {
      return null;
    }
  }
  return (cur is num) ? cur : num.tryParse(cur.toString());
}

String _formatPercent(num n) {
  return n % 1 == 0 ? n.toInt().toString() : n.toString();
}

_KitchenItemState? _resolveKitchenItemState(
  Map<String, dynamic> item,
  Map<String, dynamic> order,
) {
  final rawKitchenProcessId = item['kitchen_process_id'];
  final kitchenProcessId = rawKitchenProcessId == null
      ? null
      : num.tryParse(rawKitchenProcessId.toString())?.toInt();
  final status = (item['status'] ?? '').toString();
  final orderStatus = (order['order_status'] ?? '').toString();

  if (status == 'SERVED BY KITCHEN') {
    return _KitchenItemState.servedKitchen;
  }

  if (status == 'SERVED BY CASHIER' || orderStatus == 'SERVED') {
    return _KitchenItemState.servedCashier;
  }

  if (status == 'PROCESSED_BY_CASHIER') {
    return _KitchenItemState.processing;
  }

  if (kitchenProcessId != null && kitchenProcessId > 0) {
    return _KitchenItemState.processing;
  }

  return null;
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
