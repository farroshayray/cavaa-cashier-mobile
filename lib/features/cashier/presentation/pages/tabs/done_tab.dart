// lib/features/cashier/presentation/pages/tabs/done_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/features/cashier/presentation/printing/receipt_printer.dart';
import '/features/cashier/data/preference/printer_manager.dart';
import '/features/cashier/data/models/printer_device.dart';

import '../../../data/orders_api.dart';
import '../../../data/models/orders_repository.dart';
import '../../../../../core/storage/secure_storage_service.dart';

import '../../providers/done_provider.dart';
import '/features/cashier/presentation/pages/tabs/modals/detail_order_sheet.dart';

class DoneTab extends StatelessWidget {
  const DoneTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DoneProvider(
        OrdersRepository(api: OrdersApi(), storage: SecureStorageService()),
      )..load(),
      child: const _DoneView(),
    );
  }
}

class _DoneView extends StatefulWidget {
  const _DoneView();

  @override
  State<_DoneView> createState() => _DoneViewState();
}

class _DoneViewState extends State<_DoneView> {
  final _searchCtrl = TextEditingController();
  final ScrollController _listCtrl = ScrollController();
  double _lastOffset = 0;

  final Set<int> _printingIds = <int>{};

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _listCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DoneProvider>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: _SearchBar(
            controller: _searchCtrl,
            onSubmit: () {
              context.read<DoneProvider>().setQuery(_searchCtrl.text);
              context.read<DoneProvider>().load();
            },
            onClear: () {
              _searchCtrl.clear();
              context.read<DoneProvider>().setQuery('');
              context.read<DoneProvider>().load();
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
                child: Text('Selesai', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              ),
              _Badge(text: '${vm.items.length} order'),
            ],
          ),
        ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: () => context.read<DoneProvider>().load(),
            child: Builder(
              builder: (_) {
                if (vm.isLoading) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 200),
                      Center(child: CircularProgressIndicator()),
                    ]);
                }

                if (vm.error != null) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(vm.error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => context.read<DoneProvider>().load(),
                        child: const Text('Coba lagi'),
                      ),
                    ],
                  );
                }

                if (vm.items.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 80),
                      Icon(Icons.inbox_outlined, size: 56, color: Colors.black.withOpacity(0.35)),
                      const SizedBox(height: 10),
                      Text(
                        'Belum ada order selesai.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black.withOpacity(0.60)),
                      ),
                    ],
                  );
                }

                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  controller: _listCtrl,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  itemCount: vm.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final id = _toId(vm.items[i]['id']);
                    return _DoneOrderCard(
                      data: vm.items[i],
                      isPrinting: _printingIds.contains(id),
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
                              loadDetail: (orderId) => context.read<DoneProvider>().getOrderDetail(orderId),
                            ),
                          ),
                        );
                      },
                      onPrint: () async {
                        if (id <= 0) return;
                        await _printOrder(id);
                      },
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

  Future<void> _printOrder(int id) async {
    if (_printingIds.contains(id)) return;

    setState(() => _printingIds.add(id));
    try {
      final order = await context.read<DoneProvider>().getPrintDetail(id);

      final paid = _pickNum(order, ['payment', 'paid_amount']) ??
          _pickNum(order, ['latest_payment', 'paid_amount']) ??
          _pickNum(order, ['paid_amount']) ??
          _num(order['total_order_value']);

      final change = _pickNum(order, ['payment', 'change_amount']) ??
          _pickNum(order, ['latest_payment', 'change_amount']) ??
          _pickNum(order, ['change_amount']) ??
          0;

      final pm = context.read<PrinterManager>();
      final p = pm.defaultPrinter;
      if (p == null) throw Exception('Default printer belum dipilih');
      if (p.type != PrinterType.bluetooth || p.address == null || p.address!.trim().isEmpty) {
        throw Exception('Default printer bukan Bluetooth / address kosong');
      }

      final bytes = await ReceiptPrinter().buildReceiptBytes(
        order: order,
        paidAmount: paid,
        changeAmount: change,
      );

      await pm.write(bytes);

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
}

int _toId(dynamic v) => (v is int) ? v : int.tryParse(v.toString()) ?? 0;
num _num(dynamic v) => (v is num) ? v : num.tryParse(v?.toString() ?? '') ?? 0;

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

class _DoneOrderCard extends StatelessWidget {
  const _DoneOrderCard({
    required this.data,
    required this.onDetail,
    required this.onPrint,
    required this.isPrinting,
  });

  final Map<String, dynamic> data;
  final VoidCallback onDetail;
  final VoidCallback onPrint;
  final bool isPrinting;

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
              _statusChipDone(),
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

              IconButton(
                onPressed: isPrinting ? null : onPrint,
                icon: isPrinting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.print_rounded),
                tooltip: 'Print',
              ),

              IconButton(
                onPressed: onDetail,
                icon: const Icon(Icons.visibility_outlined),
                tooltip: 'Detail',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChipDone() {
    final bg = const Color(0xFFEEF2FF);
    final border = const Color(0xFFC7D2FE);
    final dot = const Color(0xFF4F46E5);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999), border: Border.all(color: border)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          const Text('Selesai', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
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
