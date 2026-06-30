// lib/features/cashier/presentation/pages/tabs/process_tab.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/features/cashier/presentation/printing/receipt_action_service.dart';
import '/features/cashier/presentation/widgets/receipt_action_icon_button.dart';
import '/features/cashier/data/local/db/sync/sync_service.dart';
import '/features/cashier/data/sync/order_tab_coordinator.dart';
import '/features/cashier/presentation/providers/done_provider.dart';

// ✅ bikin provider khusus proses (contoh)
import '../../providers/process_provider.dart';
import '../../providers/payment_provider.dart';

import '/features/cashier/presentation/pages/tabs/modals/detail_order_sheet.dart';
import '/features/cashier/presentation/pages/tabs/modals/edit_order_sheet.dart';
import '/features/cashier/presentation/utils/order_edit_utils.dart';
import '/features/cashier/presentation/utils/order_delete_helper.dart';
import '/features/cashier/presentation/utils/order_tab_grouping.dart';
import '/features/cashier/presentation/widgets/order_tab_section_widgets.dart';
import '/features/cashier/utils/cash_rounding_helpers.dart';
import '/features/scanner/pages/barcode_scanner_page.dart';
// kalau nanti ada modal khusus proses/selesai, import juga

class ProcessTab extends StatefulWidget {
  const ProcessTab({
    super.key,
    this.focusOrderId,
    this.focusRequestKey = 0,
  });

  final int? focusOrderId;
  final int focusRequestKey;

  @override
  State<ProcessTab> createState() => _ProcessTabState();
}

class _ProcessTabState extends State<ProcessTab> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;

    Future.microtask(() => context.read<ProcessProvider>().load());
  }

  @override
  Widget build(BuildContext context) {
    return _ProcessView(
      focusOrderId: widget.focusOrderId,
      focusRequestKey: widget.focusRequestKey,
    );
  }
}

class _ProcessView extends StatefulWidget {
  const _ProcessView({
    this.focusOrderId,
    this.focusRequestKey = 0,
  });

  final int? focusOrderId;
  final int focusRequestKey;

  @override
  State<_ProcessView> createState() => _ProcessViewState();
}


class _ProcessViewState extends State<_ProcessView> {
  static const Duration _searchDebounceDelay = Duration(milliseconds: 500);

  final _searchCtrl = TextEditingController();
  final ScrollController _listCtrl = ScrollController();
  double _lastOffset = 0;
  int? _blinkOrderId;
  Timer? _blinkTimer;
  Timer? _searchDebounce;
  int? _lastHandledFocus;
  ProcessSection? _sectionFilter;
  final Set<ProcessSection> _collapsedProcessSections = {};

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
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    _listCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _ProcessView oldWidget) {
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

  Future<void> _runSearch() async {
    final provider = context.read<ProcessProvider>();
    provider.setQuery(_searchCtrl.text.trim());
    await provider.load();
  }

  Future<void> _handleProcessAction(Map<String, dynamic> row) async {
    final provider = context.read<ProcessProvider>();
    final status = (row['order_status'] ?? '').toString();

    if (status == 'OPENBILL_CONFIRMATION') {
      final res = await provider.actionProcess(row);
      if (!mounted) return;

      final message = (res['message'] ?? 'Berhasil diproses').toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

      if ((res['status'] ?? '').toString() == 'warning') {
        await provider.load();
      }
      return;
    }

    final detail = await provider.getOrderDetailFromListItem(row);
    if (!mounted) return;

    final selectedSelections = await showModalBottomSheet<List<ServeItemSelection>>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ServeItemsSheet(order: detail),
    );

    if (selectedSelections == null || selectedSelections.isEmpty) {
      return;
    }

    final res = await provider.actionServeItems(
      row,
      selections: selectedSelections,
    );
    if (!mounted) return;

    await context.read<OrderTabCoordinator>().reloadAllTabs(
      payment: context.read<PaymentProvider>(),
      process: context.read<ProcessProvider>(),
      done: context.read<DoneProvider>(),
    );

    if (!mounted) return;
    final message = (res['message'] ?? 'Item berhasil ditandai served').toString();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _scheduleSearch() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(_searchDebounceDelay, () {
      if (!mounted) return;
      unawaited(_runSearch());
    });
  }

  Future<void> _scanAndSearch() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerPage()),
    );

    if (!mounted) return;

    if (code != null && code.trim().isNotEmpty) {
      _searchCtrl.text = code.trim();
      _searchDebounce?.cancel();
      await _runSearch();
      FocusScope.of(context).unfocus();
    }
  }

  Widget _buildProcessCard(
    BuildContext context,
    ProcessProvider vm,
    Map<String, dynamic> data,
  ) {
    final id = _toId(data['id']);
    final actionKey = id > 0
        ? id
        : ((data['local_id'] ?? '').toString().isNotEmpty
            ? data['local_id'].toString().hashCode
            : data.hashCode);
    final receiptKey = id > 0 ? id : (data['local_id']?.hashCode ?? id);
    final blinking = (_blinkOrderId != null && _blinkOrderId == id);

    return KeyedSubtree(
      key: ValueKey('process-$actionKey'),
      child: AnimatedContainer(
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
          isReceiptBusy: _receiptBusyIds.contains(receiptKey),
          isActing: vm.isActionLoading(actionKey),
          onDetail: () async {
            final detailId = _toId(data['id']);
            await _openProcessOrderDetail(context, data, detailId);
          },
          onReceiptPrint: () => _handleReceiptPrint(data),
          onReceiptShare: () => _handleReceiptShare(data),
          onProcess: () async {
            try {
              await _handleProcessAction(data);
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Gagal proses: $e')),
              );
            }
          },
          onCancelProcess: () async {
            try {
              final res = await context.read<ProcessProvider>().actionCancelProcess(data);
              if (!mounted) return;

              final message = (res['message'] ?? 'Proses dibatalkan').toString();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
              );
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Gagal batal: $e')),
              );
            }
          },
          onFinish: () async {
            try {
              final res = await context.read<ProcessProvider>().actionFinish(data);

              if (!mounted) return;

              await context.read<OrderTabCoordinator>().reloadAllTabs(
                payment: context.read<PaymentProvider>(),
                process: context.read<ProcessProvider>(),
                done: context.read<DoneProvider>(),
              );

              if (!mounted) return;

              final message = (res['message'] ?? 'Order selesai').toString();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
              );
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Gagal selesai: $e')),
              );
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProcessProvider>();
    final media = MediaQuery.of(context);
    final isLandscape = media.orientation == Orientation.landscape;
    final shortestSide = media.size.shortestSide;
    final isMobileLandscape = isLandscape && shortestSide < 600;
    final groupedSections = groupProcessItems(vm.items, filter: _sectionFilter);
    final hasSearchQuery = vm.query.trim().isNotEmpty;

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
            onScan: _scanAndSearch,
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

        ...buildProcessSectionFilterChips(
          items: vm.items,
          selected: _sectionFilter,
          compact: isMobileLandscape,
          onSelected: (value) => setState(() => _sectionFilter = value),
        ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await context.read<SyncService>().syncPendingOrders();
              await context.read<OrderTabCoordinator>().reloadAllTabs(
                payment: context.read<PaymentProvider>(),
                process: context.read<ProcessProvider>(),
                done: context.read<DoneProvider>(),
              );
            },
            child: Builder(
              builder: (_) {
                if (vm.isLoading && vm.items.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 200),
                      Center(child: CircularProgressIndicator()),
                    ],
                  );
                }

                if (vm.error != null) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
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
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 80),
                      Icon(Icons.inbox_outlined, size: 56, color: Colors.black.withOpacity(0.35)),
                      const SizedBox(height: 10),
                      Text(
                        hasSearchQuery
                            ? 'Tidak ditemukan untuk pencarian "${vm.query}".'
                            : 'Tidak ada order yang sedang diproses.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black.withOpacity(0.60)),
                      ),
                    ],
                  );
                }

                if (groupedSections.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 80),
                      Icon(Icons.filter_list_off_outlined, size: 56, color: Colors.black.withOpacity(0.35)),
                      const SizedBox(height: 10),
                      Text(
                        'Tidak ada order di kelompok ini.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black.withOpacity(0.60)),
                      ),
                    ],
                  );
                }

                return CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  controller: _listCtrl,
                  slivers: buildGroupedOrderSlivers<ProcessSection>(
                    context: context,
                    sections: groupedSections,
                    compact: isMobileLandscape,
                    isSectionExpanded: _isProcessSectionExpanded,
                    onToggleSection: _toggleProcessSection,
                    itemBuilder: (context, data, i) =>
                        _buildProcessCard(context, vm, data),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  final Set<int> _receiptBusyIds = <int>{};

  int _receiptKeyFor(Map<String, dynamic> row) {
    final id = _toId(row['id']);
    return id > 0 ? id : row['local_id'].hashCode;
  }

  Future<void> _withReceiptBusy(
    Map<String, dynamic> row,
    Future<void> Function() action,
  ) async {
    final key = _receiptKeyFor(row);
    if (_receiptBusyIds.contains(key)) return;

    setState(() => _receiptBusyIds.add(key));
    try {
      await action();
    } finally {
      if (mounted) setState(() => _receiptBusyIds.remove(key));
    }
  }

  Future<void> _handleReceiptPrint(Map<String, dynamic> row) async {
    await _withReceiptBusy(row, () async {
      await ReceiptActionService(context).printReceipt(
        row: row,
        fetchOrder: context.read<ProcessProvider>().getPrintDetailFromListItem,
        requirePaid: true,
      );
    });
  }

  Future<void> _handleReceiptShare(Map<String, dynamic> row) async {
    await _withReceiptBusy(row, () async {
      await ReceiptActionService(context).shareReceiptPdf(
        row: row,
        fetchOrder: context.read<ProcessProvider>().getPrintDetailFromListItem,
        requirePaid: true,
      );
    });
  }

  Future<void> _refreshKeepScroll() async {
    if (_listCtrl.hasClients) _lastOffset = _listCtrl.offset;

    await context.read<ProcessProvider>().load(silent: true);

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

  bool _isProcessSectionExpanded(ProcessSection section) =>
      !_collapsedProcessSections.contains(section);

  void _toggleProcessSection(ProcessSection section) {
    setState(() {
      if (_collapsedProcessSections.contains(section)) {
        _collapsedProcessSections.remove(section);
      } else {
        _collapsedProcessSections.add(section);
      }
    });
  }

  Future<void> _goToAndBlink(int orderId) async {
    final vm = context.read<ProcessProvider>();

    if (vm.items.isEmpty) {
      await vm.load();
    }
    if (!mounted) return;

    ProcessSection? targetSection;
    for (final item in vm.items) {
      if (_toId(item['id']) == orderId) {
        targetSection = classifyProcessSection(item);
        break;
      }
    }

    final needsExpand = targetSection != null &&
        _collapsedProcessSections.contains(targetSection);

    if (needsExpand) {
      setState(() => _collapsedProcessSections.remove(targetSection));
    }

    void scrollAndBlink() {
      if (!mounted) return;

      var grouped = groupProcessItems(vm.items, filter: _sectionFilter);
      var flatItems = flattenGroupedItems(
        grouped,
        isSectionExpanded: _isProcessSectionExpanded,
      );
      var idx = flatItems.indexWhere((e) => _toId(e['id']) == orderId);

      if (idx < 0 && _sectionFilter != null) {
        setState(() => _sectionFilter = null);
        grouped = groupProcessItems(vm.items);
        flatItems = flattenGroupedItems(
          grouped,
          isSectionExpanded: _isProcessSectionExpanded,
        );
        idx = flatItems.indexWhere((e) => _toId(e['id']) == orderId);
      }
      if (idx < 0) return;

      final targetOffset = estimateGroupedScrollOffset(
        sections: grouped,
        orderId: orderId,
        toId: _toId,
        isSectionExpanded: _isProcessSectionExpanded,
        cardHeight: 170,
      );

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

    if (needsExpand) {
      WidgetsBinding.instance.addPostFrameCallback((_) => scrollAndBlink());
    } else {
      scrollAndBlink();
    }
  }

}

int _toId(dynamic v) => (v is int) ? v : int.tryParse(v.toString()) ?? 0;

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onScan,
    required this.onChanged,
    required this.onSubmit,
    required this.onClear,
    this.compact = false,
  });

  final TextEditingController controller;
  final VoidCallback onScan;
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
          IconButton(
            visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
            constraints: compact
                ? const BoxConstraints(minWidth: 32, minHeight: 32)
                : null,
            onPressed: onScan,
            icon: Icon(Icons.qr_code_scanner_rounded, size: actionIconSize),
            tooltip: 'Scan barcode',
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

class _ProcessOrderCard extends StatelessWidget {
  const _ProcessOrderCard({
    super.key,
    required this.data,
    required this.onDetail,
    required this.onReceiptPrint,
    required this.onReceiptShare,
    required this.isReceiptBusy,
    required this.onProcess,
    required this.onCancelProcess,
    required this.onFinish,
    required this.isActing,
  });

  final Map<String, dynamic> data;
  final VoidCallback onDetail;
  final VoidCallback onReceiptPrint;
  final VoidCallback onReceiptShare;
  final bool isReceiptBusy;
  final VoidCallback onProcess;
  final VoidCallback onCancelProcess;
  final VoidCallback onFinish;
  final bool isActing;

  @override
  Widget build(BuildContext context) {
    final code = (data['booking_order_code'] ?? '-').toString();
    final customer = (data['customer_name'] ?? '-').toString();
    final total = _calcGrandTotalFromMap(data);
    final roundingAmount = _calcCashRoundingAmount(data);
    final orderDateTime = _formatOrderDateTime(data);
    final table = (
      data['table'] is Map
          ? (data['table']['table_no'] ?? data['table_no_snapshot'] ?? '-')
          : (data['table_no_snapshot'] ?? '-')
    ).toString();

    final media = MediaQuery.of(context);
    final isLandscape = media.orientation == Orientation.landscape;
    final shortestSide = media.size.shortestSide;

    // khusus mobile landscape
    final isMobileLandscape = isLandscape && shortestSide < 600;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isActing ? null : onDetail,
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
    final canPrint = canPrintProcessReceipt(data);

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                      if (_toBool(data['openbill_flag']) ||
                          data['payment_method']?.toString() == 'OPENBILL' ||
                          (data['order_status'] ?? '').toString().startsWith('OPENBILL')) ...[
                        const SizedBox(width: 6),
                        const _Badge(text: 'Openbill', compact: true),
                      ],
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
                  if (data['is_synced'] == false &&
                      localSyncStatusMessage(data) != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      localSyncStatusMessage(data)!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: localSyncStatusMessageIsError(
                              localSyncStatusMessage(data),
                              data,
                            )
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
            if (isActing)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            if (canPrint)
              ReceiptActionIconButton(
                isLoading: isReceiptBusy,
                enabled: !isActing,
                onPrint: onReceiptPrint,
                onShare: onReceiptShare,
              ),
            _buildStatusActions(),
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
    final canPrint = canPrintProcessReceipt(data);

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
                  if (_toBool(data['openbill_flag']) ||
                      data['payment_method']?.toString() == 'OPENBILL' ||
                      (data['order_status'] ?? '').toString().startsWith('OPENBILL')) ...[
                    const SizedBox(width: 6),
                    const _Badge(text: 'Openbill', compact: true),
                  ],
                  const SizedBox(width: 8),
                  _statusChip(),
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
              if (localSyncStatusMessage(data) != null) ...[
                const SizedBox(height: 6),
                Text(
                  localSyncStatusMessage(data)!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: localSyncStatusMessageIsError(
                          localSyncStatusMessage(data),
                          data,
                        )
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

                if (isActing)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                if (canPrint)
                  ReceiptActionIconButton(
                    compact: true,
                    isLoading: isReceiptBusy,
                    enabled: !isActing,
                    onPrint: onReceiptPrint,
                    onShare: onReceiptShare,
                  ),
                _buildLandscapeStatusActions(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusChip() {
    final st = (data['order_status'] ?? '').toString();
    final isLocalOnly = data['is_local_only'] == true;
    final isSynced = data['is_synced'] == true;
    final pendingAction = (data['pending_action'] ?? '').toString();
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

    if (isLocalOnly) {
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

    if (!isSynced) {
      String label = 'Menunggu sync';

      if (pendingAction == 'PROCESS') {
        label = 'Sync proses';
      } else if (pendingAction == 'CANCEL_PROCESS') {
        label = 'Sync batal';
      } else if (pendingAction == 'FINISH') {
        label = 'Sync selesai';
      } else if (pendingAction == 'SERVE_ITEMS') {
        label = 'Sync served';
      } else if (pendingAction == 'MARK_KITCHEN_SERVED') {
        label = 'Sync served kitchen';
      }

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
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      );
    }

    Color bg = const Color(0xFFECFDF5);
    Color border = const Color(0xFFBBF7D0);
    Color dot = const Color(0xFF22C55E);
    String label = 'Proses';

    if (st == 'PAID' || st == 'OPENBILL_WAITING_ORDER') {
      bg = const Color(0xFFFFF7ED);
      border = const Color(0xFFFED7AA);
      dot = const Color(0xFFEA580C);
      label = 'Siap proses';
    } else if (st == 'OPENBILL_CONFIRMATION') {
      bg = const Color(0xFFFEF3C7);
      border = const Color(0xFFFDE68A);
      dot = const Color(0xFFD97706);
      label = 'Konfirmasi';
    } else if (st == 'PROCESSED') {
      label = 'Proses';
    } else if (st == 'SERVED') {
      bg = const Color(0xFFF5F3FF);
      border = const Color(0xFFDDD6FE);
      dot = const Color(0xFF7C3AED);
      label = 'Selesai';
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
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dot,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusActions() {
    final st = (data['order_status'] ?? '').toString();

    if (st == 'PAID' || st == 'OPENBILL_CONFIRMATION' || st == 'OPENBILL_WAITING_ORDER' || st == 'PROCESSED') {
      final buttonText = st == 'OPENBILL_CONFIRMATION' ? 'Konfirmasi' : 'Pilih Served';
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: ElevatedButton(
          onPressed: isActing ? null : onProcess,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEA580C),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.w900)),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildLandscapeStatusActions() {
    final st = (data['order_status'] ?? '').toString();

    if (st == 'PAID' || st == 'OPENBILL_CONFIRMATION' || st == 'OPENBILL_WAITING_ORDER' || st == 'PROCESSED') {
      final buttonText = st == 'OPENBILL_CONFIRMATION' ? 'Konfirmasi' : 'Pilih Served';
      return Padding(
        padding: const EdgeInsets.only(right: 4),
        child: ElevatedButton(
          onPressed: isActing ? null : onProcess,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEA580C),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            minimumSize: const Size(0, 40),
          ),
          child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.w900)),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _ServeItemsSheet extends StatefulWidget {
  const _ServeItemsSheet({required this.order});

  final Map<String, dynamic> order;

  @override
  State<_ServeItemsSheet> createState() => _ServeItemsSheetState();
}

class _ServeItemsSheetState extends State<_ServeItemsSheet> {
  final Set<String> _selectedKeys = <String>{};

  String _selectionKey(Map<String, dynamic> item) {
    final id = orderDetailId(item);
    if (id != null && id > 0) return 'id:$id';
    final uuid = (item['local_detail_uuid'] ?? '').toString().trim();
    if (uuid.isNotEmpty) return 'uuid:$uuid';
    return '';
  }

  List<ServeItemSelection> _buildSelections() {
    return _selectedKeys.map((key) {
      if (key.startsWith('id:')) {
        return ServeItemSelection(
          serverDetailId: int.tryParse(key.substring(3)),
        );
      }
      if (key.startsWith('uuid:')) {
        return ServeItemSelection(clientDetailUuid: key.substring(5));
      }
      return const ServeItemSelection();
    }).where((item) => item.isValid).toList();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final details = ((order['order_details'] as List?) ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final hasSelectableItems =
        details.any(isItemAwaitingCashierServe);

    return SafeArea(
      top: false,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Material(
          color: Colors.white,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FA),
                    border: Border(
                      bottom: BorderSide(color: Colors.black.withOpacity(0.08)),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Pilih Menu Served',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: details.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Tidak ada menu pada order ini.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black.withOpacity(0.65)),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                          itemBuilder: (_, index) {
                            final item = details[index];
                            final selectionKey = _selectionKey(item);
                            final qty = _toNum(item['quantity']).toInt();
                            final name = (item['product_name'] ?? 'Produk').toString();
                            final note = (item['customer_note'] ?? '').toString().trim();
                            final optionLines = _orderDetailOptionLines(item, qty);
                            final state = _resolveProcessItemState(item, order);
                            final isSelectable = isItemAwaitingCashierServe(item) &&
                                selectionKey.isNotEmpty;
                            final checked = _selectedKeys.contains(selectionKey);

                            return Opacity(
                              opacity: isSelectable ? 1 : 0.55,
                              child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: isSelectable
                                  ? () {
                                setState(() {
                                  if (checked) {
                                    _selectedKeys.remove(selectionKey);
                                  } else {
                                    _selectedKeys.add(selectionKey);
                                  }
                                });
                              }
                                  : null,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelectable
                                        ? Colors.black.withOpacity(0.08)
                                        : Colors.black.withOpacity(0.05),
                                  ),
                                  color: !isSelectable
                                      ? const Color(0xFFF3F4F6)
                                      : checked
                                          ? const Color(0xFFFFF7ED)
                                          : Colors.white,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (isSelectable)
                                      Checkbox(
                                        value: checked,
                                        onChanged: (_) {
                                          setState(() {
                                            if (checked) {
                                              _selectedKeys.remove(selectionKey);
                                            } else {
                                              _selectedKeys.add(selectionKey);
                                            }
                                          });
                                        },
                                      )
                                    else
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 4,
                                          right: 8,
                                          top: 2,
                                        ),
                                        child: Icon(
                                          state == _ProcessItemState.served
                                              ? Icons.check_circle_rounded
                                              : Icons.lock_outline_rounded,
                                          size: 22,
                                          color: Colors.black.withOpacity(0.35),
                                        ),
                                      ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  '$name × $qty',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                              if (state != null) _ProcessItemStateBadge(state: state),
                                            ],
                                          ),
                                          if (optionLines.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            ...optionLines.map(
                                              (line) => Padding(
                                                padding: const EdgeInsets.only(bottom: 2),
                                                child: Text(
                                                  '- $line',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.black.withOpacity(0.65),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                          if (note.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              'Catatan: $note',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontStyle: FontStyle.italic,
                                                color: Colors.black.withOpacity(0.55),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            );
                          },
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemCount: details.length,
                        ),
                ),
                if (!hasSelectableItems && details.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                    child: Text(
                      'Semua item sudah diambil kitchen atau kasir lain.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withOpacity(0.55),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedKeys.isEmpty
                          ? null
                          : () => Navigator.of(context).pop(_buildSelections()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _selectedKeys.isEmpty
                            ? 'Pilih item dulu'
                            : 'Tandai Served (${_selectedKeys.length})',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
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

class _ProcessItemStateBadge extends StatelessWidget {
  const _ProcessItemStateBadge({required this.state});

  final _ProcessItemState state;

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;
    late final IconData icon;
    late final String label;

    switch (state) {
      case _ProcessItemState.processing:
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF1D4ED8);
        icon = Icons.timelapse_rounded;
        label = 'Diproses';
        break;
      case _ProcessItemState.served:
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

enum _ProcessItemState {
  processing,
  served,
}

List<String> _orderDetailOptionLines(Map<String, dynamic> item, int qty) {
  final opts = (item['order_detail_options'] as List?) ?? [];
  final lines = <String>[];

  for (final raw in opts) {
    if (raw is! Map) continue;
    final om = Map<String, dynamic>.from(raw);

    String optName;
    String parentName;

    if (om['option'] is Map) {
      final opt = Map<String, dynamic>.from(om['option'] as Map);
      optName = (opt['name'] ?? '-').toString();
      parentName = opt['parent'] is Map
          ? (opt['parent']['name'] ?? '').toString()
          : '';
    } else {
      optName =
          (om['partner_product_option_name'] ?? om['name'] ?? '-').toString();
      parentName = (om['parent_name'] ?? '').toString();
    }

    final price = _toNum(om['price']);
    final priceText =
        price > 0 ? ' (+ Rp ${_rupiah(price * qty)})' : '';

    if (parentName.isNotEmpty) {
      lines.add('$parentName: $optName$priceText');
    } else {
      lines.add('$optName$priceText');
    }
  }

  return lines;
}

_ProcessItemState? _resolveProcessItemState(
  Map<String, dynamic> item,
  Map<String, dynamic> order,
) {
  final status = detailStatusOf(item);

  if (isDetailServedStatus(status)) {
    return _ProcessItemState.served;
  }

  if (isDetailProcessingStatus(status) || isDetailWithKitchenHands(item)) {
    return _ProcessItemState.processing;
  }

  return null;
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

bool _isProcessedByKitchen(Map<String, dynamic> data) {
  return _toBool(data['processed_by_kitchen']);
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

Future<void> _openProcessOrderDetail(
  BuildContext context,
  Map<String, dynamic> row,
  int id,
) async {
  final processProvider = context.read<ProcessProvider>();
  final editable = canEditOrder(row);
  final deletable = canDeleteUnpaidOrder(row);
  final kitchenServed = canMarkKitchenServed(row);
  final syncStatus = (row['sync_status'] ?? '').toString();

  await showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => SizedBox(
      height: MediaQuery.of(sheetCtx).size.height * 0.92,
      child: DetailOrderSheet(
        orderId: id > 0 ? id : -1,
        stockConflictMessage: row['last_error']?.toString(),
        loadDetail: (_) => processProvider.getOrderDetailFromListItem(row),
        canEdit: editable && syncStatus != 'PENDING_DELETE',
        canDelete: deletable && syncStatus != 'PENDING_DELETE',
        canMarkKitchenServed: kitchenServed && syncStatus != 'PENDING_DELETE',
        onMarkKitchenServed: kitchenServed && syncStatus != 'PENDING_DELETE'
            ? (detailId) async {
                final res = await processProvider.actionMarkKitchenServed(
                  row,
                  detailId: detailId,
                );
                final status = (res['status'] ?? '').toString();
                if (status == 'warning' || status == 'error') {
                  throw Exception((res['message'] ?? 'Gagal update status').toString());
                }
                await processProvider.load();
                await context.read<PaymentProvider>().load();
              }
            : null,
        onEdit: editable && syncStatus != 'PENDING_DELETE'
            ? () async {
                Navigator.of(sheetCtx).pop();
                final detail = await processProvider.getOrderDetailFromListItem(row);
                if (!context.mounted) return;
                await showModalBottomSheet(
                  context: context,
                  useRootNavigator: true,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => EditOrderSheet(
                    order: detail,
                    onSaved: () async {
                      await processProvider.load();
                      await context.read<PaymentProvider>().load();
                    },
                  ),
                );
              }
            : null,
        onDelete: deletable && syncStatus != 'PENDING_DELETE'
            ? () => confirmDeleteUnpaidOrder(context, row)
            : null,
      ),
    ),
  );
}
