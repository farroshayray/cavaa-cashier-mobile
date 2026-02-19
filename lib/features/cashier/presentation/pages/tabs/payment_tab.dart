import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../../providers/payment_provider.dart';
import '../../../../scanner/pages/barcode_scanner_page.dart';
import '/features/cashier/presentation/pages/tabs/modals/payment_process_sheet.dart';
import '/features/cashier/presentation/pages/tabs/modals/detail_order_sheet.dart';



class PaymentTab extends StatelessWidget {
  const PaymentTab({super.key, this.focusOrderId});

  final int? focusOrderId;

  @override
  Widget build(BuildContext context) {
    return _PaymentView(focusOrderId: focusOrderId);
  }
}

class _PaymentView extends StatefulWidget {
  const _PaymentView({this.focusOrderId});
  final int? focusOrderId;

  @override
  State<_PaymentView> createState() => _PaymentViewState();
}

class _PaymentViewState extends State<_PaymentView> {
  final _searchCtrl = TextEditingController();
  final ScrollController _listCtrl = ScrollController();

  int? _blinkOrderId;
  Timer? _blinkTimer;
  int? _lastHandledFocus;


  @override
  void initState() {
    super.initState();

    _searchCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant _PaymentView oldWidget) {
    super.didUpdateWidget(oldWidget);

    final id = widget.focusOrderId;
    if (id != null && id > 0 && id != _lastHandledFocus) {
      _lastHandledFocus = id;
      _goToAndBlink(id);
    }
  }


  @override
  void dispose() {
    _blinkTimer?.cancel();
    _searchCtrl.dispose();
    _listCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final id = widget.focusOrderId;
    if (id != null && id > 0 && id != _lastHandledFocus) {
      _lastHandledFocus = id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _goToAndBlink(id);
      });
    }
  }


  Future<void> _scanAndSearch() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerPage()),
    );

    if (!mounted) return;

    if (code != null && code.trim().isNotEmpty) {
      _searchCtrl.text = code.trim();
      final provider = context.read<PaymentProvider>();
      provider.setQuery(_searchCtrl.text);
      await provider.load();
      FocusScope.of(context).unfocus();
    }
  }

  int _toId(dynamic v) => (v is int) ? v : int.tryParse(v.toString()) ?? 0;

  Future<void> _goToAndBlink(int orderId) async {
    final vm = context.read<PaymentProvider>();

    // 1) pastikan list sudah ada data terbaru
    // (kalau dari Home sudah load(), ini tetap aman)
    if (vm.items.isEmpty) {
      await vm.load();
    }

    if (!mounted) return;

    final idx = vm.items.indexWhere((e) => _toId(e['id']) == orderId);
    if (idx < 0) {
      // order tidak ketemu di tab ini (bisa karena statusnya sudah pindah tab)
      return;
    }

    // 2) scroll ke index (perkiraan tinggi item)
    // kalau kamu butuh akurat banget, nanti kita bisa pakai package scrollable_positioned_list
    const approxItemHeight = 160.0; // estimasi tinggi card + spacing
    final targetOffset = (idx * (approxItemHeight + 10)).toDouble();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_listCtrl.hasClients) return;
      final max = _listCtrl.position.maxScrollExtent;
      _listCtrl.animateTo(
        targetOffset.clamp(0.0, max),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOut,
      );
    });

    // 3) blink border
    _blinkTimer?.cancel();
    setState(() => _blinkOrderId = orderId);
    _blinkTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _blinkOrderId = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PaymentProvider>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: _SearchBar(
            controller: _searchCtrl,
            onScan: _scanAndSearch,
            onSubmit: () {
              context.read<PaymentProvider>().setQuery(_searchCtrl.text);
              context.read<PaymentProvider>().load();
            },
            onClear: () {
              _searchCtrl.clear();
              context.read<PaymentProvider>().setQuery('');
              context.read<PaymentProvider>().load();
              setState(() {});
            },
          ),
        ),

        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F8FA),
            border: Border(
              top: BorderSide(color: Colors.black.withOpacity(0.06)),
              bottom: BorderSide(color: Colors.black.withOpacity(0.06)),
            ),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text('Pembayaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              ),
              _Badge(text: '${vm.items.length} order'),
            ],
          ),
        ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: () => context.read<PaymentProvider>().load(),
            child: Builder(
              builder: (_) {
                if (vm.isLoading) {
                  return ListView(
                    children: [
                      SizedBox(height: 200),
                      Center(child: CircularProgressIndicator()),
                    ],
                  );
                }

                if (vm.error != null) {
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(vm.error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => context.read<PaymentProvider>().load(),
                        child: const Text('Coba lagi'),
                      ),
                    ],
                  );
                }

                if (vm.items.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 80),
                      Icon(Icons.inbox_outlined, size: 56, color: Colors.black.withOpacity(0.35)),
                      const SizedBox(height: 10),
                      Text(
                        'Tidak ada order yang menunggu pembayaran.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black.withOpacity(0.60)),
                      ),
                    ],
                  );
                }

                return ListView.separated(
                  controller: _listCtrl, // ✅ penting untuk scroll
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  itemCount: vm.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final data = vm.items[i];
                    final id = _toId(data['id']);
                    final blinking = (_blinkOrderId != null && _blinkOrderId == id);

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: blinking ? Colors.red : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: _PaymentOrderCard(
                        data: data,
                        onDetail: () async {
                          if (id <= 0) return;

                          await showModalBottomSheet(
                            context: context,
                            useRootNavigator: true,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => SizedBox(
                              height: MediaQuery.of(context).size.height * 0.92,
                              child: DetailOrderSheet(
                                orderId: id,
                                loadDetail: (orderId) => context.read<PaymentProvider>().getOrderDetail(orderId),
                              ),
                            ),
                          );
                        },
                        onDelete: () async {
                          if (id <= 0) return;

                          final ok = await showDialog<bool>(
                            context: context,
                            useRootNavigator: true,
                            builder: (ctx) {
                              return AlertDialog(
                                title: const Text('Hapus order?'),
                                content: const Text('Order yang dihapus tidak dapat dikembalikan.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(false),
                                    child: const Text('Batal'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color.fromARGB(255, 146, 10, 0),
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => Navigator.of(ctx).pop(true),
                                    child: const Text('Hapus'),
                                  ),
                                ],
                              );
                            },
                          );

                          if (ok != true) return;

                          try {
                            await context.read<PaymentProvider>().deleteOrder(id);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Order berhasil dihapus.')),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Gagal hapus order: $e')),
                            );
                          }
                        },
                        onProcess: () async {
                          if (id <= 0) return;

                          final result = await showModalBottomSheet<bool>(
                            context: context,
                            useRootNavigator: true,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => SizedBox(
                              height: MediaQuery.of(context).size.height * 0.92,
                              child: PaymentProcessSheet(
                                orderId: id,
                                loadDetail: (orderId) => context.read<PaymentProvider>().getOrderDetail(orderId),
                              ),
                            ),
                          );

                          if (result == true && context.mounted) {
                            await context.read<PaymentProvider>().load();
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onScan,
    required this.onSubmit,
    required this.onClear,
  });

  final TextEditingController controller;
  final VoidCallback onScan;
  final VoidCallback onSubmit;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.04),
          )
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => onSubmit(),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Cari order (kode/meja/nama)…',
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Reset',
            ),
          IconButton(
            onPressed: onScan,
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Scan barcode',
          ),
          const SizedBox(width: 6),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: brand,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onPressed: onSubmit,
            child: const Icon(Icons.search_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Color(0xFF1D4ED8),
        ),
      ),
    );
  }
}

class _PaymentOrderCard extends StatelessWidget {
  const _PaymentOrderCard({
    required this.data,
    required this.onDetail,
    required this.onDelete,
    required this.onProcess,
  });

  final Map<String, dynamic> data;
  final VoidCallback onDetail;
  final VoidCallback onDelete;
  final VoidCallback onProcess;

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);

    final code = (data['booking_order_code'] ?? '-').toString();
    final customer = (data['customer_name'] ?? '-').toString();
    final total = (data['total_order_value'] ?? 0);
    final status = (data['order_status'] ?? '').toString();
    final table = (data['table'] is Map ? (data['table']['table_no'] ?? '-') : '-').toString();

    final badge = _statusBadge(status, (data['payment_method'] ?? '').toString());

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            offset: const Offset(0, 8),
            color: Colors.black.withOpacity(0.04),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // code + customer + meja/time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        code,
                        style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w800, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      customer,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Meja: $table',
                      style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.55)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              badge,
            ],
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: Colors.black.withOpacity(0.06)),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total', style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.55))),
                    const SizedBox(height: 2),
                    Text(
                      'Rp ${_rupiah(total)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDetail,
                icon: const Icon(Icons.visibility_outlined),
                tooltip: 'Detail',
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Hapus',
              ),
              const SizedBox(width: 6),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onPressed: onProcess,
                child: const Text('Process', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String orderStatus, String paymentMethod) {
    // kamu bisa refine sesuai web kamu
    final isExpiredQris = paymentMethod == 'QRIS' && orderStatus == 'EXPIRED';
    final isRequest = orderStatus == 'PAYMENT REQUEST';

    Color bg;
    Color border;
    Color dot;
    String text;

    if (isExpiredQris) {
      bg = const Color(0xFFFFF1F2);
      border = const Color(0xFFFECACA);
      dot = const Color(0xFFEF4444);
      text = 'Unpaid';
    } else if (isRequest) {
      bg = const Color(0xFFFFFBEB);
      border = const Color(0xFFFDE68A);
      dot = const Color(0xFFF59E0B);
      text = 'Request';
    } else {
      bg = const Color(0xFFFFFBEB);
      border = const Color(0xFFFDE68A);
      dot = const Color(0xFFF59E0B);
      text = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

String _rupiah(dynamic n) {
  final num vNum = (n is num) ? n : num.tryParse(n.toString()) ?? 0;
  final v = vNum.toDouble().round();
  final s = v.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final idxFromEnd = s.length - i;
    buf.write(s[i]);
    if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buf.write('.');
  }
  return buf.toString();
}
