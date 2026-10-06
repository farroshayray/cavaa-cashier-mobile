import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/core/network/dio_client.dart';
import '/features/cashier/data/report_api.dart';
import '/features/owner/presentation/widgets/dock_inset.dart';
import 'stock_report_export.dart';
import 'stock_report_widgets.dart';

class StockLedgerPage extends StatefulWidget {
  const StockLedgerPage({
    super.key,
    required this.stockId,
    required this.stockName,
    required this.from,
    required this.to,
    required this.rangeLabel,
  });

  final int stockId;
  final String stockName;
  final String from;
  final String to;
  final String rangeLabel;

  @override
  State<StockLedgerPage> createState() => _StockLedgerPageState();
}

class _StockLedgerPageState extends State<StockLedgerPage> {
  bool _loading = true;
  bool _exporting = false;
  String? _error;
  String _unit = '';
  String _code = '';
  List<Map<String, dynamic>> _lines = const [];

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
      final api = ReportApi(context.read<DioClient>().dio);
      final res = await api.getStockLedger(
        stockId: widget.stockId,
        from: widget.from,
        to: widget.to,
      );
      final data = res['data'];
      final map = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
      final raw = map['lines'];
      setState(() {
        _unit = map['unit']?.toString() ?? '';
        _code = map['stock_code']?.toString() ?? '';
        _lines = raw is List
            ? raw
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _export() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final api = ReportApi(context.read<DioClient>().dio);
      final safeCode = _code.isNotEmpty
          ? _code.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')
          : '${widget.stockId}';
      await exportStockReportCsv(
        context: context,
        fetchCsv: () => api.exportStockLedger(
          stockId: widget.stockId,
          from: widget.from,
          to: widget.to,
        ),
        fileName: 'kartu_stok_${safeCode}_${widget.from}_${widget.to}.xlsx',
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFAE1504);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: Text(
          widget.stockName,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: brand,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: DockAwareFab(
        child: FloatingActionButton.extended(
          onPressed: (_loading || _exporting) ? null : _export,
          backgroundColor: brand,
          foregroundColor: Colors.white,
          icon: _exporting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.file_download_outlined),
          label: Text(_exporting ? 'Exporting...' : 'Export Excel'),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: brand))
          : RefreshIndicator(
              color: brand,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100)
                    .withBottomInset(context),
                children: [
                  Text(
                    'Kartu stok · Periode: ${widget.rangeLabel}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.black.withValues(alpha: 0.55),
                    ),
                  ),
                  if (_code.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _code,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 14),
                  if (_lines.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Text(
                        'Belum ada mutasi di periode ini.',
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.55),
                        ),
                      ),
                    )
                  else
                    ...List.generate(_lines.length, (index) {
                      return StockLedgerTimelineTile(
                        line: _lines[index],
                        unit: _unit,
                        isFirst: index == 0,
                        isLast: index == _lines.length - 1,
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
