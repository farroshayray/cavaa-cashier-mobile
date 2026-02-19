// lib/features/cashier/presentation/pages/tabs/process_tab.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/features/cashier/presentation/printing/receipt_printer.dart';
import '/features/cashier/data/preference/printer_manager.dart';
import '/features/cashier/data/models/printer_device.dart';

import '../../../data/orders_api.dart';
import '../../../data/models/orders_repository.dart';
import '../../../../../core/storage/secure_storage_service.dart';

// ✅ bikin provider khusus proses (contoh)
import '../../providers/process_provider.dart';

import '/features/cashier/presentation/pages/tabs/modals/detail_order_sheet.dart';
// kalau nanti ada modal khusus proses/selesai, import juga

class ProcessTab extends StatelessWidget {
  const ProcessTab({super.key, this.focusOrderId});

  final int? focusOrderId;

  @override
  Widget build(BuildContext context) {
    return _ProcessView(focusOrderId: focusOrderId);
  }
}

class _ProcessView extends StatefulWidget {
  const _ProcessView({this.focusOrderId});
  final int? focusOrderId;

  @override
  State<_ProcessView> createState() => _ProcessViewState();
}


class _ProcessViewState extends State<_ProcessView> {
  final _searchCtrl = TextEditingController();
  final ScrollController _listCtrl = ScrollController();
  double _lastOffset = 0;
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
  void dispose() {
    _blinkTimer?.cancel();
    _searchCtrl.dispose();
    _listCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _ProcessView oldWidget) {
    super.didUpdateWidget(oldWidget);

    final id = widget.focusOrderId;
    if (id != null && id > 0 && id != _lastHandledFocus) {
      _lastHandledFocus = id;
      _goToAndBlink(id);
    }
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

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProcessProvider>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: _SearchBar(
            controller: _searchCtrl,
            onSubmit: () {
              context.read<ProcessProvider>().setQuery(_searchCtrl.text);
              context.read<ProcessProvider>().load();
            },
            onClear: () {
              _searchCtrl.clear();
              context.read<ProcessProvider>().setQuery('');
              context.read<ProcessProvider>().load();
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
                child: Text('Proses', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              ),
              _Badge(text: '${vm.items.length} order'),
            ],
          ),
        ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: () => context.read<ProcessProvider>().load(),
            child: Builder(
              builder: (_) {
                if (vm.isLoading) {
                  return ListView(children: const [
                    SizedBox(height: 200),
                    Center(child: CircularProgressIndicator()),
                  ]);
                }

                if (vm.error != null) {
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(vm.error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => context.read<ProcessProvider>().load(),
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
                        'Tidak ada order yang sedang diproses.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black.withOpacity(0.60)),
                      ),
                    ],
                  );
                }

                return ListView.separated(
                  controller: _listCtrl,
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
                      child: _ProcessOrderCard(
                        data: data,
                        isPrinting: _printingIds.contains(id),
                        isActing: vm.isActionLoading(id),
                        onDetail: () async {
                          final id = _toId(vm.items[i]['id']);
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
                                loadDetail: (orderId) =>
                                    context.read<ProcessProvider>().getOrderDetail(orderId),
                              ),
                            ),
                          );
                        },
                        onPrint: () async {
                          final id = _toId(vm.items[i]['id']);
                          if (id <= 0) return;
                          await _printOrder(id);
                        },
                        onProcess: () async {
                          final id = _toId(vm.items[i]['id']);
                          if (id <= 0) return;
                          try {
                            final res = await context.read<ProcessProvider>().actionProcess(id);
                            if (!mounted) return;
                            final st = (res['status'] ?? 'ok').toString();
                            final msg = (res['message'] ?? 'OK').toString();
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                            if (st == 'warning') await context.read<ProcessProvider>().load();
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal proses: $e')));
                          }
                        },
                        onCancelProcess: () async {
                          final id = _toId(vm.items[i]['id']);
                          if (id <= 0) return;
                          try {
                            await context.read<ProcessProvider>().actionCancelProcess(id);
                            if (!mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Proses dibatalkan')),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Gagal batal: $e')),
                            );
                          }
                        },
                        onFinish: () async {
                          final id = _toId(vm.items[i]['id']);
                          if (id <= 0) return;
                          try {
                            await context.read<ProcessProvider>().actionFinish(id);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order selesai')));
                            // refresh tapi tetap di posisi scroll saat ini
                            await _refreshKeepScroll();

                            // optional: refresh
                            // await context.read<ProcessProvider>().load();
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal selesai: $e')));
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

  final Set<int> _printingIds = <int>{};

  Future<void> _printOrder(int id) async {
    if (_printingIds.contains(id)) return;

    setState(() => _printingIds.add(id));
    try {
      // 1) ambil data print-detail (include store_name, address, wifi, payment updated_at, dll)
      final order = await context.read<ProcessProvider>().getPrintDetail(id);

      // 2) ambil paid & change dari response (fallback aman)
      final paid = _pickNum(order, ['payment', 'paid_amount']) ??
          _pickNum(order, ['latest_payment', 'paid_amount']) ??
          _pickNum(order, ['paid_amount']) ??
          _num(order['total_order_value']); // fallback: total

      final change = _pickNum(order, ['payment', 'change_amount']) ??
          _pickNum(order, ['latest_payment', 'change_amount']) ??
          _pickNum(order, ['change_amount']) ??
          0;

      // 3) default printer
      final pm = context.read<PrinterManager>();
      final p = pm.defaultPrinter;
      if (p == null) throw Exception('Default printer belum dipilih');
      if (p.type != PrinterType.bluetooth || p.address == null || p.address!.trim().isEmpty) {
        throw Exception('Default printer bukan Bluetooth / address kosong');
      }

      // 4) print
      await ReceiptPrinter().printOrder(
        order: order,
        paidAmount: paid,
        changeAmount: change,
        btMacAddress: p.address!,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Struk berhasil diprint')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal print: $e')),
      );
    } finally {
      if (mounted) setState(() => _printingIds.remove(id));
    }
  }

  // helper: ambil num dari path map bertingkat
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

  Future<void> _refreshKeepScroll() async {
    if (_listCtrl.hasClients) _lastOffset = _listCtrl.offset;

    await context.read<ProcessProvider>().load();

    if (!mounted) return;

    // tunggu frame selesai rebuild dulu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_listCtrl.hasClients) return;

      final max = _listCtrl.position.maxScrollExtent;
      final target = _lastOffset.clamp(0.0, max);

      _listCtrl.jumpTo(target);
    });
  }

  int _toId(dynamic v) => (v is int) ? v : int.tryParse(v.toString()) ?? 0;

  Future<void> _goToAndBlink(int orderId) async {
    final vm = context.read<ProcessProvider>();

    // pastikan data ada
    if (vm.items.isEmpty) {
      await vm.load();
    }
    if (!mounted) return;

    final idx = vm.items.indexWhere((e) => _toId(e['id']) == orderId);
    if (idx < 0) {
      debugPrint('FOCUS PROCESS: id=$orderId NOT FOUND in process list');
      return;
    }

    const approxItemHeight = 170.0; // estimasi tinggi card proses
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

    // blink
    _blinkTimer?.cancel();
    setState(() => _blinkOrderId = orderId);
    _blinkTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _blinkOrderId = null);
    });
  }

}

int _toId(dynamic v) => (v is int) ? v : int.tryParse(v.toString()) ?? 0;

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onSubmit,
    required this.onClear,
  });

  final TextEditingController controller;
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
            IconButton(onPressed: onClear, icon: const Icon(Icons.close_rounded)),
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
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1D4ED8)),
      ),
    );
  }
}

class _ProcessOrderCard extends StatelessWidget {
  const _ProcessOrderCard({
    super.key,
    required this.data,
    required this.onDetail,
    required this.onPrint,
    required this.isPrinting,
    required this.onProcess,
    required this.onCancelProcess,
    required this.onFinish,
    required this.isActing,
  });

  final Map<String, dynamic> data;
  final VoidCallback onDetail;
  final VoidCallback onPrint;
  final bool isPrinting;
  final VoidCallback onProcess;
  final VoidCallback onCancelProcess;
  final VoidCallback onFinish;
  final bool isActing;



  @override
  Widget build(BuildContext context) {
    final code = (data['booking_order_code'] ?? '-').toString();
    final customer = (data['customer_name'] ?? '-').toString();
    final total = (data['total_order_value'] ?? 0);
    final table = (data['table'] is Map ? (data['table']['table_no'] ?? '-') : '-').toString();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(blurRadius: 14, offset: const Offset(0, 8), color: Colors.black.withOpacity(0.04)),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(999)),
                      child: Text(
                        code,
                        style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w800, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(customer, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text('Meja: $table', style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.55))),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _statusChip(),
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
                    Text('Rp ${_rupiah(total)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),

              // ===== ACTIONS =====
              if (isActing)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                ),

              // ✅ tombol status-based
              _buildStatusActions(),

              // tombol print
              IconButton(
                onPressed: (isPrinting || isActing) ? null : onPrint,
                icon: isPrinting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.print_rounded),
                tooltip: 'Print',
              ),

              IconButton(
                onPressed: isActing ? null : onDetail,
                icon: const Icon(Icons.visibility_outlined),
                tooltip: 'Detail',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip() {
    final bg = const Color(0xFFECFDF5);
    final border = const Color(0xFFBBF7D0);
    final dot = const Color(0xFF22C55E);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999), border: Border.all(color: border)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          const Text('Proses', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildStatusActions() {
    final st = (data['order_status'] ?? '').toString();

    // PAID -> tampil tombol Proses
    if (st == 'PAID') {
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: ElevatedButton(
          onPressed: isActing ? null : onProcess,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEA580C), // orange-ish
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          child: const Text('Proses', style: TextStyle(fontWeight: FontWeight.w900)),
        ),
      );
    }

    // PROCESSED -> tampil Cancel + Finish
    if (st == 'PROCESSED') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: isActing ? null : onCancelProcess,
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Cancel process',
          ),
          const SizedBox(width: 2),
          ElevatedButton(
            onPressed: isActing ? null : onFinish,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED), // purple
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            child: const Text('Selesai', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 6),
        ],
      );
    }

    // status lain -> tidak tampil tombol proses
    return const SizedBox.shrink();
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

num _num(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v;
  return num.tryParse(v.toString()) ?? 0;
}
