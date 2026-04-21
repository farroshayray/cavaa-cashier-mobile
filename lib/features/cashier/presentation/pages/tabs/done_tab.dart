// lib/features/cashier/presentation/pages/tabs/done_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '/features/cashier/presentation/printing/receipt_printer.dart';
import '/features/cashier/data/preference/printer_manager.dart';
import '/features/cashier/data/models/printer_device.dart';
import '/features/cashier/data/local/db/sync/sync_service.dart';

import '../../providers/done_provider.dart';
import '/features/cashier/presentation/pages/tabs/modals/detail_order_sheet.dart';

class DoneTab extends StatefulWidget {
  const DoneTab({
    super.key,
    this.focusOrderId,
    this.focusRequestKey = 0,
  });

  final int? focusOrderId;
  final int focusRequestKey;

  @override
  State<DoneTab> createState() => _DoneTabState();
}

class _DoneTabState extends State<DoneTab> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;

    Future.microtask(() => context.read<DoneProvider>().load());
  }

  @override
  Widget build(BuildContext context) {
    return _DoneView(
      focusOrderId: widget.focusOrderId,
      focusRequestKey: widget.focusRequestKey,
    );
  }
}

class _DoneView extends StatefulWidget {
  const _DoneView({
    this.focusOrderId,
    this.focusRequestKey = 0,
  });

  final int? focusOrderId;
  final int focusRequestKey;

  @override
  State<_DoneView> createState() => _DoneViewState();
}

class _DoneViewState extends State<_DoneView> {
  static const Duration _searchDebounceDelay = Duration(milliseconds: 500);

  final _searchCtrl = TextEditingController();
  final ScrollController _listCtrl = ScrollController();
  double _lastOffset = 0;
  int? _blinkOrderId;
  Timer? _blinkTimer;
  Timer? _searchDebounce;

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
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    _listCtrl.dispose();
    _blinkTimer?.cancel();
    super.dispose();
  }

  Future<void> _runSearch() async {
    final provider = context.read<DoneProvider>();
    provider.setQuery(_searchCtrl.text.trim());
    await provider.load();
  }

  void _scheduleSearch() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(_searchDebounceDelay, () {
      if (!mounted) return;
      unawaited(_runSearch());
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DoneProvider>();
    final media = MediaQuery.of(context);
    final isLandscape = media.orientation == Orientation.landscape;
    final shortestSide = media.size.shortestSide;
    final isMobileLandscape = isLandscape && shortestSide < 600;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            12,
            isMobileLandscape ? 8 : 12,
            12,
            isMobileLandscape ? 6 : 10,
          ),
          child: _SearchBar(
            compact: isMobileLandscape,
            controller: _searchCtrl,
            onChanged: (_) => _scheduleSearch(),
            onSubmit: () {
              _searchDebounce?.cancel();
              unawaited(_runSearch());
            },
            onClear: () {
              _searchDebounce?.cancel();
              _searchCtrl.clear();
              unawaited(_runSearch());
              setState(() {});
            },
          ),
        ),

        Container(
          padding: EdgeInsets.fromLTRB(
            16,
            isMobileLandscape ? 8 : 10,
            16,
            isMobileLandscape ? 8 : 10,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F8FA),
            border: Border(
              top: BorderSide(color: Colors.black.withOpacity(0.06)),
              bottom: BorderSide(color: Colors.black.withOpacity(0.06)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Selesai',
                  style: TextStyle(
                    fontSize: isMobileLandscape ? 14 : 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _Badge(
                text: '${vm.items.length} order',
                compact: isMobileLandscape,
              ),
            ],
          ),
        ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await context.read<SyncService>().syncPendingOrders();
              await context.read<DoneProvider>().load();
            },
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
                    final data = vm.items[i];
                    final id = _toId(data['id']);
                    final printKey = id > 0 ? id : (data['local_id']?.hashCode ?? id);
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
                      child: _DoneOrderCard(
                        data: data,
                        isPrinting: _printingIds.contains(printKey),
                        onDetail: () async {
                          final row = vm.items[i];
                          final id = _toId(row['id']);

                          await showModalBottomSheet(
                            context: context,
                            useRootNavigator: true,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => SizedBox(
                              height: MediaQuery.of(context).size.height * 0.92,
                              child: DetailOrderSheet(
                                orderId: id > 0 ? id : -1,
                                stockConflictMessage: row['last_error']?.toString(),
                                loadDetail: (_) =>
                                    context.read<DoneProvider>().getOrderDetailFromListItem(row),
                              ),
                            ),
                          );
                        },
                        onPrint: () async {
                          final row = vm.items[i];
                          await _printOrder(row);
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

  Future<void> _printOrder(Map<String, dynamic> row) async {
    final id = _toId(row['id']);
    final printKey = id > 0 ? id : row['local_id'].hashCode;

    if (_printingIds.contains(printKey)) return;

    setState(() => _printingIds.add(printKey));
    try {
      final order =
          await context.read<DoneProvider>().getPrintDetailFromListItem(row);

      final paid = _pickNum(order, ['payment', 'paid_amount']) ??
          _pickNum(order, ['latest_payment', 'paid_amount']) ??
          _pickNum(order, ['paid_amount']) ??
          _orderGrandTotal(order);

      final change = _pickNum(order, ['payment', 'change_amount']) ??
          _pickNum(order, ['latest_payment', 'change_amount']) ??
          _pickNum(order, ['change_amount']) ??
          0;

      final pm = context.read<PrinterManager>();
      final p = pm.defaultPrinter;
      if (p == null) throw Exception('Default printer belum dipilih');
      if (p.type != PrinterType.bluetooth ||
          p.address == null ||
          p.address!.trim().isEmpty) {
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
      if (mounted) setState(() => _printingIds.remove(printKey));
    }
  }

  @override
  void didUpdateWidget(covariant _DoneView oldWidget) {
    super.didUpdateWidget(oldWidget);

    final id = widget.focusOrderId;
    final focusChanged = widget.focusRequestKey != oldWidget.focusRequestKey;

    if (focusChanged && id != null && id > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _goToAndBlink(id);
      });
    }
  }

  Future<void> _goToAndBlink(int orderId) async {
    final vm = context.read<DoneProvider>();

    if (vm.items.isEmpty) {
      await vm.load();
    }
    if (!mounted) return;

    final idx = vm.items.indexWhere((e) => _toId(e['id']) == orderId);
    if (idx < 0) return;

    const approxItemHeight = 160.0;
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

    _blinkTimer?.cancel();
    setState(() => _blinkOrderId = orderId);

    _blinkTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _blinkOrderId = null);
    });
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
    required this.onChanged,
    required this.onSubmit,
    required this.onClear,
    this.compact = false,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;
  final VoidCallback onClear;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);

    final horizontalPadding = compact ? 10.0 : 12.0;
    final verticalPadding = compact ? 8.0 : 10.0;
    final iconSize = compact ? 20.0 : 24.0;
    final actionIconSize = compact ? 20.0 : 24.0;
    final buttonPadding = compact
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
        : const EdgeInsets.symmetric(horizontal: 14, vertical: 10);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 14 : 18),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            blurRadius: compact ? 10 : 16,
            offset: Offset(0, compact ? 6 : 10),
            color: Colors.black.withOpacity(0.04),
          )
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: iconSize),
          SizedBox(width: compact ? 8 : 10),
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              style: TextStyle(fontSize: compact ? 13 : 14),
              onChanged: onChanged,
              onSubmitted: (_) => onSubmit(),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Cari order (kode/meja/nama)…',
                hintStyle: TextStyle(fontSize: compact ? 13 : 14),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
              constraints: compact
                  ? const BoxConstraints(minWidth: 32, minHeight: 32)
                  : null,
              onPressed: onClear,
              icon: Icon(Icons.close_rounded, size: actionIconSize),
              tooltip: 'Reset',
            ),
          SizedBox(width: compact ? 4 : 6),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: brand,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(compact ? 10 : 12),
              ),
              padding: buttonPadding,
              minimumSize: compact ? const Size(0, 36) : null,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: onSubmit,
            child: Icon(Icons.search_rounded, size: compact ? 16 : 18),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.text,
    this.compact = false,
  });

  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF1D4ED8),
        ),
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
    final total = _calcGrandTotalFromMap(data);
    final roundingAmount = _calcCashRoundingAmount(data);
    final table = (data['table'] is Map ? (data['table']['table_no'] ?? '-') : '-').toString();
    final orderDateTime = _formatOrderDateTime(data);

    final media = MediaQuery.of(context);
    final isLandscape = media.orientation == Orientation.landscape;
    final shortestSide = media.size.shortestSide;

    // khusus mobile landscape
    final isMobileLandscape = isLandscape && shortestSide < 600;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onDetail,
        borderRadius: BorderRadius.circular(16),
        child: Container(
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
              ),
            ],
          ),
          child: isMobileLandscape
              ? _buildMobileLandscapeLayout(
                  code: code,
                  customer: customer,
                  table: table,
                  total: total,
                  roundingAmount: roundingAmount,
                  orderDateTime: orderDateTime,
                )
              : _buildDefaultLayout(
                  code: code,
                  customer: customer,
                  table: table,
                  total: total,
                  roundingAmount: roundingAmount,
                  orderDateTime: orderDateTime,
                ),
        ),
      ),
    );
  }

  Widget _buildDefaultLayout({
    required String code,
    required String customer,
    required String table,
    required num total,
    required num roundingAmount,
    required String? orderDateTime,
  }) {
    const brand = Color(0xFFAE1504);

    return Column(
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
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      code,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
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
                    orderDateTime != null
                        ? 'Meja: $table  |  $orderDateTime'
                        : 'Meja: $table',
                    style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.55)),
                  ),
                  if (data['is_local_only'] == true || data['is_synced'] == false) ...[
                    const SizedBox(height: 6),
                    Text(
                      (data['sync_status'] ?? '').toString() == 'STOCK_CONFLICT'
                          ? 'Konflik stok: ${((data['last_error'] ?? '').toString().trim().isNotEmpty) ? data['last_error'] : 'stok tidak cukup di server'}'
                          : 'Perubahan lokal belum tersinkron',
                      style: TextStyle(
                        fontSize: 11,
                        color: (data['sync_status'] ?? '').toString() == 'STOCK_CONFLICT'
                            ? const Color(0xFFB91C1C)
                            : Colors.orange.shade800,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
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
                  Text(
                    'Total',
                    style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.55)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Rp ${_rupiah(total)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  if (roundingAmount > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '+ Pembulatan Cash Rp ${_rupiah(roundingAmount)}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: brand,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: isPrinting ? null : onPrint,
              icon: isPrinting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.print_rounded),
              tooltip: 'Print',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileLandscapeLayout({
    required String code,
    required String customer,
    required String table,
    required num total,
    required num roundingAmount,
    required String? orderDateTime,
  }) {
    const brand = Color(0xFFAE1504);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        code,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _statusChipDone(),
                ],
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
                orderDateTime != null
                    ? 'Meja: $table  |  $orderDateTime'
                    : 'Meja: $table',
                style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.55)),
              ),
              if (data['is_local_only'] == true || data['is_synced'] == false) ...[
                const SizedBox(height: 6),
                Text(
                  (data['sync_status'] ?? '').toString() == 'STOCK_CONFLICT'
                      ? 'Konflik stok: ${((data['last_error'] ?? '').toString().trim().isNotEmpty) ? data['last_error'] : 'stok tidak cukup di server'}'
                      : 'Perubahan lokal belum tersinkron',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: (data['sync_status'] ?? '').toString() == 'STOCK_CONFLICT'
                        ? const Color(0xFFB91C1C)
                        : Colors.orange.shade800,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),

        Flexible(
          flex: 0,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.55)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rp ${_rupiah(total)}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                    ),
                    if (roundingAmount > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        '+ Pembulatan Rp ${_rupiah(roundingAmount)}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: brand,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(width: 8),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  onPressed: isPrinting ? null : onPrint,
                  icon: isPrinting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.print_rounded),
                  tooltip: 'Print',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusChipDone() {
    final isLocalOnly = data['is_local_only'] == true;
    final isSynced = data['is_synced'] == true;
    final syncStatus = (data['sync_status'] ?? '').toString();

    if (syncStatus == 'STOCK_CONFLICT') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F2),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.error_outline_rounded, size: 14, color: Color(0xFFDC2626)),
            SizedBox(width: 6),
            Text(
              'Konflik Stok',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      );
    }

    if (isLocalOnly || !isSynced || syncStatus == 'PENDING_FINISH') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFFF59E0B),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'Pending Sync',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      );
    }

    const bg = Color(0xFFEEF2FF);
    const border = Color(0xFFC7D2FE);
    const dot = Color(0xFF4F46E5);

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
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: dot,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'Selesai',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
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

num _toNum(dynamic v) {
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

num _calcGrandTotalFromMap(Map<String, dynamic> data) {
  if (data['grand_total_local'] != null) {
    return _toNum(data['grand_total_local']).ceil();
  }

  final subtotal = _toNum(data['total_order_value']);
  final isPpnActive = _toBool(data['is_ppn_active']);
  final ppnPercent = _toNum(data['ppn']);

  final baseTotal = isPpnActive
      ? (subtotal + (subtotal * ppnPercent / 100)).ceil()
      : subtotal.ceil();
  return baseTotal + _calcCashRoundingAmount(data, baseTotal: baseTotal);
}

num _orderGrandTotal(Map<String, dynamic> order) {
  if (order['grand_total_local'] != null) {
    return _toNum(order['grand_total_local']).ceil();
  }

  final subtotal = _toNum(order['total_order_value']);
  final isPpnActive = _toBool(order['is_ppn_active']);
  final ppnPercent = _toNum(order['ppn']);

  final baseTotal = isPpnActive
      ? (subtotal + (subtotal * ppnPercent / 100))
      : subtotal;

  return baseTotal.ceil() + _calcCashRoundingAmount(order, baseTotal: baseTotal.ceil());
}

num _calcCashRoundingAmount(Map<String, dynamic> data, {num? baseTotal}) {
  final stored = _pickNum(data, ['cash_rounding_amount']) ??
      _pickNum(data, ['rounding_amount']) ??
      _pickNum(data, ['payment', 'rounding_amount']) ??
      _pickNum(data, ['latest_payment', 'rounding_amount']);
  if (stored != null && stored > 0) return stored.ceil();

  final method = (data['payment_method'] ?? '').toString().toUpperCase();
  if (method != 'CASH') return 0;

  final effectiveBaseTotal = baseTotal ?? _baseGrandTotal(data);
  final snap = _toNum(data['grand_total_local'] ?? data['grand_total']);
  final diff = snap.ceil() - effectiveBaseTotal.ceil();
  return diff > 0 ? diff : 0;
}

num _baseGrandTotal(Map<String, dynamic> data) {
  final subtotal = _toNum(data['total_order_value'] ?? data['subtotal']);
  final isPpnActive = _toBool(data['is_ppn_active']);
  final ppnPercent = _toNum(data['ppn']);
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

String? _formatOrderDateTime(Map<String, dynamic> data) {
  final raw = (data['created_at'] ??
          data['sort_time'] ??
          data['updated_at_local'] ??
          data['cached_at'])
      ?.toString();
  if (raw == null || raw.trim().isEmpty) return null;

  final dateTime = DateTime.tryParse(raw)?.toLocal();
  if (dateTime == null) return null;

  final date =
      '${_twoDigits(dateTime.day)}/${_twoDigits(dateTime.month)}/${dateTime.year}';
  final time =
      '${_twoDigits(dateTime.hour)}:${_twoDigits(dateTime.minute)}';
  return '$date $time';
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');
